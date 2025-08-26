#!/bin/bash
#
# cron job script : updates overpass database. ONLY "overpass" user does this.
#
# This script calls "getdiff" program to fetch differ files from the internet.
# The script then calls "op_update_db.sh" to apply those differs to overpass
# database.
#
# This script is part of  the Guide in "overpass-4-slackware" repository found at:
# https://github.com/waelhammoudeh/overpass-4-slackware
#
# Edit PSWD line with osm.org password if using geofabrik.de INTERNAL server.
#
# crontab entry to run script for daily updates: (overpass user cron job entry)
# @daily ID=opUpdate /usr/local/bin/cron4op.sh 1> /dev/null
#

OP_USR_ID=367

if [[ $EUID -ne $OP_USR_ID ]]; then

# this script is to be setup as cron job by "overpass" user

    exit 1
fi

# executables directory
EXEC_DIR=/usr/local/bin

GETDIFF=$EXEC_DIR/getdiff

# update from Geofabrik use: op_update_db.sh
# update from Planet server use op_planet_update_db.sh
# planet script makes extract from planet change files before applying

# UPDATER=$EXEC_DIR/op_update_db.sh
UPDATER=$EXEC_DIR/op_planet_update_db.sh

# path to getdiff.conf configuration AND newerFiles.txt files
SYS_ROOT=/var/lib

OP_DIR=$SYS_ROOT/overpass

GETDIFF_WD=$OP_DIR/getdiff

CONF=$GETDIFF_WD/getdiff.conf

NEWER_FILES=$GETDIFF_WD/newerFiles.txt

DATA_FILE_UPDATER=$EXEC_DIR/update_osm_file.sh

DATA_FILE_DIR=$OP_DIR/sources

OSC_LIST_FILE=$DATA_FILE_DIR/$(basename $DATA_FILE_UPDATER .sh).oscList

# password for OpenStreetMap.org user - assumes "USER" is set in "getdiff.conf" file.
# required for Geofabrik internal server. Leave as is if you use geofabrik.de public server.

# PSWD=YOUR-REAL-OSM-PASSWORD-HERE

# download Change Files
if [[ ! -x $GETDIFF ]]; then

  exit 1

fi

$GETDIFF -c $CONF -p $PSWD >/dev/null 2>&1

sleep 2

# update overpass database
if [[ -s $NEWER_FILES && -x $UPDATER ]]; then

    $UPDATER >/dev/null 2>&1
fi

sleep 1

# update region OSM data file
if [[ ! -x $DATA_FILE_UPDATER ]]; then
    exit 0
fi

if [[ -d $DATA_FILE_DIR && -s $OSC_LIST_FILE ]]; then
    $DATA_FILE_UPDATER >/dev/null 2>&1
fi

exit 0
