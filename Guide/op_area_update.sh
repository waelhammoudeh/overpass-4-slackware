#!/usr/bin/bash

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Roland Olbricht et al.
#
# This file is part of Overpass_API.
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

# only overpass user can run this
# this is a WRONG way to check user, we must look in passwd & goup files
OP_USR_ID=367

SYS_ROOT=/var/lib

# this can be a link to any directory on your system - "overpass" name should stay.
OP_DIR=$SYS_ROOT/overpass

# DB_DIR : overpass database directory
# DB_DIR=/path/to/your/database
DB_DIR=$OP_DIR/database

LOG_DIR=$OP_DIR/logs

VERSION=v0.7.57
EXEC_DIR=/usr/local/bin
DSPTCHR=$EXEC_DIR/dispatcher
RULES_DIR=/usr/local/rules
LOG_FILE=$LOG_DIR/op_area_update.log

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

# when doing areas update, this script should NOT run while database is being
# updated. Wait for "update_op_db.sh" to finish first.
SLP_FLAG=TRUE
# UPDATE_DB_SCRIPT=$EXEC_DIR/update_op_db.sh
UPDATE_DB_SCRIPT=update_op_db.sh

while [[ $SLP_FLAG = "TRUE" ]]; do
{
    if ( pgrep -f $UPDATE_DB_SCRIPT  2>&1 > /dev/null) ; then
        echo "$(date '+%F %T'): Sleeping 5 minutes; for \"Update Overpass Database\" script to finish!" >>$LOG_FILE
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

if [ ! -S ${DB_DIR}/osm3s_${VERSION}_areas ]; then
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
IMAX=100

echo "Area update started. Loop COUNT is set to: $IMAX"
echo "`date '+%F %T'`: Area update started. Loop COUNT is set to: $IMAX" >>$LOG_FILE

# while [[ true ]]; do
for ((i=1; i<=$IMAX; i++)); do
{
  echo "`date '+%F %T'`: update started: iteration number <$i>" >>$LOG_FILE
  #  ./osm3s_query --progress --rules <$DB_DIR/rules/areas.osm3s
  ionice -c 2 -n 7 nice -n 19 $EXEC_DIR/osm3s_query --progress --rules <$RULES_DIR/areas.osm3s
  echo "`date '+%F %T'`: update finished: iteration number <$i>" >>$LOG_FILE
  sleep 3
}; done

echo "Area Update Done After < $IMAX > Iterations"
echo "`date '+%F %T'`: *** Area Update Done After < $IMAX > Iterations ***" >>$LOG_FILE
