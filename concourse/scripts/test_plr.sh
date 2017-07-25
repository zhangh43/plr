#!/bin/bash -l

set -exo pipefail

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${CWDIR}/../../../
source "${TOP_DIR}/gpdb_src/concourse/scripts/common.bash"

function prepare_test(){	

	cat > /home/gpadmin/test.sh <<-EOF
		set -exo pipefail

        if [ "$OSVER" == "suse11" ]; then
            # Official GPDB for SUSE 11 comes with very old version of glibc, getting rid of it here
            unset LD_LIBRARY_PATH
        fi

        source ${TOP_DIR}/gpdb_src/gpAux/gpdemo/gpdemo-env.sh
        source /usr/local/greenplum-db-devel/greenplum_path.sh
		gppkg -i bin_plr/plr-*.gppkg || exit 1
        source /usr/local/greenplum-db-devel/greenplum_path.sh
        gpstop -arf

        pushd plr_src/regress
        
        if [ "$GPGBVER" == "GPDB4.3" ]; then
            sed -i 's/extension/contrib/g' sql/plr.sql
            sed -i 's/extension/contrib/g' expected/plr.out
        fi


        \$GPHOME/lib/postgresql/pgxs/src/test/regress/pg_regress --psqldir=\$GPHOME/bin/ --load-language=plr --schedule=${TOP_DIR}/plr_src/regress/plr_schedule --srcdir=${TOP_DIR}/plr_src/regress/ --inputdir=${TOP_DIR}/plr_src/regress/ --outputdir=${TOP_DIR}/plr_src/regress/

        [ -s regression.diffs ] && cat regression.diffs && exit 1
        popd

	EOF

	chown -R gpadmin:gpadmin $(pwd)
	chown gpadmin:gpadmin /home/gpadmin/test.sh
	chmod a+x /home/gpadmin/test.sh
	mkdir -p /usr/lib64/R/lib64
	ln -s /usr/local/greenplum-db-devel/ext/R-3.3.1 /usr/lib64/R/lib64/R
	chown -R gpadmin:gpadmin /usr/lib64/R/

}

function test() {
	su gpadmin -c "bash /home/gpadmin/test.sh $(pwd)"

    case "$OSVER" in
    suse11)
        cp bin_plr/plr-*.gppkg plr_gppkg/plr-ossv8.3.0.15_pv2.x.0-$GPGBVER-orca-sles11-x86_64.gppkg
      ;;
    centos6)
        cp bin_plr/plr-*.gppkg plr_gppkg/plr-ossv8.3.0.15_pv2.x.0-$GPGBVER-orca-rhel6-x86_64.gppkg
      ;;
    centos7)
        cp bin_plr/plr-*.gppkg plr_gppkg/plr-ossv8.3.0.15_pv2.x.0-$GPGBVER-orca-rhel7-x86_64.gppkg
      ;;
    *) echo "Unknown OS: $OSVER"; exit 1 ;;
  esac

}

function setup_gpadmin_user() {
    case "$OSVER" in
    suse*)
      ${TOP_DIR}/gpdb_src/concourse/scripts/setup_gpadmin_user.bash "sles"
      ;;
    centos*)
       ${TOP_DIR}/gpdb_src/concourse/scripts/setup_gpadmin_user.bash "centos"
      ;;
    *) echo "Unknown OS: $OSVER"; exit 1 ;;
  esac
	
}

function _main() {
	time install_gpdb
	time setup_gpadmin_user

	time make_cluster
	time prepare_test 
	time test
}

_main "$@"