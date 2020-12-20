This is the README file for Overpass-API software from Open Street Maps (OSM)
installation and web server setup on local machine running Linux Slackware64 
current operating system.

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
requirements and easier to setup. Has Its Own Database engine. No need for 
Postgresql or anything else; software requires expat library which is provided
by Slackware64 current.

This is NOT a tutorial for OverpassAPI. I will just show you how I installed it
on my system, so you too can have your own local server.
For more information check out the wiki page quoted above.

There are public servers running around the world. The issue with them; the
coming and going. They disappear with no warning, having your own avoids the 
unpleasant surprises. There are other reasons to have your own server ...

Hardware Requirements: 

From the "Complete Installation Guide" that comes with the software:
 "Concerning hardware, I suggest at least 4 GB of RAM. The more RAM is available,
 the better, because caching of disk content in the RAM will significantly speed
 up Overpass API. The processor speed will have little relevance. For the hard 
 disk, it depends on what you want to install. A full planet database with 
 minutely updates should have at least 250 GB of hard disk space at disposal. 
 Without minute diffs and meta data, 100 GB would already suffice."
 
Myself I think the processor speed is important, do not try to run on 32 bit
processor! Use solid state drive for the data base storage with at least 100 GB
space, and 4 GB memory or more.

Installation and setup consist of the following steps:

1) Build / compile the source software using Slack Build script.
2) Populate the Database using the provided software and data source
   file you get from OSM server.
3) Setup Apache web server on your local machine to use OverpassAPI.

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

http://overpass-api.de/api/interpreter?data=[out:csv(\"name\";false)];way(33.56090, -111.96920, 33.57510, -111.93470)[highway];out;


Installation and Setup Details:

Please continue reading in the README file.
Wael H. 
