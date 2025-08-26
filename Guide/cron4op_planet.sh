#!/bin/bash
#
# cron job script : updates overpass database. ONLY "overpass" user does this.
#
# this is cron4op2.sh -- uses planet server change files.
#


# This script calls "getdiff" program to fetch differ files from the internet.
# The script then calls "op_update_db.sh" to apply those differs to overpass
# database.
#
# This script is part of  the Guide in "overpass-4-slackware" repository found at:
# https://github.com/waelhammoudeh/overpass-4-slackware
#
# Edit PSWD line with osm.org password if using geofabrik.de INTERNAL server.
#
# crontab entry to run script for daily updates: (overpass user cron job entry)
# @daily ID=opUpdate /usr/local/bin/cron4op.sh 1> /dev/null
#

# script name no path & no extension
scriptName=$(basename "$0" .sh)

OP_USR_ID=367

if [[ $EUID -ne $OP_USR_ID ]]; then

  echo "$scriptName: Error you must be \"overpass\" user"
  # this script is to be setup as cron job by "overpass" user
  exit 1

fi

# directories:
sysRoot=/var/lib

opDir=$sysRoot/overpass

dbDir=$opDir/database

areaDir=$opDir/arizona

differsDir=$areaDir/differs

execDir=/usr/local/bin

# files:
gtConf=$opDir/getdiff.conf

newChanges=$areaDir/newChanges.txt

# executables:
GETDIFF=$execDir/getdiff

OSC_MAKER=$execDir/mk_regional_osc.sh

UPDATER=$execDir/op_update_db2.sh

chk_directories() {

  for dir in "$sysRoot" "$opDir" "$areaDir" "$differsDir" "$execDir" ; do
    if [ ! -d "$dir" ]; then
      echo "$scriptName: Error - Directory not found: $dir"
      exit 1
    fi
  done
}

# function to check database directory
# directory can be real or a link to directory, directory can not be empty.
# function does NOT terminate on error; check return value.
check_database_directory() {
    local DIR=$1

    if [[ -z "$1" ]]; then
      echo "$scriptName: Error, missing argument in check_database_directory()!"
      return 2
    fi

    echo "check_database_directory(): Checking database directory at: $dbDir"

    # we check for just few files
    local REQUIRED_FILES=("node_keys.bin" "relation_keys.bin" "way_keys.bin" "osm_base_version")

    if [ -L "$DIR" ] || [ -d "$DIR" ] && [ -n "$(ls -A "$DIR")" ]; then
        for file in "${REQUIRED_FILES[@]}"; do
            if [ ! -e "$DIR/$file" ]; then
                echo "$scriptName: Error; Missing essential database file: ($file) not found in the database directory."
                return 1
            fi
        done
    else
        echo "Error: The database directory ($DIR) does not exist or is not a symbolic link to a non-empty directory."
        return 1
    fi
#    echo "$0: Directory $DIR checked okay"
    return 0
}
# END check_database_directory() function

chk_executables() {

  for prog in "$GETDIFF" "$OSC_MAKER" "$UPDATER"  ;do
    if [ ! -x "$prog" ]; then
      echo "$scriptName: Error could not find executable: $prog"
      exit 1
    fi
  done
}

chk_directories

check_database_directory $dbDir

# check return value from this function
returnValue=$?

if [[ ! $returnValue -eq 0 ]]; then

    echo "$scriptName: Error failed check_database_directory() function!"
    exit 1
fi

chk_executables

# fetch change files from planet server, use configuration file
$GETDIFF -c $gtConf

if [[ ! $? -eq 0 ]]; then

    echo "$scriptName: Error $GETDIFF"
    exit 1
fi

# make regional change files from planet change files
$OSC_MAKER
if [[ ! $? -eq 0 ]]; then

    echo "$scriptName: Error $OSC_MAKER"
    exit 1
fi

# update overpass database; script takes 2 arguments
$UPDATER $newChanges $differsDir
if [[ ! $? -eq 0 ]]; then

    echo "$scriptName: Error $UPDATER"
    exit 1
fi

exit 0
