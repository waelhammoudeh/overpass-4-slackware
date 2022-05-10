#!/bin/bash

# script to set overpass database path variable in several scripts and other files:
# op_ctl.sh
# update_op_db.sh
# cron4op.sh
# op_logrotate file
# getdiff.conf file

# scripts takes two argumnets: DB_DIR and LOC_DIR
# DB_DIR : database directory to set variable to; do not include last slash
# LOC_DIR : location directory for files, by default we look in current directory
# Files are assumed to be in unaltered state, as they exist in the repository.
#
# sed -i "s|^DB_DIR=.*$|DB_DIR=${DB_DIR}|" looks first occurrence ONLY
# line starts with DB_DIR= and anything else after to end of line.

if [[ -z $1 ]]; then
    echo "Error: missing arguments."
    echo "Usage: $0 DB_DIR [LOC_DIR]"
    echo " DB_DIR: overpass database directory to use, do not end with a slash"
    echo " LOC_DIR: directory where scripts and file are located"
    echo " by default current directory is used"
    exit 0
fi

CWD=$(pwd)
LOC_DIR=$CWD

# echo "CWD is $CWD"
DB_DIR=$1

# check directory first
# test for database directory - might be empty; that is okay
if [ ! -d $DB_DIR ]; then
   echo " Could not find specified directory"
   echo " We set path to real directory path."
   exit 2
fi

# use second argument for LOC_DIR when provided - to find files to change
if [[ -n $2 ]]; then
    LOC_DIR=$2
fi

# op_ctl.sh line
# DB_DIR=/path/to/your/overpass/DBase
if [[ -s $LOC_DIR/op_ctl.sh ]]; then
    {
    sed -i "s|^DB_DIR=.*$|DB_DIR=${DB_DIR}|" $LOC_DIR/op_ctl.sh
    echo "Fixed $LOC_DIR/op_ctl.sh"
    };
else
    {
    echo "Did NOTHING to: $LOC_DIR/op_ctl.sh"
    };
fi

# update_op_db.sh line
# DB_DIR=/mnt/nvme4/op2-meta
if [[ -s $LOC_DIR/update_op_db.sh ]]; then
    {
    sed -i "s|^DB_DIR=.*$|DB_DIR=${DB_DIR}|" $LOC_DIR/update_op_db.sh
    echo "Fixed $LOC_DIR/update_op_db.sh"
    };
else
    {
    echo "Did NOTHING to: $LOC_DIR/update_op_db.sh"
    };
fi

# cron4op.sh line
# DB_DIR=/path/to/overpass/database
if [[ -s $LOC_DIR/cron4op.sh ]]; then
    {
    sed -i "s|^DB_DIR=.*$|DB_DIR=${DB_DIR}|" $LOC_DIR/cron4op.sh
    echo "Fixed $LOC_DIR/cron4op.sh"
    };
else
    {
    echo "Did NOTHING to: $LOC_DIR/cron4op.sh"
    };
fi

# op_area_update.sh line
# DB_DIR=/mnt/nvme4/op2-meta
if [[ -s $LOC_DIR/op_area_update.sh ]]; then
    {
    sed -i "s|^DB_DIR=.*$|DB_DIR=${DB_DIR}|" $LOC_DIR/op_area_update.sh
    echo "Fixed $LOC_DIR/op_area_update.sh"
    };
else
    {
    echo "Did NOTHING to: $LOC_DIR/op_area_update.sh"
    };
fi

# op_logrotate lines; 2 lines:
# $DB_DIR/logs/update_op_db.log  $DB_DIR/logs/op_area_update.log $DB_DIR/getdiff/getdiff.log {
# and
# $DB_DIR/transactions.log {
if [[ -s $LOC_DIR/op_logrotate ]]; then
    {
    sed -i "s|\$DB_DIR|${DB_DIR}|g" $LOC_DIR/op_logrotate
    echo "Fixed $LOC_DIR/op_logrotate"
    };
else
    {
    echo "Did NOTHING to: $LOC_DIR/op_logrotate"
    };
fi

# getdiff.conf.example lines; 2 lines:
# DIRECTORY = {DB_DIR}/getdiff/
# and
# NEWER_FILE = {DB_DIR}/getdiff/newerFile.txt
if [[ -s $LOC_DIR/getdiff.conf.example ]]; then
    {
    sed -i "s|{DB_DIR}|${DB_DIR}|g" $LOC_DIR/getdiff.conf.example
    echo "Fixed $LOC_DIR/getdiff.conf.example"
    };
else
    {
    echo "Did NOTHING to: $LOC_DIR/getdiff.conf.example"
    };
fi

# cron entries
