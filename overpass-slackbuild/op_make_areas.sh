#!/usr/bin/bash

# This is "op_make_areas.sh" bash script:
# Creates areas in newly initialed overpass database.
# Note: this is the same script as "op_update_areas.sh" with one exception; IMAX
# The loop counter {IMAX} here is set to twice the value found in areas update
# script "op_update_areas.sh".
# This "op_make_areas.sh" script is intended to run only once on newly initialed
# overpass database.
#
# Note that both scripts write to the SAME log file!
#
# This file is part of the Guide for overpass-4-slackware found on GitHub at:
# https://github.com/waelhammoudeh/overpass-4-slackware
#
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

# this script is a rewrite of overpass script "rules_loop.sh" with the new name
#

# WARNING: Script needs to run to completion to avoid corrupted database.

# only overpass user can run this

SYS_ROOT=/var/lib

# this can be a link to any directory on your system - "overpass" name should stay.
OP_HOME=$SYS_ROOT/overpass

# DB_DIR : overpass database directory
# DB_DIR=/path/to/your/database
DB_DIR=$OP_HOME/database

LOG_DIR=$OP_HOME/logs

# script name no path & no extension
SCRIPT_NAME=$(basename "$0" .sh)

EXEC_DIR=/usr/local/bin
DSPTCHR=$EXEC_DIR/dispatcher
RULES_DIR=/usr/local/rules
LOG_FILE=$LOG_DIR/$SCRIPT_NAME.log

touch $LOG_FILE

OP_USER_NAME="overpass"

if [[ $(id -u -n) != $OP_USER_NAME ]]; then
    echo "$SCRIPT_NAME: ERROR Not overpass user! You must run this script as the \"$OP_USER_NAME\" user."
    echo ""
    echo "This script is part of the Guide for \"overpassAPI\" installation and setup on"
    echo "Linux Slackware system. The Guide repository can be found here:"
    echo "https://github.com/waelhammoudeh/overpass-4-slackware"
    echo ""

    exit 1
fi

echo "`date '+%F %T'`: $SCRIPT_NAME.sh just started with destination database set to: $DB_DIR" >>$LOG_FILE

set -e

# dispatcher must be running to make area
if ( ! pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
    echo "$SCRIPT_NAME: Error: dispatcher is NOT running!"
    echo "Dispatcher must be running to make areas objects. Exiting."
    echo "$(date '+%F %T'): Error dispatcher must be running to make areas. Exiting." >>$LOG_FILE
    exit 1
fi

# get the database dispatcher manages - INUSE_DIR
INUSE_DIR=$($DSPTCHR --show-dir)

if [[ $INUSE_DIR != "$DB_DIR/" ]]; then

   echo "$SCRIPT_NAME: Error: Not same INUSE_DIR and DB_DIR; dispatcher manages different database"
   echo "$(date '+%F %T'): Error dispatcher manages different database than destination" >>$LOG_FILE
   exit 1
fi

# check dispatcher area socket
if [ ! -S ${DB_DIR}/osm3s_areas ]; then
    echo "$SCRIPT_NAME: Error: Dispatcher is not running with area support. Exiting"
    echo "$(date '+%F %T'): Areas dispatcher is not running. Exiting" >>$LOG_FILE
    exit 1
fi

#
# IMAX is to control loop iteration counter - THIS IS AN EXPERIMENT
# change IMAX if you wish
#
# area functionality will be available after only ONE iteration is completed.
# Do not know if more iteration produce more accurate results.
#
# IMAX=100
IMAX=10

echo "$SCRIPT_NAME: Area update started with Loop COUNT set to: $IMAX"
echo "`date '+%F %T'`: Area update started. Loop COUNT is set to: $IMAX" >>$LOG_FILE

for ((i=1; i<=$IMAX; i++)); do
{
  echo "`date '+%F %T'`: update iteration number < $i > started " >>$LOG_FILE

  ionice -c 2 -n 7 nice -n 19 $EXEC_DIR/osm3s_query --progress --rules <$RULES_DIR/areas.osm3s

  echo "`date '+%F %T'`: update iteration number < $i > done." >>$LOG_FILE

  sleep 3
}; done

echo "Area Update Done After $IMAX Iterations"
echo "`date '+%F %T'`: *** Area Update Done After < $IMAX > Iterations ***" >>$LOG_FILE
