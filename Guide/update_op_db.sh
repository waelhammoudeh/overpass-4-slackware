#!/bin/bash

# script to daily update overpass database from Geofabrik Change Files (.osc)
# Script applies DAILY Change Files update to database.
#
# Timestamp in log file uses local time.
# WARNING: This script will NOT work to update database with "--keep-attic" switch
#
# script reads a text file with a list of newer retieved Change Files (differ files) and their
# (.state.txt) files.
# The file with the list is produced by my "getdiff" program.
# The file name and path is set for the "getdiff" program with either "--new"
# command line option or "NEWER_FILE" configuration file setting.
# This script sets this file in variable "NEWER_FILES" below. The two settings must
# refer to the same file.

# NEWER_FILES sample: sorted list, files are in pairs
# 302.osc.gz
# 302.state.txt
# 303.osc.gz
# 303.state.txt
# 304.osc.gz
# 304.state.txt
# 305.osc.gz
# 305.state.txt

OP_USR_ID=367

if [[ $EUID -ne $OP_USR_ID ]]; then
    echo "$0: ERROR Not overpass user! You must run this script as the \"overpass\" user."
    echo ""
    echo " This script is part of the Guide for \"overpassAPI\" installation and setup on"
    echo "Linux Slackware system. The Guide repository can be found here:"
    echo "https://github.com/waelhammoudeh/overpass-4-slackware"
    echo ""

    exit 1
fi

# DB_DIR : overpass database directory
DB_DIR=/path/to/database

# GETDIFF_WD: getdiff Work Directory
GETDIFF_WD=$DB_DIR/getdiff

# DIFF_DIR: where to find differ files - downloaded "Change Files"
DIFF_DIR=$GETDIFF_WD/diff

# NEWER_FILES : file produced by "getdiff" program
NEWER_FILES=$GETDIFF_WD/newerFiles.txt

# settings below assume overpass.SlackBuild installed package - change ONLY if NOT true.
EXEC_DIR=/usr/local/bin

# used for area creation. SlackBuild script installs to: /usr/local/rules
# eventually DB_DIR will have database files only - no other directories or files
RULES_DIR=/usr/local/rules

# full path to exectables we use
OP_CTL=$EXEC_DIR/op_ctl.sh
UPDATER=$EXEC_DIR/update_database
QRY_EXEC=$EXEC_DIR/osm3s_query

# update_database changable options
META=--meta
FLUSH_SIZE=4
COMPRESSION=no

# THIS script log file
LOGFILE=$DB_DIR/logs/update_op_db.log

echo "$(date '+%F %T'): update_op_db.sh started ..." >>$LOGFILE
echo "$(date '+%F %T'): database directory is: $DB_DIR" >>$LOGFILE

# initial an empty array
declare -a newFilesArray=()

if [[ ! -s $NEWER_FILES ]]; then
   echo "$0: NEWER_FILES not found or empty - nothing to do."
   echo "$(date '+%F %T'): No newer files to update. Done." >>$LOGFILE
   echo "++++++++++++++++++++++++++ Did Nothing +++++++++++++++++++++++++++"
   exit 0
fi

# check ALL executables
if [[ ! -x $UPDATER ]]; then

    echo "$0: Error could not find \"update_database\" executable"
    echo " Please install or reinstall overpassAPI package"
    echo "$(date '+%F %T'): Error could not find \"update_database\" executable" >>$LOGFILE
    exit 1
fi

if [[ ! -x $OP_CTL ]]; then

    echo "$0: Error could not find \"op_ctl.sh\" control script"
    echo " Please install / reinstall overpass package"
    echo "$(date '+%F %T'): Error could not find \"op_ctl.sh\" control script" >>$LOGFILE
    exit 1
fi

if [[ ! -x $QRY_EXEC ]]; then

    echo "$0: Error could not find \"osm3s_query\" executable"
    echo " Please install / reinstall overpass package"
    echo "$(date '+%F %T'): Error could not find \"osm3s_query\" executable" >>$LOGFILE
    exit 1
fi

# dispatcher needs to be running to get database directory {INUSE_DIR}
# we could read script to get {INUSE_DIR} - so we should only stop it if
# running, then for areas start it up.????? FIXME
if (! pgrep -f $EXEC_DIR/dispatcher  2>&1 > /dev/null) ; then
   echo " Error: dispatcher is not running !!!"
   echo "$(date '+%F %T'): Error dispatcher is not running " >>$LOGFILE
   exit 1
fi

INUSE_DIR=$($EXEC_DIR/dispatcher --show-dir)

if [[ $INUSE_DIR != "$DB_DIR/" ]]; then

   echo "Error: Not same INUSE_DIR and DB_DIR"
   echo "$(date '+%F %T'): Error dispatcher manages different database than destination" >>$LOGFILE
   exit 1
fi

# check for areas.osm3s template; needed to update areas
if [[ ! -s $RULES_DIR/areas.osm3s ]]; then
   echo "$0: Error: Areas template \"areas.osm3s\" not found or empty"
   echo "$(date '+%F %T'): Error: Areas template \"areas.osm3s\" not found or empty" >>$LOGFILE
   echo
   exit 1
fi

# read NEWER_FILES placing each line in an array element
while IFS= read -r line
do
{
    newFilesArray+=($line)
}
done < "$NEWER_FILES"

