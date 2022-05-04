This is the "README-SETUP.md" file for overpass Slackware package.

IMPORTANT: This is a work in progress, may also have inaccurate information.

Overpass "SETUP" is database initialization and starting daemon "dispatcher" such
that queries can be done on the local machine.

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

Now we run everything as "overpass" user. To put "overpass" hat on:

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

### initial_op_db.sh Script:

Note old "updateDB.sh script" has been replaced with "initial_op_db.sh" script.

OverpassAPI provides two script to initial the database found in "/usr/local/bin" directory .
The first is the "download_clone.sh" script which is for cloning planet database from
a live overpass server. Here we talk about **region** setup, this script is of no use
for us here.

The second script is "init_osm3s.sh" script. This script calls "update_database" program
found also in the overpass package executable "bin" directory. My "initial_op_db.sh" script
found with this "Guide" is a rewrite of this script and I use it to initial overpass database.
To use this script you may need to adjust some variables! And you **must install** osmium
tools in your system [from my repository](https://github.com/waelhammoudeh/osmium-tool_slackbuild).

```
wael@yafa:~$ update_database -h
Unkown argument: -h
Usage: update_database [--db-dir=DIR] [--version=VER] [--meta|--keep-attic] [--flush_size=FLUSH_SIZE] [--compression-method=(no|gz|lz4)] [--map-compression-method=(no|gz|lz4)]
```

The program "update_database" reads its input from standard input (the terminal) expecting
uncommpressed XML text format.
The "--flush-size" controls the amount of memory the progam uses. I set this to 8 with
my 16GB ram in my machine, set this to 4 or 2 if you have less than 16 GB of memory.
The "--compression-method" and "--map-compression-method" are to compress the produced
database in separate parts?! This may yield samller database but there will always be compression
and decompression! I set compression to "no", feel free to change this.

To use "initial_op_db.sh" script:

 * Make sure that the script is executable: (chmod +x {path}/initial_op_db.sh).
 * You may want to use lower / higher number for "flush-size". Use 4 if your ram < 16 GB.

The script assumes that you installed my overpassAPI using my SlackBuild script and
that you also installed my osmium-tool_slackbuild.

The script takes THREE arguments; input file name, version number as date string
and destination directory for database.

- Input file name is your region downloaded OSM file.
- Date is the last date contained in that input file in "YYYY-MM-DD" format.
    If your file was from Geofabrik then this date is listed on the download page. If not,
    then you have to use "osmium fileinfo --extended {inputfile}" to get that date.
- Destination directory must exist - we created it above.

This step can take some time depending on input file size and your machine. It can
take hours for a large country like Germany or minutes in my case with the state of
Arizona file. My file was latest from Geofabrik website with a size of 213 MB; file with
meta data (all meta) and **no** attic. The following were the exact steps I did:

  - created a new directory "source" under database directory, (/mnt/nvme4/op-meta).
  - moved to source directory (cd source).
  - copied my input file "arizona-latest-internal-2022-04-08.osm.pbf" to source directory.
  - I had added the date to the file name in my "Downloads" directory - renamed it.
  - copied "initial_op_db.sh" script to source directory.
  - from source directory issued command to initial overpass database with:
```
 overpass@yafa:/mnt/nvme4/op-meta/source$ time nohup ./initial_op_db.sh arizona-latest-internal-2022-04-08.osm.pbf 2022-04-08 /mnt/nvme4/op-meta &
```
This took about 21 minutes with time output shown below:
```
real	20m53.554s
user	20m55.571s
sys	0m51.003s
[1]+  Done       time nohup ./initial_op_db.sh arizona-latest-internal-2022-04-08.osm.pbf 2022-04-08 /mnt/nvme4/op-meta
```

You may need to reboot your machine after this step! "update_database" uses a lot of memory.

The input file I just used above had no attic data, while the examples I mention above in
"Local Storage" had an input file with attic data. You can use full history OSM data file to
initial database with "meta" only but NOT the other way around.
The produced database directory size was about 22 GB with file count of 44 files, note "area"
is NOT initialed yet.

With those steps so far, you can query your database on the command line using the "example"
file provided in the root directory in this Guide; the example uses bounding box for "Arizona",
so please replace with good {bounding box} points for your region database:
```
    $ osm3s_query --db-dir=/home/overpass < example
```
command above assumes you are in the directory where the "example" file is, and database
directory is "/home/overpass", please replace with your actual database directory. Anybody on
the system can use overpass to query the database, but to control overpass you need to put
overpass hat on; be the "overpass" user.

If you are new to overpass then **osm3s_query** program is your friend, get to know it.

### Database with FULL HISTORY (attic):

**Using Full History extracts to initial overpass database is not supported and discouraged**

This approach is highly experimental, the produced database can **only** be queried via the
command line, no web interface with this database is available. In addition your log file
"transactions.log" **grows very rapidly**. I discourage this use. You use "osm3s_query" program
with "--quiet" switch or redirect stderr using your shell to query database in a terminal. In addition
to those short comings it is also **NOT** possible to update the database using my "update_op_db.sh" script
mentioned below.

To initial the database, your source input file must have "attic" or historical data, the "initial_op_db.sh"
script used above can be used with setting "META" to "--keep-attic", just uncomment that line.
There is no known way to control logging to "transactions.log", it will be hard to maintain that file.

### Starting the "dispatcher" daemon:

The "dispatcher" program is part of the overpass package, it is the daemon
which forwards queries to the correct part of the package. As long as the
dispatcher is running, your queries to overpass will be answered.

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
database was initialed.

```
 overpass@yafa:/mnt/nvme4/op-meta/source$ dispatcher --osm-base --db-dir=/mnt/nvme4/op-meta --meta &
```

With dispatcher running, --db-dir option for "osm3s_query" program is not needed, providing that
is the directory you want to use.

In my SlackBuild script directory, I provide "rc.dispatcher" script to start
the dispatcher. When you install your package, you will find a new file with
the name "rc.dispatcher.new" in your "/etc/rc.d/", the install script sets the
file to be executable - if it is not then you need to make it executable.

There are two things you need to do to the file (yes, as the root user):
1) rename it to "rc.dispatcher" (drop the .new extension)
2) edit the file to set your actual database directory.

