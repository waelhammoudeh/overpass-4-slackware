README.update - Overpass SlackBuild

This file explains how to update an initialized Overpass database with the latest
available OSM data using daily change files from "Geofabrik.de" site. It also describes
how to automate this process on a Slackware64 system (maybe applied to any Linux system).

Updating from planet OSM change files is also possible and explained futher down
in this file.

1. About Change files:

Databases and OSM data files are updated with "change files". Change file is the
difference between two OSM data files from two different times, when adding change
file to the oldest of the two data files we get the newest of the two.
Each change file has a correponding "state.txt" with 2 important identification
lines; the sequence number and a timestamp lines. Sequence number is incremented
for each new change file and the timestamp is when that change file was calculated.
See [README.ChangeFiles.md](README.changeFiles.md) for more information.

2. Update Database:

This process is basically two steps; in the first we retrieve or fetch change
files using my "getdiff" program and on the second step we apply change files
to update the overpass database using my "op_update_db.sh" script.

The "getdiff" program and "op_update_db.sh" script work in succession, "getdiff"
fills a bucket then "op_update_db.sh" empties this bucket.

The "getdiff" program appends new downloaded filenames (making a list) to file
called "newerFiles.txt", this file is then read by "op_update_db.sh" script to
update the database, the script renames the list file to "newerFiles.txt.bak" so
getdiff starts a new "newerFiles.txt" next time around.

## 2.1 Install and setup "getdiff"

Installing "getdiff" program now has many options; you could clone the whole
repository, you could just download the source tarball then untar it and use
`make install` to compile and install the program. If you are on Slackware then
use the SlackBuild script instead to build and install the package.

Either way the program installs to /usr/local/bin/ directory, program docs are
installed to /usr/local/doc/ with different names depending on method used to
install; `make install` writes docs in "getdiff" directory while SlackBuild moves
that (renames it) to "getdiff-0.01.87" with the same contents in both cases.

Now we setup "getdiff" as the "overpass" user with a couple of settings taken
from the region OSM data file for which you use "osmium fileinfo" to retrieve
required information.

Now from "root" user change to the "overpass" user and change directory to user
"overpass" home directory:
```
 # su overpass
 $ cd ~
```
now `pwd` should return "/var/lib/overpass".

If you did not create "getdiff" directory yet, now is the time to create it - the
program will create it for you on first use, but we need to place our configuration
file in that directory now. Program will not complain it will use the existing
directory.


Create "getdiff" directory, and copy the example configure file to it.
This will be "getdiff" program work directory where it will write "newerFiles.txt"
file and where it will create "geofabrik" directory to save downloaded change files.

```
 $ mkdir getdiff
 $ cp /usr/local/doc/getdiff-0.01.87/getdiff.conf.example getdiff/getdiff.conf
```
or
```
 $ cp /usr/local/doc/getdiff/getdiff.conf.example getdiff/getdiff.conf
```

Note that I dropped the extension "example" from the destination file.

Now we edit "getdiff.conf" file, to illustrate I will use the following output:

<pre>
overpass@regrets:~$ osmium fileinfo sources/california-latest-internal.osm.pbf
File:
  Name: sources/california-latest-internal.osm.pbf
  Format: PBF
  Compression: none
  Size: 1387283693
Header:
  Bounding boxes:
    (-125.8935,32.48171,-114.1291,42.01618)
  With history: no
  Options:
    generator=osmium/1.15.0
    osmosis_replication_base_url=https://osm-internal.download.geofabrik.de/north-america/us/california-updates
    osmosis_replication_sequence_number=4525
    osmosis_replication_timestamp=2025-08-24T20:21:35Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2025-08-24T20:21:35Z
overpass@regrets:~$
</pre>

We change the following settings in our "getdiff.conf" file:
```
USER
DIRECTORY
LOG_FILE
SOURCE
BEGIN
```

The USER name is required since we used Geofabrik **INTERNAL** server to download our
region data file, we will enter the password on invocation of getdiff:

USER = myemail@someserver.com

The DIRECTORY setting is where "getdiff" work directory is created; this is really not
required since this is the default location for the work directory. But I may foreget
this fact in a month or few days from now! So I usually set this.

