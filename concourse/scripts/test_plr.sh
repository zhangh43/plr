#!/bin/bash -l

set -eox pipefail

WORKDIR=`pwd`
TMPDIR=/tmp/localplrcopy

CWDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${CWDIR}/common.bash"

if [ "$OSVER" == "centos5" ]; then
    rm -f /usr/bin/python && ln -s /usr/bin/python26 /usr/bin/python
fi

# Put GPDB binaries in place to get pg_config
install_gpdb_bin
source /usr/local/greenplum-db-devel/greenplum_path.sh || exit 1

# GPDB Installation Preparation
mkdir /data
source plr_src/concourse/scripts/gpdb_install_functions.sh || exit 1
setup_gpadmin_user $OSVER
setup_sshd

# GPDB Installation
cp plr_src/concourse/scripts/*.sh /tmp
chmod 777 /tmp/*.sh
su - gpadmin -c "source /usr/local/greenplum-db-devel/greenplum_path.sh && bash /tmp/install-cluster.sh /data" || exit 1

# Installing PL/R and running tests
su - gpadmin -c "bash /tmp/plr_install_test.sh bin_plr $OSVER $WORKDIR $TMPDIR"
RETCODE=$?

if [ $RETCODE -ne 0 ]; then
    echo "PL/R test failed"
    echo "====================================================================="
    echo "========================= REGRESSION DIFFS =========================="
    echo "====================================================================="
    cat $TMPDIR/regression.out
    cat $TMPDIR/regression.diffs
    echo "====================================================================="
    echo "============================== RESULTS =============================="
    echo "====================================================================="
    cat $TMPDIR/results/plr.out
else
    echo "PL/R test succeeded"
fi

exit $RETCODE