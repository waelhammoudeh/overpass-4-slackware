#!/bin/bash
#
# Common functions for OSM bash scripts
#

# --- Exit / return codes ---
EXIT_SUCCESS=0
E_MISSING_PARAM=1
E_INVALID_PARAM=2
E_FAILED_TEST=3
E_UNKNOWN=4

# --- Required globals ---
# The calling script must set:
#   scriptName="<name of calling script>"
#   logFile="<path to log file>"
#   OSMIUM path to osmium executable

: "${scriptName:?Error: scriptName is not set}"
: "${logFile:?Error: logFile is not set}"
: "${OSMIUM:?Error: OSMIUM executable is not set}"

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
        log "Error: missing argument in check_database_directory()"
        return $E_MISSING_PARAM
    fi

    log "Checking database directory: $DIR"

    # Required files: we only check very few! should check for ALL really.
    local REQUIRED_FILES=("node_keys.bin" "relation_keys.bin" "way_keys.bin" "osm_base_version")

    # Directory must be symlink OR (directory AND not empty)
    if [ -L "$DIR" ] || { [ -d "$DIR" ] && [ "$(find "$DIR" -mindepth 1 -print -quit)" ]; }; then
        for file in "${REQUIRED_FILES[@]}"; do
            if [ ! -e "$DIR/$file" ]; then
                log "Error: Missing essential database file: $file"
                return $E_FAILED_TEST
            fi
        done
    else
        log "Error: The database directory ($DIR) does not exist or is empty."
        return $E_FAILED_TEST
    fi

    return $EXIT_SUCCESS
}

