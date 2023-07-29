This repository is a guide for setting up overpassAPI server on a local machine;
your own server - with limited area database. I use Linux Slackware64, included
in this repository is a SlackBuild script to build a Slackware package for the
overpassAPI software, scripts to initial and update overpass database, program to
retrieve "Change Files" from Geofabrik servers for the updates: ["getdiff"](https://github.com/waelhammoudeh/getdiff).
How to utilize cron and logrotate utilities to automate updates and maintenance of the database.

Concepts and methods mentioned here can be applied to any Linux distribution not just Slackware.

#### Upgrades:

Updated the bash script for database update "update_op_db.sh" in the Guide.
The updated script is needed for new upgraded "getdiff" program.
The program output file "newerFiles.txt" has changed format, old format is not compatible with the new format.

Note: Watch for new (needed) updates to this guide ... soon I hope.


##### This guide is a work in progress!

#### Warning:

Running overpass database instance initialed from extract for limited area file with
**FULL HISTORY (attic)** is not supported.

#### Prerequisite and caveat:

There are some requirements to install and learn overpass, the most important
thing is time and patience in addition to the followings:

  * Hardware demands for memory at least 4 GB, fast hard disk - Solid State Drive
     or NVME - with disk space at least 50 GB for a small one country area and 64
     bit multi core processor.
  * Basic knowledge of Unix / Linux commands, not afraid to use the terminal.
  * Software tool to operate on OSM data files, I recommend Osmium Command
     Line Tools - I have a SlackBuild script next to this repository. You may use
     other tools.
  * Caveat to keep in mind that I am NOT an overpass expert neither very smart.

#### Organization:

This repository has two directories; the first is "overpass-slackbuild" where I
placed the build script for Slackware package. The second directory is the "Guide"
where you will find instruction files for overpass setup and other essential
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
     - Software setup to query and control database
     - Areas creation.
     - Automating updates using my "getdiff" program
     - Scripts to utilize cron and logrotate for maintenance and updates.

     This will need another README no kidding.

* README.web :
     Has details for setting up Apache web server for the web user interface
   to overpass.

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
