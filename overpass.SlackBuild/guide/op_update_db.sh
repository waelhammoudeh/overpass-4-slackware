#!/bin/bash

# Script updates overpass database and area objects from a list of change
# files specified by <list_file> and their location directory specified by <osc_dir>.
#
# overpasss database directory is set to "db_dir" with default value below:
# db_dir="/var/lib/overpass/database"
#
# script does NOT require dispatcher to be running.
# script will stop the dispatcher during the update.
#
## you may adjust FLUSH_SIZE; values I have used;
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
# Usage: update_from_osc_list <database_dir> <flush_size> <prefix_dir> <osc_array>
#
update_from_osc_list() {

    local UPDATER=/usr/local/bin/update_database
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
        log "  Usage: update_from_osc_list <database_dir> <flush_size> <prefix_dir> <osc_array>"
        return $E_MISSING_PARAM
    fi

    local database_dir=$1
    local FLUSH_SIZE=$2
    local prefix_dir=$3
    local -n osc_array=$4
    local length=${#osc_array[@]}

    echo "" >> $logFile
    log "Function update_from_osc_list(): Recieved list with $((length/2)) change file(s)."

    for ((i=0; i<length; i+=2)); do
        local change_suffix=${osc_array[i]}
        local state_suffix=${osc_array[i+1]}
        local change_file="$prefix_dir$change_suffix"
        local state_file="$prefix_dir$state_suffix"

        local timestampLine
        timestampLine=$(grep timestamp "$state_file")
        local full_version=${timestampLine#timestamp=}
        full_version=${full_version//\\/}

        local sequence_number
        sequence_number=$(grep sequenceNumber "$state_file" | cut -d= -f2)

        local PRE_UPDATE_VERSION
        PRE_UPDATE_VERSION=$(<"$database_dir/osm_base_version")
        log "   PRE_UPDATE_VERSION number is: $PRE_UPDATE_VERSION"
        log "   Applying update from:"
        log "     Change File: <$change_file>"
        log "     Dated: <$full_version>"

        if ! gunzip <"$change_file" | "$UPDATER" \
            --db-dir="$database_dir" \
            --version="$full_version" \
            $META \
            --flush-size="$FLUSH_SIZE" \
            --compression-method="$COMPRESSION" \
            --map-compression-method="$COMPRESSION" >/dev/null 2>&1; then
            log "update_from_osc_list(): Failed to update from file $change_file"
            return $E_UNKNOWN
        fi

        echo "$sequence_number" >"$database_dir/replicate_id"

        local POST_UPDATE_VERSION
        POST_UPDATE_VERSION=$(<"$database_dir/osm_base_version")
        log "   POST_UPDATE_VERSION number is: $POST_UPDATE_VERSION"
        log "   Done updating from change file: $change_file"
        log ""
        sleep 2
    done

    log "Function update_from_osc_list(): Done updating from $((length/2)) change file(s)."
    echo "" >> $logFile

    return $EXIT_SUCCESS

} # END update_from_osc_list()

# End common functions ---

# SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

op_dir="/var/lib/overpass"
db_dir=$(realpath $op_dir/database)

rules_dir=$db_dir/rules

log_dir=$op_dir/logs
logFile=$log_dir/$scriptName.log

exec_dir="/usr/local/bin"
OSMIUM=$exec_dir/osmium # not used here!
OP_CTL=$exec_dir/op_ctl.sh
DISPATCHER=$exec_dir/dispatcher

op_user="overpass"

# source common_functions.sh -- included used functions here
# source "$SCRIPT_DIR/common_functions.sh"

usage() {
  echo "usage:"
  echo ""
  echo "$scriptName.sh <list_file> <osc_dir>"
  echo " list_file: file with list of new change files and their state.txt files"
  echo " osc_dir: directory for differs and their state.txt files."
  exit $E_MISSING_PARAM
}

### --- Validate arguments number ---
[[ $# -ne 2 ]] && usage

list_file=$1
osc_dir=$2

# only "overpass" user can update database
if [[ $(id -u -n) != $op_user ]]; then
    echo "$scriptName: ERROR Not $op_user user! You must run this script as the \"$op_user\" user."
    exit $E_FAILED_TEST
fi

# remove trailing slash unless root - if you have more than 1, you are SOL
[[ $osc_dir != "/" ]] && osc_dir=${osc_dir%/}

chk_directories $op_dir $db_dir $rules_dir $exec_dir $osc_dir

if [[ $? -ne $EXIT_SUCCESS ]]; then
    echo "$scriptName.sh: Error failed chk_directories() function. Exiting"
    echo ""
    exit $E_FAILED_TEST
fi

# create log directory if it does not exist
mkdir -p $log_dir

# now our log directory is there and we can write to it, so open log file
touch $logFile

log "======================== Starting ========================"
log "$scriptName has started ..."

check_database_directory $db_dir

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

chk_files $rules_dir/areas.osm3s
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_files() function to update area. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $E_FAILED_TEST
fi

# we only update real active database
# get it from dispatcher if it is running, else get it from op_ctl.sh
if pgrep -x dispatcher > /dev/null; then
    dbDisDir=$($DISPATCHER --show-dir 2>/dev/null)
    active_db_path=$(realpath "$dbDisDir")
else
    dbOpctlDir=$($OP_CTL status | grep "database directory" \
               | cut -d ':' -f 3 | sed 's/^ //')
    active_db_path=$(realpath "$dbOpctlDir")
fi

if [[ -z $active_db_path ]]; then
    log "Error, could not get active directory! EMPTY string."
    exit $E_UNKNOWN
fi

if [[ $db_dir != $active_db_path ]]; then
    log "Error, database directory and active directory are different"
    log " db_dir is: <$db_dir>"
    log " active_db_path is: <$active_db_path>"
    exit $E_INVALID_PARAM
fi

# list_file maybe empty, this is not an error - we just have no work to do.
if [[ ! -s $list_file ]]; then
   log "List file: \"$list_file\" not found or empty."
   log "No new change files to update with. Exiting"
   log "+++++++++++++++++ No New Change Files Were Found +++++++++++++++++++++"
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
done < "$list_file"

checkList $osc_dir newFilesArray

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

# Usage: update_from_osc_list <database_dir> <flush_size> <prefix_dir> <osc_array>"

update_from_osc_list $db_dir $FLUSH_SIZE $osc_dir newFilesArray

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed update_from_osc_list() function. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $?
fi

# rename the list file so "getdiff" starts new file.
mv $list_file $list_file.bak

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
    $exec_dir/osm3s_query --progress --rules <"$rules_dir/areas.osm3s"
else
   $exec_dir/osm3s_query --db-dir="$db_dir" --progress  --rules <"$rules_dir/areas.osm3s"
fi

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed to update area objects in database. Exiting"
    log "Terminated with ERROR   XXXXX"
    exit $?
fi

log "Done updating areas."

log "Database: <$db_dir> update complete."
log "++++++++++++++++++++++++ Done ++++++++++++++++++++++++++"
echo ""

exit $EXIT_SUCCESS
