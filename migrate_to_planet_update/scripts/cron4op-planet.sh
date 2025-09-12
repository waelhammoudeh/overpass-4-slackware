#!/bin/bash

# cron4op-planet.sh -- cron job for overpass from planet server
# script calls "getdiff" to fetch planet daily change files, calls "mk_regional_osc.sh"
# to make region daily change files and new OSM data file, script then calls
# "op_update_db.sh" to update overpass database using made region change files.
#
# script removes old files from directories: getdiff download, region change files
# and region extract.
#

# --- Exit / return codes ---
EXIT_SUCCESS=0
E_MISSING_PARAM=1
E_INVALID_PARAM=2
E_FAILED_TEST=3
E_UNKNOWN=4

# script name no path & no extension
scriptName=$(basename "$0" .sh)

# --- Logging helper ---
log() {
    # Usage: log "message"
    # Writes to stdout and appends to log file with timestamp
    echo "$(date '+%F %T') [$scriptName] $*"
    echo "$(date '+%F %T') [$scriptName] $*" >> "$logFile"
}

getErrorString() {
    # usage: getErrorString <code>
    # code is one of 0 - 4 as defined above

    local code=$1
    case $code in
        $EXIT_SUCCESS)
            echo "EXIT_SUCCESS (0): operation completed successfully"
            ;;
        $E_MISSING_PARAM)
            echo "E_MISSING_PARAM (1): missing required parameter"
            ;;
        $E_INVALID_PARAM)
            echo "E_INVALID_PARAM (2): invalid parameter provided"
            ;;
        $E_FAILED_TEST)
            echo "E_FAILED_TEST (3): check failed (file/dir/executable/test)"
            ;;
        $E_UNKNOWN|*)
            echo "E_UNKNOWN (4): unknown or unexpected error"
            ;;
    esac
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

opUser="overpass"

opDir=/var/lib/overpass

logDir=$opDir/logs

regionDir=$opDir/region

extractDir=$regionDir/extract

replicationDir=$regionDir/replication

getdiffDir=$opDir/getdiff

planetDir=$getdiffDir/planet/day

execDir=/usr/local/bin

GETDIFF=$execDir/getdiff

OSC_MAKER=$execDir/mk_regional_osc.sh

UPDATER=$execDir/op_update_db.sh

gdConfigure=$getdiffDir/getdiff.conf

logFile=$logDir/$scriptName.log

# only "overpass" user can update database
if [[ $(id -u -n) != $opUser ]]; then
    echo "Not $opUser user! You must run this script as the \"$opUser\" user."
    exit $E_FAILED_TEST
fi

mkdir -p $logDir
touch $logFile

log "Starting cron job for overpass ..."

chk_directories $opDir $regionDir $extractDir $replicationDir $getdiffDir $planetDir  $execDir

if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_directories() function. Exiting"
    exit $E_FAILED_TEST
fi

chk_executables $GETDIFF $OSC_MAKER $UPDATER
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_executables() function. Exiting"
    exit $E_FAILED_TEST
fi

chk_files $gdConfigure
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_files() for getdiff configure. Exiting"
    exit $E_FAILED_TEST
fi

# get new daily planet change files with getdiff
log "Getting new change files from planet server"

$GETDIFF -c "$gdConfigure"

rc=$?
if [[ $rc -ne $EXIT_SUCCESS ]]; then
    log "Error failed <getdiff> operation. Exiting with code < $rc >"
    log "See program log for more info."
    log "Exiting with error XXXXX"
    log ""
    exit $rc
fi

log "Program < getdiff > completed successfully"
log "======================================================"
log""

# make regional change file(s) from planet change ones - using list / download from getdiff
log "Making regional change and data files ..."

$OSC_MAKER $getdiffDir/newerFiles.txt

rc=$?
if [[ $rc -ne $EXIT_SUCCESS ]]; then
    log "Error failed <mk_regional_osc.sh> operation. Exiting with code < $rc >; code is for:"
    log "< $(getErrorString $rc) >, see script log for more info."
    log "Exiting with error XXXXX"
    log ""
    exit $rc
fi

log "Script < mk_regional_osc.sh > completed successfully"
log "======================================================"
log""


# update overpass database - from regional change files
log "Updating overpass database ..."

$UPDATER $regionDir/oscList.txt $replicationDir

rc=$?
if [[ $rc -ne $EXIT_SUCCESS ]]; then
    log "Error failed <op_update_db.sh> operation. Exiting with code < $rc >; code is for:"
    log "< $(getErrorString $rc) >, see script log for more info."
    log "Exiting with error XXXXX"
    log ""
    exit $rc
fi

log "Script < op_update_db.sh > completed successfully"
log "======================================================"
log""

# --- Cleanup old files ---
cd "$opDir" || exit $E_UNKNOWN

deleted=$(find "$extractDir" -mtime +7 -type f -print -delete | wc -l)
log "Cleanup: removed $deleted old extract files"

deleted=$(find "$replicationDir" -mtime +7 -type f -print -delete | wc -l)
log "Cleanup: removed $deleted old change/state.txt files"

deleted=$(find "$planetDir" -mtime +7 -type f -print -delete | wc -l)
log "Cleanup: removed $deleted old files from getdiff"

log "Cron job for overpass was done successfully"
log "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
log ""

exit $EXIT_SUCCESS
