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
# and that both "getdiff" and "update_op_db.sh" are found in /usr/local/bin/
# directory.
#
# crontab entry to run script for daily updates:
# @daily ID=opUpdate /usr/local/bin/cron4op.sh 1> /dev/null

# "newerFiles.txt" produced by "getdiff", found in getdiff work directory.
newfiles=/path/to/getdiff/newerFiles.txt

# user name on your local machine
LOCAL_USER=wael

# "getdiff" configuration file.
CONFIGURE=/home/wael/getdiff.conf

# password for OpenStreetMap.org user - assumes "USER" is set in "getdiff.conf" file.
# required for Geofabrik internal server. Leave as is if you use their public server.
PSWD=your-real-password

sudo -u $LOCAL_USER /usr/local/bin/getdiff -c $CONFIGURE -p $PSWD 1>/dev/null

sleep 5

if [[ -s $newfiles ]]; then

    /usr/local/bin/update_op_db.sh 1>&2 >/dev/null
fi

exit 0