Then you can start, stop and get status as follows:
```
 # /etc/rc.d/rc.dispatcher start
 # /etc/rc.d/rc.dispatcher stop
 # /etc/rc.d/rc.dispatcher status
```

With dispatcher running, you can run the "example" query without providing the
database directory argument as follow:
```
    $ osm3s_query < example
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
the "rules" directory in my slackware overpass package, so the first thing we do is copy
that directory to your overpass database directory as the "overpass" user:
```
overpass@yafa:/root$ cp -pR /usr/local/rules/ /mnt/nvme4/op-meta/
```
replace my destination "/mnt/nvme4/op-meta/" above with your real database directory.

Another dispatcher instance has to be running with "--areas" switch in addition to the
"--osm-base" instance, you can start that with:

```
overpass@yafa:/root$ /usr/local/bin/dispatcher --areas --db-dir=/path/to/overpass/ &
```

But wait; we can do better, you should have setup your "rc.dispatcher.new" by now, no?
As the "root" user and using your text editor, open the file "/etc/rc.d/rc.dispatcher.new"
then just set the value for "DBDIR" in the line with "DBDIR=/path/to/your/overpass/DBase"
on top of the file to the real path to your database directory, then save the file without ".new"
extension; that is "/etc/rc.d/rc.dispatcher". You should also have changed your "/etc/rc.d/local"
and "/etc/rc.d/rc.local_shutdown" to include the lines mentioned above in: Starting the
"dispatcher" daemon.

Now start the dispatcher (only root can do this) and you will have two dispatcher(S) running with:
```
root@yafa:~# /etc/rc.d/rc.dispatcher start
```

To generate "areas" in your database run "osm3s_query" program as "overpass" user setting
"--rules" switch as:
```
overpass@yafa:/root$ osm3s_query --progress --rules < /mnt/nvme4/op-meta/rules/areas.osm3s
```
again replace the path to "areas.osm3s" file with your actual database directory.

The area creation produces more files with "area*" in your database directory, mine added
nine of them. This step finished in less than one minute on my machine. There is nothing to
adjust here. This may take long time for **planet** file but not a small region like Arizona.
The areas need to be regenrated every time database is updated. We shall do that when we
get to updating our database.

The "area" filter can be used now, a simple overpass query is provided to test for this in
"area-test.op" file in this Guide. To test your database run:
```
 osm3s_query < area-test.op | sort -ub
