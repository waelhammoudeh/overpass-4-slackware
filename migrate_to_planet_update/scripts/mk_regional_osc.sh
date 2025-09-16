#!/bin/bash

# Script makes change files for a regional extract data file from daily planet
# change files. Script produces one extract change file for each daily planet
# change file - daily planet change files are NOT merged.
#
# Change file is the difference between 2 extract data files, so in this process
# an updated regional extract OSM data file is produced.
#
# Script file and "common_functions.sh" file must be in the same directory.
#
# usage: mk_regiom_osc.sh <list_file>
# <list_file>: file with change and state.txt pair list from planet osm server.
# this is the "newerFiles.txt" file produced by getdiff program.
#
# script requires (expect) the following setup:
#
# File system structure:
#
# /var/lib/overpass
#           |---getdiff
#           |---scripts
#           |---logs
#           |---region
#                   |---extract
#                   |---replication
#                   |target.name
#                   |poly_file
#                   |oscList.txt  ---> output file
#
# Script uses the following files from directories specified:
#
# <poly_file>: region polygon (.poly) file in region directory.
# <target_file>: file with name for latest regional OSM data file; in region directory.
#
# Target file must be created by user with name "target.name" in the region
# directory containing only the name for latest planet daily aligned regional
# OSM data file - file produced by "extract2planet.sh" script, data file is placed
# under region/extract directory. From your overpass home directory, this can be
# done with command:
#
#  ~$ echo "area-data-file_2025-08-12.osm.pbf" > region/target.name
#
# Script outputs:
#
# Script outputs "oscList.txt" file with new region change & state.txt file names
# appended to it in the region directory. Example "oscList.txt" file:
#
# /000/004/718.osc.gz
# /000/004/718.state.txt
# /000/004/719.osc.gz
# /000/004/719.state.txt
#
# Updater program / script should remove or rename this "oscList.txt" file.
#
# Region change files and their corresponding state.txt files are written to
# replication directory under the region directory.
# Updated region OSM data files are written in the extract directory under the
# region directory.
#
# Script settings by user:

# User must set variables below in the script (top):
#
# polyFileName: set variable to poly file name only and place it in region directory.
# regionName: set to your area or region name, use short name!
#
# Script has no gaurantee at all. USE AT YOU OWN RISK
#
# Wael Hammoudeh
#

# set to your region poly file name ONLY, place file in your region directory
polyFileName=arizona.poly

# set to your area or region name, use short name
regionName=Arizona

# script name no path & no extension
scriptName=$(basename "$0" .sh)

# directories:

scriptsDir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

opDir=/var/lib/overpass

regionDir=$opDir/region

extractDir=$regionDir/extract

replicationDir=$regionDir/replication

getdiffDir=$opDir/getdiff

planetDir=$getdiffDir/planet/day

# tmpDir=/tmp/mk_osc
# Create temporary directory under /tmp with mk_osc prefix
tmpDir=$(mktemp -d /tmp/mk_oscXXXXXX)

logDir=$opDir/logs

execDir=/usr/local/bin

# files:

polyFile=$regionDir/$polyFileName

# new change state.txt files are appended to our list file.
# updater should remove or rename when done!
oscList=$regionDir/oscList.txt

# create "target.name" file with your region OSM data file name in it - no path.
# this is the file produced by "extract2planet.sh" script, use command below:
# echo "arizona-internal_2025-08-12.osm.pbf" > region/target.name
#
# region OSM data file is placed in region/extract directory.

targetFile=$regionDir/target.name

listFile=$getdiffDir/newerFiles.txt

logFile=$logDir/$scriptName.log

# executables
OSMIUM=$execDir/osmium

source "$scriptsDir/common_functions.sh"

usage() {
  echo "usage:"
  echo ""
  echo "$scriptName.sh <list_file>"
  echo " list_file: file name with a list of planet change and state.txt files."
  echo ""
  return $EXIT_SUCCESS
}