# get array length
length=${#newFilesArray[@]}

if [[ $length -lt 2 ]]; then
   echo "$0: Error number of lines is less than 2"
   echo "$(date '+%F %T'): Error number of lines in newer file is less than 2" >>$LOGFILE
   exit 1
fi

# length should be EVEN number
rem=$(( $length % 2 ))
if [[ $rem -ne 0 ]]; then
   echo "$0: Error found ODD number of lines"
   echo "$(date '+%F %T'): Error found ODD number of lines in newer file." >>$LOGFILE
   exit 1
fi

# check that change file matches the very next state file
# just checking ALL files - it is ALL or NOTHING deal
i=0
j=0

while [ $i -lt $length ]
do
    j=$((i+1))
    changeFileName=${newFilesArray[$i]}
    stateFileName=${newFilesArray[$j]}

    # get string number from file names
    changeFileNumber=`echo "$changeFileName" | cut -f 1 -d '.'`
    stateFileNumber=`echo "$stateFileName" | cut -f 1 -d '.'`

    # they better be the same numbers
    if [[ $changeFileNumber -ne $stateFileNumber ]]; then
        echo "$0: Error Not same files; change and state!"
        echo "changeFileName : $changeFileName"
        echo "stateFileName : $stateFileName"
        echo "$(date '+%F %T'): Error changeFile and stateFile do NOT match" >>$LOGFILE
        exit 1
    fi

    # check they exist in diff directory
    changeFile=$DIFF_DIR/$changeFileName
    stateFile=$DIFF_DIR/$stateFileName
    if [[ ! -s $changeFile ]]; then
        echo "$0: Error missing or empty changeFile $changeFile"
        echo "$(date '+%F %T'): Error missing or empty changeFile" >>$LOGFILE
        exit 1
    fi

    if [[ ! -s $stateFile ]]; then
        echo "$0: Error missing or empty changeFile $stateFile"
        echo "$(date '+%F %T'): Error missing or empty stateFile" >>$LOGFILE
        exit 1
    fi

    # move to next pair
     i=$((j+1))
done

# TODO
# check database directory
# gap between database version and first change file version? is there a way to know it exists?

set -e

# all good, stop dispatcher before updating
# $DISP_CTRL_SCRIPT stop 2>&1 >/dev/null
$OP_CTL stop 2>&1 >/dev/null

# with "set -e" on top: we do not get here in case of error from command?
if [[ ! $? -eq 0 ]]; then
    echo "$0: Error could not stop dispatcher!"
    echo "$(date '+%F %T'): Error could not stop dispatcher! I think we are dead already?" >>$LOGFILE
    exit 1
fi

# log stopped dispatcher
echo "$(date '+%F %T'): stopped dispactcher daemon" >>$LOGFILE
echo "stopped dispactcher daemon"

i=0
j=0

while [ $i -lt $length ]
do
    j=$((i+1))
    changeFileName=${newFilesArray[$i]}
    stateFileName=${newFilesArray[$j]}

    changeFile=$DIFF_DIR/$changeFileName
    stateFile=$DIFF_DIR/$stateFileName

    # get date only YYYY-MM-DD & use as version number
    VERSION=`cat $stateFile | grep timestamp | cut -d 'T' -f -1 | cut -d '=' -f 2`

    echo "$(date '+%F %T'): applying update from Change File: <$changeFile> Dated: <$VERSION>" >>$LOGFILE
    echo " applying update from Change File: <$changeFile> Dated: <$VERSION>"

    # Usage: update_database [--db-dir=DIR] [--version=VER] [--meta|--keep-attic] [--flush_size=FLUSH_SIZE] [--compression-method=(no|gz|lz4)] [--map-compression-method=(no|gz|lz4)]

    gunzip <$changeFile | $UPDATER --db-dir=$DB_DIR \
                                   --version=$VERSION \
                                   $META \
                                   --flush-size=$FLUSH_SIZE \
                                   --compression-method=$COMPRESSION \
                                   --map-compression-method=$COMPRESSION 2>&1 >/dev/null

    if [[  ! $? -eq 0 ]]; then
        # set -e ????
        echo "$(date '+%F %T'): Failed to update from file $changeFile" >>$LOGFILE
        exit 1
    fi

    echo "$(date '+%F %T'): done update from file $changeFile" >>$LOGFILE
    echo "done update from file $changeFile"

    # wait 2 seconds to update next changeFile
    sleep 2

    # move to next pair
     i=$((j+1))
done

# start dispatcher
$OP_CTL start 2>&1 >/dev/null

echo "$(date '+%F %T'): started dispactcher daemon again" >>$LOGFILE
echo "started dispactcher daemon again"

# make sure dispatcher started
sleep 2

# update areas data - we apply ALL changeFile(s) then use ONE area update call

# this is an experiment, database is not compromised.
# assumes rules directory path: /usr/local/rules
# set iCount to a lot smaller number compared to IMAX in "op_area_update.sh" script
# DO NOT SET LESS THAN TEN
# do NOT set < 10

iCount=10

echo "$(date '+%F %T'): @@@@ updating overpass areas: With Loop Counter = $iCount" >>$LOGFILE
echo " @@@@ updating overpass areas: With Loop Counter = $iCount"

for ((i=1; i<=$iCount; i++)); do
{
   ionice -c 2 -n 7 nice -n 19 $EXEC_DIR/osm3s_query --progress --rules < $RULES_DIR/areas.osm3s 2>&1 >/dev/null
   sleep 3
}; done

echo "$(date '+%F %T'): @@@@ Done areas update; Loop Counter: $iCount" >>$LOGFILE
echo " @@@@ Done areas update; Loop Counter: $iCount"

# we MUST empty or remove this file. "getdiff" program recreates a new file
mv $NEWER_FILES $NEWER_FILES.old

echo "$(date '+%F %T'): Moved $NEWER_FILES TO: $NEWER_FILES.old" >>$LOGFILE

echo "$(date '+%F %T'): ---------------------------------------- DONE --------------------------------------" >>$LOGFILE
echo "$0: All Done."

exit 0
