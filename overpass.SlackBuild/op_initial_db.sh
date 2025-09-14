#!/bin/bash
#
# op_initial_db.sh : Initialize Overpass database and build area objects.
#
# Usage: op_initial_db.sh <osm_file> <db_dir>
#   osm_file : OSM data file (any format supported by osmium)
#   db_dir   : Destination database directory (must exist and be empty)
#
# run script with nohup
#  nohup op_initial_db.sh inputfile database/  < /dev/null > nohup.out 2>&1 &
#
# Requirements:
#   - Run as user "overpass"
#   - "osmium" (from osmium-tool package)
#   - "update_database" (from overpassAPI)
#
# Part of the installation guide for overpassAPI on Slackware:
#   https://github.com/waelhammoudeh/overpass-4-slackware
#

scriptName=$(basename "$0" .sh)
opUser="overpass"

execDir=/usr/local/bin

UPDATER="$execDir/update_database"
OSMIUM="$execDir/osmium"

pkgLib=/usr/local/lib/overpass
templateDir="$pkgLib/templates"
rulesDir="$pkgLib/rules"

META=--meta               # preferred import mode
COMPRESSION="gz"          # accepted values: [ no | gz | lz4 ]
# FLUSH_SIZE=${FLUSH_SIZE:-4} # changed to optional last argument 9/14/2025
REPLICATE_ID="replicate_id"

### --- Helper functions ---
die() { echo "$scriptName: ERROR: $*" >&2; exit 1; }
warn() { echo "$scriptName: WARNING: $*" >&2; }
info() { echo "$scriptName: $*"; }

usage() {
    cat <<EOF
Usage: $scriptName.sh <osm_file> <db_dir> [flush_size]
  osm_file : Input file (any OSM format supported by osmium)
  db_dir   : Destination Overpass DB directory (must exist and be empty)
  flush_size : (optional) Chunk size for update_database [default: 4]
EOF
    exit 1
}

### --- Validate arguments ---
[[ $# -lt 2 || $# -gt 3 ]] && usage

inFile=$1
dbDir=$(realpath "$2")

# Default flush size = 4 if not given
FLUSH_SIZE=${3:-4}

# Validate flush size is a positive integer
[[ "$FLUSH_SIZE" =~ ^[0-9]+$ ]] || die "Invalid flush size: $FLUSH_SIZE"

[[ $(id -un) != "$opUser" ]] && \
    die "Must run as user \"$opUser\"."

pgrep dispatcher >/dev/null && {
    dir=$(dispatcher --show-dir)
    die "dispatcher is running using DB dir: \"$dir\". Stop it before initializing."
}

[[ ! -s $inFile ]] && die "Input file not found or empty: $inFile"
[[ ! -d $dbDir ]] && die "Destination directory missing: $dbDir"
[[ -n "$(ls -A "$dbDir")" ]] && die "Destination directory not empty: $dbDir"
[[ ! -x $OSMIUM ]] && die "Missing executable: osmium"
[[ ! -x $UPDATER ]] && die "Missing executable: update_database"

# Ensure trailing slash for DB dir
[[ $dbDir != */ ]] && dbDir="$dbDir/"

# --- do not allow keyboard input ---
exec </dev/null

### --- Extract OSM metadata ---
seqNum=$($OSMIUM fileinfo -e -g header.option.osmosis_replication_sequence_number "$inFile")
regionURL=$($OSMIUM fileinfo -e -g header.option.osmosis_replication_base_url "$inFile")
timestamp=$($OSMIUM fileinfo -e -g header.option.osmosis_replication_timestamp "$inFile")
if [[ -z "$timestamp" ]]; then
    timestamp=$($OSMIUM fileinfo -e -g data.timestamp.last "$inFile")
fi

### --- Run database initialization ---
set -eo pipefail

$OSMIUM cat "$inFile" -o - -f .osc \
  | $UPDATER --db-dir="$dbDir" \
             --version="$timestamp" \
             $META \
             --flush-size="$FLUSH_SIZE" \
             --compression-method="$COMPRESSION" \
             --map-compression-method="$COMPRESSION" \
  || die "Database initialization failed."

info "Database initialization successful."
[[ -n $timestamp ]] && info "OSM Timestamp: $timestamp" || warn "Missing OSM timestamp."
[[ -n $regionURL ]] && info "Replication URL: $regionURL" || warn "Missing replication URL."
[[ -n $seqNum ]] && info "Replication sequence #: $seqNum" || warn "Missing replication sequence #."

### --- Write replication sequence number ---
[[ -n $seqNum ]] && echo "$seqNum" > "${dbDir}${REPLICATE_ID}"

### --- Copy templates & rules ---
[[ -d $templateDir ]] && cp -pR "$templateDir" "$dbDir"
[[ -d $rulesDir ]] && cp -pR "$rulesDir" "$dbDir"

### --- Build area objects ---
info "Building areas in database ..."
$execDir/osm3s_query --db-dir="$dbDir" --rules <"$rulesDir/areas.osm3s" \
  || die "Failed to build areas."

info "Areas built successfully."
info "Database is ready for use."
info "$scriptName completed."

exit 0
