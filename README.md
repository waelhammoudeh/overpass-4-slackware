This repository is a guide for setting up overpassAPI server on a local machine;
your own server - with limited area database. I use Linux Slackware64, concepts,
methods and steps mentioned here can be applied to any Linux distribution.

##### This guide is a work in progress!

Mistake and Correction: April 9th, 2022

I had given wrong instrucation to initial overpass database with full history or
"attic" data by using converted OSM data file with history from pbf (portable
binary format) to bz2 compressed file format using "osmium" command line tool.
Note that the conversion itself was not wrong, however that conversion step
produced a file WITHOUT history data. That file can not be used to initial
overpass with attic data since it has no attic or history data.
I also just found out that initialing overpass database from extract or limited
area with full history is problematic. There is a lot more about this in the
"README.data" file, please see that file and accept my apology.

End "Mistake and Correction" note added 4/9/2022 W.H.

OverpassAPI uses its own database, naturally this guide is broken into two
parts; first software installation and hardware requirements, the second is
database initialization including information about source data file required
for this, what to look for in this file, where to get it from and where to place
your database on your machine. Then the procedure for database initialization
is explained with its various options. The guide concludes with the web user
interface setup utilizing Apache Web Server.

This repository has two directories; the first is "overpass-slackbuild" where I
placed the build script for Slackware package. The second directory is the "Guide"
where you will find instruction files for overpass setup and other essential
information.

What is OSM Overpass? 
  Quoting from https://wiki.openstreetmap.org/wiki/Overpass_API:
    
    "The Overpass API (formerly known as OSM Server Side Scripting, or OSM3S
    before 2011) is a read-only API that serves up custom selected parts of 
    the OSM map data. It acts as a database over the web: the client sends a 
    query to the API and gets back the data set that corresponds to the query."

end quote.

Overpass is a query language with its own rules, I find it very easy to learn.
To me Overpass is a tool to retrieve OSM data, similar to another OSM tool 
known as "Nominatim". Overpass is a lot less demanding in terms of hardware
requirements and easier to setup. Overpass has its own database.

Limited Area Database Rational:

Full database (planet) size can be huge, 100s of gigabytes maybe approaching
one terabyte of disk space - I do not know the actual size. To save disk space
we limit the area and have database for single country for example. OSM data
files are available for different regions of the world (big and small) ranging
from continents to individual countries even cities. This guide shows this method
for the database initialization / setup.

There are public servers running overpassAPI around the world. There are a lot
of issues with using a public server which can be avoided with having ones own
server.
 
Installation and setup consist of the following steps:

1) Build / compile the source software using my SlackBuild script.
2) Download OSM data file for your region (maybe country).
3) Populate (initial) the Database using your OSM region file .
4) Setup Apache web server on your local machine to use OverpassAPI.

An Example Query:
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
   meaning do not include a separator character.
   
   Line 2 with "way(33.56090, -111.96920, 33.57510, -111.93470)[highway];" tells
   the API software to look for a node that "way" within this bounding box that
   has a tag named "highway" and this highway tag is set to true.
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
Guide Organization:

This guide details are provided in three "README" files found in the directory
"Guide" in this repository as follows:

 1. README : hardware requirements and software installation.
 2. README.data : all about OSM data file you need for the database.
 3. README.web : shows basic setup for Apache web server on local machine.

Upgrade:

 If upgrading from earlier overpass version, just make sure to stop "dispatcher"
before you do the upgrade.


### DISCLAIMER:
I am NOT an expert on "overpassAPI". Information here may not be accurate, use
at your own risk. I mention other websites, they all have rules and there are laws
to abide by, read the rules and follow the law please. Be in the know.


Wael Hammoudeh
