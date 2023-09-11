#!/bin/bash

# Script to update an extract OSM data file - the target file.
# Script applies changes using open street map daily change files (OSC) to
# region extract OSM data file.
# Script is designed to automatically applies the changes - called by cron job.
#
# Script work directory (workDir) is the directory where the target OSM data file
# is placed and its required 2 text files are expected to be found.
# The target OSM data file name is read from file: "scriptName.target".
# The OSC files to apply are read from file: "scriptName.oscList"
#
# Format for target name: prefix-YYYY-MM-DD.osm.pbf where:
#   - prefix is all alphabets (do not use dashes).
#   - YYYY-MM-DD year, month & day (date);  last date for included data
#   - .osm.pbf extension can be .osh.pbf (history file)
#
# Script replaces the date part in target name and uses that as output file name.
# Script removes (deletes) target OSM data file when successfully changes are applied.
#
#

#
# update_osm_file.target input file example; 2 lines below:

# target=arizonaAttic-2023-08-20.osh.pbf
# url=https://osm-internal.download.geofabrik.de/north-america/us/arizona-updates

# if value for osmosis_replication_base_url is missing from original OSM data
# file header; use this file to have it set in the new file header.

# update_osm_file.oscList input file example:

# /var/lib/overpass/getdiff/diff/combined/796.osc.gz
# /var/lib/overpass/getdiff/diff/combined/796.state.txt
# /var/lib/overpass/getdiff/diff/000/003/797.osc.gz
# /var/lib/overpass/getdiff/diff/000/003/797.state.txt
# /var/lib/overpass/getdiff/diff/000/003/798.osc.gz
# /var/lib/overpass/getdiff/diff/000/003/798.state.txt

# this list is produced by "op_update_db.sh" script.

# file system root directory
sysRoot=/var/lib

# overpass home directory
opHome=$sysRoot/overpass

# log file directory
logDir=$opHome/logs

# script name no path & no extension
scriptName=$(basename "$0" .sh)

# script log file name
logFile="$logDir/$scriptName.log"

ERR_FOOTER="x=x=x=x=x=x=x=x=x=x=x=x= Exiting with ERROR =x=x=x=x=x=x=x=x=x=x=x=x=x=x=x"

# script work directory : file to update & osc list location
workDir=$opHome/sources

# create merged directory for merged osc files; should use 'mktemp' maybe!
mergedDir=$workDir/mergedOSC

# script input are 2 text files:

# text file with Target OSM data file name to update
# file name format: regionName-YYYY-MM-DD.osm.pbf
# name includes '-YYYY-MM-DD' with dashes; do NOT
# include dashes in regionName name. Date part will be
# replaced with each update applied.
hasTarget=$workDir/$scriptName.target

# list in pairs for Change File & corresponding state.txt files
hasOscList=$workDir/$scriptName.oscList

# executables directory
execDir=/usr/local/bin

# osmium executable
OSMIUM=$execDir/osmium