DIRECTORY = /var/lib/overpass

Program logs its progress to "getdiff.log" under its work directory by default,
we change that to the overpass common logging directory "logs" with:

LOG_FILE = /var/lib/overpass/logs/getdiff.log

The SOURCE setting is the region update URL at geofabrik.de, that is listed on
your data file header information as replication_base_url; from the illustration above:

SOURCE = https://osm-internal.download.geofabrik.de/north-america/us/california-updates

The BEGIN number is the sequence number to start download from, this is also from
the header information above. The listed replication_sequence_number = 4525 is the
LAST INCLUDED change file in the extract, we start from the one **JUST AFTER** this:

BEGIN = 4526

Edit your "getdiff.conf" file with your own information and save it using your
favourite text editor.

To download change files, we invoke `getdiff` passing to it our configuration file
and our password for "openstreetmap.org" account:

```
  $ getdiff -c getdiff/getdiff.conf -p xxxxxx
```

Program is more verbose in its log file when `verbose` option is set. This log
file may recieve logs from curl-library and or my cookie handling code.

Assuming the region OSM data file is more than a day old, program should download
change files and their correponding state.txt files into "geofabrik" directory.
Check the log file, inspect `newerFiles.txt` and "previous.seq" files.

## 2.2 Update with "op_update_db.sh" script:

The script "op_update_db.sh" is used to update overpass database with change files
downloaded by "getdiff". Script usage is:

```
 op_update_db.sh <list_file> <osc_dir>
```

The list_file is "newerFiles.txt" produced by "getdiff", osc_dir is the directory
where change files are in the file system, that is "geofabrik" under "getdiff with
full path: "/var/lib/overpass/getdiff/geofabrik".

The script uses the same overpass "update_database" program we used to initialize
the database, what we said about the "FLUSH_SIZE" there applies here. You should
adjust the default value "4" used in the script. See the script for suggested values.
To adjust the value, edit that setting in the script - its on top of the script!

The script is designed to run in a cron job, if you have to run it manually in a
terminal, then run the script as a background process.

Start the script with:

```
  $ op_update_db.sh /var/lib/overpass/getdiff/newerFiles.txt \
                   /var/lib/overpass/getdiff/geofabrik
```

The script writes its progress to "logs/op_update_db.log" in overpass home directory.

3. Automate Update Process:

The script "cron4op.sh" runs the opertions: getdiff then op_update_db.sh one after
another. Besides that it also deletes change files older than seven days to free
your disk space.

If you are using the INTERNAL server on Geofabrik site you need to provide your
"openstreetmap.org" account password; edit "cron4op.sh" script and provide your
password as the value for the SECRET variable in the script.

Slackware64 ships with Dillon Cron, You tell Cron when to run a job and it does
that for you. This is done by adding a new "crontab" - cron table entry. For more
information "man crontab" at your terminal.

We add a new crontab as the "overpass" user to run our "cron4op.sh" script every
day (Slackware64 will start vi for you in this command), this is accomplished by:

```
 $ crontab -e
```

press "i" to enter vi insert mode then type the following line:

@daily ID=opUpdateDB /usr/local/bin/cron4op.sh

press "Escape key" to get to vi command mode, then type ":wq"

You are done adding the required "crontab entry", to verify this, list your entries:

```
  $ crontab -l
```

your output should be something like:

```
overpass@yafa:~$ crontab -l
# cron entry to download change files AND update overpass database
@daily ID=opUpdateDB /usr/local/bin/cron4op.sh
```

If you made a mistake, then correct it by doing "crontab -e" again.

4. Log Files and Rotation

Logging got a make-over on June 26/2026 with ALL scripts and programs under our
control writing their log files to one central log location directly, that location
is overpass user "logs" directory at: "/var/lib/overpass/logs/". This involved
changing the log setting in "httpd-overpass.conf" and modifying `getdiff` program
to make its log file configurable by its user. The exception that remains is
`overpass` - this is out of our control.

 *) Overpass API has the two log files:
    - /var/lib/overpass/database/database.log
    - /var/lib/overpass/database/transactions.log

