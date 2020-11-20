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

1) Build the Slackware package using the provided SlackBuild script and then
   install the produced package on your system. Use the link provided in the 
   the script README file to get the source. That link is: 
        
        "https://dev.overpass-api.de/releases/osm-3s_v0.7.56.8.tar.gz"
        
2) Populate the database:
   
A) Decision time:
   At this point you need to decide where to store the database and what to 
   include in the database.
   Store the database on SSD if you have one, or your fastest hard drive. you
   need to make sure you have enough space for the data base. How much space?
   You ask; it depends on the input file size - what to include. I think the
   recommended amounts mentioned in the complete installation is of mark, it is
   an OLD document. It says 250 GB for full planet database! I think you need
   more than the 500 GB very easy. I do not go by that.
   What to include in the data base? You can include the whole world if you
   have the space on your hard disk. Or pick smaller database input file; they
   are available for continents, regions, individual countries or states.
   The time it takes to populate the database depends on the input file size
   and your processor / machine speed.
   The input file to initial / populate the database is OSM file. And OSM (Open 
   Street Map) files are of many types. Usually you can tell the type by the
   file suffix. The OSM command line tool "Osmium" is used to work with files;
   you can use "osmium" to convert from type to another, get information about
   a file and many other uses. You can find a Slackware build script for osmium
   on my repository. The file type required to initial the database is ".osm.bz2"
   type. Read more about OSM data files at:
   
     https://wiki.openstreetmap.org/wiki/Databases_and_data_access_APIs
   
   In short your input file name needs to end with ".osm.bz2". To add to the mix;
   files may include "meta data" or extra data.
   A shell script is provided with the software to download and clone database.
   I have NOT used this script. If you want you can use "download_clone.sh".
   
   This is what I did; I live in Phoenix, Arizona so I got a file for the state
   of Arizona with meta data and used that to initial my database.
   To download your file go to this web site:
   
        https://osm-internal.download.geofabrik.de/index.html
        
   and choose your file - for state, country, region or planet.
   If you choose a file with meta data - not available in ".osm.bz2" type - then
   you need to convert it with "osmium" to .osm.bz2 type with this command:
    $ osmium cat yourfile.osm.pbf -o yourfile.osm.bz2
   
   Before leaving this section, we are going to make our decisions / assumptions
   as follow:
     - Store database under /home directory since there is enough disk space,
       so we make a directory as root with the name of "overpass";
       # mkdir /home/overpass
       I will refer to the /home part of the path above as {DB_ROOT}, so place
       your database directory anywhere you want.
     - The input file I will use has meta data with the name "infile.osm.bz2"
     
B) Create group and user:
   Do not run your server as root. As done with Postgresql SlackBuild, I create
   an overpass detecated group and user to limit access and permissions. This 
   can be done with the following:
     
     # groupadd -g 1055 overpass
     # useradd -u 1055 -g 1055 -d {DB_ROOT}/overpass overpass
     
   Feel free to use different uid and gid above, I use high numbers to avoid
   conflicts. Look in your /etc/group and /etc/psswd files first!!!
   Now change the owner and group for overpass directory with:
     # chown -R overpass:overpass {DB_ROOT}/overpass
     
C) Initial The Data Base:
   With the above assumptions we initial the data base using "init_osm3s.sh"
   provided with the software; this script takes three arguments and one 
   command option as follows:
   1) infile: is the input file; has to be of type .osm.bz2
   2) data base directory: where to store the data base - destination
   3) executable directory: this is the bin directory root where overpass is
      installed - /usr/local/ without the bin entery.
   4) the meta option: if infile has no meta data, then change to "--meta=no".
   
   Do the following to initial data base:
   - As root user change user to overpass with:
     root@lazyant:~# su overpass <enter>
     
   - Then your prompt should look like this on your terminal:
     overpass@lazyant:/root$ 
     
     And whoami and its output should look like:
     overpass@lazyant:/root$ whoami
     overpass
     
     Assuming everything is good; change directory to where you placed your 
     "infile.osm.bz2" and initial the data base with:
     
     overpass@lazyant:/root$ nohup init_osm3s.sh infile.osm.bz2 "{DB_ROOT}/overpass/" "/usr/local/" --meta&
     
     Replace {DB_ROOT} above with your real path.
     
     My actual infile.osm.bz2 was "arizona-latest-internal.osm.bz2" for the
     state of Arizona with file size about 300 MB, on my machine the above
     command to initial the data base took about 32 minutes, with directory 
     size about about 17 GB. YMMV!
     
   With those steps so far, you can query your data base on the command line.
   Using the example file provided with this README; and please replace with
   good points from your database input file:
   
     $ osm3s_query --db-dir={DB_ROOT}/overpass < example
   
   above assumes you are in the directory where the example file is.

