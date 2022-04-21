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

### UpdateDB.sh Script:

OverpassAPI provides two script to initial the database found in "/usr/local/bin" directory .
The first is the "download_clone.sh" script which is for cloning planet database from
a live overpass server. Here we talk about **region** setup, this script is of no use
for us here.

The second script is "init_osm3s.sh" script. This script calls "update_database" program
found also in the overpass package executable "bin" directory. My "updateDB.sh" script
found with this "Guide" is a rewrite of this script and I use it to initial overpass database.
To use this script you may need to adjust some variables! And you **must install** osmium
tools in your system.

```
wael@yafa:~$ update_database -h
Unkown argument: -h
Usage: update_database [--db-dir=DIR] [--version=VER] [--meta|--keep-attic] [--flush_size=FLUSH_SIZE] [--compression-method=(no|gz|lz4)] [--map-compression-method=(no|gz|lz4)]
```

The program "update_database" reads its input from STDIN (terminal) expecting
uncommpressed XML text format.
The "--flush-size" controls the amount of memory the progam uses. I set to 8 with my 16GB ram.
The "--compression-method" and "--map-compression-method" are to compress the produced
database in parts?!

To use "updateDB.sh" script, make sure it is executable first, and provide your input
file name and the date in YYYY-MM-DD format, where the date is the last one contained
in input file. (from Geofabrik: this date is listed on the download page).


[^1]:  More about this below.
