This is the "README-SETUP.md" file for Overpass Guide.

**This is INCOMPLETE STILL**

I am trying to complete this file and making it shorter, but it not working that way ....

### Changes:

**Areas Making & Updates**

Making areas have change a lot since I started using overpass, I still do not fully understand the process.

 - In "op_make_areas.sh" script I have changed the IMAX loop counter to 2. Down from 100.
 - Areas update is only done after database update (daily) with loop counter 2 also.
 - Remove overpass crontab entry for opAreaUpade.


In this "README-SETUP.md" file:
  - initial database, make areas and start database manager will result in functional database on local machine.
  - database manager control, start on boot and stop on shutdown.
  - update database
  - automatation & log files handling.
  - backup & recovery. (working on it.)

### Required Reading:

[README-START.md](https://github.com/waelhammoudeh/overpass-4-slackware/Guide/README-START.md)

This file builds on README-START.md, please read that file first if you did not do so.

### Required Software:

**overpass_API**
I assume you have installed "overpass_API" software. If not; see README_START.md, build and install
my overpass Slackware package; my scripts to initial and update overpass database are included in this
package.

**Osmium**
[Osmium command line tools](https://github.com/waelhammoudeh/osmium-tool_slackbuild) is required to use my "op_initial_db.sh" script.
You will always use osmium when working with OSM data files.

**getdiff**
My ["getdiff" program](https://github.com/waelhammoudeh/getdiff) is required to update overpass database.

**Region OSM data file**
I also assume you already downloaded your region data file in (.osm.pbf) format from Geofabrik.de website.

### File System Structure:

All scripts and configuration files here assume the following File System layout:

<pre>
{OP_HOME}
      |--- database/
      |--- getdiff/
      |--- logs/
</pre>

in addition {OP_HOME} is assumed to have this path "/var/lib/overpass". This "overpass"
directory entry can be a real directory or a link to another directory - but must end with
"overpass" entry name. Replacing {OP_HOME} with the value, we have:

<pre>
/var/lib/overpass/
      |--- database/
      |--- getdiff/
      |--- logs/
</pre>

where database, getdiff and logs are directories for the indicated name created by the
"overpass" user.

All my scripts use the following paths for indicated purpose:

```
The System Root is "/var/lib" is a System directory on Slackware - already exist.
SYS_ROOT=/var/lib

The Overpass Directory is the overpass user home directory, this can be a link or real
directory on your system - it must end with "overpass" entry name.
OP_DIR=$SYS_ROOT/overpass

Database Directory is where we initial the overpass database.
DB_DIR=$OP_DIR/database

Getdiff Working Directory where getdiff files are kept and "diff" directory is created where
differ files are downloaded to.
GETDIFF_WD=$OP_DIR/getdiff

LOG_DIR=$OP_DIR/logs
Log Directory is where we write log files to and link ones we can not redirect / move.
```

The {OP_HOME} directory was created when "overpass" user was created. Create a link to your "overpass"
home directory under "/var/lib/" directory:

```
    root@yafa:/var/lib# ln -s /path/to/your/overpass /var/lib/overpass
```
then create the three directories mentioned above. Note: if you need to change overpass home directory use "usermod" command.

### Version number (database & area):

Among the files created in the overpass database directory at initialisation is "osm_base_version" file, and with areas creation
"area_version" file. It is customarily to use last date for included OSM data in the database as the version number with "YYYY-MM-DD"
formated string. My "op_initial_db.sh" script second parameter is for this version number. This number will get replaced with each
update applied to the database by my update script. The same version number is used for the "area_version" (created / updated from same data).

Note that the "timestamp" program in "cgi-bin" directory outputs the contents of "osm_base_version" file. See README-WEB.md file.

### Space Required:

The overpass database directory size will depend on your region OSM data file size. I do not have any method to tell how much space
you need - you have to try! Initialing the database with no meta data will save **very little** space; do not bother. To get an idea, I
have initialed two databases - with meta data - and made areas in both, both sources were in (.pbf) format. Database directory size was
many many times the size of the region OSM data file and varied wildly!

```
  region      OSM data file        database directory Size
  ---------------------------------------------------------
  Arizona       254 MB                      26 GB
  US West       2.8 GB                        71 GB
```
The database directory size was between (30 - 90) times the size of the respected region OSM data file size. I do not know why the multiplier varied so much! I guess YMMV!

**All commands are to be executed by the overpass user unless specified otherwise**

**All the information about your OSM data file needed for initial and update scripts below can be retrieved with "osmium fileinfo --extended"**

Listed below is "osmium fileinfo --extended" output for my region OSM data file "arizona-latest-internal.osm.pbf";
I will list the relevant line(s) for script argument when needed - note that the output has four sections (File, Header, Data & Metadata):

```
overpass@yafa:~/source$ osmium fileinfo --extended arizona-latest-internal.osm.pbf
File:
  Name: arizona-latest-internal.osm.pbf
  Format: PBF
  Compression: none
  Size: 265419524
Header:
  Bounding boxes:
    (-114.8325,30.05891,-109.0437,37.00596)
  With history: no
  Options:
    generator=osmium/1.15.0
    osmosis_replication_base_url=https://osm-internal.download.geofabrik.de/north-america/us/arizona-updates
    osmosis_replication_sequence_number=3763
    osmosis_replication_timestamp=2023-07-18T20:21:43Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2023-07-18T20:21:43Z
[======================================================================] 100%
Data:
  Bounding box: (-115.7133191,30.9030825,-108.218831,38.8430606)
  Timestamps:
    First: 2007-08-10T17:38:36Z
    Last: 2023-07-18T19:45:41Z
  Objects ordered (by type and id): yes
  Multiple versions of same object: no
  CRC32: not calculated (use --crc/-c to enable)
  Number of changesets: 0
  Number of nodes: 36140382
  Number of ways: 3758726
  Number of relations: 17465
  Smallest changeset ID: 0
  Smallest node ID: 13265445
  Smallest way ID: 2901206
  Smallest relation ID: 56412
  Largest changeset ID: 0
  Largest node ID: 11053675192
  Largest way ID: 1190465397
  Largest relation ID: 16089412
  Number of buffers: 57276 (avg 696 objects per buffer)
  Sum of buffer sizes: 3632038840 (3.463 GB)
  Sum of buffer capacities: 3757768704 (3.583 GB, 97% full)
Metadata:
  All objects have following metadata attributes: all
  Some objects have following metadata attributes: all
overpass@yafa:~/source$
```
### Initial Overpass Database:

OverpassAPI provides two scripts to initial the database found in "/usr/local/bin" directory .
The first is the "download_clone.sh" script which is for cloning **whole planet** database from
a live overpass server. This script can not be used for a limited area or region.

The second script is "init_osm3s.sh" script. This script calls overpass "update_database"
program to accomplish its goal. This script usage is as follows:
```
$ init_osm3s.sh
Usage:  /usr/local/bin/init_osm3s.sh  Planet_File  Database_Dir  Executable_Dir  [--meta]
        where
    Planet_File is the filename and path of the compressed planet file, including .bz2,
    Database_Dir is the directory the database should go into, and
    Executable_Dir is the directory that contains the executable update_database.
    Add --meta in the end if you want to use meta data.
```
Note that "Planet_File" above can be an extract for limited area, so you can use this script
to initial your database.

This "init_osm3s.sh" script requires input file to be in (.osm.bz2) format, this format is a lot larger than (.osm.pbf) file
format, it takes longer to download - it shows if you do not have the bandwidth.

**op_initial_db.sh script:**

My "op_initial_db.sh" script included in my SlackBuild is a replacement to overpass (init_osm3s.sh) script.


The overpass *update_database* program usage or accepted arguments:
```
wael@yafa:~$ update_database -h
Unkown argument: -h
Usage: update_database [--db-dir=DIR] [--version=VER] [--meta|--keep-attic] [--flush_size=FLUSH_SIZE] [--compression-method=(no|gz|lz4)] [--map-compression-method=(no|gz|lz4)]
```

The program "update_database" reads its input from standard input (the terminal) expecting
OSM data as uncompressed XML text format.
The "--flush-size" controls the amount of memory the progam uses. I set this to 8 with
my 16GB ram in my machine, set this to 4 or 2 if you have less than 16 GB of memory.
The "--compression-method" and "--map-compression-method" are to compress the produced
database in separate parts?! This may yield samller database but there will always be compression
and decompression! I set compression to "no", feel free to change this.

To use "op_initial_db.sh" script:

 * Make sure that the script is executable (it should be) if not; set it to be exectable with:
```
    # chmod +x /usr/local/bin/op_initial_db.sh
```
 * You may want to use lower / higher number for "flush-size". Use 4 if your ram < 16 GB.

The script assumes that you installed my overpassAPI package using my SlackBuild script
and that you also installed *osmium*. I also assume you already created "database" directory.

The script takes THREE arguments; input file name, version number as date string
and destination directory for database.

- Input file name is your region OSM data file in any format supported by "osmium".
  If the file is not in your current directory, then include the path with file name.
- Date is the last date contained in that input file in "YYYY-MM-DD" format. This date will be
  used as the version number for the database.
- Destination directory is overpass database directory and must exist (DB_DIR). If you used
  the File System Structure above, then this will be "/var/lib/overpass/database"

  **version number from osmium output:**
  The output from "osmium fileinfo" above includes 2 timestamp lines labeled (timestamp + Timestamps):

  - The first is under the "Header" section, this is the file creation time. This is **not** what we want.

  - The second is under the "Data" section and has First and Last lines; it provides a range for data dates in the file.

 <pre>
 Data:
  Bounding box: (-115.7133191,30.9030825,-108.218831,38.8430606)
  Timestamps:
    First: 2007-08-10T17:38:36Z
    Last: <b>2023-07-18</b>T19:45:41Z
</pre>

the version number we will use is from the **Last:** line above in "YYYY-MM-DD" format. It is **2023-07-18** from this file.

As everything run this as the "overpass" user, move to the directory where you have your
source file and assuming that "op_initial_db.sh" script is in your path "/usr/local/bin/" and
your region source file name is "sourcefile.osm.pbf" with last date "2023-07-18" and you are
using the above mentioned File System layout ( DB_DIR is: /var/lib/overpass/database ):

```
 overpass@yafa:/source$ nohup op_initial_db.sh sourcefile.osm.pbf 2023-07-18  "/var/lib/overpass/database" &
```

By default "op_initial_db.sh" passes (--meta) option to "update_database" program. Edit the script to change that.

This process will take some time to complete; depending on your region data file size and your hardware.

With those steps so far, you can query your database on the command line using the "test-first.op"
example file provided in the root directory in this Guide; the example uses bounding box for "Arizona",
so please replace with good {bounding box} points for your region database:
```
    $ osm3s_query --db-dir=DB_DIR < test-first.op
```
command above assumes you are in the directory where the "test-first.op" file is, please replace
"DB_DIR" with your actual database directory. Anybody on the system can use overpass to
query the database, but to control overpass you need to put overpass hat on; be the "overpass" user.

**osm3s_query**
If you are new to overpass then "osm3s_query" program is your friend, get to know it. In short it has 2 modes:
 - Interactive mode: you enter your query statements in the terminal and end your input with "Ctrl D".
 - Batch mode: you write your query in a text file; like the example above then use shell redirection for input.
   You can use c-programming comment style in your file - please see the example file above.







### Limited Area Database with FULL HISTORY (attic) Is Not Supported:

**Using Full History extracts to initial overpass database is not supported and discouraged**


### Starting the "dispatcher" daemon:

The "dispatcher" program is part of the overpass package, it is the daemon
which forwards queries to the correct part of overpass. As long as the dispatcher
is running, your queries to overpass will be answered.

The dispatcher program can take a lot of arguments:
```
Accepted arguments are:
  --osm-base: Start or talk to the dispatcher for the osm data.
  --areas: Start or talk to the dispatcher for the areas data.
  --meta: When starting the osm data dispatcher, also care for meta data.
  --attic: When starting the osm data dispatcher, also care for meta and museum data.
  --db-dir=$DB_DIR: The directory where the database resides.
  --terminate: Stop the adressed dispatcher.
  --status: Let the addressed dispatcher dump its status into
        $DB_DIR/osm_base_shadow.status or $DB_DIR/areas_shadow.status
  --my-status: Let the adressed dispatcher return everything known about this client token
  --show-dir: Returns $DB_DIR
  --purge=pid: Let the adressed dispatcher forget everything known about that pid.
  --query_token: Returns the pid of a running query for the same client IP.
  --space=number: Set the memory limit for the total of all running processes to this value in bytes.
  --time=number: Set the time unit  limit for the total of all running processes to this value in bytes.
  --rate-limit=number: Set the maximum allowed number of concurrent accesses from a single IP.
```
The important arguments for us now are: ( --osm-base,  --areas, --meta, --attic and --db-dir ).
 * --osm-base: start basic or main dispatcher.
 * --areas: start areas dispatcher.
 * --meta | --attic: must match initialed database option.
 * --db-dir: actual overpass database directory.

You start "dispatcher" as the "overpass" user giving it your database directory and how that
database was initialed, using "&" in the end to make it run as background process:

```
 overpass@yafa:~/source$ dispatcher --osm-base --db-dir=/var/lib/overpass/database --meta &
```

With dispatcher running in the background, --db-dir option for "osm3s_query" program is not needed.
You can run the "test-first.op" query example - mentioned above - without providing the database
directory argument as follows (assuming "example" file is in your curent directory):
```
    $ osm3s_query < test-first.op
```

To stop the dispatcher daemon, as the overpass user run:
```
overpass@yafa:/mnt/nvme4/source$ dispatcher --osm-base --terminate
```

The script "op_ctl.sh" can be used to control the dispatcher program. The script gets
installed into "/usr/local/bin/" directory by my overpass Slackware package. The script
is meant to be used by the overpass user only. If you are not using the File System mentioned
above, you will need to set DB_DIR variable in the script before using it.

The "op_ctl.sh" script provides three functions: { start, stop & status }. Control the
dispatcher as "overpass" user with:

```
  overpass@yafa:~$ op_ctl.sh start
  overpass@yafa:~$ op_ctl.sh status
  overpass@yafa:~$ op_ctl.sh stop
```

### Start "Dispatcher" At Boot:

Please note that "rc.dispatcher" script has been rewritten, it just calls "op_ctl.sh" script now.

The dispatcher is run as daemon, in Slackware daemons start/stop scripts are added
to the system "/etc/rc.d/" directory prefixed with (rc.) - which stands for Run Command.
In my SlackBuild script directory, I provide "rc.dispatcher" script to start
the dispatcher. When you install your package, you will find a new file with
the name "rc.dispatcher" in your "/etc/rc.d/" this script is almost ready to be used.

No editing is required for "rc.dispatcher" script; just ensure that it is exectable.

This script has been rewritten, it only calls "op_ctl.sh" script now. The "root" user can use
it to start, stop and get status as follows:
```
 # /etc/rc.d/rc.dispatcher start
 # /etc/rc.d/rc.dispatcher stop
 # /etc/rc.d/rc.dispatcher status
```

To have dispatcher start and stop on system boot and shutdown you need to modify your
startup scripts. For Slackware system you change your "/etc/rc.d/rc.local" file and your
"/etc/rc.d/rc.local_shutdown" file by adding the following lines to each file (wear root hat):

```
 /etc/rc.d/rc.local
 ============================
 # Startup overpass dispatcher
 if [ -x /etc/rc.d/rc.dispatcher ]; then
    /etc/rc.d/rc.dispatcher start
 fi

 /etc/rc.d/rc.local_shutdown
 ============================
 # Stop overpass dispatcher
 if [ -x /etc/rc.d/rc.dispatcher ]; then
    /etc/rc.d/rc.dispatcher stop
 fi
```

You may need to create the "/etc/rc.d/rc.local_shutdown" if not present in your system.

### Area Creation:

The "area" object is not an OpenStreetMaps object - like nodes, ways or relations.
The object is an Overpass type, it is generated by Overpass from OSM data and
added to Overpass database by the "osm3s_query" program using "--rules" switch that
reads settings from an XML formated file. The file is "areas.osm3s" which is included in
the "rules" directory in my Slackware overpass package "/usr/local/rules/".
To use area functions; another dispatcher instance has to be started with "--areas" switch
in addition to the "--osm-base" instance, the following command does the job:

```
overpass@yafa:/root$ /usr/local/bin/dispatcher --areas &
```
or just use "op_ctl.sh" script as the overpass user; it starts both instances for you:
```
 $ op_ctl.sh start
```
To generate "areas" in overpass database developer provided "rules_loop.sh" script is used.
I have replaced this script with "op_make_areas.sh" script to make areas type in a new initialed overpass
database.

To generate "areas" in your database run the script "op_make_areas.sh" to completion ***without changing***
IMAX loop counter. This will take time to complete, let the script run to completion. The area creation
produces more files in your database with "area*" names, mine added nine of them. The
"area" filter can be used now, a simple overpass query is provided to test area functions in the file named
"test-area.op" in this Guide. To test your database run:

```
 osm3s_query < test-area.op | sort -ub
```
this should result in a sorted list of names for cities and towns in your database.

### Backup, Clone, Source:

* Keep your source files
* Clone DB from time to time with : osm3s_query --clone=$TARGET_DIR
* Clone does NOT copy areas files - make areas again OR copy area files with:
```
    $ cp $DB_DIR/area* $TARGET_DIR/.
```
also copy base version number:
```
    $ cp $DB_DIR/osm_base_* $TARGET_DIR/.
```

### Database Update:

OSM data changes by the minute - literally. Recall Change Files were mentioned in README-DATA.md
section "OSM File Format", they have (.osc) file extension and they include changes within a time period.

Lets recap and say the obvious. Each data element inside OSM data files has a date;
it gets this date when edited for addition, deletion or modification. To bring OSM data
up to date, newer elements are added or merged into the data. Newer elements are in
the change files. To update OSM data file or database we need to know the last date
for data included in that original OSM file then add data dated just AFTER this date from
change files.

###### Know last date included in your region OSM data file:

At geofabrik.de servers regional OSM extracts data files have 2 sets, the first include full historic data, the second
does not. Extracts with full historic data are generated **weekly** while the non-historic ones are
generated **daily**. Since we can not initial an overpass database with full historic support for limited area,
please stay away from full historic data file to initial your database.

At geofabrik.de website, the date for last included data in the file is stated on the download page.
Under "Commonly Used Formats" heading at the line with the download link you will find something like the following:
```
This file was last modified 14 hours ago and contains all OSM data up to 2023-07-28T20:21:58Z. File size:233 MB;
```

Under "Other Formats and Auxiliary Files" heading; the line with the download link will say:
```
This file was last modified 6 days ago. File size: 439 MB;
```
in this case you calculate the date by going back 6 days from today. Please note that this is the same
data file listed under the "Commonly Used Formats" heading in older OSM data format and a lot bigger
file size. Use the smaller file size with (.pbf) data format listed first under "Commonly Used Formats" heading
to download your region data file.

TODO: include screenshot.

There are tools that can be used to get information about OSM data files, using one you
can get the last date for data included in that file. One tool (program) is "osmium" with
the fileinfo command. For example the following command was issued in the directory
where I have my OSM data file "arizona-latest-internal.osm.pbf" - note no historic data:
```
$ osmium fileinfo arizona-latest-internal.osm.pbf
```
The output was:
```
File:
  Name: arizona-latest-internal.osm.pbf
  Format: PBF
  Compression: none
  Size: 265419524
Header:
  Bounding boxes:
    (-114.8325,30.05891,-109.0437,37.00596)
  With history: no
  Options:
    generator=osmium/1.15.0
    osmosis_replication_base_url=https://osm-internal.download.geofabrik.de/north-america/us/arizona-updates
    osmosis_replication_sequence_number=3763
    osmosis_replication_timestamp=2023-07-18T20:21:43Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2023-07-18T20:21:43Z
```
notice the timestamp line at the end. This is the date for latest data included in the file.

There are other tools you may use that will give you this information. For osmium you may want
my slackware package find it [here](https://github.com/waelhammoudeh/osmium-tool_slackbuild).

Now we know the LAST date included in our data file, we need to match that with the change file
with date just AFTER this date. Change files have corresponding "state.txt" files which includes
a timestamp line and sequenceNumber line. We look in "state.txt" files looking for date just
after our last date we just found.

The change files and their corresponding state.txt are listed on the region **updates** page at
geofabrik.de website. For each file in the list there is a date for its modification, this date is very
close to the date in Change file we are looking for. Look inside "state.txt" and check timestamp
line to match just after your region date. Once we match dates in "state.txt" the sequence
number for change file to start updating from is the number in sequenceNumber line.
The sequence number is 4 to 9 digit long number, never starts with zero.

The sequenceNumber line in this matched "state.txt" file has the sequence number needed
for the 'begin' argument of my "getdiff" program.

At "download.geofabrik.de" - this is the public server - the region **updates** page lists "state.txt"
and change files in **sorted** order, those same files are **not** sorted and do not include modified
date for the internal server. Internal and public servers files are generated at just about the same time,
they also share file names "the 3-digit number file name", if you are using the internal server, it is easier
to browse your region updates page on the **public** server.

The overpassAPI provides two ways to keep databases updated with "Change Files"
The first method uses "update_from_directory" program and used with a live server; meaning the
"dispatcher" has to be running, database can still be queried during the update process. This is the
method used in the script "apply_osc_to_db.sh" shipped with the API source, you can look at the
script found in the executable "usr/local/bin" directory.

The second method uses "update_database" program and used with a stopped server; meaning the
"dispatcher" can not be running. The developer words about this method:
```
(As a side note, this also works for applying OSC files onto an existing database. Thus you can
make daily updates by applying these diffs with a cronjob. This method takes fewer disk loads
than minute updates, and the data is still pretty timely.)
```
This is the method I will use here to keep overpass database updated. The server will be stopped
for a period of one to three minutes during the update; since mine is for personal use, I do not
announce this down time, if yours is on an intranet network - used by others - you should announce
this 1 to 3 minutes down time.

The update process is broken into two steps; retrieve Change Files and apply them to database. The
first is done using my "getdiff" program, the second is done with my "op_update_db.sh" script.

I use Geofabrik website to get my extracts for them providing **daily "Change Files"** for those
extracts. Those files include changes in the area extract in the last 24 hours only, when updating
with them, your OSM data is updated up to that time. This makes updating data a lot easier, which
makes life easier, easier is better, thank you very much Geofabrik.
If you do not use Geofabrik for your extracts, this may not help you much and you need to look
somewhere else to update your database. You may apply the same concept in your own scripts.

You will be wearing three "hats" here, your own normal self, "overpass" and "root" users ... you will dance!
No seriously, if you think it is easier for you to setup "getdiff" by editing "getdiff.conf" file and make sure
everything is running correctly by testing your configuration as your own self first before downloading
files as the "overpass" user, then feel free to do that. Everything done to the database will be done as the
"overpass" user. Downloading "Change Files" should also be done as "overpass" user. The "dispatcher"
daemon is started by overpass, "root" switches to "overpass" user in "rc.dispatcher" script used in the
system initial and shutdown scripts.

#### Retrieve Change Files:

My "getdiff" program retrieves "Change Files" from Geofabrik **public or internal servers.**

Find ["getdiff" source here](https://github.com/waelhammoudeh/getdiff), the repository has full instructions for compiling and usage.

The program is written in C language, download, compile and place the executable "getdiff" in
"/usr/local/bin/" directory because that is where a script down below expects to find it.
(only root can write to this directory - so be root).

modify the example configuration file: "getdiff.conf.example" included with this Guide,
Set values for KEYS below and save it without the "example" extension please:

  - SOURCE
  - BEGIN
  - DIRECTORY

If you use Geofabrik internal server, please fill "USER" value too, we will provide password when we call the program.

Program "getdiff" appends newly downloaded file names to the file 'newerFiles.txt' in its working directory.
This file is processed by "op_update_db.sh" script to do the updates. The script renames this file when done - emptying
or hiding the file from "getdiff". We could have deleted / removed altogether, but there is a plan for it!

The 'source' argument is the internet address for your area (region) updates page at geofabrik.de site.
This ends with an entry formatted as {region}-updates, where region is the name of your area or country.

The argument for 'begin' is the sequence number for the change file to start downloading from.

To ensure that you have the right sequence number, start with fresh downloaded OSM data file, then
your change files will be generated the very next day by geofabrik.de servers. Easy is better.
The sequence number is inside the corresponding "state.txt" file at the sequenceNumber line.
The next day, browse your area updates page for new state.txt files, you will easly find your needed
sequence number.

The sequence number is 4 to 9 digit long number, never starts with zero. By OSM convention daily change
files have sequence number of four digits; at geofabrik.de this convention is followed.

If this not possible, then follow the instructions mentioned above under the heading
"Know last date included in your region OSM data file:" to find your sequence number.

With all settings filled in configuration file - we need to make sure that all is okay now. Run "getdiff" to download
your region Change Files to test your settings in one of two ways:

* If you are using Geofabrik **PUBLIC** server:
```
      $ getdiff -c path/to/your/getdiff.conf
```

* If you are using Geofabrik **INTERNAL** server:
```
     $ getdiff -c path/to/your/getdiff.conf -p xxxxxxxx
```
replace the "xxxxxxxx" above with your password for your ( openstreetmap.org ) account.

This should download your region (.osc) Change Files AND their (.state.txt) files placing them
in your "DIRECTORY" setting under "diff" directory entry.

If it does not work as expected, please double check your settings espacially the URL for SOURCE. And
test your settings again.

As mentioned in the File System Structure section above "getdiff" Work Directory is created under
"overpass" directory, this makes DIRECTORY setting:

```
DIRECTORY = /var/lib/overpass/getdiff
```
with this setting, "getdiff" program created "diff" directory is where I find the new dowloaded
differ files and their state.txt files.

#### Update Overpass Database:

The "op_update_db.sh" bash script is to update the overpass database. The script uses "update_database"
program provided by overpassAPI. The "dispatcher" must be stopped while "update_database" does its work.

The "op_update_db.sh" uses files dowloaded by "getdiff" program, so both share some settings, namely:

 * DB_DIR : overpass database directory
 * DIFF_DIR : where to find differ (change) files

Note that "op_update_db.sh" script uses "gunzip" program and does not require osmium - osmium
is still required to initial databse with "op_initial_db.sh" script.

To use the script copy it to "/usr/local/bin/" directory, and make sure it is executable. Only
change setting if you are NOT using my File System Structure.

With filled settings, you can now update your overpass database using the downloaded (.osc)
Change Files by running "op_update_db.sh" script as the "overpass" user. This script has "LOGFILE"
setting, I set this to "logs" directory under OP_DIR:
```
LOGFILE=/var/lib/overpass/logs/op_update_db.log
```
Check your log file and your database version file: DB_DIR/osm_base_version. Hope it works for you.

**Area update:**

The area update is done in "op_update_db.sh" script with a small loop counter of **ten** iterations,
a **larger** loop counter is used in "op_update_areas.sh" script. Running "op_update_db.sh" daily
and "op_update_areas.sh" weekly will keep areas files updated in your database.

The "op_update_areas.sh" script has a loop counter in "IMAX" variable, you can experiment with this
counter running the script periodically like once a week or even once a month, checking your
database results for "area" queries. I set the IMAX variable to 50 to update Arizona areas, I had
used 100 to initial the areas, that is half for area update. I run "op_update_areas.sh" script once
a week plus the daily "op_update_db.sh" script.

The combination of daily area update with small loop counter in "op_update_db.sh" script and
a larger loop counter in "op_update_areas.sh" will keep areas files updated.

**NOTE:** Those two scripts should NOT be running at the **same time**.

#### Automate the Process:

**Database Auto Updates**

Now we can download new "Change Files" and update our database with them, we need this done
automatically by the system. In Linux a daemon known as "cron" is used, you tell cron **when** to
run a program and it does that for you. Slackware uses Dillon Cron - there are a lot of those, but they
mostly work the same way. You tell Cron to run a program by editing "crontab" or cron table, which is
just a file. Use "man crontab" for information of how to do that.

We dowloaded Change Files and updated our database as the "overpass" user, so "getdiff" progam
and "op_update_db.sh" are to be scheduled to run by the "overpass" user. In Slackware all users have
their own "crontab" entries file. Crontab is to be edited as the "overpass" user.

Your dowload and updates do not need to be done at the same time, you can download files **daily**
as they are available from Geofabrik and do **weekly** updates with "op_update_db.sh" script. To do
this setup you need two cron entries in overpass crontab; one for daily "getdiff" and the other for
weekly "op_update_db.sh".

I do **both** my downloads and updates one after the other **daily**. The script "cron4op.sh"
ties "getdiff" and "op_update_db.sh" together; it calls "getdiff" first then "op_update_db.sh". This
makes it easier to schedule cron job with one crontab entry. I use "@daily" crontab entry format
because my machine does not run 24/7. If yours does you may want to set a specific time for your
cron job. As the "overpass" user edit crontab with:
```
 $ crontab -e
```
and enter this crontab entry:
```
@daily ID=opUpdateDB /usr/local/bin/cron4op.sh >/dev/null 2>&1
```

The name after the ID= above is needed by Dillon Cron and used as a timestamp, you always provide
**full path** to scripts and programs to be run.

Adjust paths settings only if you do not use the File System Structure on top of this Guide.

**Password Note** I enter my OSM password as text in this script file, you can also enter it
in your "getdiff.conf" file, if you are concerned about your password then set permission on the
file - wherever your password is - to be readable only by "overpass" user. This is easier to do for
"gediff.conf" file, but you get the idea. I do not do any of this, just FYI.

**Area Auto Update**

The script to use to keep area data updated is "op_update_areas.sh".
This script has a loop counter set to 50 iteration and is run once per week.

Keep in mind area data is being updated daily with database update script "op_update_db.sh"
using very small loop counter.
Use the following crontab entry - as the "overpass" user - to update area data once a week:

@weekly ID=opAreaUpdate /usr/local/bin/op_update_areas.sh >/dev/null 2>&1

Hint: '$ man crontab' will give you examples for entries.

**Remove Old Change Files**

Change Files are saved to your "diff" under getdiff program work directory, they are small and do
no harm, but they can accumulate and add up in disk space usage. We can remove old files with the
'find' command; this removes all files older than 7 days in directory /path/to/diff:
```
find /path/to/diff -mtime +7 -type f -delete
```

I remove Change Files daily that are older than 7 days, to do that a new cron entry is added to
"root" crontab as root of course, the following entry does that:
```
@daily ID=rm_OSM_osc find /var/lib/overpass/getdiff/diff -mtime +7 -type f -delete >/dev/null 2>&1
```

The ID=rm_OSM_osc is needed by Dillon Cron as mentioned in update database above.
The path above is for the file system structure on top of this Guide, change if you do not
use that.

#### Log Files And Rotation:

Logs directory was created under DB_DIR; that is our database directory, my two scripts
"op_update_db.sh" and "op_update_areas.sh" write their log files to this directory, we have
another two files we need linked into this directory - we can not move them. Those are the
"transactions.log" produced by overpass and "getdiff.log" produced by getdiff. To create links
do the following commands as the "overpass" user after moving to your logs directory:

```
overpass@yafa:/var/lib/overpass/logs$ ln -s ../database/transactions.log .
overpass@yafa:/var/lib/overpass/logs$ ln -s ../getdiff/getdiff.log .
```
note the periods in the end, again replace my paths with your real paths. By doing this we have
access to all log files from one directory.

Logrotate program is used to rotate log files and and it comes configured in Slackware. A log
rotate configure file is provided in "op_logrotate" file and shown below. Copy this file to your
/etc/logrotate.d/ directory as the "root" user. This will rotate files depending on their sizes.
Log rotation configuration file:

```
# logrotate file for overpass logs - FIVE files are handled
# compress is global

compress
nomail

/var/lib/overpass/logs/op_update_db.log  /var/lib/overpass/logs/op_update_areas.log /var/lib/overpass/getdiff/getdiff.log {

    su overpass overpass
    rotate 5
    size 100K
    missingok
    notifempty
}

/var/lib/overpass/database/transactions.log /var/lib/overpass/database/database.log {

    su overpass overpass
    rotate 5
    size 500K
    missingok
    notifempty
}
```

To ensure that "op_logrotate" file has the correct syntax run a simple test - as root - after you have copied the file:
```
 # logrotate -d /etc/logrotate.d/op_logrotate
```

The -d option above will just test and does not rotate any file. It will tell you what the
program will do for each file listed.

If your machine does NOT run 24/7 you may miss the log rotation! By default Slackware calls
logrotate as a daily cron job at 4:40 AM local time. See /etc/cron.daily and see root crontab
by ' # crontab -l', that said; to ensure that your logs get rotated add the following crontab entry
to the "root" cron table:

```
@daily ID=op_logrotate  /usr/sbin/logrotate /etc/logrotate.d/op_logrotate >/dev/null 2>&1
```

#### Shutdown Caveat:

Scripts do not handle shutdown signals. To avoid corrupted database make sure that
scripts are done and have completed their work before shutting down the system.
Check log files for all scripts always.


[^1]:  More about this below.

Note to myself:

Managing custom output
To make the custom output feature operational, you only need to copy the default templates into the corresponding subdirectory of the database:

cp -pR "templates" "db/"

Wael K. Hammoudeh

August 18/2023
