This repository is a guide for setting up overpassAPI server on a local machine;
your own server - with limited area database. I use Linux Slackware64, concepts,
methods and steps mentioned here can be applied to any Linux distribution.

This guide is a work in progress!

OverpassAPI uses its own database, naturally this guide is broken into two
parts; first software installation and hardware requirements, the second is
database initialization including information about source data file required
for this, what to look for in this file, where to get it from and where to place
your database on your machine. Then the procedure for database initialization
is explained with its various options. The guide concludes with the web user
interface setup utilizing Apache Web Server.

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

This is NOT a tutorial for OverpassAPI. I will just show you how I installed it
on my system, so you too can have your own local server.

There are public servers running overpassAPI around the world. There are a lot
of issues with using a public server which can be avoided with having ones own
server.

Hardware Requirements: 

From the "Complete Installation Guide" that comes with the software:
 "Concerning hardware, I suggest at least 4 GB of RAM. The more RAM is available,
 the better, because caching of disk content in the RAM will significantly speed
 up Overpass API. The processor speed will have little relevance. For the hard 
 disk, it depends on what you want to install. A full planet database with 
 minutely updates should have at least 250 GB of hard disk space at disposal. 
 Without minute diffs and meta data, 100 GB would already suffice."
 
Myself I think the processor speed is important, do not try to run on 32 bit
processor! Use solid state drive for the database storage with at least 50 GB
space for small country, and at least 4 GB memory or more.

Installation and setup consist of the following steps:

1) Build / compile the source software using my SlackBuild script.
2) Download OSM data file for your region (maybe country).
3) Populate (initial) the Database using your OSM region file .
4) Setup Apache web server on your local machine to use OverpassAPI.

An Example Query:
   Again this is NOT a tutorial for overpass-API. But we will use an example
   through this installation to make sure we are on the right tracks. For
   full language explanation see this link:
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
Installation and Setup Details:

Details are provided in three "README" files found in "overpass-slackbuild"
directory in this repository as follows:

 1. README : package build and installation.
 2. README.data : all about OSM data file you need for the database.
 3. README.web : shows basic setup for Apache web server.

Wael Hammoudeh
