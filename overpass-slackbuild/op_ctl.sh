#!/bin/bash

# op_ctl.sh : overpass control script.
#
# Script to start, stop and get status for overpass dispatcher daemon
#
# This script is part of my overpass.SlackBuild script and accompanied
# by my Guide for overpassAPI installation and usage on Slackware64
# Linux system.
#
# Binaries are assumed to be installed into "/usr/local/bin" directory.
# An 'overpass' user and group are also assumed to exist in the system.
# This script is to be called by the 'overpass' user only.
#
# If not following my Guide for database directory, you need to change
# DB_DIR setting below; set it to your actual overpass database directory.
#

OP_USR_ID=367

SYS_ROOT=/var/lib

# this can be a link to any directory on your system - "overpass" name should stay.
OP_DIR=$SYS_ROOT/overpass

# DB_DIR : overpass database directory
# DB_DIR=/path/to/your/database
DB_DIR=$OP_DIR/database

EXEC_DIR=/usr/local/bin
DSPTCHR=$EXEC_DIR/dispatcher
USER=overpass
DIS_MODE="normal mode"
unset META

if ! grep ^overpass: /etc/passwd 2>&1 > /dev/null; then
    echo "$0:"
    echo " You must have overpass user and group to run this script."
    echo " Please see the main \"README\" file included with build script"
    exit 1
fi

if [[ $EUID -ne $OP_USR_ID ]]; then
    echo "$0: ERROR Not overpass user! Run this script as the \"overpass\" user."
    echo ""
    echo " This script is part of the Guide for \"overpassAPI\" installation and"
    echo " setup on Linux Slackware64 system. The Guide repository can be"
    echo " found here:"
    echo " https://github.com/waelhammoudeh/overpass-4-slackware"
    echo ""
    exit 1
fi

# always show database directory in use
echo ""
echo "$0: Database directory is set to: ${DB_DIR}"
echo ""

# test for database directory - directory can not be empty
if [ ! -d $DB_DIR ]; then
    echo " Could not find database directory"
    echo ""
    echo "DB_DIR variable should have been edited, was that done?"
    exit 2
fi

if [ ! "$(ls -A $DB_DIR)" ]; then
    echo "  Seems like database directory is empty! Overpass database must be initialed first."
    echo "  Please see the \"README-SETUP.md\" file included in the Guide directory."
    exit 2
fi

# set META depending on files in db
if [ -f ${DB_DIR}/nodes_meta.bin ]; then
    META=--meta
    DIS_MODE="meta data support"
fi

# keep this if after if [ -f ${DB_DIR}/nodes_meta.bin ]; above
if [ -f ${DB_DIR}/nodes_attic.bin ]; then
    META=--attic
    DIS_MODE="attic data support"
fi

# check dispatcher executable
if [ ! -x $DSPTCHR ]; then
    echo " Could not find dispatcher executable file!"
    exit 2
fi

case "$1" in

    "start")

    if (pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
      echo " dispatcher is already running! with ${DIS_MODE}"
      exit 0
    fi

    # I hope not to add "force-stop" case with this!
    if [ -S ${DB_DIR}/osm3s_osm_base ]; then
      echo " Found STALLED overpass BASE socket file, removing."
      rm -f ${DB_DIR}/osm3s_osm_base
      rm -f /dev/shm/osm3s_osm_base 2>&1 > /dev/null
    fi

    if [ -S ${DB_DIR}/osm3s_areas ]; then
      echo " Found STALLED overpass AREAS socket file, removing."
        rm -f ${DB_DIR}/osm3s_areas
        rm -f /dev/shm/osm3s_areas 2>&1 > /dev/null
    fi

    # start base dispatcher
    echo " Starting base dispatcher with ${DIS_MODE} ..."

    $DSPTCHR --osm-base --db-dir=${DB_DIR} ${META} &
    sleep 1

    # start areas dispatcher if base started successfully ONLY
    if (! pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
      echo " Error: dispatcher did not start !!!"
      exit 1
    fi

    echo " base dispatcher started."
    echo ""

    # start areas dispatcher if base started successfully ONLY
    echo " Starting areas dispatcher ..."

    $DSPTCHR --areas --db-dir=${DB_DIR} &
    sleep 1

    if [ -S ${DB_DIR}/osm3s_areas ]; then
      echo " areas dispatcher started"
      exit 0
    else
      echo " Error areas dispatcher did NOT start"
      exit 2
    fi

;;

    "stop")

    if (! pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
      echo " Error: dispatcher is not running."
      exit 2
    else
      # stop base dispatcher
      $DSPTCHR --osm-base --terminate

      if [ -S ${DB_DIR}/osm3s_areas ]; then
        # stop area dispatcher
        $DSPTCHR --areas --terminate
      fi

      # increased to 2 seconds; occasionally 1 is not enough!
      sleep 2

      if (pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
        echo " Error: could not stop dispatcher"
        exit 2
      else
        echo " dispatcher stopped"
      fi
    fi
    exit 0
;;

    "status")

    if (pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
      echo " dispatcher is running with ${DIS_MODE}"
      echo ""
      $DSPTCHR --status
    else
      echo " dispatcher is stopped. Not running!"
    fi
    exit 0
;;

    *)
      # something else - show usage
    echo ""
    echo " $0: Error: missing argument or unkown command."
    echo "  Usage: $0 ACTION"
    echo "  where ACTION is one of: { start | stop | status }"
    echo ""
    echo "  Please note they are all lower case letters!"
    echo ""
    exit 1
;;
esac
