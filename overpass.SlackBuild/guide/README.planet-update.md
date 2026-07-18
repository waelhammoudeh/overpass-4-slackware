README.planet-update.md — Overpass SlackBuild

This file explains how to update "overpass" database from planet OSM change files.

Updating "overpass" database from planet OSM change files gives you anothor option
for the update other than [Geofabrik.de](https://download.geofabrik.de/) server.

There are reasons for and reasons against updating an extract OSM data from planet
change files, but this is not the subject of this README.

Weather you already have setup "overpass" database or are seting up a new "overpass"
database, this README will guide you with the process of using planet OSM change
files to update your "overpass" database.

**Daily** and **hourly** updates are supported by the provided scripts.


The process involves a new database initialization, and can be summarized by first
creating a new region OSM extract data file that is aligned with planet change
file insuance time; **daily alinged** for daily update and **hourly aligned** for
hourly update. Second initial a new "overpass" with the new extract data file
and third use a provided script to make your region change files and finally use a
replacement script for cron jobs.

This requires a recent regional OSM extract data file from [Geofabrik.de](https://download.geofabrik.de/)
for your area.

The detailed steps are as follows:

## 1) Create Aligned Extract Data File:

Follow the instruction in my [osm_extract_planet](https://github.com/waelhammoudeh/osm_extract_planet)
to create your region OSM extract data file that is aligned with the desired planet OSM
change file issuance time **(daily or hourly).**


## 2) Initial "Overpass" database:

If you have setup "overpass" database; you need to stop the "dispatcher" and remove
everything from your current "database" directory. As the overpass user you do:

```
overpass@regrets:~$ cd ~

overpass@regrets:~$ op_ctl.sh stop

overpass@regrets:~$ rm -rf database/

overpass@regrets:~$ mkdir database
```

Copy your new OSM extract data file made in step 1 to overpass "sources/" directory
and use that to initialize a new database as described in [README.setup.md](README.setup.md)
file.

With your setup complete including starting and stopping "dispatcher" on startup
and shutdown. Understand the new update process is different from that from geofabrik.

The update process from planet change files is different from that described in
[README.update.md](README.update.md) file first by change file source now is from
"planet.osm.org/replication" server not "download.geofabrik.de" server and second
there is an extra step of making our own regional change file to update database
with. Those changes required a new cron job script `cron4op-planet.sh`.

The update process now works as follows:

  - download planet change files using `getdiff`.
  - make regional change file from planet change file using `mk_regional_osc.sh` script.
  - update overpass database using region change file using `op_update_db.sh` script.
  - `cron4op-planet.sh` is called by `crond` to perform above steps in addition to
  perform old files removal (cleanup).


## 3) Configure `getdiff`:

If you have been updating from "geofabrik" server, you must at least **remove**
"previous.seq" file from "getdiff" directory. Removing everything in "getdiff"
directory is recommended.

Create "getdiff.conf" file in "getdiff" directory with the following keys and values:
```
# getdiff.conf file for planet update:

DIRECTORY = /var/lib/overpass

LOG_FILE = /var/lib/overpass/logs/getdiff.log

# To turn verbose on use: TRUE, ON or 1. Case ignored for TRUE and ON.
VERBOSE = True

# use for daily update
SOURCE = https://planet.osm.org/replication/day

# use for hourly update
# SOURCE = https://planet.osm.org/replication/hour

# BEGIN: This is the sequence number to start download from.
BEGIN = {sequence_number}

```

set the "SOURCE" value for the desired update granularity (daily or hourly) and
specify the {sequence_number} to start download from; this is for the change file
just after the last included in your extract from step 1.

## 4) Configure "/etc/overpass.conf" file:

The file has four variables you set once only; varaibles are used by "mk_regional_osc.sh"
and "op_update_db.sh" scripts. Edit the file as root.

```
# this is overpass.conf file;;;

# variables for "op_update_db.sh" script:

FLUSH_SIZE=4

# varaibles for "mk_regional_osc.sh" script:

# set to your region poly file name ONLY, place file in your region directory

polyFileName=arizona.poly

# set to your area or region name; used in generated state.txt files
# use short name!

regionName=Arizona

# this is the directory where "getdiff" downloads planet change files
# which depends on its '--source / -s' option or 'SOURCE' key value:

# for daily files: SOURCE = https://planet.osm.org/replication/day
# planetDir=/var/lib/overpass/planet/day

# for hourly files: SOURCE = https://planet.osm.org/replication/hour
# planetDir=/var/lib/overpass/getdiff/planet/hour

# scripts may need adjusments for minute updates.

planetDir=/var/lib/overpass/getdiff/planet/day

```

The "planetDir" value needs to match that used in your "getdiff.conf" file.

Ensure you create the "target.name" file for "mk_regional_osc.sh" script in the
"region" directory as described in [README.extract-planet.md](README.extract-planet.md)
file. The file name inside this "target.name" is the file created in step 1 above
and used to initialize your database. Copy the file with timestamp formated name to
"region/extract/" directory.


## 5) Use new "cron4op-planet.sh" script:

The new "cron4op-planet.sh" is a replacement for "cron4op.sh" script called from
`crontab` entry.

If you are changing from "geofabrik" update then all you need here is to edit the
"overpass" user existing `crontab` entry to use the new script. For new setup you
create a new crontab entry; the process is very similar (as the "overpass" user)
and as follows:


```
overpass@regrets:~$ crontab -e
```

you then press the `i` key on your keyboard to enter "edit" mode and change old
entry by adding "-planet" to it or type the whole entry line; your new entry line
should be one of two below (depending on your update daily or hourly):

```
@daily ID=opUpdateDB /usr/local/bin/cron4op-planet.sh
```

```
@hourly ID=opUpdateDB /usr/local/bin/cron4op-planet.sh
```

you save the new "crontab" entry by pressing "Esc" then type ':wq' then enter.

This should take care of your setup for auto update overpass database. Check your
log files; they are all under "logs/" directory.


Wael Hammoudeh

July 17/2026
