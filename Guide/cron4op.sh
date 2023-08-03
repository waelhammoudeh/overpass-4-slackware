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

UPDATER=$EXEC_DIR/op_update_db.sh

# path to getdiff.conf configuration AND newerFiles.txt files
SYS_ROOT=/var/lib

OP_DIR=$SYS_ROOT/overpass

GETDIFF_WD=$OP_DIR/getdiff

CONF=$GETDIFF_WD/getdiff.conf

NEWER_FILES=$GETDIFF_WD/newerFiles.txt

# password for OpenStreetMap.org user - assumes "USER" is set in "getdiff.conf" file.
# required for Geofabrik internal server. Leave as is if you use geofabrik.de public server.

# PSWD=YOUR-REAL-OSM-PASSWORD-HERE

# download Change Files
if [[ ! -x $GETDIFF ]]; then

  exit 1

fi

$GETDIFF -c $CONF -p $PSWD >/dev/null 2>&1

sleep 2

if [[ -s $NEWER_FILES ]]; then

    $UPDATER >/dev/null 2>&1
fi

exit 0
