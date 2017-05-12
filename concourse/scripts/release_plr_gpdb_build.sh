#!/bin/bash

set -x
set -e


if [ "$OSVER" == "centos5" ]; then
    rm -f /usr/bin/python && ln -s /usr/bin/python26 /usr/bin/python
fi

## Intsall GPDB
mkdir /usr/local/greenplum-db-devel
tar zxvf bin_gpdb/bin_gpdb.tar.gz -C /usr/local/greenplum-db-devel
source /usr/local/greenplum-db-devel/greenplum_path.sh

## Install R
tar zxvf bin_r/bin_r_$OSVER.tar.gz -C /usr/lib64

export R_HOME=/usr/lib64/R/lib64/R
export USE_PGXS=1
pushd plr_src
make clean
make
pushd gpdb
make cleanall && make
popd
popd

cp plr_src/gpdb/plr-*.gppkg bin_plr/
