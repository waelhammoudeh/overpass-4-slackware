#!/bin/bash
#
# cron job script : calls "getdiff" then applies new Change files  (updates database)
# by calling "update_op_db.sh".
# script to retrieve differs then calls "update_op_db.sh" when new differs are ready
#
# This script is part of  the Guide in "overpass-4-slackware" repository found at:
# https://github.com/waelhammoudeh/overpass-4-slackware
#
# Scripts assumes the use of "getdiff" program mentioned in the above Guide and
# can be found next to it here: https://github.com/waelhammoudeh/getdiff
# It assumes the use of "getdiff.conf" with all required settings except the
# password for OSM account.
# This script assumes also that "update_op_db.sh" has the correct variables set
# and that both "getdiff" and "update_op_db.sh" are found in /usr/local/bin
# directory.
#
# crontab entry to run script for daily updates:
# @daily ID=opUpdate /usr/local/bin/cron4op.sh 1> /dev/null

# DB_DIR=/path/to/database
DB_DIR=/path/to/database
GETDIFF_WD=$DB_DIR/getdiff

# "newerFiles.txt" produced by "getdiff", found in getdiff work directory.
# Same as NEWER_FILES in "update_op_db.sh" and "NEWER_FILE" in getdiff.conf
newfiles=$GETDIFF_WD/newerFiles.txt

# "getdiff" configuration file.
CONF=$GETDIFF_WD/getdiff.conf

# password for OpenStreetMap.org user - assumes "USER" is set in "getdiff.conf" file.
# required for Geofabrik internal server. Leave as is if you use their public server.
PSWD=YOUR-REAL-OSM-PASSWORD-HERE

# download Change Files
/usr/local/bin/getdiff -c $CONF -p $PSWD 1>/dev/null

sleep 2

if [[ -s $newfiles ]]; then

    /usr/local/bin/update_op_db.sh 1>&2 >/dev/null
fi

exit 0