```
this should result in a sorted list of names for areas in your database.

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

To set "BEGIN", using your browser navigate to your "SOURCE" URL, there you will find (.osc) change files and each has
a (.state.txt) file, find (.state.txt) file with date just AFTER the date in your region file used to initial database above.

With all settings filled in configuration file - we need to make sure all okay now. Run "getdiff" to download
your region Change Files as your normal user in one of two ways:

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

If it does not work as expected, please double check your settings espacially the URL for SOURCE.

Note that everything above is done as your normal user; expect copy / move "getdiff" to "/usr/local/bin/".

#### update_op_db.sh script:

The "update_op_db.sh" bash script is to update the overpass database. The script uses "update_database"
program provided by overpassAPI as mentioned above. You need to change the THREE settings marked
in the script to match your real paths. Those settings are:

 * NEWER_FILES : file produced by "getdiff" program
    NEWER_FILES={ must match "getdiff" NEWER_FILE configuration setting }

 * DIFF_DIR : where to find differ files
    DIFF_DIR= { getdiff work directory + "diff" entry }

 * DB_DIR : overpass database directory
    DB_DIR={ overpass database directory }

Note that "update_op_db.sh" script uses "gunzip" program and DOES NOT use osmium - osmium is still needed
and used by "initial_op_db.sh".

Edit the script with your settings and copy or move it to "/usr/local/bin/" directory, the script needs
to be executable:
```
chmod +x initial_op_db.sh
```
if not already set. This script is to be executed as "root".

With filled settings, you can now update your overpass database using the downloaded (.osc)
Change Files by running "update_op_db.sh" script as root. This script produces a LOG file in:
/var/log/overpass/update_op_db.log. Check the log and your database, hopefully everything
worked without any error.

#### Automate the Process:

The script "cron4op.sh" is a driver script that calls "getdiff" to download "Change Files", then calls the
"update_op_db.sh" when new change files are downloaded to update overpass database. The script
is intended to be called as a cron job, can be scheduled to run as needed.

 * newfiles={ NEWER_FILES : file produced by "getdiff" program}
 * LOCAL_USER={ your normal user name on your local machine }
 * CONFIGURE={ Name and path to "getdiff" configuration file }
 * PSWD={ openstreetmap.org password; if Geofabrik internal server is in use }

Please fill the above settings in the script and place it as usual in "/usr/local/bin/" directory.

You need to edit the "root" cron table to add an entry to run the script above, I chose this entry:
```
@daily ID=opUpdate /usr/local/bin/cron4op.sh 1> /dev/null
```
because my machine does not run 24 / 7. The above entry will run the script once every day.
If the machine was down for more than 24 hours, the script will run on boot.
If your machine runs 24 / 7, you may want an entry with exact time.

To edit cron table as "root":
```
 # crontab -e
```
then you can copy / paste the entry as above, or enter your own entry for exact time.

Hint: $ man crontab will give you examples for entries.

TODO: add example entries; lazy!

 - Crontab entry : every 24 hours at LEAST -> on boot
 - Crontab entry : every 24 hours at exact time -> machine runs 24 / 7
 - Crontab entry : every WEEK -> 24 / 7 machine
 - Crontab entry : add to /etc/cron.daily OR /etc/cron.weekly -> add SCRIPT to DIRECTORY

TODO: Logrotate. Still?!

[^1]:  More about this below.