# function merge-changes2() :
# like mergeChanges() function but take 2 arguments; the second is for output file name.
# merged (combined) file is written to argument specified by $2.
# mergeChanges2() - Merge a list of OpenStreetMap change files into a single file.
# function calls 'osmium' to do the merging.
# Parameters:
#   $1: A space-separated list of OpenStreetMap change files to be merged.
#       The last file name in the list will be used as the output for the merged changes.
#       Last file in the list is renamed by appending ".original" to its name.
#   $2: destination file name for output; string includes path + filename.
# Returns: 1 on errors; if osmium executable is not found or merge list has a single file.
#
#
mergeChanges2() {

    input=$1
    output=$2

    # Check if the input list of files is empty
    if [ -z "$1" ]; then
        echo "$(date '+%F %T'): mergeChanges2() Error: missing required first argument" >> $logFile
        echo "$(date '+%F %T'): mergeChanes2(): Argument is a string containing a list of OSM change file names to merge." >> $logFile
        return 1
    fi

    # Check for second argument - destination combined file (path + name)
    if [ -z "$1" ]; then
        echo "$(date '+%F %T'): mergeChanges2() Error: missing required second argument for destination" >> $logFile
        return 1
    fi

    myExec=/usr/local/bin/osmium
    if [[ ! -x $myExec ]]; then
      echo "mergeChanges2(): Error could not find \"osmium\" executable." >&2
      echo "mergeChanges2(): Error could not find \"osmium\" executable." >> $logFile
      return 1
    fi

    # Convert the input string of filenames into an array
    fileArray=($input)

    # do not allow list with SINGLE file name
    numFiles=${#fileArray[@]}

    if [ $numFiles -eq 1 ]; then
        echo "$(date '+%F %T'): mergeChanges2() Error: Only one file provided. Please provide 2 or more files for merging." >> $logFile
        return 1
    fi

    echo "$(date '+%F %T'): mergeChanges2(): Input files: $input" >> $logFile

        # Create the formatted list
    fileListFormatted=$(echo "$input" | sed 's/ / \\ \n/g')

    echo "$(date '+%F %T'): mergeChanges2(): Formatted argument list is below:" >> $logFile
    echo "$fileListFormatted" >> $logFile
    echo "" >> $logFile

    echo "$(date '+%F %T'): mergeChanges2(): Output File is: $output" >> $logFile
    echo "" >> $logFile

    # Run osmium merge-changes to combine input files into the output file -
    # Notice the lack qoutes around $input
    #
    # use "${fileArray[@]}" instead of $input - used fileArray to get numbers in.
    ## $myExec merge-changes --fsync --no-progress -o "$output" $input >> "$logFile" 2>&1

    $myExec merge-changes --fsync --no-progress --overwrite -o "$output" "${fileArray[@]}" >> "$logFile" 2>&1
    return_code=$?

    # Check the return code of osmium merge-changes
    if [ $return_code -ne 0 ]; then
        echo "$(date '+%F %T'): mergeChanges2(): Error: osmium merge-changes failed with exit code $return_code" >> $logFile
        echo $ERR_FOOTER >> $logFile
        return $return_code
    fi

    echo "mergeChanges2(): Merging complete." >> $logFile
    echo "" >> $logFile

    return 0

}
# END mergeChanges2()

OP_USER_NAME="overpass"

if [[ $(id -u -n) != $OP_USER_NAME ]]; then
    echo "$SCRIPT_NAME: ERROR Not \"$OP_USER_NAME\" user! You must run this script as the \"$OP_USER_NAME\" user."
    echo ""
    echo " This script is part of the Guide for \"overpassAPI\" installation and setup on"
    echo "Linux Slackware system. The Guide repository can be found here:"
    echo "https://github.com/waelhammoudeh/overpass-4-slackware"
    echo $ERR_FOOTER >> $logFile
    echo ""

    exit 1
fi

# check workDir, bailout if it does not exist
if [[ ! -d $workDir ]]; then
  echo "$scriptName: Error work directory does NOT exist."
  echo $ERR_FOOTER >> $logFile
  exit 1
fi

# ensure log directory exists
if [[ ! -d $logDir ]]; then
    mkdir $logDir
fi

# touch our log file
touch $logFile

echo "============================================================================" >> $logFile
echo "$(date '+%F %T'): $scriptName.sh started ..." >>$logFile

# check hasTarget file
if [[ ! -s $hasTarget ]]; then
  echo "$scriptName: Error 'hasTarget': \"$hasTarget\" file is empty or not found."
  echo "$scriptName: Error 'hasTarget': \"$hasTarget\" file is empty or not found." >> $logFile
  echo $ERR_FOOTER >> $logFile
  exit 1
fi

# get the targetName: file name only in text file WITHOUT PATH.
targetName=$(cat "$hasTarget" | grep target | cut -d '=' -f 2)

# target name must be in format: regionName-YYYY-MM-DD.osm.pbf or regionName-YYYY-MM-DD.osh.pbf
# allow exactly 3 dashes, YYYY, MM & DD are all digits.

# Define the required format using a regular expression
required_format="^[A-Za-z-]+-[0-9]{4}-[0-9]{2}-[0-9]{2}\.(osm|osh)\.pbf$"

# Check if the targetName matches the required file name format
if [[ ! "$targetName" =~ $required_format ]]; then
    echo "$scriptName: Error targetName \"$targetName\" does not match the required file name format."
    echo "accepted format: regionName-YYYY-MM-DD.osm.pbf or regionName-YYYY-MM-DD.osh.pbf"
    echo "where Y, M & D are all digits, no dashes are allowed in regionName."
    echo "$scriptName: Error targetName \"$targetName\" does not match the required format." >> $logFile
    echo $ERR_FOOTER >> $logFile
    exit 1
fi

# inputFile to "osmium" includes path + name
inputFile=$workDir/$targetName

# check it exist
if [[ ! -s $inputFile ]]; then
  echo "$scriptName: Error target file not found in expected directory: $inputFile"
  echo "$scriptName: Error target file not found in expected directory: $inputFile" >>$logFile
  echo $ERR_FOOTER >> $logFile
  exit 1
fi

echo "$scriptName: updating OSM data file: \"$targetName\" in $workDir" >> $logFile

if [[ ! -d $mergedDir ]]; then
  mkdir $mergedDir
fi

# check Change File list file; nothing to do if it is empty
if [[ ! -s $hasOscList ]]; then
  echo "$scriptName: OSC file list is empty or does not exist. No new changes to apply." >> $logFile
  echo "$scriptName: No new changes to apply. script is done."
  echo "++++++++++++++++++++++++++ No New Change Files Found +++++++++++++++++++++++++++" >>$logFile
  exit 0
fi

# initial an empty array
declare -a newFilesArray=()

# read osc list file placing each line in an array element
# IFS (Internal Field Separator). read has ONE variable (line), it gets the whole
# line from read.
while IFS= read -r line
do
{
    newFilesArray+=($line)
}
done < "$hasOscList"

# verify input:
# array length must be even number - file pairs
# a pair must have same file name number - .osc file & .state.txt file
length=${#newFilesArray[@]}

if [[ $length -lt 2 ]]; then
   echo "$SCRIPT_NAME: Error number of lines in input file is less than 2"
   echo "$(date '+%F %T'): Error number of lines in input file is less than 2" >>$logFile
   echo $ERR_FOOTER >>$logFile
   exit 1
fi

echo "$(date '+%F %T'): Read input file with number of lines: $length" >>$logFile

# is number EVEN?
rem=$(( $length % 2 ))
if [[ $rem -ne 0 ]]; then
   echo "$SCRIPT_NAME: Error found ODD number of lines in input file"
   echo "$(date '+%F %T'): Error found ODD number of lines in input file." >>$logFile
   echo $ERR_FOOTER >>$logFile
   exit 1
fi

# check that change file matches the very next state file
# checking ALL file pairs - it is ALL or NOTHING deal
# assumes list is sorted - getdiff produces sorted list.

# Note about variable names below:
#
# stateFileName: /000/003/641.state.txt
# stateName: 641.state.txt
# stateFileNumber 641
#
# osc list file has FULL path; unlike "newerFiles.txt" for op_update_db.sh script.
#
# /var/lib/overpass/getdiff/diff/combined/812.osc.gz
# /var/lib/overpass/getdiff/diff/combined/812.state.txt
#
# /var/lib/overpass/getdiff/diff/000/003/813.osc.gz
# /var/lib/overpass/getdiff/diff/000/003/813.state.txt
#

i=0
j=0

while [ $i -lt $length ]
do
    j=$((i+1))
    changeFileName=${newFilesArray[$i]}
    stateFileName=${newFilesArray[$j]}

    # get file names ONLY - drop path part
    changeName=`basename $changeFileName`
    stateName=`basename $stateFileName`

    # get file name string (numbers) from file names
    changeFileNumber=`echo "$changeName" | cut -f 1 -d '.'`
    stateFileNumber=`echo "$stateName" | cut -f 1 -d '.'`

    # they better be the same numbers
    if [[ $changeFileNumber -ne $stateFileNumber ]]; then
        echo "$SCRIPT_NAME: Error Not same files; mismatched change and state files!"
        echo "changeFileName : $changeFileName"
        echo "stateFileName : $stateFileName"
        echo "$(date '+%F %T'): Error changeFileName and stateFileName do NOT match" >>$logFile
        echo $ERR_FOOTER >>$logFile
        exit 1
    fi

    # osc list may have original downloaded Change files PLUS combined Change Files;
    # that is already merged Change Files. we skip checking for files until needed below.
    # osc list file has FULL path; unlike "newerFiles.txt" for op_update_db.sh script.
    #
    # /var/lib/overpass/getdiff/diff/combined/812.osc.gz
    # /var/lib/overpass/getdiff/diff/combined/812.state.txt
    #
    # /var/lib/overpass/getdiff/diff/000/003/813.osc.gz
    # /var/lib/overpass/getdiff/diff/000/003/813.state.txt

    # move to next pair
     i=$((j+1))
done

# done checking - all good to go.

# merge change files when array has more than 1 of them
if [ $length -gt 2 ]; then
  echo "$(date '+%F %T'): Array has more than one change files, combining them ..." >> $logFile
  echo "$(date '+%F %T'): Making file list string ..." >> $logFile

  i=0

  # maximum number of files to merge at one time
  # adjust batchMax if you want to merge more at a time.
  batchMax=4

  # use same number of files in each batch - last file from previous batch is included in next batch
  adjustBatchMax=1

  while [[ $i -lt $length ]]; do
  {

    for (( j = 0;  j < batchMax  ; j++ )); do

      changeFileName=${newFilesArray[$i]}

      # insert file name into list - as is; it includes FULL path
      fileList="$fileList $changeFileName"

      # next change file - skip .state.txt file
      i=$((i+2))

      if [ $i -eq $length ]; then
        break
      fi

    done;

#    echo "fileList has: $fileList"
#    echo ""

    # set destination file for merged / combined output
    fileName=$(basename "$changeFileName")
    combinedFile=$mergedDir/$fileName

    # remove leading space from fileList
    fileList=$(echo "$fileList" | sed 's/^ //')

    echo "Calling function mergeChanges2() with 2 arguments:" >> $logFile
    echo "    fileList: $fileList" >> $logFile
    echo "    output: $combinedFile" >> $logFile
    echo "" >> $logFile

    mergeChanges2 "${fileList}" $combinedFile
    return_code=$?

    # Check the return code from mergeChanges2() function
    if [ $return_code -ne 0 ]; then
       echo "$(date '+%F %T'): Error: function mergeChanges2() failed with exit code $return_code" >> $logFile
       echo $ERR_FOOTER >>$logFile
       exit $return_code
    fi

    # write state.txt file corresponding to combinedFile - copy state.txt for last change file in the list
    # i was already moved to next change file - state file is BEFORE the one we are pointing at with i
    stateFile=${newFilesArray[$((i-1))]}

    cp $stateFile $mergedDir/

    stateFileCopy=$mergedDir/$(basename $stateFile)

    # start next "fileList" with "combinedFile"
    fileList="$combinedFile"

    # decrement batchMax; we just inserted lastFile from previous batch into new batch list
    if [ $adjustBatchMax -eq 1 ]; then
      batchMax=$((batchMax-1))
      adjustBatchMax=0
    fi

  }; done

fi

# use merged file when it was done
if [ $length -gt 2 ]; then
   changeFile=$combinedFile
   stateFile=$stateFileCopy
else
  changeFile=${newFilesArray[0]}
  stateFile=${newFilesArray[1]}
fi

echo "$(date '+%F %T'): Using Change File: $changeFile" >> $logFile
echo "$(date '+%F %T'): Using State File: $stateFile" >> $logFile
echo "" >> $logFile

# make new OSM data file name; by replacing $YMD part in name
# $YMD is: "YYYY-MM-DD" part in the name.
# get date string "YYYY-MM-DD" from state.txt & use as replacement
# in OSM data file name.
# greped line from state.txt file:
# timestamp=2023-09-03T20\:21\:30Z
#
YMD=`cat $stateFile | grep timestamp | cut -d 'T' -f -1 | cut -d '=' -f 2`

# OSM data file name is in $targetName variable - file name only; no path
# targetName="arizonaAttic-2023-08-20.osh.pbf"

fPrefix=$(echo $targetName | cut -d '-' -f -1)
ext=$(echo $targetName | cut -d '.' -f 2,3)

# stitch new name for output file
newTarget=$fPrefix-$YMD.$ext

echo "$(date '+%F %T') $scriptName: newTarget name is: $newTarget" >> $logFile
echo "newTarget name is: $newTarget"

if [[ "$targetName" == "$newTarget" ]]; then
    echo "$scriptName: Error, output file name is the same as input file name; exiting."
    echo "$(date '+%F %T') $scriptName: Error, output file name is the same as input file name; exiting." >>$logFile
    echo "ERR_FOOTER" >>$logFile
    exit 1
fi

# outputFile from "osmium" includes path + newTarget name
outputFile=$workDir/$newTarget

# we only set 2 header options; sequence number & URL for region update page.
# get sequence number from state.txt file
sequenceNum=$(cat $stateFile | grep 'sequenceNumber' | cut -d '=' -f 2)

# try to get regionUpdateURL from origional file using 'osmium fileinfo'
regionUpdateURL=$($OSMIUM fileinfo --no-progress -e -g header.option.osmosis_replication_base_url $inputFile)

# if not set in original file, try from hasTarget file
if [[ -z $regionUpdateURL ]]; then
  regionUpdateURL=`cat $hasTarget | grep 'url' | cut -d '=' -f 2`
fi

historyOption=""
inFormat="--input-format=osm.pbf"
outFormat="--output-format=osm.pbf"

if [[ -n $(echo $ext | grep osh) ]]; then
  historyOption="--with-history"
  inFormat="--input-format=osh.pbf"
  outFormat="--output-format=osh.pbf"

  echo "using --with-history option"
fi

# apply the change

$OSMIUM apply-changes \
      $inputFile \
      $changeFile \
      --output=$outputFile \
      --output-header=osmosis_replication_sequence_number=$sequenceNum \
      --output-header=osmosis_replication_base_url=$regionUpdateURL \
      $inFormat $outFormat --change-file-format=osc.gz \
      --overwrite \
      --no-progress \
      ${historyOption:+$historyOption} \
       --fsync

 if [[ ! $? -eq 0 ]]; then
    echo "$scriptName: Error apply-changes failed !"
    echo "$(date '+%F %T'): $scriptName: Error apply-changes failed!" >>$logFile
    echo $ERR_FOOTER >>$logFile
    exit 1
fi

# update hasTarget file:
echo "target=$newTarget" > $hasTarget
echo "url=$regionUpdateURL" >> $hasTarget

# empty the bucket - remove / delete oscList
rm $workDir/$scriptName.oscList

# remove / delete old target file
rm $inputFile

# remove files from merged directory - if used
if [[ $length -gt 2 ]]; then
  rm $mergedDir/*.*
fi

echo "$scriptName: changes applied successfully."

echo "$(date '+%F %T'): $scriptName: changes applied successfully." >>$logFile

echo "$(date '+%F %T'): --------------------------------------$scriptName is done --------------------------------------" >>$logFile

exit 0

# setting bbox in header reduces nodes, ways & relations count. I went without bbox in header.
# https://github.com/osmcode/osmium-tool/issues/243
# https://github.com/osmcode/osmium-tool/issues/181
# overpass@yafa:~/sources$ osmium apply-changes --verbose --output-header=osmosis_replication_sequence_number=3814 arizonaAttic-2023-08-20.osh.pbf mergedOSC/814.osc.gz -O -o mergedOSC/arizonaAttic-2023-09-07.osh.pbf

# MUST use --with-history for history files when using osmium-extract. TODO: test osmium-sort for history files.
# set bounding box
# overpass@yafa:~/sources$ osmium extract --bbox "-114.8325,30.05891,-109.0437,37.00596" --set-bounds mergedOSC/arizonaAttic-2023-09-07.osh.pbf -o mergedOSC/arizonaAttic-2023-09-07-extract.osh.pbf -v --overwrite --with-history
# this also sets bbox using poly file; with MORE data loss.
# overpass@yafa:/root$ osmium extract -p arizona.poly --set-bounds mergedOSC/arizonaAttic-2023-09-07.osh.pbf -o mergedOSC/arizonaAttic-2023-09-07-extrctpoly.osh.pbf -v --overwrite --with-history

