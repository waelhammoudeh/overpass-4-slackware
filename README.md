This repository is a guide for setting up OSM overpass software on a local machine
for limited area initialed from an OSM extract data file. It covers software installation,
database initialization, database manager "dispatcher" control, web server setup for
database access, database updates. An automation process is described and implemented
for running the server and for the database updates.

I use Linux Slackware64 system, included in this repository is a SlackBuild script to
build a Slackware package for the overpassAPI software, scripts to initial and update
overpass database, script to control the dispatcher and program to retrieve the
"Change Files" from Geofabrik servers needed for database updates: ["getdiff"](https://github.com/waelhammoudeh/getdiff).

Concepts and methods mentioned here can be applied to any Linux distribution not just Slackware.

### Changes:

August 20/2023

  - SlackBuild builds overpass version "0.7.61.6"
  - op_make_areas.sh: change IMAX loop counter to 10. Yes again!
  - op_initial_db.sh: modified; copies "templates" directory to database directory now.
  - edited README-SETUP.md: sadly still incomplete!
  - {HOME} directory for overpass user is what we create at "/var/lib/overpass" **OR**
   link your overpass home directory using this named link. Directory has to be created
   and ownership set to: "overpass:overpass".

August 18/2023

 - op_make_areas.sh: changed IMAX loop counter from 100 down to 2.
 - op_update_areas.sh: removed script - areas objects are updated daily after database update with iCount = 2.

**Overpass**

On April 25/2023 the Overpass developer made the following announcement in a blog post:

```
Since almost two weeks a new version of the Overpass API is out.
This version addresses primarly those people that maintain an
instance on a magnetic hard disk. The version has changed the
data format of the backend such that updates run four times faster.
```
Read the [blog here](https://dev.overpass-api.de/blog/version_0_7_60.html)

  - New database format
  - New migration program from [v0.7.52 - v0.7.59] database format to v0.7.60 database format.
  - New log file in the database directory with file name: 'database.log'
  - Dropped Version Number from socket file names.

**Guide Scripts Renamed And Moved To Package Directory**

 Scripts names now start with "op"; scripts for the overpass user, followed by the action - verb,
 then the object each scripts acts upon.

 Scripts have been moved to SlackBuild directory and are included in the package; you still
 need to copy "op_logrotate" to "/etc/logrotate.d/" if you use it.

 The old "op_area_update.sh" script gets two new names; op_make_areas.sh and op_update_areas.sh,
 the first has the {IMAX} loop counter set to twice the value found in the second for this {IMAX},
 the first is run to make areas in a new database and the second is run once a week from a cron job
 to keep areas updated. Note that they both still write to the same log file, we have too many of them!
 Log files names have changed; the two we have now are: "op_update_db.log" and "op_update_areas.log"

 ```
    Old Name                     New Name
  ------------------------------------------------------------
  initial_op_db.sh           op_initial_db.sh
  op_area_update.sh          op_make_areas.sh
  op_area_update.sh          op_update_areas.sh
  update_op_db.sh            op_update_db.sh
```

**op_ctl.sh**

  - Restructured the script
  - Removerd Version Number from socket file names

**gediff**

  - Program was upgraded with code improvements and more
  - The program output file 'newerFiles.txt' format has changed.
  - For all changes see [my getdiff repository](https://github.com/waelhammoudeh/getdiff)

**op_update_db.sh**

  - Updated the script to process the new format from 'newerFiles.txt' file.

**op_logrotate**

  - The new 'database.log' file is included in this file.

**SlackBuild**

  - Updated to overpass version 0.7.61.4
  - Dropped the 'new' file name extension from '/etc/rc.d/rc.dispatcher'
  - Scripts from the Guide are installed by the package build script.
  - The op_logrotate file has been moved to the package build directory.

**Upgrade Instructions:**

The procedure to upgrade is simple, put no mistakes are allowed; there is no way to go back!
We first build the new slackware package as usual, stop the "dispatcher" and use upgradepkg.
Once that is done, we will have the new tool to migrate the database to the new format.
The migratation process does not convert area files in overpass database. We have to remake
areas after the migratation. Please follow the steps below exactly:

  - download the source tar ball; the URL is in the "overpass.info" file. Place the source into
    the build script directory and as "root" build the package with:
    ```
     # ./overpass.SlackBuild
    ```
  assuming the package built okay, it will be placed in your "/tmp" directory.

  - **Before** the upgrade step, we stop the "dispatcher"; since you are "root", issue:
  ```
   # /etc/rc.d/rc.dispatcher stop
  ```
  you could also switch to "overpass" user and use "op_ctl.sh" as follows:
  ```
   # su overpass
   $ op_ctl.sh stop

   go back to "root"
   $ exit
   #
   ```
   it is important that the dispatcher is stopped, double check with "status" check as follows:
   ```
   # /etc/rc.d/rc.dispatcher status
   ```
   the output should be:
   ```
   /usr/local/bin/op_ctl.sh: Database directory is set to: /var/lib/overpass/database

   dispatcher stopped
   ```

  - Upgrade with the new built overpass package; as root issue:
  ```
   # upgradepkg /tmp/overpass-0.7.61.4-x86_64-3_wh.tgz
   ```
  - Switch to "overpass" user, start the dispatcher:
  ```
   # su overpass
   $ op_ctl.sh start
   ```
   your output should look like the following:
   ```
   overpass@yafa:/root$ op_ctl.sh start

   /usr/local/bin/op_ctl.sh: Database directory is set to: /var/lib/overpass/database

   Starting base dispatcher with meta data support ...
   base dispatcher started.

   Starting areas dispatcher ...
   areas dispatcher started
   ```

   - Migrate your database to new format, still as the "overpass" user issue this command:
   ```
   $ migrate_database --migrate
   ```
   note the switch --migrate after the command. This will take few minutes to complete
   for small region database. After this completes, your database has been converted to
   the new format. Use my "test-first.op" query file to check as follows:
   ```
   $ osm3s_query < test-first.op | sort -u
   ```
   keeping my fingers crossed, I hope this worked okay for you.

   - Remove area files from your database directory **(only area files)** as the "overpass" user issue:
   ```
   $ rm /var/lib/overpass/database/area*
   ```
   this is assuming you followed my file system structure outlined in my Guide, adjust the path
   above to your database directory if you did not follow my file system structure. Again areas*
   files **only** are to be removed from the database directory.

   - Make new area files compatible with the new database format; as "overpass" user:
   ```
   $ op_make_areas.sh
   ```
   This step will take about an hour for small region database. Test your new area files using
   "test-area.op" file in the Guide:
   ```
    $ osm3s_query < test-area.op | sort -u
   ```
  I hope everything was successful for you.

  - Edit "overpass" user crontab entry for areas update to use the new script name.

  - Replace old "op_logrotate" file with the new file in SlackBuild directory.

  If this was not successful, new database has to be initialed after insalling the new overpass
  package.

##### This guide is a work in progress!

#### Warning:

Running overpass database instance initialed from extract for limited area file with
**FULL HISTORY (attic)** is not supported.

#### Prerequisite and caveat:

There are some requirements to install and learn overpass, the most important
thing is time and patience in addition to the followings:

  * Hardware demands for memory at least 4 GB, fast hard disk - Solid State Drive
     or NVME - with disk space at least 70 GB for a small one country area and 64
     bit multi core processor.
  * Basic knowledge of Unix / Linux commands, not afraid to use the terminal.
  * Software tool to operate on OSM data files, I recommend Osmium Command
     Line Tools - use my [SlackBuild](https://github.com/waelhammoudeh/osmium-tool_slackbuild) script to build slackware package.
     You may use other tools.
  * Caveat to keep in mind is that I am NOT an overpass expert neither very smart.

#### Organization:

This repository has two directories; the first is "overpass-slackbuild" where I
placed the build script for Slackware package. The second directory is the "Guide"
where you will find instructions and files for overpass setup and other essential
information.

Guide details are provided in README files in the "Guide" directory as follows:

* README:
     Provide hardware requirements and software installation.
   Instruction to build ovepassAPI Slackware package.

* README-DATA.md:
     Essential information about OSM data files.

* README-SETUP.md

     - Disk storage and file system structure
     - Database initialization
     - Software setup and configuration
     - Areas creation.
     - Database maintenance and updates
     - Automating the updates
     - Log maintenance and rotation

* README-WEB.md :
     Has details for setting up Apache Web Server to access the overpass database through the network and internet.

What is OSM Overpass? 
  Quoting from https://wiki.openstreetmap.org/wiki/Overpass_API:
```
    The Overpass API (formerly known as OSM Server Side Scripting, or OSM3S
    before 2011) is a read-only API that serves up custom selected parts of 
    the OSM map data. It acts as a database over the web: the client sends a 
    query to the API and gets back the data set that corresponds to the query.
```

Overpass is a query language with its own rules, I find it very easy to learn.
To me Overpass is a tool to retrieve OSM data, similar to another OSM tool 
known as "Nominatim". Overpass is a lot less demanding in terms of hardware
requirements and easier to setup. Overpass has its own database.

#### Limited Area Database Rational:

OSM data files are huge, limited area OSM data file makes disk space manageable.
Having ones own server removes any usage limits public server may impose.
You are still free to have multiple databases when working with multiple areas.

#### Installation and setup:

See the README.* files in the Guide directory for the long story, The short story
consist of the following steps:

1) Build / compile the source software using my SlackBuild script.
2) Download OSM data file for your region (maybe country).
3) Populate (initial) the Database using your OSM region file .
4) Setup Apache web server on your local machine to use OverpassAPI.

