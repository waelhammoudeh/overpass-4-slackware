#!/bin/bash
#
# op_initial_db.sh : Initialize Overpass database and build area objects.
#
# Usage: op_ initial_db.sh <osm_file> <db_dir>
#   osm_file : OSM data file (any format supported by osmium)
#   db_dir   : Destination database directory (must exist and be empty)
#
# Requirements:
#   - Run as user "overpass"
#   - "osmium" (from osmium-tool package)
#   - "update_database" (from overpassAPI)
#
# Part of the installation guide for overpassAPI on Slackware:
#   https://github.com/waelhammoudeh/overpass-4-slackware
#

SCRIPT_NAME=$(basename "$0" .sh)
OP_USER_NAME="overpass"

EXEC_DIR=/usr/local/bin
UPDATE_EXEC="$EXEC_DIR/update_database"
OSMIUM="$EXEC_DIR/osmium"

PKG_LIB=/usr/local/lib/overpass
TEMPLATES_DIR="$PKG_LIB/templates"
RULES_DIR="$PKG_LIB/rules"

META=--meta               # preferred import mode
COMPRESSION="gz"          # accepted values: [ no | gz | lz4 ]
FLUSH_SIZE=${FLUSH_SIZE:-4}
REPLICATE_ID="replicate_id"

### --- Helper functions ---
die() { echo "$SCRIPT_NAME: ERROR: $*" >&2; exit 1; }
warn() { echo "$SCRIPT_NAME: WARNING: $*" >&2; }
info() { echo "$SCRIPT_NAME: $*"; }

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME.sh <osm_file> <db_dir>
  osm_file : Input file (any OSM format supported by osmium)
  db_dir   : Destination Overpass DB directory (must exist and be empty)
EOF
    exit 1
}

### --- Validate arguments ---
[[ $# -ne 2 ]] && usage

IN_FILE=$1
DB_DIR=$(realpath "$2")

[[ $(id -un) != "$OP_USER_NAME" ]] && \
    die "Must run as user \"$OP_USER_NAME\"."

pgrep dispatcher >/dev/null && {
    dir=$(dispatcher --show-dir)
    die "dispatcher is running using DB dir: \"$dir\". Stop it before initializing."
}

[[ ! -s $IN_FILE ]] && die "Input file not found or empty: $IN_FILE"
[[ ! -d $DB_DIR ]] && die "Destination directory missing: $DB_DIR"
[[ -n "$(ls -A "$DB_DIR")" ]] && die "Destination directory not empty: $DB_DIR"
[[ ! -x $OSMIUM ]] && die "Missing executable: osmium"
[[ ! -x $UPDATE_EXEC ]] && die "Missing executable: update_database"

# Ensure trailing slash for DB dir
[[ $DB_DIR != */ ]] && DB_DIR="$DB_DIR/"

### --- Extract OSM metadata ---
SEQ_NUM=$($OSMIUM fileinfo -e -g header.option.osmosis_replication_sequence_number "$IN_FILE")
URL_REGION=$($OSMIUM fileinfo -e -g header.option.osmosis_replication_base_url "$IN_FILE")
TIMESTAMP=$($OSMIUM fileinfo -e -g data.timestamp.last "$IN_FILE")

### --- Run database initialization ---
set -eo pipefail

$OSMIUM cat "$IN_FILE" -o - -f .osc \
  | $UPDATE_EXEC --db-dir="$DB_DIR" \
                 --version="$TIMESTAMP" \
                 $META \
                 --flush-size="$FLUSH_SIZE" \
                 --compression-method="$COMPRESSION" \
                 --map-compression-method="$COMPRESSION" \
                 >/dev/null 2>&1 \
  || die "Database initialization failed."

info "Database initialization successful."
[[ -n $TIMESTAMP ]] && info "OSM Timestamp: $TIMESTAMP" || warn "Missing OSM timestamp."
[[ -n $URL_REGION ]] && info "Replication URL: $URL_REGION" || warn "Missing replication URL."
[[ -n $SEQ_NUM ]] && info "Replication sequence #: $SEQ_NUM" || warn "Missing replication sequence #."

### --- Write replication sequence number ---
[[ -n $SEQ_NUM ]] && echo "$SEQ_NUM" > "${DB_DIR}${REPLICATE_ID}"

### --- Copy templates & rules ---
[[ -d $TEMPLATES_DIR ]] && cp -pR "$TEMPLATES_DIR" "$DB_DIR"
[[ -d $RULES_DIR ]] && cp -pR "$RULES_DIR" "$DB_DIR"

### --- Build area objects ---
info "Building areas in database ..."
$EXEC_DIR/osm3s_query --db-dir="$DB_DIR" --rules <"$RULES_DIR/areas.osm3s" \
  || die "Failed to build areas."

info "Areas built successfully."
info "Database is ready for use."
info "$SCRIPT_NAME completed."

exit 0
