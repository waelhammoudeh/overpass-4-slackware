#!/usr/bin/bash

# This is "op_update_areas.sh" bash script:
# Updates areas in an overpass database where areas have been initialed already.
# Note: this is the same script as "op_make_areas.sh" with one exception; IMAX
# The loop counter {IMAX} here is set to half the value found in make areas
# script "op_make_areas.sh".
# This "op_update_areas.sh" script is intended to run weekly in a cron job to
# keep areas updated in the database.
#
# Note that both scripts write to the SAME log file!
#
# This file is part of the Guide for overpass-4-slackware found on GitHub at:
# https://github.com/waelhammoudeh/overpass-4-slackware
#
# Overpass_API is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Overpass_API is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Overpass_API. If not, see <https://www.gnu.org/licenses/>.

# this script is a rewrite of overpass script "rules_loop.sh" with new name: op_area_update.sh
#
#
# WARNING: Script needs to run to completion to avoid corrupted database.

# only overpass user can run this
#
OP_USR_ID=367

SYS_ROOT=/var/lib

# this can be a link to any directory on your system - "overpass" name should stay.
OP_DIR=$SYS_ROOT/overpass

# DB_DIR : overpass database directory
# DB_DIR=/path/to/your/database
DB_DIR=$OP_DIR/database

LOG_DIR=$OP_DIR/logs

EXEC_DIR=/usr/local/bin
DSPTCHR=$EXEC_DIR/dispatcher
RULES_DIR=/usr/local/rules
LOG_FILE=$LOG_DIR/op_update_areas.log

touch $LOG_FILE

if [[ $EUID -ne $OP_USR_ID ]]; then
    echo "$0: ERROR Not overpass user! You must run this script as the \"overpass\" user."
    echo ""
    echo " This script is part of the Guide for \"overpassAPI\" installation and setup on"
    echo "Linux Slackware system. The Guide repository can be found here:"
    echo "https://github.com/waelhammoudeh/overpass-4-slackware"
    echo ""

    exit 1
fi

set -e

# when doing areas update, this script should NOT run while database is being
# updated. Wait for "op_update_db.sh" to finish first.
# UPDATE_DB_SCRIPT=$EXEC_DIR/update_op_db.sh

SLP_FLAG=TRUE
UPDATE_DB_SCRIPT=op_update_db.sh

while [[ $SLP_FLAG = "TRUE" ]]; do
{
    # do NOT use -f switch as we are looking for process name & use quotation marks
    if ( pgrep "$UPDATE_DB_SCRIPT"  2>&1 > /dev/null) ; then
        echo "$(date '+%F %T'): Found running \"op_update_db.sh\" script." >>$LOG_FILE
        echo "$(date '+%F %T'): Waiting 5 minutes; for \"Update Overpass Database\" script to finish!" >>$LOG_FILE
        sleep 300
    else
        SLP_FLAG=FALSE
    fi

}; done

# dispatcher must be running with --areas option
if ( ! pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
    echo "Error: dispatcher is NOT running!"
    echo "Areas dispatcher must be running to update areas. Exiting."
    echo "$(date '+%F %T'): Areas dispatcher must be running to update areas. Exiting." >>$LOG_FILE
    exit 1
fi

if [ ! -S ${DB_DIR}/osm3s_areas ]; then
    echo "Error: Areas dispatcher is not running. Exiting"
    echo "$(date '+%F %T'): Areas dispatcher is not running. Exiting" >>$LOG_FILE
    exit 1
fi

# we all need to be on the same page
INUSE_DIR=$($DSPTCHR --show-dir)

if [[ $INUSE_DIR != "$DB_DIR/" ]]; then

   echo "Error: Not same INUSE_DIR and DB_DIR"
   echo "$(date '+%F %T'): Error dispatcher manages different database than destination" >>$LOG_FILE
   exit 1
fi

#
# IMAX is to control loop iteration counter - change & check query results
#
# to INITIAL area data set IMAX to 100 - 200 iterations. Arizona = 100 & USA = 200
# to UPDATE area data set IMAX to half number above & run cronjob weekly or monthly
# when UPDATE you may want to rename script with IMAX number: op_area_update50.sh
#
IMAX=50

echo "Area update started. Loop COUNT is set to: $IMAX"
echo "`date '+%F %T'`: Area update started. Loop COUNT is set to: $IMAX" >>$LOG_FILE

for ((i=1; i<=$IMAX; i++)); do
{
  echo "`date '+%F %T'`: update iteration number < $i > started " >>$LOG_FILE

  ionice -c 2 -n 7 nice -n 19 $EXEC_DIR/osm3s_query --progress --rules <$RULES_DIR/areas.osm3s

  echo "`date '+%F %T'`: update iteration number < $i > done." >>$LOG_FILE

  sleep 1
}; done

echo "Area Update Done After $IMAX Iterations"
echo "`date '+%F %T'`: *** Area Update Done After < $IMAX > Iterations ***" >>$LOG_FILE
