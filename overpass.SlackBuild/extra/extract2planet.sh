#!/bin/bash

# extract2planet.sh
#
# script merges a list of sorted planet change files into a regional extract
# data file - updating the regional extract file with the combined change files.
#
# Usage: extract2planet.sh <data_file> <poly_file> <list_file>
#   <data_file>: recent region extract from Geofabrik.de
#   <poly_file>: region polygon (.poly) file, available from Geofabrik site.
#   <list_file>: range list file "rangeList.txt" produced by getdiff.
#
# The script writes the new produced OSM data file to region/extract/
# (directory must exist) using input <data_file> name with appended date
# from last state.txt file timestamp date part in the rangeList.txt file
# separated by an underscore character resulting in name format below:
#
#   original-name_YYYY-MM-DD.osm.pbf
#
# input file name should follow this naming format with underscore between
# name and date part ONLY.
# Please do not use underscore in original data file name.):-
#
# script write its progress to logs/extract2planet.log file
# script uses "osmium" to accomplish its work.
#
# script assumes the following file system structure:
#
#   extract_planet
#       ├── getdiff
#       ├── logs
#       ├── scripts
#       │   ├── common_functions.sh
#       │   └── extract2planet.sh
#       ├── region
#       │   ├── arizona.poly
#       |   └── region-extract_YYYY-MM-DD.osm.pbf
#       └── tmp
#
# There is no guarantee that this is accurate. USE AT YOUR OWN RISK.
#
#

scriptName=$(basename "$0" .sh)

# common.sh file is in scriptDir
scriptDir=$(realpath $(dirname "$0"))

workDir=$(dirname $scriptDir)

opDir=/var/lib/overpass

opUser="overpass"

# non overpass user must create "extract_planet" directory in their HOME
if [[ $(id -un) != "$opUser" ]]; then
    opDir=$HOME/extract_planet
    echo "Anchored to directory: $opDir"
fi

# set / change to your own region name below
# or set when calling script: REGION=myRegion extract2planet.sh
# where "myRegion" is your region name to use AND create directory
REGION=${REGION:-region}

regionDir=$opDir/$REGION

extractDir=$regionDir/extract

getdiffDir=$opDir/getdiff

tmpDir=$opDir/tmp # directory is used by mergeListOSC() function

# TMP is passed on to common_functions.sh script to use our directory
TMP=$opDir/tmp

planetDir=$getdiffDir/planet

logDir=$opDir/logs

logFile=$logDir/$scriptName.log

execDir=/usr/local/bin

OSMIUM=$execDir/osmium

source "$scriptDir/common_functions.sh"

usage() {
  echo "usage:"
  echo ""
  echo "$scriptName.sh <data_file> <poly_file> <list_file>"
  echo " data_file: Extract data file to update"
  echo " poly_file: Region polygon (.poly) file."
  echo " list_file: Filename with change files list to merge."

  return $EXIT_SUCCESS
  }

### --- check arguments number ---
[[ $# -ne 3 ]] && usage && exit $E_MISSING_PARAM

dataFile=$1
polyFile=$2
listFile=$3

mkdir -p $logDir
touch $logFile

chk_directories $regionDir $extractDir $getdiffDir $planetDir $execDir $tmpDir $TMP
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

combinedOSC=$TMP/combined_gap.osc.gz

mergeListOSC $combinedOSC $planetDir newFilesArray
rc=$?
if [[ $rc -ne $EXIT_SUCCESS ]]; then
  log "Error failed mergeListOSC() function!"
  exit $rc
fi

mixedFileName=$TMP/$(getMixedName $dataFile $lastStateFile)

log "Merging PLANET changes with area data file; parameters:"
log "  region data file: $dataFile"
log "  planet change file: $combinedOSC"
log "  output file: $mixedFileName"
log ""

$OSMIUM apply-changes --overwrite \
                      --output $mixedFileName \
                      $dataFile $combinedOSC

# save return code
rc=$?

# Check the return code from osmium apply-changes
if [ $rc -ne 0 ]; then
  log "Error: osmium apply-changes failed with exit code $rc"
  exit $rc
fi

log "Merged combined PLANET change file, find mixed file: $mixedFileName"
log ""

newDataFile=$extractDir/$(getNewName $dataFile $lastStateFile)

# --output-header is used to set sequence number, URL & timestamp
sequenceNum=$(grep sequenceNumber "$lastStateFile" | cut -d= -f2)

lastLine=${newFilesArray[$length - 1]}

# URL is based on first entry from last read line
granularity=$(cut -d/ -f2 <<< "$lastLine")

URL="https://planet.osm.org/replication/$granularity"

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
rc=$?

# Check the return code from osmium extract
if [ $rc -ne 0 ]; then
    log "Error: Failed osmium extract command with exit code $rc"
    exit $rc
fi

log "Successfully made new extract OSM data file contains all OSM data up to: $timestamp"
log "New OSM data file was written to: $newDataFile"
log "$scriptName is done"
log ""

# remove files from tmp directory - you want to uncomment line below!
# rm $TMP/*

exit $EXIT_SUCCESS
