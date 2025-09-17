#!/bin/bash

# Script updates overpass database and area objects from a list of change
# and their corresponding state.txt file, with specified directory for files
# location in file system.
#
# Script usage:
#  op_update_db.sh <listFile> <oscDir>
#   listFile: file with list of new change files and their corresponding state.txt files
#   oscDir: directory for differs and their state.txt files.
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
#   128 GB ram --> FLUSH_SIZE=512
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

# --- Logging helper ---
log() {
    # Usage: log "message"
    # Writes to stdout and appends to log file with timestamp
    echo "$(date '+%F %T') [$scriptName] $*"
    echo "$(date '+%F %T') [$scriptName] $*" >> "$logFile"
}

err() {
    # Usage: err "message"
    # Writes message to stderr with timestamp
    # log file not open yet!
    echo "$(date '+%F %T') $scriptName: ERROR: $*" >&2
}

# --- check_database_directory ---
# Usage: check_database_directory <dir>
# Returns EXIT_SUCCESS if directory looks like an Overpass database directory.
check_database_directory() {
    local DIR="$1"

    if [[ -z "$DIR" ]]; then
        log "check_database_directory(): missing argument <DIR>"
        return $E_MISSING_PARAM
    fi

    # Required files: we only check very few! should check for ALL really.
    local REQUIRED_FILES=("node_keys.bin" "relation_keys.bin" "way_keys.bin" "osm_base_version")

    # Directory must be symlink OR (directory AND not empty)
    if [ -L "$DIR" ] || { [ -d "$DIR" ] && [ "$(find "$DIR" -mindepth 1 -print -quit)" ]; }; then
        for file in "${REQUIRED_FILES[@]}"; do
            if [ ! -e "$DIR/$file" ]; then
                log "check_database_directory(): Missing essential database file: $file"
                return $E_FAILED_TEST
            fi
        done
    else
        log "check_database_directory(): The database directory ($DIR) does not exist or is empty."
        return $E_FAILED_TEST
    fi

    return $EXIT_SUCCESS
}