###### An Example Query:

  This is NOT a tutorial for overpass-API, we will use an example query to
  show overpass usage. For full language explanation see this link:
       "https://wiki.openstreetmap.org/wiki/Overpass_API/Overpass_QL"
   I will use the following script with 3 lines to retrieve a list of street
   names within a bounding box:
   
    1  [out:csv("name";false)];
    
    2  way(33.56090, -111.96920, 33.57510, -111.93470)[highway];
    
    3  out;
    
   Line 1 with "[out:csv("name";false)];" defines the output type we want "csv"
   and what is included in it "name", the false is an option to csv output here
   meaning do not include the column header "name".
   
   Line 2 with "way(33.56090, -111.96920, 33.57510, -111.93470)[highway];" tells
   the API software to look for an element that is "way" within this bounding box that
   has a tag named "highway" and we do not care about the value of this tag. In another
   word there has to be a tag with the name "highway".
   Bounding box is defined with floating point numbers (south,west,north,east),
   another way to think of this bounding box is (point A, point B) such as:
   
           |                    | B
        ---|--------------------|---
           |                    |
           |                    |
           |                    |
        ---|--------------------|---
         A |                    |
         
    where the points are defined in (longitude, latitude) pair.
    Note that the numbers listed above are for good points in Phoenix, Arizona.
    You need to replace them with good points within your database input file.
   
   Line 3 with "out;" tells the API software to return normal output to standard
   output device - your screen.
      
    Before leaving; the three lines can be combined into one line:
    
    [out:csv("name";false)];way(33.56090, -111.96920, 33.57510, -111.93470)[highway];out;
    
    and that line can be fed as data for a public server "http://overpass-api.de/"
    for query. Try to copy the next line into your browser!
```
http://overpass-api.de/api/interpreter?data=[out:csv(\"name\";false)];way(33.56090, -111.96920, 33.57510, -111.93470)[highway];out;
```

### DISCLAIMER:
I am NOT an expert on "overpassAPI". Information here may not be accurate, use
at your own risk. I mention other websites, they all have rules and there are laws
to abide by, read the rules and follow the law please. Be in the know.


Wael Hammoudeh
