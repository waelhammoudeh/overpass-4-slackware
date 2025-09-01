#!/bin/bash

# cron4op.sh -- cron job for overpass
# script calls getdiff then op_update_db.sh
# script removes change files older than 7 days from getdiff/geofabrik directory
#

# --- Exit / return codes ---
EXIT_SUCCESS=0
E_MISSING_PARAM=1
E_INVALID_PARAM=2
E_FAILED_TEST=3
E_UNKNOWN=4

# script name no path & no extension
scriptName=$(basename "$0" .sh)

# --- Logging ---

log_dir=/var/lib/overpass/logs
log_file=$log_dir/cron4op.log
mkdir -p "$log_dir"
exec >>"$log_file" 2>&1

err() {
    # Usage: err "message"
    # Writes message to stderr with timestamp
    echo "$(date '+%F %T') $scriptName: ERROR: $*" >&2
}

log() {
    # Normal log message
    echo "$(date '+%F %T') $scriptName: $*"
}

# --- chk_executables ---
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

# --- chk_files ---
chk_files() {
    if [[ $# -eq 0 ]]; then
        err "chk_files(): missing argument(s) file1 [file2 ...]"
        return $E_MISSING_PARAM
    fi

    for f in "$@"; do
        if [[ ! -s "$f" ]]; then
            err "chk_files(): File not found or is an empty file: $f"
            return $E_FAILED_TEST
        fi
    done

    return $EXIT_SUCCESS
}

# --- chk_directories ---
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

# --- Configuration ---
op_user="overpass"

op_home=/var/lib/overpass
getdiff_dir=$op_home/getdiff
osc_dir=$getdiff_dir/geofabrik
exec_dir=/usr/local/bin

configure=$getdiff_dir/getdiff.conf

GETDIFF=$exec_dir/getdiff
UPDATER=$exec_dir/op_update_db.sh

SECRET=""
# OSM account password for INTERNAL server at Geofabrik

log "Starting cron job"

# only "overpass" user can update database
if [[ $(id -u -n) != $op_user ]]; then
    err "Not $op_user user! You must run this script as the \"$op_user\" user."
    exit $E_FAILED_TEST
fi

chk_directories $op_home $getdiff_dir $osc_dir $exec_dir
if [[ $? -ne $EXIT_SUCCESS ]]; then
    err "Error failed chk_directories() function. Exiting"
    exit $E_FAILED_TEST
fi

chk_executables $GETDIFF $UPDATER
if [[ $? -ne $EXIT_SUCCESS ]]; then
    err "Error failed chk_executables() function. Exiting"
    exit $E_FAILED_TEST
fi

chk_files $configure
if [[ $? -ne $EXIT_SUCCESS ]]; then
    err "Error failed chk_files() for getdiff configure. Exiting"
    exit $E_FAILED_TEST
fi

# --- Run getdiff ---
if [[ -z $SECRET ]]; then
    $GETDIFF -c "$configure"
else
    $GETDIFF -c "$configure" -p "$SECRET"
fi
ret=$?
if [[ $ret -ne $EXIT_SUCCESS ]]; then
    err "Error failed <getdiff> operation. Exiting with code $ret"
    exit $ret
fi

# --- Run updater ---
$UPDATER "$getdiff_dir/newerFiles.txt" "$osc_dir"
ret=$?
if [[ $ret -ne $EXIT_SUCCESS ]]; then
    err "Error failed <op_update_db.sh> operation. Exiting with code $ret"
    exit $ret
fi

# --- Cleanup old files ---
cd "$op_home" || exit $E_UNKNOWN
find "$osc_dir" -mtime +7 -type f -delete >/dev/null 2>&1

log "Finished successfully"

exit $EXIT_SUCCESS
