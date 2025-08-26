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

SCRIPT_NAME=$(basename "$0")
SYS_ROOT=/var/lib
OP_HOME="$SYS_ROOT/overpass"

# Adjust this to your actual database path if needed
DB_DIR="$OP_HOME/database"

EXEC_DIR="/usr/local/bin"
DSPTCHR="$EXEC_DIR/dispatcher"
OP_USER_NAME="overpass"

META="--meta"   # with extract data file always use --meta (not --attic)
DIS_MODE="normal mode" # dispatcher modes: [normal | meta | attic]

#--- Helper functions --------------------------------------------------

err() { echo "$SCRIPT_NAME: Error: $*" >&2; }
is_dispatcher_running() { pgrep -f "$DSPTCHR" >/dev/null 2>&1; }

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

if ! id -u "$OP_USER_NAME" >/dev/null 2>&1; then
    err "user '$OP_USER_NAME' not found. Please create 'overpass' user/group."
    exit 1
fi

if [[ $(id -un) != "$OP_USER_NAME" ]]; then
    err "Not running as '$OP_USER_NAME'. Please switch user."
    exit 1
fi

echo
echo "$SCRIPT_NAME: Using database directory: $DB_DIR"
echo

if [[ ! -d "$DB_DIR" ]]; then
    err "Database directory not found."
    exit 2
fi

if [[ -z "$(ls -A "$DB_DIR")" ]]; then
    err "Database directory is empty! Initialize the Overpass database first."
    exit 2
fi

[[ -f "$DB_DIR/nodes_meta.bin"  ]] && DIS_MODE="meta data support"
[[ -f "$DB_DIR/nodes_attic.bin" ]] && DIS_MODE="attic data support"

if ! command -v "$DSPTCHR" >/dev/null 2>&1; then
    err "dispatcher binary not found at $DSPTCHR"
    exit 2
fi

#--- Command dispatcher ------------------------------------------------

case "$1" in
    start)
        if is_dispatcher_running; then
            echo "Dispatcher already running ($DIS_MODE)."
            exit 0
        fi

        # Clean up stale sockets - we get here if dispatcher is NOT running
        for sock in osm3s_osm_base osm3s_areas; do
            if [[ -S "$DB_DIR/$sock" ]]; then
                echo "Found stalled socket $sock, removing..."
                rm -f "$DB_DIR/$sock" "/dev/shm/$sock" 2>/dev/null
            fi
        done

        echo "Starting base dispatcher ($DIS_MODE)..."
        "$DSPTCHR" --osm-base --db-dir="$DB_DIR" $META --allow-duplicate-queries=yes &
        sleep 1

        if ! is_dispatcher_running; then
            err "Base dispatcher failed to start."
            exit 1
        fi
        echo "Base dispatcher started."

        echo "Starting areas dispatcher..."
        "$DSPTCHR" --areas --db-dir="$DB_DIR" --allow-duplicate-queries=yes &
        sleep 1

        if [[ -S "$DB_DIR/osm3s_areas" ]]; then
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

        "$DSPTCHR" --osm-base --terminate
        [[ -S "$DB_DIR/osm3s_areas" ]] && "$DSPTCHR" --areas --terminate

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
            "$DSPTCHR" --status
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
        echo "Usage: $SCRIPT_NAME { start | stop | status }"
        echo
        exit 1
        ;;
esac
