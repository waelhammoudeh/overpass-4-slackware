This is the "README-SETUP.md" file for Overpass Guide.

In this file I explain overpass database initialization, overpass dispatcher daemon
role and how to start it, overpass areas creation is explained. After setup we move
to keeping the database updated with latest available OSM data. Finally we get to
automating the database updates and up keep. Hope you enjoy the ride.

### Local Storage:

At this point you need to decide where to store the database. Store the database
on a fast hard drive like SSD (Solid State Drive) or NVME if you have one, the faster
the drive the less time for the query result since there will be a lot of file I/O.
You need to make sure you have enough space for the database. I cannot tell
you how much since it depends on your file and data files vary wildly in size for
countries and regions, hence it is hard to tell the required disk space. You may
have to experiment with this!
My database directory size may help to give you an idea of the space you need.
First I did initial two databases from one source data file with "attic" data and
this source file was in (.pbf) format with size 362 MegaByte (MB). In both databases
I did initial "areas" [^1] the first database I used the "--meta" option and the second
I used the "--attic" option.

```
  Option      File Count      Directory Size
  -----------------------------------------------
  --attic        103              41 GB
  --meta         55               22 GB

```

Note that directory size using "--attic" option is about **double** the "--meta" option.
Countries with about 4 GB source file size - like Germany and France - will require
disk space of 100 to 200 GB. You need to allow for growth, so in my 41 BG above I
need about 80 GB of free disk space, or the 22 GB means 40 to 45 GB of free space.
Again you need to experiment with your region.

Where you store the database is the "overpass" user home directory we used when
we created the overpass group and user. If you need to make any changes to that,
now is the time before you initial the database.

You create the database directory as "root", somewhere on your system where you have
enough free space and let us call that {db_root}, also as "root" you change ownership of
that directory to overpass user and group; the followings two commands do that:

```
   # mkdir {db_root}/overpass
   # chown overpass:overpass {db_root}/overpass
```

Now we run everything as "overpass" user. To put "overpass" hat on as root user do:

