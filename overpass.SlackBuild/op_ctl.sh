#!/bin/bash
#
# op_ctl.sh : Overpass dispatcher control script
#
# Controls the Overpass API dispatcher daemon (start/stop/status).
# Designed for Slackware64 with binaries installed in /usr/local/bin
# and an 'overpass' user/group. Must be run as the 'overpass' user.
#
# Guide: https://github.com/waelhammoudeh/overpass-4-slackware
#

scriptName=$(basename "$0")
sysRoot=/var/lib
opHome="$sysRoot/overpass"

# Adjust this to your actual database path if needed
dbDir="$opHome/database"

execDir="/usr/local/bin"
DISPATCHER="$execDir/dispatcher"
opUser="overpass"

META="--meta"   # with extract data file always use --meta (not --attic)
DISPATCHER_MODE="normal mode" # dispatcher modes: [normal | meta | attic]

#--- Helper functions --------------------------------------------------

err() { echo "$scriptName: Error: $*" >&2; }
is_dispatcher_running() { pgrep -f "$DISPATCHER" >/dev/null 2>&1; }

# Detect current dispatcher mode by inspecting running process
get_base_mode() {
    local pid cmd
    pid=$(pgrep -f "dispatcher.*--osm-base" | head -n1)
    if [ -z "$pid" ]; then
        echo "not running"
        return 1
    fi
    cmd=$(ps -o args= -p "$pid")
    if [[ "$cmd" == *"--attic"* ]]; then
        echo "attic"
    elif [[ "$cmd" == *"--meta"* ]]; then
        echo "meta"
    else
        echo "normal"
    fi
}

#--- Environment checks ------------------------------------------------

if ! id -u "$opUser" >/dev/null 2>&1; then
    err "user '$opUser' not found. Please create 'overpass' user/group."
    exit 1
fi

if [[ $(id -un) != "$opUser" ]]; then
    err "Not running as '$opUser'. Please switch user."
    exit 1
fi

echo
echo "$scriptName: Using database directory: $dbDir"
echo

if [[ ! -d "$dbDir" ]]; then
    err "Database directory not found."
    exit 2
fi

if [[ -z "$(ls -A "$dbDir")" ]]; then
    err "Database directory is empty! Initialize the Overpass database first."
    exit 2
fi

[[ -f "$dbDir/nodes_meta.bin"  ]] && DISPATCHER_MODE="meta data support"
[[ -f "$dbDir/nodes_attic.bin" ]] && DISPATCHER_MODE="attic data support"

if ! command -v "$DISPATCHER" >/dev/null 2>&1; then
    err "dispatcher binary not found at $DISPATCHER"
    exit 2
fi

#--- Command dispatcher ------------------------------------------------

case "$1" in
    start)
        if is_dispatcher_running; then
            echo "Dispatcher already running ($DISPATCHER_MODE)."
            exit 0
        fi

        # Clean up stale sockets - we get here if dispatcher is NOT running
        for sock in osm3s_osm_base osm3s_areas; do
            if [[ -S "$dbDir/$sock" ]]; then
                echo "Found stalled socket $sock, removing..."
                rm -f "$dbDir/$sock" "/dev/shm/$sock" 2>/dev/null
            fi
        done

        echo "Starting base dispatcher ($DISPATCHER_MODE)..."
        "$DISPATCHER" --osm-base --db-dir="$dbDir" $META --allow-duplicate-queries=yes &
        sleep 1

        if ! is_dispatcher_running; then
            err "Base dispatcher failed to start."
            exit 1
        fi
        echo "Base dispatcher started."

        echo "Starting areas dispatcher..."
        "$DISPATCHER" --areas --db-dir="$dbDir" --allow-duplicate-queries=yes &
        sleep 1

        if [[ -S "$dbDir/osm3s_areas" ]]; then
            echo "Areas dispatcher started."
            exit 0
        else
            err "Areas dispatcher failed to start."
            exit 2
        fi
        ;;

    stop)
        if ! is_dispatcher_running; then
            err "Dispatcher is not running."
            exit 2
        fi

        "$DISPATCHER" --osm-base --terminate
        [[ -S "$dbDir/osm3s_areas" ]] && "$DISPATCHER" --areas --terminate

        sleep 2
        if is_dispatcher_running; then
            err "Could not stop dispatcher."
            exit 2
        else
            echo "Dispatcher stopped."
        fi
        ;;

    status)
        # Base dispatcher
        BASE_PID=$(pgrep -f "dispatcher.*--osm-base" | head -n1)
        if [ -n "$BASE_PID" ]; then
            BASE_MODE=$(get_base_mode)
            echo "Base dispatcher (PID $BASE_PID): running in $BASE_MODE mode support"
            echo ""
            "$DISPATCHER" --status
            echo ""
        else
            echo "Base dispatcher: not running"
        fi

        # Areas dispatcher
        AREAS_PID=$(pgrep -f "dispatcher --areas" | head -n1)
        if [ -n "$AREAS_PID" ]; then
            echo "Areas dispatcher (PID $AREAS_PID): running"
        else
            echo "Areas dispatcher: not running"
        fi
        ;;

    *)
        echo
        err "missing or unknown command."
        echo "Usage: $scriptName { start | stop | status }"
        echo
        exit 1
        ;;
esac
