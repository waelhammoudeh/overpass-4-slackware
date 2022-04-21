#!/bin/bash

# script NOT final

INFILE=$1
VERSION=$2

# EXEC_DIR : overpass bin directory from Slackware package
EXEC_DIR=/usr/local/bin

# update_database and osmium programs
UPDATE_EXEC=$EXEC_DIR/update_database
OSMIUM=$EXEC_DIR/osmium

# where to initial overpass database
# set to your "overpass" home directory

DB_DIR=/path/to/database/directory

# option to use - recommended is "--meta"

META=--meta

# experimental option for limited area extract
# META=--keep-attic

# accepted values are one of [ no| gz | lz4 ]
COMPRESSION=no

# the amount of RAM to use, with 16 GB ram I set this to 8
FLUSH_SIZE=8

echo "DB_DIR is $DB_DIR"

set -e

if [[ -z $2 ]]; then
    echo "$0: Error missing argument(s); 2 are required"
    echo "usage: $0 inputfile version"
    echo "        where"
    echo " inputfile is OSM file in any osmium supported format"
    echo " version is version number to use; set to last date in inputfile"
    exit 1
fi

$OSMIUM cat $INFILE -o - -f .osc | $UPDATE_EXEC --db-dir=$DB_DIR \
                                            --version=$VERSION $META \
                                            --flush-size=$FLUSH_SIZE \
                                            --compression-method=$COMPRESSION

