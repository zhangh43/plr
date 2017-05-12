#!/bin/bash

source ~/.bashrc

set -x

PLRBIN=$1
OSVER=$2
WORKDIR=$3
TMPDIR=$4

cd $WORKDIR

# Install PL/R package
gppkg -i $PLRBIN/plr-*.gppkg || exit 1
source ~/.bashrc
gpstop -afr

rm -rf $TMPDIR
cp -r plr_src $TMPDIR
cd $TMPDIR

export USE_PGXS=1
# We need to first run "make" to generate plr.sql
if [ "$OSVER" == "suse11" ]; then
    # Official GPDB for SUSE 11 comes with very old version of glibc, getting rid of it here
    unset LD_LIBRARY_PATH
fi
make || exit 1
source ~/.bashrc
make installcheck || exit 1