# --- chk_files ---
# Usage: chk_files file1 [file2 ...]
chk_files() {
    if [[ $# -eq 0 ]]; then
        log "Error: missing argument(s) in chk_files()"
        return $E_MISSING_PARAM
    fi

    for f in "$@"; do
#        log "Checking file: $f"
        if [[ ! -s "$f" ]]; then
            log "Error: File not found or is an empty file: $f"
            return $E_FAILED_TEST
        fi
    done

    return $EXIT_SUCCESS
}

# --- chk_directories ---
# Usage: chk_directories dir1 [dir2 ...]
chk_directories() {
    if [[ $# -eq 0 ]]; then
        log "Error: missing argument(s) in chk_directories()"
        return $E_MISSING_PARAM
    fi

    for dir in "$@"; do
#        log "Checking directory: $dir"
        if [ ! -d "$dir" ]; then
            log "chk_directories() Error: Directory not found: $dir"
            return $E_FAILED_TEST
        fi
    done

    return $EXIT_SUCCESS
}

# --- chk_executables ---
# Usage: chk_executables /path/to/prog1 [/path/to/prog2 ...]
chk_executables() {
    if [[ $# -eq 0 ]]; then
        log "Error: missing argument(s) in chk_executables()"
        return $E_MISSING_PARAM
    fi

    for prog in "$@"; do
#        log "Checking executable: $prog"
        if [ ! -x "$prog" ]; then
            log "Error chk_executables(): could not find executable: $prog"
            return $E_FAILED_TEST
        fi
    done

    return $EXIT_SUCCESS
}

printList() {

    if [[ $# != 1 ]]; then
        log "printList(): Error missing argument."
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

getNumberedName() {

    # Not used? I needed to drop extension!!!
    if [[ $# -ne 1 ]]; then
        err "getNumberedName(): Error missing argument."
        return $E_MISSING_PARAM
    fi

    str=$1

    #/minute/006/724/018

    NUMBERED_NAME=$str

    if [[ $str =~ ^\/minute\/.* ]]; then
        echo "matches minutes"
        NUMBERED_NAME="${str:0:19}"
    elif [[ $str =~ ^\/hour\/.* ]]; then
        echo "matches hours"
        NUMBERED_NAME="${str:0:17}"
    elif [[ $str =~ ^\/day\/.* ]]; then
        echo "matches day"
        NUMBERED_NAME="${str:0:16}"
    elif [[ $str =~ ^\/[0-9]{3}\/ ]]; then
        echo "matches digits"
        NUMBERED_NAME="${str:0:12}"
    else {
        echo "matched None"
        return $E_INVALID_PARAM
    }; fi

    return $EXIT_SUCCESS

} # END getNumberedName()

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
        err "checkList() Error could not find specified directory: $prefix"
    fi

    local length=${#fileArray[@]}

    log "checkList(): Recieved file list with $length lines"

    # Minimum length
    if (( length < 2 )); then
        err "checkList() Error: number of lines in list file is less than 2"
        return $E_INVALID_PARAM
    fi

    # Must be even number of entries
    if (( length % 2 != 0 )); then
        err "checkList() Error: found ODD number of lines in list file (length=$length)"
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
            err "checkList() Error: mismatched pair names for change/state files! \
            Change: <$changeSuffix> State: <$stateSuffix>"
            return $E_FAILED_TEST
        fi

        if [[ $changeNoExt == $prevNoExt || $stateNoExt == $prevNoExt ]]; then
            log "checkList() Error: duplicate pair in files list: $changeSuffix"
            err "checkList() Error: duplicate pair in files list: $changeSuffix"
            return $E_FAILED_TEST
        fi

        # File existence & non-empty check - suffixes in list start with '/'
        local changeFile="$prefix$changeSuffix"
        local stateFile="$prefix$stateSuffix"

        if [[ ! -s "$changeFile" || ! -s "$stateFile" ]]; then
            log "checkList Error: missing or empty file(s) below:"
            log "  changeFile: $changeFile"
            log "  stateFile: $stateFile"
            err "checkList Error: missing or empty file(s). \
            changeFile: <$changeFile> stateFile: <$stateFile>"
            return $E_FAILED_TEST
        fi

        prevNoExt=$changeNoExt
        i=$((j + 1))

    };
    done

    log "checkList() Done checking files list; list and files passed all tests."
    return $EXIT_SUCCESS

} # END checkList()

# My "getdiff" program generates "rangeList.txt" - read as the Array here - in
# two forms; one with leading [minute|hour|day] directory entry - or mixture of
# them and the other form starts without any of those - starts with numbered
# directory entries. When first form is used; combined file name starts with a
# letter [m|h|d]. For example [ "m123" | "h123" | "d123" ], when starting with
# numbered directory entry, combined name is simply "123".
# argument FILE is the last file in file list to merge.
#
getCombinedName() {

    if [[ $# -lt 1 ]]; then
        log "getCombinedName(): Error - missing argument. Usage:"
        log "  getCombinedName FILE"
        return $E_MISSING_PARAM
    fi

    local myFile="$1"
    if [[ -z "$myFile" ]]; then
        log "getCombinedName(): Error - argument is empty"
        return $E_INVALID_PARAM
    fi

    local fileOnly firstLetter combinedName

    fileOnly=$(basename "$myFile")

    if [[ $myFile =~ ^/[0-9]{3}/ ]]; then
        combinedName="$fileOnly"
    else
        # get first letter from [minute|hour|day]
        firstLetter=$(echo "$myFile" | cut -d '/' -f 2 | cut -c 1)
        combinedName="${firstLetter}${fileOnly}"
    fi

    echo "$combinedName"
    return $EXIT_SUCCESS
}

# getStateHeaderLine() : form (make string) header comment line in state.txt file
getStateHeaderLine() {

    if [[ $# -lt 1 ]]; then
        log "getStateHeaderLine(): Error - missing argument. Usage:"
        log "  getStateHeaderLine FILE"
        return $E_MISSING_PARAM
    fi

    local myFile="$1"
    if [[ -z "$myFile" ]]; then
        log "getStateHeaderLine(): Error - argument is empty"
        return $E_INVALID_PARAM
    fi

    local firstLetter granularity
    firstLetter=$(echo "$myFile" | cut -d '/' -f 2 | cut -c 1)

    case "$firstLetter" in
        m) granularity="minutely" ;;
        h) granularity="hourly" ;;
        d) granularity="daily" ;;
        *) granularity="" ;;
    esac

    echo "# merged file; sequence number is for original OSM $granularity replication"

    return $EXIT_SUCCESS
}

# mergeListOSC() : merges a list of chage files specified by listArray
# into one change file specified by outputFile. dirPrefix specifies the directory
# prefix (root part) in the file system for files in oscArray.
# User should call checkList() BEFORE using this function.
#
# Usage: mergeListOSC OUT_FILE DIR_PREFIX OSC_ARRAY
#               OUT_FILE: user specified output file
#               DIR_PREFIX: First part of directory to change files
#               OSC_ARRAY: Array of strings for Change files and their
#                                      corresponding "state.txt" files. Array is
#                                      assumed to pass all tests in checkList()
#                                      function in this file.

mergeListOSC() {

    if [[ $# -lt 3 ]]; then
        log "mergeListOSC(): Error - missing arguments. Usage:"
        log "  mergeChanges OUT_FILE DIR_PREFIX OSC_ARRAY"
        return $E_MISSING_PARAM
    fi

    local outputFile="$1"
    local dirPrefix="$2"
    local -n oscArray="$3"   # Name reference for the array

    local length=${#oscArray[@]}

    if [[ $length -eq 0 ]]; then
        # do not explain reason, just return error code
        # user should NOT send an empty array!
        return $E_INVALID_PARAM
    fi

    log "mergeListOSC(): Parameters in are:"
    log "  outputFile is: $outputFile"
    log "  dirPrefix is: $dirPrefix"
    log "  oscArray LENGTH is: $length"
    log ""

    # set tmpDir where we write intermidiante merged files; use "getdiffDir/tmp"
    local tmpDir=$(dirname $dirPrefix)/tmp

    local i=0
    local batchMax=4 # adjust as your machine allows!
    local iBatch=0

    # i is index in the array
    # batchMax is maximum number of files to merge at one time
    # adjust batchMax if you want to merge more at a time.

    log "mergeListOSC(): Merging $batchMax files at a time."

    # flag to adjust number of OSC files from list after first loop
    adjustBatchMax=1

    while [[ $i -lt $length ]]; do {

        for (( j = 0;  j < batchMax  ; j++ )); do

            changeSuffix=${oscArray[$i]}
            changeFile=$dirPrefix$changeSuffix

            # insert file name into argument list,
            # first file in first loop will be first file from the Array
            argList="$argList $changeFile"
            ((iBatch++))

            # next change file - skip .state.txt file
            i=$((i+2))

            if [ $i -eq $length ]; then
                break
            fi
        done; # end for()

        # set name for current batch (intermediate) merged output file;
        # we set it from last file in argument list

        combinedName=$(getCombinedName "$changeSuffix") || return $?
        combinedFile=$tmpDir/$combinedName.osc.gz # we add the extension

        # format batch list (argList) for logging -- printf is better
        batchListFormatted=$(echo "$argList" | sed 's/ / \\ \n/g')
        batchListFormatted=$(echo "$batchListFormatted" | sed 's/^/                                /g')

        log "mergeListOSC() calling osmsium-merge-changes with:"
        log "  combinedFile is: $combinedFile"
        log "  argList has $iBatch files:"
        echo "$batchListFormatted" >> $logFile
        echo "$batchListFormatted"
        # $argList"

        # call osmsium-merge-changes
        $OSMIUM merge-changes --fsync --no-progress --overwrite --output "$combinedFile" $argList

        return_code=$?
        # Check the return code of osmium merge-changes
        if [ $return_code -ne 0 ]; then
            log "mergeListOSC(): Error: osmium merge-changes failed with exit code $return_code"
            return $return_code
        fi

        # osc file has its "state.txt" file -- this is the output state.txt
        combinedStateFile=$tmpDir/$combinedName.state.txt

        # index 'i' was already moved to next change file - in for() loop
        # state file is BEFORE the one we are pointing at with current "i".
        # we use state.txt for the last osc file in current batch
        stateFile=$dirPrefix${oscArray[$((i-1))]}

        log "mergeListOSC() copying state.txt:"
        log "   stateFile is: $stateFile"
        log "   combinedStateFile is: $combinedStateFile"

        cp $stateFile $combinedStateFile

        newLine=$(getStateHeaderLine "${oscArray[$((i-1))]}") || return $?
        sed -i "1s|.*|$newLine|" $combinedStateFile

        # start next batch "argList" with last merged file
        argList="$combinedFile"
        iBatch=1

        # decrement batchMax after first loop only;
        if [ $adjustBatchMax -eq 1 ]; then
            batchMax=$((batchMax-1))
            adjustBatchMax=0
        fi

    }; done # end while()

    log "mergeListOSC(): Done merging change files"
    log "mergeListOSC(): copying final merged file to destination"

    # move last combine + last state to output file
    outputStateFile="${outputFile%%.*}".state.txt

    cp $combinedFile $outputFile
    cp $combinedStateFile $outputStateFile

    log "mergeListOSC(): Wrote output file: $outputFile"
    log "mergeListOSC(): Wrote state.txt file: $outputStateFile"

    # Uncomment line below to EMPTY TMP DIRECTORY
    # rm -f $tmpDir/*

    return $EXIT_SUCCESS

} # END mergeListOSC()

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
        log "PRE_UPDATE_VERSION number is: $PRE_UPDATE_VERSION"
        log "Applying update from Change File: <$change_file> Dated: <$full_version>"

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
        log "POST_UPDATE_VERSION number is: $POST_UPDATE_VERSION"
        log "Done updating from $change_file"
    done

    log "update_from_osc_list(): DONE updating from $((length/2)) change file(s)."
    return $EXIT_SUCCESS

} # END update_from_osc_list()

# getMixedName <originalName> <stateFile>
getMixedName(){

if (( $# < 2 )); then
    log "getMixName(): Error - missing arguments."
    log "  Usage: getMixedName <originalName> <stateFile>"
    return $E_MISSING_PARAM
fi

local originalName=$1
local stateFile=$2

local timestampLine=$(grep timestamp "$stateFile")
local timestamp=${timestampLine#timestamp=}

# use date only shorter name! time is always at midnight (00:00:00)
local lastDate=$(echo $timestamp | cut -d 'T' -f 1)

# timestamp=${timestamp//\\/}
local fileName=$(basename $originalName)
local mixedFile=${fileName%%.*}-MIXED_$lastDate.osm.pbf

echo "$mixedFile"

return $EXIT_SUCCESS

} # END getMixedName()

# getNewName <originalName> <stateFile>
getNewName() {

    if (( $# < 2 )); then
        log "getNewName(): Error - missing arguments."
        log "  Usage: getNewName <originalName> <stateFile>"
        return $E_MISSING_PARAM
    fi

    local originalName=$1
    local stateFile=$2

    local timestampLine=$(grep timestamp "$stateFile")
    local timestamp=${timestampLine#timestamp=}

    # use date only, time is always midnight
    local lastDate=$(echo "$timestamp" | cut -d 'T' -f 1)

    local fileName=$(basename "$originalName")
    local base=${fileName%%.*}

    # if base ends with _YYYY-MM-DD, strip it
    base=$(echo "$base" | sed -E 's/_[0-9]{4}-[0-9]{2}-[0-9]{2}$//')

    local newFile="${base}_${lastDate}.osm.pbf"

    echo "$newFile"

    return $EXIT_SUCCESS

} # END getNewName()

getFileSysOSM(){

    # formats sequence number into OSM file system xxx/xxx/xxx
    if (( $# < 1 )); then
        log "getFileSysOSM(): Error - missing arguments."
        log "  Usage: getFileSysOSM <sequenceNum>"
        return $E_MISSING_PARAM
    fi

    local sequenceNum=$1

    # Validate: must be digits only, max 9 digits, not starting with zero
    if [[ ! $sequenceNum =~ ^[1-9][0-9]{0,8}$ ]]; then
        log "getFileSysOSM(): Error - invalid sequenceNum '$sequenceNum'."
        log "  Must be numeric, 1–9 digits, no leading zero."
        return $E_INVALID_PARAM
    fi

    local file parent root

    printf -v file   %03u $(( sequenceNum % 1000 ))
    printf -v parent %03u $(( (sequenceNum / 1000) % 1000 ))
    printf -v root   %03u $(( (sequenceNum / 1000000) % 1000 ))

    local fileSysOSM="$root/$parent/$file"

    echo "$fileSysOSM"

    return $EXIT_SUCCESS

} # END getFileSysOSM()
