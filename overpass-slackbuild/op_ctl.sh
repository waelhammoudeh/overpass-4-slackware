#!/bin/bash

# op_ctl.sh : overpass control script.
# Script to start, stop and get status for overpass dispatcher daemon
# script is part of overpass slackbuild; it assumes installation into
# /usr/local directory with binaries installed into /usr/local/bin and the
# creation of overpass user and group as indicated in the main README
# file included with the slackbuild script
#
# To use this script you need to set one varaible below:
# DB_DIR : set it to your actual overpass database directory.
#

OP_USR_ID=367

# we set DB_DIR variable with set_db_path.sh script - run as root
DB_DIR=/path/to/your/overpass/DBase

EXEC_DIR=/usr/local/bin
DSPTCHR=$EXEC_DIR/dispatcher
VERSION=v0.7.57
USER=overpass
DIS_MODE="normal mode"
unset META

if ! grep ^overpass: /etc/passwd 2>&1 > /dev/null; then
   echo "$0:"
   echo "  You must have overpass user and group to run this script."
   echo "   Please see the main \"README\" file included with build script"
   exit 1
fi

if [[ $EUID -ne $OP_USR_ID ]]; then
    echo "$0: ERROR Not overpass user! Run this script as the \"overpass\" user."
    echo ""
    echo " This script is part of the Guide for \"overpassAPI\" installation and setup on Linux"
    echo "Slackware system. The Guide repository can be found here:"
    echo "https://github.com/waelhammoudeh/overpass-4-slackware"
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

# maybe nested if
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

   else
      # I hope not to add "force-stop" case with this!
      # /dev/shm/osm3s_${VERSION}_* are NOT socket files
      if [ -S ${DB_DIR}/osm3s_${VERSION}_osm_base ]; then
         echo " Found STALLED overpass BASE socket file, removing."
         rm -f ${DB_DIR}/osm3s_${VERSION}_osm_base
         rm -f /dev/shm/osm3s_${VERSION}_osm_base
      fi

      if [ -S ${DB_DIR}/osm3s_${VERSION}_areas ]; then
         echo " Found STALLED overpass AREAS socket file, removing."
         rm -f ${DB_DIR}/osm3s_${VERSION}_areas
         rm -f /dev/shm/osm3s_${VERSION}_areas
      fi
   fi

   # start base dispatcher
   echo " Starting overpass dispatcher with ${DIS_MODE} ..."
#   sudo -u $USER $DSPTCHR --osm-base --db-dir=${DB_DIR} ${META} &
   $DSPTCHR --osm-base --db-dir=${DB_DIR} ${META} &
   sleep 1

   if (! pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
      echo " Error: dispatcher did not start !!!"
      exit 1
   else
      # only start areas dispatcher if base started successfully
#      sudo -u $USER $DSPTCHR --areas --db-dir=${DB_DIR} &
      $DSPTCHR --areas --db-dir=${DB_DIR} &
      echo " overpass dispatcher started"
   fi
   exit 0
;;

   "stop")

    if (! pgrep -f $DSPTCHR  2>&1 > /dev/null) ; then
       echo " Error: dispatcher is not running."
       exit 2
    else
       # stop base dispatcher
#       sudo -u $USER $DSPTCHR --osm-base --terminate
       $DSPTCHR --osm-base --terminate

       if [ -S ${DB_DIR}/osm3s_${VERSION}_areas ]; then
          # stop area dispatcher
#          sudo -u $USER $DSPTCHR --areas --terminate
          $DSPTCHR --areas --terminate
       fi
          sleep 1

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
#         sudo -u $USER $DSPTCHR --status
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
