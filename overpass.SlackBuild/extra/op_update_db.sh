#!/bin/bash

# Script updates overpass database and area objects from a list of change
# and their corresponding state.txt files, with specified directory for files
# location in file system.
#
# Script usage:
#  op_update_db.sh <listFile> <oscDir>
#   listFile: file with list of new change files and their corresponding state.txt files
#   oscDir: directory for change files and their state.txt files.
#
# overpasss database directory is set to "dbDir" with default value below:
# dbDir="/var/lib/overpass/database"
#
# script does NOT require dispatcher to be running.
# script will stop the dispatcher - if found running - during the update.
#
# FLUSH_SIZE is set in the script below, you may adjust this value.
# values I have used;
#   8 GB ram --> FLUSH_SIZE=8
#   16 GB ram --> FLUSH_SIZE=16
#   128 GB ram --> FLUSH_SIZE=128
#

FLUSH_SIZE=4

# script name no path & no extension
scriptName=$(basename "$0" .sh)

# Start common functions ---

# --- Exit / return codes ---
EXIT_SUCCESS=0
E_MISSING_PARAM=1
E_INVALID_PARAM=2
E_FAILED_TEST=3
E_UNKNOWN=4


opDir="/var/lib/overpass"
dbDir=$(realpath $opDir/database)

rulesDir=$dbDir/rules

logDir=$opDir/logs
logFile=$logDir/$scriptName.log

execDir="/usr/local/bin"
OSMIUM=$execDir/osmium # not used here!
OP_CTL=$execDir/op_ctl.sh
DISPATCHER=$execDir/dispatcher

UPDATER=$execDir/update_database

TMP=$opDir/tmp

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

opUser="overpass"

# source common_functions.sh -- included used functions here
source "$SCRIPT_DIR/common_functions.sh"

usage() {
  echo "usage:"
  echo ""
  echo "$scriptName.sh <listFile> <oscDir>"
  echo " listFile: file with list of new change files and their state.txt files"
  echo " oscDir: directory for differs and their state.txt files."
  exit $E_MISSING_PARAM
}