# --- chk_files ---
# Usage: chk_files file1 [file2 ...]
chk_files() {
    if [[ $# -eq 0 ]]; then
        log "chk_files(): missing argument(s) file1 [file2 ...]"
        return $E_MISSING_PARAM
    fi

    for f in "$@"; do
        if [[ ! -s "$f" ]]; then
            log "chk_files(): File not found or is an empty file: $f"
            return $E_FAILED_TEST
        fi
    done

    return $EXIT_SUCCESS
}

# --- chk_directories ---
# Usage: chk_directories dir1 [dir2 ...]
chk_directories() {
    if [[ $# -eq 0 ]]; then
        err "chk_directories(): missing argument(s) dir1 [dir2 ...]"
        return $E_MISSING_PARAM
    fi

    for dir in "$@"; do
        if [ ! -d "$dir" ]; then
            err "chk_directories(): Directory not found: $dir"
            return $E_FAILED_TEST
        fi
    done

    return $EXIT_SUCCESS
}

# --- chk_executables ---
# Usage: chk_executables /path/to/prog1 [/path/to/prog2 ...]
chk_executables() {
    if [[ $# -eq 0 ]]; then
        err "chk_executables(): missing argument(s) prog1 [prog2 ...]"
        return $E_MISSING_PARAM
    fi

    for prog in "$@"; do
        if [ ! -x "$prog" ]; then
            err "chk_executables(): could not find executable: $prog"
            return $E_FAILED_TEST
        fi
    done

    return $EXIT_SUCCESS
}

printList() {

    if [[ $# != 1 ]]; then
        echo "printList(): Error missing argument."
        return E_MISSING_PARAM
    fi

    local -n myArray=$1

    local length=${#myArray[@]}

    echo "printList(): array length is $length lines"

    if [[ $length -lt 1 ]]; then
        echo "printList(): Array / list is empty"
        return $EXIT_SUCCESS
    fi

    echo "printList(): Array elements (in pairs) are below:"
    echo ""

    local i=0
    local j=0
    while [[ $length -gt $i ]]; do
        j=$((i + 1))
        echo "Change file is: ${myArray[$i]}"
        echo "State file is : ${myArray[$j]}"
        echo "------------------------------------------"
        i=$((j + 1))
    done

    return $EXIT_SUCCESS

} # END printList()

# --- checkList ---
# Validate and verify a list of change/state file pairs from an array.
# Parameters:
#   $1: Directory prefix to combine with suffixes for file existence checks
#   $2: Name of the array containing suffixes (passed by reference)
#   Note: array name is LAST parameter, suffixes in file list start with back slash.
# Returns:
#   EXIT_SUCCESS (0) on success, error code otherwise.
checkList() {

    local prefix="$1"
    local -n fileArray="$2"   # Name reference for the array

    # prefix is for an existing directory, is it there?
    if [[ ! -d $prefix ]]; then
        log "checkList() Error could not find specified directory: $prefix"
    fi

    local length=${#fileArray[@]}

    log "checkList(): Recieved file list with $length lines"

    # Minimum length
    if (( length < 2 )); then
        log "checkList() Error: number of lines in list file is less than 2"
        return $E_INVALID_PARAM
    fi

    # Must be even number of entries
    if (( length % 2 != 0 )); then
        log "checkList() Error: found ODD number of lines in list file (length=$length)"
        return $E_INVALID_PARAM
    fi

    local i=0
    local prevNoExt=""

    while (( i < length )); do
    {
        local j=$((i + 1))

        local changeSuffix="${fileArray[$i]}"
        local stateSuffix="${fileArray[$j]}"

        # drop extension
        local changeNoExt="${changeSuffix%%.*}"
        local stateNoExt="${stateSuffix%%.*}"

        # Pair number match check
        if [[ $changeNoExt != $stateNoExt ]]; then
            log "checkList() Error: mismatched pair names for change/state files!"
            log "Change: $changeSuffix"
            log "State:  $stateSuffix"
            return $E_FAILED_TEST
        fi

        if [[ $changeNoExt == $prevNoExt || $stateNoExt == $prevNoExt ]]; then
            log "checkList() Error: duplicate pair in files list: $changeSuffix"
            return $E_FAILED_TEST
        fi

        # File existence & non-empty check - suffixes in list start with '/'
        local changeFile="$prefix$changeSuffix"
        local stateFile="$prefix$stateSuffix"

        if [[ ! -s "$changeFile" || ! -s "$stateFile" ]]; then
            log "checkList Error: missing or empty file(s) below:"
            log "  changeFile: $changeFile"
            log "  stateFile: $stateFile"
            return $E_FAILED_TEST
        fi

        prevNoExt=$changeNoExt
        i=$((j + 1))

    };
    done

    log "checkList() Done checking files list; list and files passed all tests."
    return $EXIT_SUCCESS

} # END checkList()

# --- update_from_osc_list()  ----
# Usage: update_from_osc_list <dbDir> <flush_size> <prefixDir> <oscArray>
#
update_from_osc_list() {

    local execDir=/usr/local/bin
    local UPDATER=$execDir/update_database
    local META=--meta
#    local FLUSH_SIZE # made as seconad parameter! It was an after thought!
    local COMPRESSION=gz

    if pgrep dispatcher; then
        log "update_from_osc_list(): Error, dispatcher is running."
        return $E_FAILED_TEST
    fi

    chk_executables $UPDATER
    if [[ $? -ne $EXIT_SUCCESS ]]; then
        log "Error failed chk_executables() for $UPDATER."
        return $E_FAILED_TEST
    fi

    if (( $# < 4 )); then
        log "update_from_osc_list(): Error - missing arguments."
        log "  Usage: update_from_osc_list <dbDir> <flush_size> <prefixDir> <oscArray>"
        return $E_MISSING_PARAM
    fi

    local dbDir=$1
    local FLUSH_SIZE=$2
    local prefixDir=$3
    local -n oscArray=$4
    local length=${#oscArray[@]}

    echo "" >> $logFile
    log "Function update_from_osc_list(): Recieved list with $((length/2)) change file(s)."

    for ((i=0; i<length; i+=2)); do
        local changeSuffix=${oscArray[i]}
        local stateSuffix=${oscArray[i+1]}
        local changeFile="$prefixDir$changeSuffix"
        local stateFile="$prefixDir$stateSuffix"

        local timestampLine
        timestampLine=$(grep timestamp "$stateFile")
        local fullVersion=${timestampLine#timestamp=}
        fullVersion=${fullVersion//\\/}

        local sequenceNum
        sequenceNum=$(grep sequenceNumber "$stateFile" | cut -d= -f2)

        local PRE_UPDATE_VERSION
        PRE_UPDATE_VERSION=$(<"$dbDir/osm_base_version")
        log "   PRE_UPDATE_VERSION number is: $PRE_UPDATE_VERSION"
        log "   Applying update from:"
        log "     Change File: <$changeFile>"
        log "     Dated: <$fullVersion>"

        if ! gunzip <"$changeFile" | "$UPDATER" \
            --db-dir="$dbDir" \
            --version="$fullVersion" \
            $META \
            --flush-size="$FLUSH_SIZE" \
            --compression-method="$COMPRESSION" \
            --map-compression-method="$COMPRESSION" >/dev/null 2>&1; then
            log "update_from_osc_list(): Failed to update from file $changeFile"
            return $E_UNKNOWN
        fi

        echo "$sequenceNum" >"$dbDir/replicate_id"

        local POST_UPDATE_VERSION
        POST_UPDATE_VERSION=$(<"$dbDir/osm_base_version")
        log "   POST_UPDATE_VERSION number is: $POST_UPDATE_VERSION"
        log "   Done updating from change file: $changeFile"
        log ""
        sleep 2
    done

    log "Function update_from_osc_list(): Done updating from $((length/2)) change file(s)."
    echo "" >> $logFile

    return $EXIT_SUCCESS

} # END update_from_osc_list()

# End common functions ---

# SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

opDir="/var/lib/overpass"
dbDir=$(realpath $opDir/database)

rulesDir=$dbDir/rules

logDir=$opDir/logs
logFile=$logDir/$scriptName.log

execDir="/usr/local/bin"
OSMIUM=$execDir/osmium # not used here!
OP_CTL=$execDir/op_ctl.sh
DISPATCHER=$execDir/dispatcher

opUser="overpass"

# source common_functions.sh -- included used functions here
# source "$SCRIPT_DIR/common_functions.sh"

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

checkList $oscDir newFilesArray

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed checkList() function. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $E_FAILED_TEST
fi

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

# Usage: update_from_osc_list <dbDir> <flush_size> <prefixDir> <oscArray>"

update_from_osc_list $dbDir $FLUSH_SIZE $oscDir newFilesArray

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed update_from_osc_list() function. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $?
fi

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

sleep 2

# update area in database
log "Updating areas in database ..."

if pgrep dispatcher; then
    $execDir/osm3s_query --progress --rules <"$rulesDir/areas.osm3s"
else
   $execDir/osm3s_query --db-dir="$dbDir" --progress  --rules <"$rulesDir/areas.osm3s"
fi

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed to update area objects in database. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $?
fi

log "Done updating areas."

log "Database: <$dbDir> update complete."
log "++++++++++++++++++++++++ Done ++++++++++++++++++++++++++"
echo "">>$logFile

exit $EXIT_SUCCESS
