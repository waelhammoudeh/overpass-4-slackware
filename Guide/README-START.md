This is "README-START.md" file for the overpass installation and setup Guide.

Guide details are provided in seperate README files as follows:

 *) README-START.md - this file you are reading now:
     Provide hardware requirements and software installation.

 *) README-DATA.md:
     Essential information about OSM data files.

 *) README-SETUP.md
     Setting up the database in such a way to make it ready for use, including database
     initialization, start the daemon dispatcher, area creation, then maintaining and
     keeping data updated. Finally automation of this process.

  *) README-WEB.md :
      Has details for setting up Apache Web Server for network and internet database
      access.

### Hardware Requirements:

From the "Complete Installation Guide" that comes with the software:
 "Concerning hardware, I suggest at least 4 GB of RAM. The more RAM available,
 the better, because caching of disk content in the RAM will significantly speed
 up Overpass API. The processor speed will have little relevance. Magnetic hard disk
 access time is a lot slower than Solid State Drives or NVME Storage. A SSD drive is
 preferred over magnetic drive.

 For the hard disk space, it depends on what you want to install. A full planet database
 size keeps on growing and is out of the scope of this Guide.

Overpass database is initialed from OSM data file. The database size (disk space) is
depended on this OSM data file size. The size of OSM data file varies from country to
country depending on a lot of things; the country size and its population count plus
how many people are updating OSM data for that country.

My overpass database is for the State of Arizona, the data files I used was in (.osm.pbf)
format with size of 253 MB. My database directory size is just under 27 GB  initialed with
meta data plus areas were made in the database. This database size is about 90 (ninety)
times the data file size.

This is not a scientific study in any way! What I want to say is that the final database
size is many many times the data file size. I do not have a way to know your database size.
My guess is you need any where from 50 to 250 GB of free disk space depending on
your country size.

This is my opinion for hardware:
  1- CPU: any multicore 64 bit - no 32 bit please.
  2- RAM: At least 4 GB.
  3- Hard disk: Solid State Drive is better than magnetic with at least 70 GB free space.

### Software Installation:

**Required before building overpass package:**

You need to create the "overpass" group and user in your system before building
the overpass Slackware package. You also need to create the home directory for the
"overpass" user and set its ownership.

Overpass directory is where you will store your database on your system, you should
have enough free disk space to store overpass database and related files on that disk.

The following commands will accomplish those requirements:
```
   # groupadd -g 367 overpass
   # useradd -u 367 -g 367 -d /path/to/overpass overpass
   # mkdir /path/to/overpass
   # chown overpass:overpass /path/to/overpass
```
Replace "/path/to/overpass" with your actual overpass home directory.

Thanks to Robby Workman from SlackBuilds.org for issuing and including the
above ids in the "Recommended UID/GIDs" document in their site. This avoids
conflicts with software installed from SlackBuilds.org, so I highly recommend
you use the above group and user ids. Feel free to use different gid/uid above,
look in your /etc/group and /etc/passwd files first!!!

**Building the Software**

Included along with this Guide is "overpass-slackbuild" directory, where you will find
my Slackware SlackBuild script to build the overpass software package. Please see the
"README.SlackBuild" file in that directory for latest information.

Building the package; assuming you added overpass group and user as outlined above.

  - Download the source from URL in "overpass.info" file and place it this slackbuild directory
  - run the build script "overpass.SlackBuild" to compile and make the package.
  - package is placed in your "/tmp" file.
  - use "installpkg" to install it.

**Notes about my package**

 - The included SlackBuild script compiles the overpassAPI software from source,
   package destination {PKGDEST} installation root is set to /usr/local/.
 - The build script creates THREE new directories under /usr/local/ with names
   "cgi-bin", "templates" and "rules".
 - Blog directory along with overpass-doc are added to the package in the
   html directory; for educational purposes. Available on the web online too.
 - This build script replaces the "index.html" from the current the tar ball source
    with that used in an earlier version 0.7.55.9.
 - The build script does NOT setup any web server, however it makes the process
   much easier.
 - Included in the package by my SlackBuild script are those helper scripts:
   1) op_initial_db.sh : script to initial overpass database. Requires osmium command line tool.
   2) op_ctl.sh: overpass control script.
   3) rc.dispatcher: starts and stops database manager; the "dispatcher" daemon program.
   4) op_make_areas.sh: script to build area objects in the database.
   5) op_update_db.sh: script for updating the overpass database.
   6) update_osm_file.sh: to keep region extract OSM data file updated with latest data.
   In addition a log rotation file is included "op_logrotate".

   All binaries are installed to "/usr/local/bin/" directory, usually this directory is included
   in users environment PATH, you may want to add it if it is not.

Thank you very much.

Wael Hammoudeh

September 11/2023

Next in this Guide is ["README-DATA.md"](README-DATA.md)