We create sybolic links to those two files in overpass "logs" directory as the
overpass user:
```
  $ cd /var/lib/overpass/logs
  $ ln -s /var/lib/overpass/database/database.log .
  $ ln -s /var/lib/overpass/database/transactions.log .
```

Now we can access any log file from that "logs" directory.


Log Rotation

Slackware already rotates logs daily via /etc/cron.daily/logrotate, scheduled in
root’s crontab at 04:40 AM:

40 4 * * * /usr/bin/run-parts /etc/cron.daily

This is fine for systems running 24/7. However, if the machine is powered off at
that time, the daily jobs never run — and Overpass logs will not be rotated.

To handle this, we provide a separate logrotate config file:

/etc/logrotate.d/op_logrotate

and add this crontab entry for root (log rotation is done by "root" in Slackware):

```
# do overpass log rotation
@daily ID=op_logrotate /usr/sbin/logrotate /etc/logrotate.d/op_logrotate >/dev/null
```

Yes, you use "crontab -e" and the "Esc" dance to edit cron entry.

This ensures Overpass logs are rotated once per day whenever the machine is on,
independent of Slackware’s 04:40 AM daily slot.

**Changed settings are NOT preserved on upgrades:**

If you upgrade your overpass package, changed settings in scripts are NOT preserved
between upgrades. This applies to "FLUSH_SIZE" in op_update_db.sh and "SECRET"
in cron4op.sh scripts.


## Update with Planet Change Files:

To update "overpass" database from planet change files; the database must be
initialized with an extract OSM data file that is aligned with planet change files
issuance time.

A method to bring an extract from Geofabrik.de site in alignmet with planet OSM
change file issuance time is detailed in [README.extract-planet.md](README.extract-planet.md)
file in this guide.

If you have an instance of "overpass" running; start with a new database initialization,
first stop "overpass" dispatcher with:

```
overpass@regrets:~$ op_ctl.sh stop
```

and backup your files (I copy my overpass "sources/" directory) before removing
everything from overpass home directroy.

Initialize a new database using your new alinged extract OSM data file, follow the
same setup instructions in README.setup.md.

This also involves an extra step in the update process; now we need to make a change
file for our extract from the planet change file; the update process workflow now
looks like this:

  - fetch planet change file from planet OSM server.
  - make the regional change file
  - update "overpass" database

**This requires the following changes:**

1) Getdiff is still used to dwonload change files, we change the URL for "SOURCE"
and set new sequence number value for "BEGIN" key in "getdiff.conf" file:

  - SOURCE = https://planet.osm.org/replication/day
  - BEGIN = *num*

where *num* is sequence number for planet daily change file to start download from.

**Remove "previous.seq" file** from "getdiff" work directory - if present.

2) Setup **mk_regional_osc.sh** script as instructed in "README.extract-planet.md"
with the following instructions:

```
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

The "target.name" file is created with:

```
overpass@regrets:~$ echo "arizona_2026-07-02.osm.pbf" > region/target.name
```

replace "arizona_2026-07-02.osm.pbf" with your region OSM file name.

3) We still use "op_update_db.sh" script but with different parameters:


```
overpass@regrets:~$ op_update_db.sh region/oscList.txt region/replication
```

4) Use **cron4op-planet.sh** instead of "cron4op.sh" to automate the process in
"overpass" crontab entry.

Edit "overpass" crontab entry with:
```
overpass@regrets:~$ crontab -e
```
press 'i' key on your keyboard to enter "vi edit mode" and enter / adjust your
entry to look as shown below:

```
# overpass cron job
@daily ID=opUpdateDB /usr/local/bin/cron4op-planet.sh

```

when done editing; press 'Esc' key and type ':wq' enter to save your changes.

**Changed settings are NOT preserved on upgrades:**

We add adjusted variables from "mk_regional_osc.sh" to those not maintained between
updates. This makes changed list apply to "FLUSH_SIZE" in op_update_db.sh, "SECRET"
in "cron4op.sh" and variable values for polyFileName and regionName in script
"mk_regional_osc.sh".


Wael Hammoudeh

July 8th, 2026