### --- check arguments number ---
[[ $# -ne 1 ]] && usage && exit $E_MISSING_PARAM

listFile=$1

mkdir -p $logDir
touch $logFile

log "======================== Starting ======================"
log "$scriptName has started ..."
log " Input settings in use:"
log "   target_file is: $targetFile"
log "   list_file is: $listFile"
log ""
log " Output settings in use:"
log "  extract directory: $extractDir"
log "  change and state files (region): $replicationDir"
log "  oscList.txt file directory: $regionDir"
log ""

chk_directories $opDir $regionDir $extractDir $replicationDir $getdiffDir $planetDir $execDir
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_directories() function. Exiting"
    log "Script work directory is where region and getdiff directories are found."
    exit $E_FAILED_TEST
fi

chk_files $polyFile $targetFile
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_files() function. Exiting"
    exit $E_FAILED_TEST
fi

chk_executables $OSMIUM
if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed chk_executables() function. Exiting"
    exit $E_FAILED_TEST
fi

# check list file - it is NOT an error when file is empty or not found
if [[ ! -s $listFile ]]; then
    log "List file: \"$listFile\" not found or empty."
    log "No new change files to update with. Exiting"
    log "+++++++++ No New Change Files Were Found ++++++++++"
    exit $EXIT_SUCCESS
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

i=0

while [[ $length -gt $i ]]; do

    changeSuffix=${newFilesArray[$i]}
    stateSuffix=${newFilesArray[($i + 1)]}

    currentChangeFile=$planetDir$changeSuffix
    currentStateFile=$planetDir$stateSuffix

    targetName=$(cat $targetFile)
    latestExtractFile=$extractDir/$targetName

    chk_files $latestExtractFile
    if [[ $? -ne $EXIT_SUCCESS ]]; then
    log "Error failed to locate latest extract file: $latestExtractFile. Exiting"
    exit $E_FAILED_TEST
    fi

    # merge change file into extract, output is set to mixedExtract in tmpDir
    mixedName=$(getMixedName $latestExtractFile $currentStateFile)
    rc=$?
    if [[ $rc -ne $EXIT_SUCCESS || -z "$mixedName" ]]; then
        log "Error failed getMixedName(), empty string or missing argument!"
        log "Returned code is: $rc. Exiting with error XXXXX"
        exit $E_UNKNOWN
    fi

    mixedExtract=$tmpDir/$mixedName

    log ""
    log "Applying planet change file to latest extract into mixedExtract"
    log "  currentChangeFile: $currentChangeFile"
    log "  latestExtractFile is: $latestExtractFile"
    log "  mixedExtract is: $mixedExtract"
    log ""

    $OSMIUM apply-changes --overwrite \
                         --output $mixedExtract \
                         $latestExtractFile $currentChangeFile

    # save return code
    rc=$?

    # Check the return code from osmium apply-changes
    if [ $rc -ne 0 ]; then
        log "Error: osmium apply-changes failed with exit code $rc"
        log "Exiting with error XXXXX"
        exit $rc
    fi

    log "Successfully wrote mixedExtract to: $mixedExtract"
    log ""

    # make new extract data file: trim mixed extract file, output is set to newName in extractDir
    newName=$(getNewName $latestExtractFile $currentStateFile)
    rc=$?
    if [[ $rc -ne $EXIT_SUCCESS || -z "$newName" ]]; then
        log "Error failed getNewName(), empty string or missing argument!"
        log "Returned code is: $rc. Exiting with error XXXXX"
        exit $E_UNKNOWN
    fi

    newExtract=$extractDir/$newName

    # info we set in --output-header for new extract data file
    sequenceNum=$(grep "sequenceNumber=" "$currentStateFile" | cut -d= -f2)

    timestampLine=$(grep timestamp "$currentStateFile")
    timestamp=${timestampLine#timestamp=}
    timestamp=${timestamp//\\/}

    # this URL is ASSUMED!!!
    URL="https://planet.osm.org/replication/day"

    log "Making new area data file from mixed file; parameters:"
    log "  MIXED data file: $mixedExtract"
    log "  poly file: $polyFile"
    log "  new area data file: $newExtract"
    log ""

    $OSMIUM extract -s complete_ways --set-bounds --overwrite -p "$polyFile" \
            --output-header="osmosis_replication_sequence_number"="$sequenceNum" \
            --output-header="osmosis_replication_timestamp"="$timestamp" \
            --output-header="osmosis_replication_base_url"="$URL" \
            --output $newExtract \
            $mixedExtract

    # save return code
    rc=$?

    # Check the return code from osmium extract
    if [[ $rc -ne 0 ]]; then
        log "Error: osmium extract command failed with exit code $rc"
        log "Exiting with error XXXXX"
        exit $rc
    fi

    # we have a new & old REGIONAL extract data files, get geion change file
    # set new change file name (destination) & ensure directories exist

    osmFileSys=$(getFileSysOSM $sequenceNum)
    if [ -z $osmFileSys ]; then
        log "Error empty string for osmFileSys variable!"
        log "Exiting with error XXXXX"
        exit $E_UNKNOWN
    fi

    # ensure destination directories exist
    dirParts="${osmFileSys:0:7}"
    mkdir -p "$replicationDir/$dirParts"

    newChangeFile=$replicationDir/$osmFileSys.osc.gz
    newStateFile=$replicationDir/$osmFileSys.state.txt

    log "Making new change file; with parameters:"
    log "  prevoius data file: $latestExtractFile"
    log "  new data file: $newExtract"
    log "  output new change file: $newChangeFile"
    log""

    $OSMIUM derive-changes  --overwrite \
                        $latestExtractFile $newExtract \
                        --output $newChangeFile

    # save return code
    rc=$?

    # Check the return code from osmium extract
    if [ $rc -ne 0 ]; then
        log "Error: osmium derive-changes command failed with exit code $rc"
        log "Exiting with error XXXXX"
        exit $rc
    fi

    log "Successfully wrote new change file to: $newChangeFile"

    # write state.txt file
    cp $currentStateFile $newStateFile

    # replace first line in new state.txt file (header)
    myHeader="# $(date -u), $regionName region OSC. Original planet daily OSC sequence number $sequenceNum"

    # Replace first line with new header
    sed -i "1s|.*|$myHeader|" "$newStateFile"

    # Clean timestamp line (remove backslashes) in new state.txt
    sed -i 's/\\//g' "$newStateFile"

    log "Successfully wrote new state.txt file to: $newStateFile"

    # add new pair file names to oscList.txt in regionDir
    # ONLY path suffix is added with slash to start path

    echo "/$osmFileSys.osc.gz" >> $oscList
    echo "/$osmFileSys.state.txt" >> $oscList

    log "Appended new pair names to list file: $oscList"

    # sequence number is written to "replicate_id" in regionDir
    echo "$sequenceNum" > $regionDir/replicate_id

    # update extract name in target file
    echo "$newName" > $targetFile

    i=$((i + 2))
done # end while()

# rename processed list file: newerFiles.txt to newerFiles.txt.old
mv $listFile $listFile.old

rm -rf $tmpDir

log "Script is done, exiting with EXIT_SUCCESS value of zero"
log "------------------------------ DONE -------------------------------"
echo "" >>$logFile

exit $EXIT_SUCCESS