### --- Validate arguments number ---
[[ $# -ne 2 ]] && usage

listFile=$1
oscDir=$2

# only "overpass" user can update database
if [[ $(id -u -n) != $opUser ]]; then
    echo "$scriptName: ERROR Not $opUser user! You must run this script as the \"$opUser\" user."
    exit $E_FAILED_TEST
fi

# remove trailing slash unless root - if you have more than 1, you are SOL
[[ $oscDir != "/" ]] && oscDir=${oscDir%/}

chk_directories $opDir $dbDir $rulesDir $execDir $oscDir

if [[ $? -ne $EXIT_SUCCESS ]]; then
    echo "$scriptName.sh: Error failed chk_directories() function. Exiting"
    echo ""
    exit $E_FAILED_TEST
fi

# create log directory if it does not exist
mkdir -p $logDir

# now our log directory is there and we can write to it, so open log file
touch $logFile

log "======================== Starting ========================"
log "$scriptName has started ..."

check_database_directory $dbDir

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed check_database_directory() function. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $E_FAILED_TEST
fi

chk_executables $DISPATCHER $OP_CTL
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_executables() function. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $E_FAILED_TEST
fi

chk_files $rulesDir/areas.osm3s
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_files() function to update area. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $E_FAILED_TEST
fi

# we only update real active database
# get it from dispatcher if it is running, else get it from op_ctl.sh
if pgrep -x dispatcher > /dev/null; then
    dbDisDir=$($DISPATCHER --show-dir 2>/dev/null)
    ACTIVE_DB_PATH=$(realpath "$dbDisDir")
else
    dbOpctlDir=$($OP_CTL status | grep "database directory" \
               | cut -d ':' -f 3 | sed 's/^ //')
    ACTIVE_DB_PATH=$(realpath "$dbOpctlDir")
fi

if [[ -z $ACTIVE_DB_PATH ]]; then
    log "Error, could not get active directory! EMPTY string."
    exit $E_UNKNOWN
fi

if [[ $dbDir != $ACTIVE_DB_PATH ]]; then
    log "Error, database directory and active directory are different"
    log " dbDir is: <$dbDir>"
    log " ACTIVE_DB_PATH is: <$ACTIVE_DB_PATH>"
    exit $E_INVALID_PARAM
fi

# listFile maybe empty, this is not an error - we just have no work to do.
if [[ ! -s $listFile ]]; then
   log "List file: \"$listFile\" not found or empty."
   log "No new change files to update with. Exiting"
   log "+++++++++ No New Change Files Were Found +++++++++++++"
   echo "">>$logFile

   exit $EXIT_SUCCESS
fi

# initial an empty array
declare -a newFilesArray=()

# read list file placing each line in an array element
while IFS= read -r line
do
{
    newFilesArray+=($line)
}
done < "$listFile"

length=${#newFilesArray[@]}
numChangeFiles=$(($length / 2))

checkList $oscDir newFilesArray

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed checkList() function. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $E_FAILED_TEST
fi

META=--meta
COMPRESSION=gz

# combine change files - if we have more than one
# Usage: mergeListOSC OUT_FILE DIR_PREFIX OSC_ARRAY

changeFile=$oscDir/${newFilesArray[0]}
stateFile=$oscDir/${newFilesArray[-1]}


if [[ $numChangeFiles -gt 1 ]]; then

    log "Merging <$numChangeFiles> change files ..."
    log "====================================================================="
    echo "" | tee -a "logFile"

    # make OUT_FILE filename: firstSeqNum-lastSeqNum
    firstStateFile=$oscDir/${newFilesArray[1]} # second element (second line)
    lastStateFile=$oscDir/${newFilesArray[-1]} # last element

    firstSeqNum=$(grep sequenceNumber "$firstStateFile" | cut -d= -f2)
    lastSeqNum=$(grep sequenceNumber "$lastStateFile" | cut -d= -f2)


    combinedOSC=$TMP/combined-$firstSeqNum-$lastSeqNum.osc.gz

    mergeListOSC $combinedOSC $oscDir newFilesArray
    rc=$?
    if [[ $rc -ne $EXIT_SUCCESS ]]; then
        log "Error failed mergeListOSC() function!"
        exit $rc
    fi

    # use combined change file
    changeFile=$combinedOSC
    log "Updating from combined file: $changeFile"
    log "====================================================================="
    echo "" | tee -a "logFile"

fi

timestampLine=$(grep timestamp "$stateFile")
full_version=${timestampLine#timestamp=}
full_version=${full_version//\\/}

sequence_number=$(grep sequenceNumber "$stateFile" | cut -d= -f2)

restartDispatcher=0

# dispatcher can not be running when using update_database
if [[ ! -z `pgrep dispatcher` ]]; then
    log "dispatcher is running; stopping ..."
    $OP_CTL stop
    rc=$?
    if [[ $rc -ne $EXIT_SUCCESS ]]; then
        log "Error, could not stop dispatcher"
        exit $E_UNKNOWN
    fi
    log "dispatcher stopped"
    restartDispatcher=1
fi

PRE_UPDATE_VERSION=$(<"$dbDir/osm_base_version")
log "   PRE_UPDATE_VERSION number is: $PRE_UPDATE_VERSION"
log "   Applying update from:"
log "     Change File: <$changeFile>"
log "     Dated: <$full_version>"

if ! gunzip <"$changeFile" | "$UPDATER" \
     --db-dir="$dbDir" \
     --version="$full_version" \
     $META \
     --flush-size="$FLUSH_SIZE" \
     --compression-method="$COMPRESSION" \
     --map-compression-method="$COMPRESSION" >/dev/null 2>&1; then
     log "ERROR XXXXX: Failed to update from file $changeFile"
     return $E_UNKNOWN
fi

echo "$sequence_number" >"$dbDir/replicate_id"

POST_UPDATE_VERSION=$(<"$dbDir/osm_base_version")
log "   POST_UPDATE_VERSION number is: $POST_UPDATE_VERSION"
log "   Done updating from change file: $changeFile"
log ""

# rename the list file so "getdiff" starts new file.
mv $listFile $listFile.bak

# start dispatcher
if (( restartDispatcher == 1 )); then
    log "Restarting dispatcher ..."
    $OP_CTL start
    rc=$?
    if [[ $rc -ne $EXIT_SUCCESS ]]; then
        log "Error, failed to start dispatcher"
        exit $E_UNKNOWN
    fi
    log "Dispatcher started."
fi

# switched to hourly change files update
# area update operation fails on system boot; 8 or 9 chanage files
# usually NOT when machine has been running for sometime; single change file

# 3 minutes sleep time seems to work okay with 6 change files - failed with 8 change files
# Possible other solutions:
#   1) combine changes and apply once
#   2) use update_from_directory and do not shutdown dispatcher

# area update failed again with combined one change file (from 17 hours) with sleepTime 3 minutes
# trying 5 minutes wait plus two tries 7/13/2026 W.H.
sleepTime=5

SECOND=60
MINUTE=5

if [[ $numChangeFiles -gt 1 ]]; then
    sleepTime=$(($MINUTE * $SECOND))
fi

# update area in database
log "Sleeping for <$sleepTime> seconds BEFORE updating area objects"

sleep $sleepTime

log "Updating areas in database ..."

if pgrep dispatcher; then
    $execDir/osm3s_query --progress --rules <"$rulesDir/areas.osm3s"
else
   $execDir/osm3s_query --db-dir="$dbDir" --progress  --rules <"$rulesDir/areas.osm3s"
fi
rc=$?

if [[ $rc -ne $EXIT_SUCCESS ]]; then
    log "Error failed to update area objects in database on FIRST TRY ..."
    log "FIRST TRY terminated with ERROR   XXXXX: \"osm3s_query\" exit code was: < $rc >"
    log "Trying again in <$sleepTime> seconds ..."

    sleep $sleepTime
    # dispatcher should be running!
    $execDir/osm3s_query --progress --rules <"$rulesDir/areas.osm3s"
    rc=$?
    if [[ $rc -ne $EXIT_SUCCESS ]]; then
        log "Error failed to update area objects in database. 2nd try!"
        log "SECOND TRY ALSO FAILED with ERROR   XXXXX: \"osm3s_query\" exit code was: < $rc >"
        log "xxxxxxxxxxxxxxxxxx FAILED AREA UPDATE xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    fi

#    exit $rc
fi


log "Done updating areas."

log "Database: <$dbDir> update complete."
log "++++++++++++++++++++++++ Done ++++++++++++++++++++++++++"
echo "">>$logFile

# remove files in tmp directory
# rm -f $TMP/*

exit $EXIT_SUCCESS
