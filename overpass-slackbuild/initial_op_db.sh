#!/bin/bash

# initial_op_db.sh : script to initial overpass database; takes THREE arguments
# $1 : inputfile where file is any OSM data file supported by "osmium" programs
# $2 : version number string, use last date from input file. Can not be empty.
# $3 : DB_DIR destination database directory.
#
# Scripts requires "osmium" to be installed.

INFILE=$1
VERSION=$2
DB_DIR=$3

# EXEC_DIR : overpass bin directory from Slackware package
EXEC_DIR=/usr/local/bin

# update_database and osmium programs
UPDATE_EXEC=$EXEC_DIR/update_database
OSMIUM=$EXEC_DIR/osmium

CTRL_SCRIPT=$EXEC_DIR/op_ctl.sh

# option to use - recommended is "--meta"
META=--meta

# experimental option for limited area extract - WARNING has multiple issues.
# META=--keep-attic

# accepted values are one of [ no| gz | lz4 ]
COMPRESSION=no

# controls amount of RAM usage by "update_database" program.
# with 16 GB ram I set this to 4 - still seems high
FLUSH_SIZE=4

set -e

if [[ -z $3 ]]; then
    echo "$0: Error missing argument(s); 3 are required"
    echo "usage: $0 inputfile version db_dir"
    echo "        where"
    echo " inputfile: OSM file in any osmium supported file format"
    echo " version: version number to use; set to last date in inputfile"
    echo " db_dir: is destination directory for overpass database"
    exit 1
fi

if [[ ! -d $DB_DIR ]]; then

    echo "$0: Error could not find destination directory: $DB_DIR"
    echo " Please create the directory and change ownership to overpass."
    exit 1
fi

# directory MUST be empty TODO

if [[ ! -s $INFILE ]]; then

    echo "$0: Error could not find or empty input file: $INFILE"
    exit 1
fi

if [[ ! -x $OSMIUM ]]; then

    echo "$0: Error could not find \"osmium\" executable"
    echo " Please install osmium-tool package"
    exit 1
fi

if [[ ! -x $UPDATE_EXEC ]]; then

    echo "$0: Error could not find \"update_database\" executable"
    echo " Please install or reinstall overpassAPI package"
    exit 1
fi

if [[ -z $VERSION ]]; then
    echo " $0: Error version string is empty"
    echo " Please use last date in your input file as version number"
    exit 1
fi

# osmconvert : is an alternative to osmium

$OSMIUM cat $INFILE -o - -f .osc | $UPDATE_EXEC --db-dir=$DB_DIR \
                                            --version=$VERSION \
                                            $META \
                                            --flush-size=$FLUSH_SIZE \
                                            --compression-method=$COMPRESSION \
                                            --map-compression-method=$COMPRESSION 2>&1 >/dev/null

# copy "rules" directory to new database?!
cp -pR /usr/local/rules $DB_DIR




# set DB_DIR path in /usr/local/bin/op_ctl.sh script
# sed -i "s|VIRTUAL_ENV=.*|VIRTUAL_ENV=\"$VENVPATH\"|g" venv/bin/activate
sed -i "s|DB_DIR=/path/to/your/overpass/DBase|DB_DIR=\"$DB_DIR\"|" $EXEC_DIR/op_ctl.sh

exit 0
