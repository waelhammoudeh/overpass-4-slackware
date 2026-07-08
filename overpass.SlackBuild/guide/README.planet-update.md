README.setup — Overpass SlackBuild

This file explains how to update "overpass" database from planet OSM change files.

Updating "overpass" database from planet OSM change files gives you anothor option
for the update other than [Geofabrik.de](https://download.geofabrik.de/) server.

There are reasons for and reasons against updating an extract OSM data from planet
change files, but this is not the subject of this README.

Weather you already have setup "overpass" database or are seting up a new "overpass"
database, this README will guide you with the process of using planet OSM change
files to update your "overpass" database.

The process involves a new database initialization, and can be summarized by first
creating a new region OSM extract data file that is aligned with planet daily change
file insuance time; second initial a new "overpass" with the new extract data file
and third use a provided script to make your region change files and finally use a
replacement script for cron jobs.

This requires a recent regional OSM extract data file from [Geofabrik.de](https://download.geofabrik.de/)
for your area.

The detailed steps are as follows:

## 1) Create Aligned Extract Data File:

Follow the instruction in my [osm_extract_planet](https://github.com/waelhammoudeh/osm_extract_planet)
to create OSM extract data file for your area that is aligned with planet OSM time
for daily change files.

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
and use that to initialize a new database as described in README.setup.md file.

## 3) Use new "cron4op-planet.sh" and "mk_regional_osc.sh" scripts:

The new "cron4op-planet.sh" is a replacement for "cron4op.sh" script called from
`crontab` entry, all you need here is to edit "overpass" user `crontab` to use the
new script; as the "overpass" user modify that entry with:

```
overpass@regrets:~$ crontab -e
```

you then press the `i` key on your keyboard to enter "edit" mode and change old
entry by adding "-planet" to it; from:

```
@daily ID=opUpdateDB /usr/local/bin/cron4op.sh
```

to:

```
@daily ID=opUpdateDB /usr/local/bin/cron4op-planet.sh
```

you save the new "crontab" entry by pressing "Esc" then enter ":wq".

Ensure you create the "target.name" file and change and set the two variables in
script "mk_regional_osc.sh" as instructed, script is called from new "cron4op-planet.sh".
Those instruction were as follows:


**Before** using "mk_regional_osc.sh" script; you need to set two varaibles in the
script and create "target.name" file in the "region" directory.

The variables to set are in the top of the script:

  - **polyFileName**
  - **regionName**

The "polyFileName" is your area poly file from Geofabrik.de which was copied to
the "region" directory in the previous step. Only file name is needed here.

The "regionName" is your region (area) name; used in produced "state.txt" files -
this should be a short name.

The "target.name" file is a text file with lastest extract data filename. Initially
this is the file made in the previous step with the "date" part in its name. The
"target.name" file is created in the "region" directory with command like:

```
overpass@regrets:~$ echo "arizona_2026-07-02.osm.pbf" > region/target.name
```

## 4) Adjust configure and clean "getdiff" directory:

Edit your "getdiff.conf" file to set new values for "SOURCE" and "BEGIN" keys.

Change and set value for the "SOURCE" key to "https://planet.osm.org/replication/day"
and set a new value for "BEGIN" key; this will be the sequence number for planet
daily change file to start updating from. The one just after the last added to your
new extract data file you made in step 1.

**Remove** "previous.seq" file from "getdiff" directory.