```
  # su overpass <enter>
```
Then your prompt should look like this on your terminal (note $ NOT # anymore):
```
  overpass@lazyant:/root$
```
And "whoami" command and its output should look like:
```
  overpass@lazyant:/root$ whoami
  overpass
```

Do not run anything as "root" unless it is only doable by "root".

### File System Structure:

I refer to overpass home directory as **DB_DIR** that is where I initial my database,
I create two directories under this; "logs" to keep log files in one place and "getdiff"
as work directory for my getdiff program for updates - explained below. So my file
system structure looks like:

DB_DIR
  - getdiff
  - logs

and as written paths (found in scripts here):
 - DB_DIR/getdiff/somefile
 - DB_DIR/logs/somelogfile

I place all my shell scripts in /usr/local/bin/ directory so they are in my path, all my
shell scripts assume this location for scripts and exectables. Scripts that do anything
to the database should only be run as the "overpass" user.

You might need to copy the "rule" directory installed by the Slackware package to your
database directory. As "overpass" user run:
```
$ cp -pR /usr/local/rules/ DB_DIR/
```
Replace DB_DIR with your database directory.

### Scripts and DB_DIR Variable:

Scripts included in my Slackware package are:
 - initial_op_db.sh
 - op_ctl.sh
 - rc.dispatcher

those scripts get installed by the package in /usr/local/bin directory.

Scripts included in the Guide are:
 - update_op_db.sh
 - op_area_update.sh
 - cron4op.sh
 - set_DB_DIR_path.sh

you need to manually copy those scripts to /usr/local/bin directory.

Most scripts and some files included use **DB_DIR** variable to refer to overpass database
directory. This has to be manually set to your real database directory. To ease this process
I have included yet another script that does that for you.

Run "set_DB_DIR_path.sh" script with your real path as an argument and all files in the
current working directory will have "DB_DIR" variable set. If the scripts you want to change
are not in your current directory, you can pass that directory as second argument to the
"set_DB_DIR_path.sh" script. Please note that doing this does NOT guarantee anything,
you still need to make sure that the real path is set.

I have removed duplicate scripts from the repository! There is only one copy of each. Feel
free to place scripts in one directory and run "set_DB_DIR_path.sh" there.

### Initial Overpass Database:

OverpassAPI provides two scripts to initial the database found in "/usr/local/bin" directory .
The first is the "download_clone.sh" script which is for cloning **whole planet** database from
a live overpass server. This script can not be used for a llimited area or region.

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

The file format has to be (.osm.bz2) format, this format is a lot larger than (.osm.pbf) file
format, it takes longer to download - it shows if you do not have the bandwidth. Another
issue I have with this script is that it does not handle all options accepted by program
"update_database" without editing the script.

My "initial_op_db.sh" script found with this "Guide" is a rewrite of this script (init_osm3s.sh)
to overcome issues mentioned above. The "initial_op_db.sh" script requires OSM *osmium*
program. Slackware package build script is available from my osmium-tool repository with
[link here](https://github.com/waelhammoudeh/osmium-tool_slackbuild).

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

To use "initial_op_db.sh" script:

 * Make sure that the script is executable:
```
    # chmod +x /usr/local/bin/initial_op_db.sh
```
 * You may want to use lower / higher number for "flush-size". Use 4 if your ram < 16 GB.

The script assumes that you installed my overpassAPI package using my SlackBuild script
and that you also installed *osmium-tool*.

The script takes THREE arguments; input file name, version number as date string
and destination directory for database.

- Input file name is your region downloaded OSM file. In any format supported by "osmium".
- Date is the last date contained in that input file in "YYYY-MM-DD" format.
    If your file was from Geofabrik then this date is listed on the download page. If not,
    then you have to use "osmium fileinfo --extended {inputfile}" to get that date.
- Destination directory is overpass database directory and must exist (DB_DIR).

As everything run this as the "overpass" user, move to the directory where you have your
source file and assuming that "initial_op_db.sh" script is in your path "/usr/local/bin/" and
your region source file name is "sourcefile.osm.pbf" with last date "2022-04-08" enter your
real path for DB_DIR below:

```
 overpass@yafa:/source$ nohup initial_op_db.sh sourcefile.osm.pbf 2022-04-08 DB_DIR &
```
By default "initial_op_db.sh" passes (--meta) option to "update_database" program. Edit the
script to change that.

With those steps so far, you can query your database on the command line using the "example"
file provided in the root directory in this Guide; the example uses bounding box for "Arizona",
so please replace with good {bounding box} points for your region database:
```
    $ osm3s_query --db-dir=DB_DIR < example
```
command above assumes you are in the directory where the "example" file is, please replace
"DB_DIR" with your actual database directory. Anybody on the system can use overpass to
query the database, but to control overpass you need to put overpass hat on; be the "overpass" user.

If you are new to overpass then **osm3s_query** program is your friend, get to know it.

### Database with FULL HISTORY (attic):

**Using Full History extracts to initial overpass database is not supported and discouraged**

This approach is highly experimental, the produced database can **only** be queried via the
command line, no web interface with this database is available. In addition your log file
"transactions.log" **grows very rapidly**. I discourage this use. You use "osm3s_query" program
with "--quiet" switch or redirect stderr using your shell to query database in a terminal. In addition
to those short comings it is also **NOT** possible to update the database using my "update_op_db.sh"
script mentioned below.

To initial the database, your source input file must have "attic" or historical data, the "initial_op_db.sh"
script used above can be used with setting "META" to "--keep-attic", just uncomment that line.
There is no known way to control logging to "transactions.log", it will be hard to maintain that file.

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
database was initialed, using "&" in the end to run in the background:

```
 overpass@yafa:/mnt/nvme4/op-meta/source$ dispatcher --osm-base --db-dir=/mnt/nvme4/op-meta --meta &
```

With dispatcher running in background, --db-dir option for "osm3s_query" program is not needed.
You can run the "example" query - mentioned above - without providing the database
directory argument as follows (assuming "example" file is in your curent directory):
```
    $ osm3s_query < example
```

To stop the dispatcher daemon, as the overpass user run:
```
overpass@yafa:/mnt/nvme4/op-meta/source$ dispatcher --osm-base --terminate
```

The script "op_ctl.sh" can be used to control the dispatcher program after setting the
"DB_DIR" variable to your real database directory. The script gets installed in the
"/usr/local/bin/" directory by my overpass Slackware package. The script is meant
to be used by the overpass user only. After setting DB_DIR you can start, stop and get
status of the dispatcher with the script.

### Start "Dispatcher" At Boot:

Please note that "rc.dispatcher" script has been rewritten, it just calls "op_ctl.sh" script now.

The dispatcher is run as daemon, in Slackware daemons start/stop scripts are added
to the system "/etc/rc.d/" directory prefixed with (rc.) - which stands for Run Command.
In my SlackBuild script directory, I provide "rc.dispatcher" script to start
the dispatcher. When you install your package, you will find a new file with
the name "rc.dispatcher.new" in your "/etc/rc.d/" this script is almost ready to be used.

To use "rc.dispatcher.new" script rename it without the "new" extension and make sure
it is executable - it should be at install time.

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
Another dispatcher instance has to be running with "--areas" switch in addition to the
"--osm-base" instance, you can start that with:

```
overpass@yafa:/root$ /usr/local/bin/dispatcher --areas --db-dir=/path/to/overpass/ &
```
or just use "op_ctl.sh" script as the overpass user:
```
 $ op_ctl.sh start
```
To generate "areas" in overpass database developer provided "rules_loop.sh" script is used.
The script needed changes to run. I have replaced this script with "op_area_update.sh" script,
this script is used in two places; here to initial areas data and down below to keep this data
updated where we change IMAX loop counter. To use the script set "DB_DIR" variable to your
database directory.

To generate "areas" in your database run the "op_area_update.sh" to completion ***without changing***
IMAX loop counter. The area creation produces more files in your database with "area*" names,
mine added nine of them. The "area" filter can be used now, a simple overpass query is provided
to test for this in "area-test.op" file in this Guide. To test your database run:

```
 osm3s_query < area-test.op | sort -ub
```
this should result in a sorted list of names for cities and towns in your database.

### Backup, Clone, Source:

* Keep your source files
* Clone DB from time to time with : osm3s_query --clone=$TARGET_DIR
* Clone does NOT copy areas files - make areas again.

TODO: adapt "download_clone.sh" from machine to machine in home office network or SON (small office network).

### Database Update:

OSM data changes by the minute - literally. Recall Change Files were mentioned in README-DATA.md
section "OSM File Format", they have (.osc) file extension and they include changes within a time period.
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
first is done using my "getdiff" program, the second is done with my "update_op_db.sh" script.

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

The repository includes an example configuration file: "getdiff.conf.example" in its root directory,
edit the file with your settings and save it without the "example" extension please.

Fill the following settings:

  - SOURCE
  - BEGIN
  - DIRECTORY
  - NEWER_FILE

If you use Geofabrik internal server, please fill "USER" setting too, we will provide password when we call the program.

Program "getdiff" appends newly dowloaded files names to the file specified by "NEWER_FILE" setting.
This file is read by "update_op_db.sh" script to do the updates. This setting needs to match for both,
one adds to the file (gediff) and the other one empties it (update_op_db.sh).

To set "BEGIN", using your browser navigate to your "SOURCE" URL, there you will find (.osc) change files and each has
a (.state.txt) file, find (.state.txt) file with date just AFTER the date in your region file used to initial database above.

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

As mentioned in File System Structure above I create "getdiff" directory under my "DB_DIR" or
overpass home, I do everything as the "overpass" user and my "DIRECTORY" setting is set to :
```
DIRECTORY = DB_DIR/getdiff
```
with this setting, "getdiff" program created "diff" directory is where I find the new dowloaded
differ files and their state.txt files.

#### Update Overpass Database:

The "update_op_db.sh" bash script is to update the overpass database. The script uses "update_database"
program provided by overpassAPI. The "dispatcher" must be stopped while "update_database" does its work.

The "update_op_db.sh" uses files dowloaded by "getdiff" program, so both share some settings, namely:

 * DB_DIR : overpass database directory
 * NEWER_FILES : file produced by "getdiff" program
 * DIFF_DIR : where to find differ files

I have structured all my scripts to use "DB_DIR" variable, if you followed my File System Structure
all you need to set is this variable. Or you can use "set_DB_DIR_path.sh" script to do it for you.

Note that "update_op_db.sh" script uses "gunzip" program and does not require osmium - osmium
is still required to initial databse with "initial_op_db.sh" script.

Edit the script with your settings and copy or move it to "/usr/local/bin/" directory, the script needs
to be executable:
```
chmod +x update_op_db.sh
```

With filled settings, you can now update your overpass database using the downloaded (.osc)
Change Files by running "update_op_db.sh" script as the "overpass" user. This script has "LOGFILE"
setting, I set this to "logs" directory under DB_DIR:
```
LOGFILE=$DB_DIR/logs/update_op_db.log
```
Check your log file and your database version file: DB_DIR/osm_base_version. Hope it works for you.

**Area update:**

The area update is done in "update_op_db.sh" script with a small loop counter of **ten** iterations,
a **larger** loop counter is used in "op_area_update.sh" script. Running "update_op_db.sh" daily
and "op_area_update.sh" weekly will keep areas files updated in your database.

The "op_area_update.sh" script has a loop counter in "IMAX" variable, you can experiment with this
counter running the script periodically like once a week or even once a month, checking your
database results for "area" queries.

The combination of daily area update with small loop counter in "update_op_db.sh" script and
a larger loop counter in "op_area_update.sh" will keep areas files updated.

#### Automate the Process:

**Database Auto Updates**

Now we can download new "Change Files" and update our database with them, we need this done
automatically by the system. In Linux a daemon known as "cron" is used, you tell cron **when** to
run a program and it does that for you. Slackware uses Dillon Cron - there are a lot of those, but they
mostly work the same way. You tell Cron to run a program by editing "crontab" or cron table, which is
just a file. Use "man crontab" for information of how to do that.

We dowloaded Change Files and updated our database as the "overpass" user, so "getdiff" progam
and "update_op_db.sh" are to be scheduled to run by the "overpass" user. In Slackware all users have
their own "crontab" entries file. Crontab is to be edited as the "overpass" user.

Your dowload and updates do not need to be done at the same time, you can download files **daily**
as they are available from Geofabrik and do **weekly** updates with "update_op_db.sh" script. To do
this setup you need two cron entries in overpass crontab; one for daily "getdiff" and the other for
weekly "update_op_db.sh".

I do **both** my downloads and updates one after the other **daily**. The script "cron4op.sh"
ties "getdiff" and "update_op_db.sh" together; it calls "getdiff" first then "update_op_db.sh". This
makes it easier to schedule cron job with one crontab entry. I use "@daily" crontab entry format
because my machine does not run 24/7. If yours does you may want to set a specific time for your
cron job. As the "overpass" user edit crontab with:
```
 $ crontab -e
```
and enter this crontab entry:
```
@daily ID=opUpdateDB /usr/local/bin/cron4op.sh 1> /dev/null
```

The name after the ID= above is needed by Dillon Cron and used as timestamp, you always provide
**full path** to scripts and programs to be run.

Do not forget to set "DB_DIR" variable to your real database directory if you use this script.

**Password Note** I enter my OSM password as text in this script file, you can also enter it
in your "getdiff.conf" file, if you are concerned about your password then set permission on the
file - wherever your password is - to be readable only by "overpass" user. This is easier to do for
"gediff.conf" file, but you get the idea. I do not do any of this, just FYI.

**Area Auto Update**

The same script used to initial area data is also used to keep it updated that script is the
"op_area_update.sh". The script has a loop counter set to 100 iteration for area creation,
I set this counter to 50 and run the script once a week. Note that you may increase your
IMAX loop counter larger than 100 during areas data initialization, do NOT set it lower in
that step.

To update areas data weekly edit "op_area_update.sh" and set IMAX to 50 or half IMAX
value used to initial areas data. Keep in mind area data is being updated daily with
database update script "update_op_db.sh" using very small loop counter. Use the following
crontab entry - as "overpass" user - to update area data once a week:

@weekly ID=opAreaUpdate /usr/local/bin/op_area_update.sh 1> /dev/null

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
@daily ID=rm_OSM_osc find /path/to/your/diff -mtime +7 -type f -delete
```

The ID=rm_OSM_osc is needed by Dillon Cron as mentioned in update database above, replace
/path/to/your/diff path string with your real path.

#### Log Files And Rotation:

Logs directory was created under DB_DIR; that is our database directory, my two scripts
"update_op_db.sh" and "op_area_update.sh" write their log files to this directory, we have
another two files we need linked into this directory - we can not move them. Those are the
"transactions.log" produced by overpass and "getdiff.log" produced by getdiff. To create links
do the following commands as the "overpass" user after moving to your logs directory:

```
overpass@yafa:/mnt/nvme4/op2-meta/logs$ ln -s /mnt/nvme4/op2-meta/transactions.log .
overpass@yafa:/mnt/nvme4/op2-meta/logs$ ln -s /mnt/nvme4/op2-meta/getdiff/getdiff.log .
```
note the periods in the end, again replace my paths with your real paths. By doing this we have
access to all log files from one directory.

Logrotate program is used to rotate log files and and it comes comes configured in Slackware.
Fix the database path in the file below - use "set_DB_DIR_path.sh" if you like - and place the file
as root user into your /etc/logrotate.d/ directory. This will rotate files depending on their sizes.

```
# logrotate file for overpass logs - four files are handled
# compress is global

compress

$DB_DIR/logs/update_op_db.log  $DB_DIR/logs/op_area_update.log $DB_DIR/getdiff/getdiff.log {

    su overpass overpass
    rotate 5
    size 100k
    missingok
    notifempty
}

$DB_DIR/transactions.log {

    su overpass overpass
    rotate 5
    size 200k
    missingok
    notifempty
}
```

If your machine does NOT run 24/7 you may miss the log rotation! By default Slackware calls
logrotate as a daily cron job at 4:40 AM local time. See /etc/cron.daily and see root crontab
by ' # crontab -l', that said; to ensure that your logs get rotated add the following crontab entry
to the "root" cron table:

```
@daily ID=op_logrotate  /usr/sbin/logrotate /etc/logrotate.d/op_logrotate
```

#### Area Update Again:

My thinking is the infinite loop is needed for the **planet** database with minuetly updates.
If that is the case we are okay; but I do not know!!!! I will post anything I find here. If anyone
has any idea please let me know.

It is complete A - Z. Not done yet.

Wael K. Hammoudeh

May 9th / 2022

[^1]:  More about this below.
