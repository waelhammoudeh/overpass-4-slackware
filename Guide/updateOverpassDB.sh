#!/bin/bash

# script to update overpass database from Geofabrik Change Files (.osc)
#
# script reads a text file with a list of newer retieved Change Files and their (.state.txt) files
# The file with the list is produced by my "getdiff" program.
# The file name and path is set with either "--new" command line option or "NEWER_FILE"
# configuration file setting. The file setting must match between this script and "gediff".
# The file setting in this script is in the "infile" variable.

# infile sample: sorted list, files in pairs
# 302.osc.gz
# 302.state.txt
# 303.osc.gz
# 303.state.txt
# 304.osc.gz
# 304.state.txt
# 305.osc.gz
# 305.state.txt

set -e

infile=/home/wael/Downloads/getdiff/newerFiles.txt
diffDir=/home/wael/Downloads/getdiff/diff

binDir=/usr/local/bin
DISPATCHER=/etc/rc.d/rc.dispatcher
OSMIUM=$binDir/osmium
UPDATER=$binDir/update_database
QUERYEXEC=$binDir/osm3s_query

CWD=$(pwd)
MY_SCRIPT=$CWD/updateDB.sh
# MY_SCRIPT=/binDir/updateDB.sh

DBDIR=/mnt/nvme4/op-meta

# log progress of updates
LOGFILE=/var/log/overpass/updateDatabase.log

# initial an empty array
declare -a newFilesArray=()

# -s FILE : FILE exists and has a size greater than zero - this is NOT an error
if [[ ! -s $infile ]]; then
   echo "$0: infile not found or empty"
   exit 0
fi

# check ALL executables
if [[ ! -x $UPDATER ]]; then

    echo "$0: Error could not find \"update_database\" executable"
    echo " Please install or reinstall overpassAPI package"
    exit 1
fi

if [[ ! -x $OSMIUM ]]; then

    echo "$0: Error could not find \"osmium\" executable"
    echo " Please install osmium-tool package"
    exit 1
fi

if [[ ! -x $DISPATCHER ]]; then

    echo "$0: Error could not find \"dispatcher\" executable"
    echo " Please install / reinstall overpass package"
    exit 1
fi

if [[ ! -x $QUERYEXEC ]]; then

    echo "$0: Error could not find \"osm3s_query\" executable"
    echo " Please install / reinstall overpass package"
    exit 1
fi


# read infile placing each line in array element
while IFS= read -r line
do
{
    newFilesArray+=($line)
}
done < "$infile"

# get array length
length=${#newFilesArray[@]}

if [[ $length -lt 2 ]]; then
   echo "$0: Error number of lines is less than 2"
   exit 1
fi

# length should be EVEN number
rem=$(( $length % 2 ))
if [[ $rem -ne 0 ]]; then
   echo "$0: Error found ODD number of lines"
   exit 1
fi

# check that change file matches the very next state file
# just checking ALL files - it is ALL or NOTHING
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
        exit 1
    fi

    # check they exist in diff directory
    changeFile=$diffDir/$changeFileName
    stateFile=$diffDir/$stateFileName
    if [[ ! -s $changeFile ]]; then
        echo "$0: Error missing or empty changeFile $changeFile"
        exit 1
    fi

    if [[ ! -s $stateFile ]]; then
        echo "$0: Error missing or empty changeFile $stateFile"
        exit 1
    fi

    # move to next pair
     i=$((j+1))
done

# TODO
# check database directory
# handle dispatcher not running ... if everything in place we should be able to start it?
# gap between database version and first change file version? is there a way to know it exists?
# empty change file? is it even possible?
# no need to call updateDB.sh ... we are redoing all its error checking again!!!!

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# all good, stop dispatcher before updating
$DISPATCHER stop 2>&1 >/dev/null

if [[ ! $? -eq 0 ]]; then
    echo "$0: Error could not stop dispatcher!"
    exit 1
fi

# log stopped dispatcher

i=0
j=0

while [ $i -lt $length ]
do
    j=$((i+1))
    changeFileName=${newFilesArray[$i]}
    stateFileName=${newFilesArray[$j]}

    changeFile=$diffDir/$changeFileName
    stateFile=$diffDir/$stateFileName

    # get date only YYYY-MM-DD & use as version number
    VERSION=`cat $stateFile | grep timestamp | cut -d 'T' -f -1 | cut -d '=' -f 2`

    echo "$(date -u '+%F %T'): applying update from file $changeFile" >>$LOGFILE

echo "using $changeFile .. updating"

    # updateDB.sh inputfile version DB_DIR
    $MY_SCRIPT $changeFile $VERSION $DBDIR 2>&1 >/dev/null

    if [[  ! $? -eq 0 ]]; then
        echo "$(date -u '+%F %T'): Failed to update from file $changeFile" >>$LOGFILE
        exit 1
    fi

    echo "$(date -u '+%F %T'): done update from file $changeFile" >>$LOGFILE

    # echo "stateFile : $stateFile has DATE : $VERSION"

    # wait 3 seconds for next file to update
    sleep 3

    # move to next pair
     i=$((j+1))
done

# start dispatcher

$DISPATCHER start 2>&1 >/dev/null

# make sure dispatcher started
sleep 3

# update areas
echo "$(date -u '+%F %T'): updating overpass areas" >>$LOGFILE

# osm3s_query --progress --rules < /mnt/nvme4/op-meta/rules/areas.osm3s

$QUERYEXEC --progress --rules < $DBDIR/rules/areas.osm3s 2>&1 >/dev/null

echo "$(date -u '+%F %T'): done areas update" >>$LOGFILE

exit 0
