#!/bin/bash

set -x
set -e

GPDBBIN=$1
OUTPUT=$2
OSVER=$3
PLRBIN=$4

if [ "$OSVER" == "centos5" ]; then
    rm -f /usr/bin/python && ln -s /usr/bin/python26 /usr/bin/python
fi

cp $GPDBBIN/$GPDBBIN.tar.gz /usr/local
pushd /usr/local
tar zxvf $GPDBBIN.tar.gz
popd
source /usr/local/greenplum-db/greenplum_path.sh

cp $PLRBIN/$PLRBIN.tar.gz /usr/lib64
pushd /usr/lib64
tar zxvf $PLRBIN.tar.gz
popd

export R_HOME=/usr/lib64/R/lib64/R
export USE_PGXS=1
pushd plr_src
make clean
make
pushd gpdb
make cleanall && make
popd
popd

cp plr_src/gpdb/plr-*.gppkg $OUTPUT/plr-$OSVER.gppkg