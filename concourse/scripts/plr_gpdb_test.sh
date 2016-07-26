#!/bin/bash

set -x

WORKDIR=`pwd`

GPDBBIN=$1
PLRBIN=$2
OSVER=$3
GPHDFS=$4
TMPDIR=/tmp/localplrcopy

if [ "$OSVER" == "centos5" ]; then
    rm -f /usr/bin/python && ln -s /usr/bin/python26 /usr/bin/python
fi

# Put GPDB binaries in place to get pg_config
cp $GPDBBIN/$GPDBBIN.tar.gz /usr/local
pushd /usr/local
tar zxvf $GPDBBIN.tar.gz
if [ "$GPHDFS" != "none" ]; then
    cp $WORKDIR/$GPHDFS/gphdfs.so /usr/local/greenplum-db/lib/postgresql/gphdfs.so
fi
popd
source /usr/local/greenplum-db/greenplum_path.sh || exit 1

# GPDB Installation Preparation
mkdir /data
source plr_src/concourse/scripts/gpdb_install_functions.sh || exit 1
setup_gpadmin_user $OSVER
setup_sshd

# GPDB Installation
cp plr_src/concourse/scripts/*.sh /tmp
chmod 777 /tmp/*.sh
su - gpadmin -c "source /usr/local/greenplum-db/greenplum_path.sh && bash /tmp/gpdb_install.sh /data" || exit 1

# Installing PL/R and running tests
su - gpadmin -c "bash /tmp/plr_install_test.sh $PLRBIN $OSVER $WORKDIR $TMPDIR"
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