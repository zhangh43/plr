#!/bin/bash

source ~/.bashrc

set -x

PLRBIN=$1
OSVER=$2
WORKDIR=$3
TMPDIR=$4

cd $WORKDIR

# Install PL/R package
gppkg -i $PLRBIN/plr-$OSVER.gppkg || exit 1
source ~/.bashrc
gpstop -afr

rm -rf $TMPDIR
cp -r plr_src $TMPDIR
cd $TMPDIR

export USE_PGXS=1
# We need to first run "make" to generate plr.sql
make || exit 1
make installcheck || exit 1