Data base updates will not be covered here. See documentation in your 
installation for that, or check online :)

D) Start / Stop the "dispatcher" daemon:
   Hoping everything above went as expected, to use the web interface for the
   overpass API a unix daemon needs to be running (started).
   
TODO: write script to simplify dispatcher start and stop.
   
   The "dispatcher" is part of the software package built and installed in
   the first step above and can be found in /usr/local/bin directory. It should
   not be run as root, we will run it as the overpass user we created above,
   placing the command to start it in /etc/rc.d/rc.local file which is called
   by the startup scripts in Slackware. To stop it we place the command in the
   /etc/rc.d/local_shutdown file (you may need to create this file as root) 
   which is called by Slackware shutdown scripts.
   
   Add those lines (between START and END) to your /etc/rc.d/rc.local file:

   START
   
   DB_ROOT=(replace with your DB_ROOT here, mine was /home)
   
   VERSION=v0.7.55
   
   # remove stalled socket file if found
   if [ -S $DB_ROOT/overpass/osm3s_$VERSION_osm_base ]; then    
        echo "Found STALLED overpass socket file, removing."
        rm -f $DB_ROOT/overpass/osm3s_$VERSION_osm_base
   fi

   # start overpass dispatcher daemeon; as user overpass not root
    echo "Starting overpass disptcher ..."
    sudo -u overpass /usr/local/bin/dispatcher --osm-base --db-dir=$DB_ROOT/overpass/ --meta&

    END
    
    Again edit the DB_ROOT line above with your actual path to your Database
    parent directory, mine becomes:
    DB_ROOT=/home
    
    Also if your infile.osm.bz2 had no meta data, edit the "--meta" option above
    to "--meta=no".
    
    To stop the dispatcher, add the following to your /etc/rc.d/rc.local_shutdown
    
    START
    
    echo "Stopping overpass dispatcher..."
    sudo -u overpass /usr/local/bin/dispatcher --terminate

    END
    
    Do not include the START and END lines, they are just makers for lines to
    be included. You add the lines between them only.
    
    With the dispatcher daemon running, you can run the example without the
    database option; as:
    
    $ osm3s_query 
    < example
    
3) Setup Apatche Web Server:
    
    With full installation of Slackware, the Apache web server is installed by
    httpd package. This package includes one of the best documentation in open
    source software; you can find the documentation on your system at:
       /var/www/htdocs/manual/index.html 
    
    There are a lot of guides, howtos and articales available on the web to
    setup the Apache web server on a Slackware machine. So I am not going to
    reinvent the wheel. One such document is here:
        https://docs.slackware.com/howtos:network_services:setup_apache

    You are going to modify the main configuration file, one tool (command) to
    be aware of is: 
        "apachectl -t"
    this checks your configuration file for syntax errors.
    
    Slackware provides a script to start and stop the Apache server. That script
    is /etc/rc.d/rc.httpd. You start the server with:
     $ sh /etc/rc.d/rc.httpd start
    And you stop the server with:
     $ sh /etc/rc.d/rc.httpd stop
    If you make the script executable with "$ chmod +x /etc/rc.d/rc.httpd" then
    Slackware will start Apache every time you boot your machine, and stops
    Apache server on shutdown.
    
    The file to modify is: /etc/httpd/httpd.conf, use a text editor, emacs or
    kate or whatever text editor you like. It is in sections, there is a full
    example configuration file with this README, it is usable, but use at your
    own risk. Few points about this example configuration file are as follow:
    
    1) In the Listen section "Listen 80", sets Apache to listen in all network
       devices in the system.
       
    2) Your localhost server is redfined in the virtual host section.
    
    3) The server Root Document is set to "/usr/local/html/overpass" which is
       part of the installed package you built and installed in step number 
       one above. This setting is done by the line:
            DocumentRoot "/usr/local/html/overpass"
            
    4) The ScriptAlias directive in htppd.conf instructs the server to look for
       scripts in "/usr/local/cgi-bin/", this directory is also produced and 
       included by the overpass Slackware package. This setting is done by:
           ScriptAlias /api/ /usr/local/cgi-bin/
           
    Using the provided example to configure your Apache server, you can access
    your overpass server on the SAME machine you installed it by entering this 
    address in your browser:
       http://localhost
  
    Note about Network - small area and home network:
    If you have your home network setup and you use STATIC IP addresses with it,
    by including this line in all your "/etc/hosts" files on your computers:
    
        xxx.xxx.xxx.xxx myoverpass.local myoverpass
    
    <Replace xxx.xxx.xxx.xxx above with IP for overpass machine>.
    
    Then you can access your overpass server from other machines with:
        "http://myoverpass 
            OR 
        http://myoverpass.local" 
    in a browser address bar
