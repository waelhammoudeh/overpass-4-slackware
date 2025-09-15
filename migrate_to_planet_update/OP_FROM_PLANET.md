
### Overpass Database Update From Planet Server

In this file I provide scripts and explain how to update an overpass database from
open street map planet servers. This gives you another option to updating your
database other than Geofabrik servers.

Few points to keep in mind before I expalin the process. Working with extract data
files is different than working with planet data file. Extracts tend to lose their
quality over time by updating. It is recommended to renew databases from a new
extract data file once a year. Change files based on planet file are different than
change files based on extract data file. We will be using the later in this process.

#### Preparation:

A lot of scripts and files have seen changes, I strongly advise of cloning the whole
repository and perform a rebuild and upgrade your overpass Slackware package.
If you choose to do that; do not forget that I strongly recommend stopping the
dispatcher daemon before performing "upgradepkg", you can start it afterwords.

Copy new scripts files from my "scripts" directory in this repository to your system
"/usr/local/bin/" directory. Files to copy are:

  - common_functions.sh
  - mk_regional_osc.sh
  - cron4op-planet.sh

make sure that "mk_regional_osc.sh" and "cron4op-planet.sh" scripts are executables.
Use chmod +x for both files.

Create "region" directory in your overpass home, along with two sub-directories
"extract" and "replication", command below should do that from overpass home:
```
  $ mkdir -p region/{extract,replication}
```

Your overpass home directory should have this file system structure:

<pre>
        /var/lib/overpass/
                |--- database/
                |--- getdiff/
                |--- logs/
                |--- sources/
                |--- region
                       |---extract           <--- directory for updated OSM extract files
                       |---replication       <--- directory for new region Change files
                       |region.poly          <--- your region poly file
                       |target.name          <--- file with OSM data file name
</pre>

Copy your planet daily aligned OSM data file you made from "Migrate To Daily Planet
Update" earlier [README.md](README.md) to the new
"region/extract" directory. The data file name was similar to "region-data_2025-09-09.osm.pbf"
witha date. This is the file **we are not to use underscore character** in its name. The
underscore is a separator between the name and the date parts.

#### Initialize New Database:

If you have not initialized an overpass database yet, follow the instructions in my
guide [README.setup](https://github.com/waelhammoudeh/overpass-4-slackware/blob/master/overpass.SlackBuild/guide/README.setup)
to setup your overpass database using your region aligned OSM data file with planet daily update.
Come back here to continue for updating your database.

We initialize a new overpass database using your OSM data file mentioned above, to
do that, stop running dispatcher, clear current "database" and "getdiff" directories
from their contents - directories stay. This is done with:

```
 $ op_ctl.sh stop

 $ rm -rf database/*

 $ rm -rf getdiff/*
```

Now initialize the database using "op_initial.sh" script,  using 8 for optional
flush_size (change if needed):

```
 $ nohup op_initial.sh region/extract/region-data_2025-09-09.osm.pbf database/ < /dev/null > nohup.out &
```

You may start the dispatcher and test your database.

#### Getdiff configuration:

Create a new "getdiff.conf" file under "getdiff" directory with the following settings:

```
DIRECTORY = /var/lib/overpass

SOURCE = https://planet.osm.org/replication/day/

BEGIN = sequence-number
```

Lookup the sequence number value at: https://planet.osm.org/replication/day site.
Your starting point will be your database version in file "osm_base_version" in your
database directory; retrieve it with:
```
 $ cat database/osm_base_version
```

the output should be something like: "2025-09-09T00:00:00Z"

Use the date to locate daily change file from planet server site and retrieve the
sequence number from the corresponding "state.txt" file, this will be your value
for BEGIN in getdiff.conf file.

Remember you need the file that has changes just after what is included in your
database. The version number above, tells me that the database has data up to
2025-09-09 at midnight, my very next change file should include data up to the
next day; that is: 2025-09-10T00:00:00Z or simply 2025-9-10.

Run "getdiff" to start downloading your change files:
```
 $ getdiff -c getdiff/getdiff.conf
```

Your planet change files will be in: "getdiff/planet/day/" directory.

#### mk_regional_osc.sh script:

This script does what its name says; it makes change files for your region plus a
new region OSM data file. Script usage:

```
mk_regional_osc.sh <list_file>
 list_file: file name with a list of planet change and state.txt files.
```

The script uses the "newerFiles.txt" list file produced by "getdiff" program - in
the step above. This file is passed as an argument to the script.

In addition to the list file, script uses your region polygon file and your region
OSM data file used to initialize overpass database. Those two need setup.

 - copy your region poly file - downloaded from Geofabrik - to your region directory.
 Then set "polyFileName" variable in the script (top) to the file name only.

 - while editing the script, set "regionName" variable to your region name, use
 a short name here. This is used in state.txt files.

 - the script reads "target.name" file in the region directory to retrieve the region
 OSM data file name. You need to create this file with the name of the file used to
 initialize your database. From overpass home directory this can be done with:

 ```
   $ echo "region-data_2025-09-09.osm.pbf" > region/target.name
```

The file "region-data_2025-09-09.osm.pbf" itself should be placed in the "region/extract"
directory.

Region change files and their corresponding state.txt files are written to replication
directory under the region directory. Updated region OSM data files are written in
the extract directory under your region directory.

Just like "getdiff" program, the script produces a list file named "oscList.txt" in
the region directory with change and state.txt file names produced. In effect it
sets between getdiff program and op_update_db.sh script.

Scripts logs its progress to "mk_regional_osc.log" file in "logs" directory.

#### op_update_db.sh script:

This is the same script we used to update from Geofabrik server, we change the script
two argument; list file argument becomes "oscList.txt" from "mk_regional_osc.sh" script
and change files directory becomes "region/replication" - full path of course.

#### cron4op-planet.sh script:

This is a replacement script for "cron4op.sh" script we use for cron job setting.
The overpass "crontab" entry needs to be updated to run the newer script, this is
done using "crontab -e", edit the entry for the new script to match:

```
# cron entry to download change files AND update overpass database
@daily ID=opUpdateDB /usr/local/bin/cron4op-planet.sh >/dev/null 2>&1
```

Scripts logs its progress to "cron4op-planet.log" file in "logs" directory.

#### op_logrotate file:

The log rotation file has been updated. You just replace the old file with newer
file in your system "/etc/logrotate.d/"

Find the new "op_logrotate" file in this repository under "/overpass.SlackBuild/guide/".

Wael Hammoudeh

September 11, 2025

    -
