#!/bin/bash

# extract2planet.sh
#
#
# Script aims to produce an new updated OSM regional extract file aligned with
# daily updates from planet OSM {https://planet.osm.org/replication/day} server.
#
# Planet server daily updates are issued at the hour (00:00:00 UTC).
#
# Usage: extract2planet.sh <data_file> <poly_file> <list_file>
#   <data_file>: recent region extract from Geofabrik.de
#   <poly_file>: region polygon (.poly) file, available from Geofabrik site.
#   <list_file>: range list file "rangeList.txt" produced by getdiff.
#
# The range list is for minutely and hourly planet change files (starting with the
# oldest and ending with newest) that covers the time gap between last included
# data in Geofabrik data file and midnight of the next day, the list is manually
# constructed and downloaded using "getdiff" program range function.
#
# The script writes the new produced OSM data file to {regionDir}/extract/
# (directory must exist) using input <data_file> name with appended date
# separated by an underscore character: original-name_YYYY-MM-DD.osm.pbf
# Please do not use underscore in data file name.):-
#
# There is no guarantee that this is accurate. USE AT YOUR OWN RISK.
#

scriptName=$(basename "$0" .sh)

scriptsDir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# script work directory is where region and getdiff directories are.
workDir=$(pwd)

# set / change to your own region name below
regionName=arizona

regionDir=$workDir/$regionName

extractDir=$regionDir/extract

getdiffDir=$workDir/getdiff

tmpDir=$getdiffDir/tmp # directory is used by mergeListOSC() function FIXME

planetDir=$getdiffDir/planet

logDir=$workDir/logs

logFile=$logDir/$scriptName.log

execDir=/usr/local/bin

OSMIUM=$execDir/osmium

source "$scriptsDir/common_functions.sh"

usage() {
  echo "usage:"
  echo ""
  echo "$scriptName.sh <data_file> <poly_file> <list_file>"
  echo " data_file: Extract data file to update"
  echo " poly_file: Region polygon (.poly) file."
  echo " list_file: File name with time gap change files list (from getdiff)."

  return $EXIT_SUCCESS
  }

### --- check arguments number ---
[[ $# -ne 3 ]] && usage && exit $E_MISSING_PARAM

dataFile=$1
polyFile=$2
listFile=$3

mkdir -p $logDir
touch $logFile

chk_directories $regionDir $extractDir $getdiffDir $planetDir $execDir $tmpDir
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_directories() function. Exiting"
    log "Script work directory is where region and getdiff directories are found."
    exit $E_FAILED_TEST
fi

log "================= $scriptName Starting ================="
log "$scriptName has started ..."
log "Arguments In Are:"
log "   dataFile is: $dataFile"
log "   polyFile is: $polyFile"
log "   listFile is: $listFile"

chk_files $dataFile $polyFile $listFile
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_files() function. Exiting"
    exit $E_FAILED_TEST
fi

chk_executables $OSMIUM
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_executables() function. Exiting"
    exit $E_FAILED_TEST
fi

# initial an empty array
declare -a newFilesArray=()

# read list file placing each line in an array element
while IFS= read -r line
do
{
    newFilesArray+=("$line")
}
done < "$listFile"

checkList $planetDir newFilesArray
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed checkList() function. Exiting"
    exit $E_FAILED_TEST
fi

length=${#newFilesArray[@]}

# we use date from last state file in names we create & sequenceNum
lastStateFile=$planetDir${newFilesArray[$length - 1]}

# Usage:: mergeListOSC <OUT_FILE> <DIR_PREFIX> <OSC_ARRAY>
# we need to specify <OUT_FILE> for mergeListOSC() function.

combinedOSC=$regionDir/combined_gap.osc.gz

mergeListOSC $combinedOSC $planetDir newFilesArray
rc=$?
if [[ $rc -ne $EXIT_SUCCESS ]]; then
  log "Error failed mergeListOSC() function!"
  exit $rc
fi

mixedFileName=$tmpDir/$(getMixedName $dataFile $lastStateFile)

log "Merging PLANET changes with area data file; parameters:"
log "  region data file: $dataFile"
log "  planet change file: $combinedOSC"
log "  output file: $mixedFileName"
log ""

$OSMIUM apply-changes --overwrite \
                      --output $mixedFileName \
                      $dataFile $combinedOSC

# save return code
return_code=$?

# Check the return code from osmium apply-changes
if [ $return_code -ne 0 ]; then
  log "Error: osmium apply-changes failed with exit code $return_code"
  exit $return_code
fi

log "Merged combined PLANET change file, find mixed file: $mixedFileName"
log ""

newDataFile=$extractDir/$(getNewName $dataFile $lastStateFile)

# --output-header is used to set sequence number, URL & timestamp
sequenceNum=$(grep sequenceNumber "$lastStateFile" | cut -d= -f2)

# this URL is ASSUMED!!!
URL="https://planet.osm.org/replication/hour"

timestampLine=$(grep timestamp "$lastStateFile")
timestamp=${timestampLine#timestamp=}
timestamp=${timestamp//\\/}

log "Making new area data file from mixed file; parameters:"
log "  polygon file: $polyFile"
log "  MIXED data file: $mixedFileName"
log "  new area data file: $newDataFile"
log ""

$OSMIUM extract -s complete_ways --set-bounds --overwrite -p "$polyFile" \
                                 --output-header="osmosis_replication_sequence_number"="$sequenceNum" \
                                 --output-header="osmosis_replication_base_url"="$URL" \
                                 --output-header="osmosis_replication_timestamp"="$timestamp" \
                                 --output $newDataFile \
                                 $mixedFileName

# save return code
return_code=$?

# Check the return code from osmium extract
if [ $return_code -ne 0 ]; then
    log "Error: Failed osmium extract command with exit code $return_code"
    exit $return_code
fi

log "Successfully made new extract OSM data file contains all OSM data up to: $timestamp"
log "New OSM data file was written to: $newDataFile"
log "$scriptName is done"
log ""

# TODO: write a state.txt file for this

exit $EXIT_SUCCESS
