**Tools And Workflow**

Now you have setup your own overpass server on your own machine, wondering how to
use it. We assume you want to learn how to write overpass queries, overpass query syntax is not complicated.
The hard part is acquiring the knowledge of how OSM is structured and stored in a database.

In this section of the Guide, I list some programs and applications that will aid in working
with your newly setup local overpass server. Tools include applications to visualize OSM data.
In the workflow section below; I include couple Perl scripts and a C-program which will aid in
constructing overpass queries.

I assume you followed my Guide for setting up OSM overpass server in your system; including the Web interface setup.
External applications usage is beyond the scope of this document, please seek each application help system.

## Tools

### Tools included with Overpass software package:

 **osm3s_query:**

This program was mentioned in README-SETUP.md file - section; this is the most important
tool you have in your tool box, it is the most direct connection to your overpass server.

To get the program full usage pass it an '-h' as argument:

```
wael@yafa:~$ osm3s_query -h
Unknown argument: -h

Accepted arguments are:
  --db-dir=$DB_DIR: The directory where the database resides. If you set this parameter
        then osm3s_query will read from the database without using the dispatcher management.
  --dump-xml: Don't execute the query but only dump the query in XML format.
  --dump-pretty-ql: Don't execute the query but only dump the query in pretty QL format.
  --dump-compact-ql: Don't execute the query but only dump the query in compact QL format.
  --dump-bbox-ql: Don't execute the query but only dump the query in a suitable form
        for an OpenLayers slippy map.
  --clone=$TARGET_DIR: Write a consistent copy of the entire database to the given $TARGET_DIR.
  --clone-compression=$METHOD: Use a specific compression method $METHOD for clone bin files
  --clone-map-compression=$METHOD: Use a specific compression method $METHOD for clone map files
  --clone-file=$FILENAME: Restrict cloning to the given file name (provided without directories).
  --rules: Ignore all time limits and allow area creation by this query.
  --request=$QL: Use $QL instead of standard input as the request text.
  --quiet: Don't print anything on stderr.
  --concise: Print concise information on stderr.
  --progress: Print also progress information on stderr.
  --verbose: Print everything that happens on stderr.
  --version: Print version and exit.
wael@yafa:~$
```

As you can see there are a lot of commands and options for this program. Our main usage
for "osm3s_query" is to query overpass server, if started with no argument, it will prompt
the user for her / his query:

```
wael@yafa:~$ osm3s_query
encoding remark: Please enter your query and terminate it with CTRL+D.

```
You may enter your query line by line here and terminate your query with Ctrl D. I call this
the "interactive mode".

There is also a "patch mode", where you type your whole query in a text file with your
favorite text editor then pass the name of your saved file to it using shell redirection.
So lets assume you entered this query and saved it in a file named "tempeBorder.op":

```
[out:json];

  area[name="Maricopa County"];
  relation [name="Tempe"][type="boundary"](area:3600110833);

out geom;
```

assuming your "tempeBorder.op" file is in your current directory, you can query your
local overpass server with this command:

```
 $ osm3s_query < tempeBorder.op

```
the less than character '<' is a shell redirection, this changes "osm3s_query" input
from standard in (terminal) to your named file.

You then hit the "Enter" key on your keyboard to execute the query script.

The program "osm3s_query" will look for what you asked it for in your database, then answers
you on your terminal. This script will output almost 700 lines to your terminal which you can
use your "pager" to see one screen-full at a time as:

```
 $ osm3s_query < tempeBorder.op | more

```
My preferred way is to save the output to a file using shell redirection as:

```
 $ osm3s_query < tempeBorder.op > tempeBorder.raw

```
we use the greater than sign '>' to redirect the standard output to a named file; in
this case "tempeBorder.raw".

In the example above - and ones that follow - we do not use any of "osm3s_query"
options. But lets look at the the description for its "--db-dir" option:
```
  --db-dir=$DB_DIR: The directory where the database resides. If you set this parameter
        then osm3s_query will read from the database without using the dispatcher management.
```
This means you are allowed to have more than one database on one system, and be able
to query any one of them at anytime as long as you specify the database directory.
This opens up possibilities and options for overpass databases initialed from an extract
for limited area or region. This is powerful my friends.

**Note** that I use the extension ".op" for overpass query script files and ".raw" extension
for the unmodified (untreated or unaltered) query result. Those extensions are not required
but keep things clear to myself - you may use whatever you want.

Feel free to experiment with other commands for this program.

 **Query Form:**
I mentioned in README.SlackBuild file that I keep the "index.html" from an old version
of overpass source. With your complete setup - including WEB setup, typing "http://localhost/"
in your web browser address bar (location bar) should show this old index page. I refer to this old HTML page as [Local Overpass API.](images/op_index.png)

Included in this old "index.html" is the "Query and Convert Forms" and links to old documentations.
In the "Query" form, you can type your overpass query and submit it to your own server with the "Query" button.
The query answer will be stored in your "Downloads" directory in file named "interpreter" which gets an incremental number for each new query.

 **Transactions.log file:**
 This log file can be qualified as a tool, your queries are saved in this file; if you
 forget or misplace a query you wrote, look for it in this file.


### Overpass Turbo

let me start by thanking all developers for their great product, that was a lot
of efforts. Probably most of you have used this web application already. The help
pages are great.

The "Data" tab next to the "Map" tab in the upper-right corner gives access to query
result.

One thing I would like to mention here is that under the "Settings" you can set
it to query your local server; use this URL for Server:  "http://localhost/api/"
This should work provided that you followed my Guide for Web setup.

### JOSM:  Java OpenStreetMap Editor

This Java application is used to edit OSM data and more,
Slackware package is available on [SlackBuild site](https://slackbuilds.org/)

JOSM enables you to see OSM data in details.
To see those details you work with small area (bounding box). Small as few square street
blocks, in yards or meters about 200 - 500 maximum. Downloading small area enables
you to zoom in to the object you are interested in, clicking on the object you can view its
tags and their values. Knowing those tags will help you construct better overpass query.

Another great function from JOSM is copying bounds for selected bounding box.
Under the download function the following tabs are available:
Slippy Map, Bookmarks, Bounding Box, Areas around places and Tile Numbers.

You highlight (set / choose) your bounding box under the "Slippy Map" tab using
your mouse, then go to "Bounding Box" tab and click on "Copy bounds" button.
Your bounding box will be copied to your clipboard. You can "paste" that into
other applications in your system including your terminal emulator or your favorite
text editor. The bounding box bounds are formatted as required by overpass.

### Well Known Text

Well, this is not a program but a standard for writing geometric entities as human
readable text.

WKT - for short; is an Open Geospatial Consortium (OGC) standard that is used to represent spatial
data in a textual format.

It is recognized and used by virtually all GIS software including QGIS.

Well Known Text format is human readable text format for basic geometric entities.
The standard is used by many GIS software, data can be shared among different
applications on different platforms.
The standard defines format for POINT, LINESTRING, POLYGON and more.

Two or three dimensional POINTs are supported, we only use two dimensional points here.
Some examples of Well Known Text format:

"POINT(-112.2265165 33.6669231)" \
The line above is for GPS point with longitude = -112.2265165 and latitude = 33.6669231.

"LINESTRING(-112.2353197 33.6438651,-112.2371329 33.6396803,-112.2376582 33.6384689)" \
The line above is for the line with 3 GPS points with (longitude, latitude) pair below: \
(-112.2353197, 33.6438651) \
(-112.2371329, 33.6396803) \
(-112.2376582, 33.6384689)

"POLYGON((-112.276840  33.573581, -112.276840  33.667354, -112.221565  33.667354, -112.221565  33.573581, -112.276840  33.573581))" \
The line above is for a Bounding Box. Notice the double parentheses and a Polygon
is closed with last point is equal to first point. The four corners of the bounding box are: \
(-112.276840, 33.573581) \
(-112.276840, 33.667354) \
(-112.221565, 33.667354) \
(-112.221565,  33.573581)

GIS software support only one geometry type (or entity)  per layer; each WKT file has only one
geometry type for this reason. We can not mix POINT and LINESTRING in one file.

For QGIS files with Well Known Text are expected to have ".csv" file extension, other applications
may use a different extension.

See [this guide](https://mapscaping.com/a-guide-to-wkt-in-gis/) for more information about Well Known Text.

### QGIS

A Free and Open Source Geographic Information System.
For visualizing your map data install this priceless free application.
Slackware package is available on [SlackBuild site](https://slackbuilds.org/)

QGIS and WKT:
Well Known Text can be added as a layer in QGIS. QGIS expects the file name to end
with ".csv" extension and the file must contain ONLY one geometric feature (entity).
You can not mix POINT with LINESTRING in a layer. To add a layer in QGIS start from
the top menu:
```
 Layer --> Add Layer --> Add Delimited Text Layer ...
```

you then enter file name or browse to your file with Well Known Text in the Dialog box.

### GDAL library

This is a required package for QGIS, you will install it before QGIS.
This library has the program named "ogr2ogr", which converts from one map data format to
another. You will be able to convert your WKT file to ESRI Shapefile format.

QGIS can open Shapefiles and accepts them in drag-and-drop operation. To add a layer
from a shapefile you just drop it into an open QGIS session. You can also pass shapefiles
to QGIS on startup; for example:
```
 $ qgis point.shp linestring.shp
```
will start QGIS with two layers from "point.shp" and "linestring.shp" files.

## Workflow

Overpass queries have settings which are optional; they all have default values.
Specifying a setting overrides its default value. Among the settings are output format specification and bounding box settings.
See the "Output Formats" link in your [Local Overpass API.](images/op_index.png)
The bounding box is the rectangle area for your query and is specified with its South-West and its North-East GPS points.

I use bounding box in my overpass queries - no polygons or areas. The output sometimes are nodes other times are geometries.
I realized I could use those two preset "TEMPLATES" for my queries.

Request nodes settings:
```
[out:csv(::lon, ::lat,::count)]
[bbox: 33.3998111,-111.9272947,33.4082661,-111.9148064];

  query statements here

out; out count;
```

Request geometry settings:
```
[out:json]
[bbox: 33.3894562,-111.9307709,33.4094483,-111.9069099];

  query statements here

out qt geom;
```

The Perl script named "bbox2template.perl" produces the templates above and WKT file
for the bounding box, a shapefile is produced if 'ogr2ogr' program is found in the system.

Note that the script - as is - produces ONE template form at a time, uncomment and edit the 2 marked lines for the
other template, or better yet write your own script in your favorite language.

Use the script as follows:

 - Select and copy your bounding box bounds from JOSM editor.
 - Start the script in your terminal emulator
 - Paste your clipboard contents (bbox bounds) into your terminal emulator.

If the script was started with filename 'PREFIX' argument, files will be written
to disk with directories and filenames constructed as follows:

 $HOME/op_scripts/$PREFIX/$PREFIX.op  ===> overpass query template \
 $HOME/op_scripts/$PREFIX/$PREFIX_Bbox.csv ===> Well Know Text file for bounding box \
 $HOME/op_scripts/$PREFIX/$PREFIX_Bbox.shp ===> ESRI shapefile for Bounding box

This file system structure keeps all your overpass scripts in one directory named "op_scripts"
in your $HOME directory with sub-directory created for each PREFIX you use.

This script does not do any error checking, if you use it, it is your responsibility to hand it the correct
input, for this "bbox2template.perl" the correct input is the well formatted bounding box bounds.
It is crucial to check what you paste in your terminal as input for this script.

**View Nodes Walk-through:**

Let us try to find the intersection of Tatum & Shea Boulevards in north Phoenix.
Using overpass query the result will be a node or maybe nodes for roads intersection.

1) Utilize our handy-dandy (and dirty) "bbox2template.perl" script; we first select / set bounding box using JOSM:
    - selected bbox from JOSM: this is accessed through the "Download" function / button in JOSM.
    - from the "Slippy Map" tab, highlight bounding box to include our intersection. ===> [see image](images/tatSheaSelect1.png) \
      Note values for selected bounding box is displayed as soon as we let go of the mouse on the status bar: \
      33.5783365,-111.9872904,33.5900273,-111.9686651

    - from the "Bounding Box" tab, click on "Copy bounds" button. ===> [see image](images/tatSheaSelect2.png) \
      Note that in this "Bounding Box" tab: values are already filled and
      the status bar in the bottom of the view (to the right of the four squares) shows the SAME
      selected bounding box values from "Slippy Map" tab above: \
      33.5783365,-111.9872904,33.5900273,-111.9686651

2) In a terminal window, move to "perl_scripts" directory (where our script lives):
  - start the script with "tatShea" argument (our filename prefix) ===> [see image](images/tatSheaScript1.png) \
    we use tatShea argument to let script create files for us.
  - Click with your mouse on your terminal window and paste bbox value as input to script ===> [see image](images/tatSheaScript2.png) \
    make sure values pasted are the same as selected bounding box from JOSM.
  - hit the enter key after checking bbox bounds values [see image](images/tatSheaScript3.png) \
    This creates overpass query template file and bbox WKT file, if ogr2ogr was found, it also creates ESRI shapefile.

3) Open query template file using your text editor [see image](images/tatSheaEditOp1.png)
    - move back to JOSM editor, Download the area, then zoom to see road names [see image](images/tatSheaTagsView.png) \
      in the map area click on either "North Tatum Boulevard" or "East Shea Boulevard" and note that tags pan
      changes and loads tags and their values for your selected object, one tag named "highway" has a value "primary"
      we use that in our query construct.
  - we continue with our text editor and write overpass query statements in the three lines shown [see image](images/tatSheaEditOp2.png)

4) Query your local overpass server using osm3s_query command line tool ===> [see image](images/tatSheaRunOp1.png)
    - ensure your query statements are correct and produce the desired result as shown below:

```
    wael@yafa:~/overpass-4-slackware/Guide/examples/tatShea$ osm3s_query < tatShea.op
    encoding remark: Please enter your query and terminate it with CTRL+D.
    runtime remark: Timeout is 180 and maxsize is 536870912.
    @lon	@lat	@count
    -111.9780030	33.5826085
    -111.9778160	33.5827762
    -111.9778180	33.5826085
    -111.9780030	33.5827763
    		4
    wael@yafa:~/overpass-4-slackware/Guide/examples/tatShea$
```

  This result starts with the line: "@lon	@lat	@count" that is the header we specified
  in our query setting. This header line is followed by formatted longitude and latitude
  values for found nodes and the last line shows the number 4 which is the "count" we
  asked for to be included in the output.

  Like any program or script, developing overpass script will require editing and trying
  multiple times to get the desired result.

  Before you continue to the next step, ensure you have the result shown above.

5) Utilize our second dirty perl script "gps2wkt.perl" to format the result as Well Known Text
    and make ESRI shapefile for query result.
    - Script "gps2wkt.perl" formats its input to WKT POINT and outputs the result to the terminal, pipe
      the query result into "gps2wkt.perl" script as:
      ```
       wael@yafa:~/op_scripts/tatShea$ osm3s_query < tatShea.op | ~/perl-scripts/gps2wkt.perl
      ```
      If successful, your WKT file will be written to your terminal.

    - To have "gps2wkt.perl" script write WKT and shapefile files; we give it a filename prefix as
       argument with filename, use the same filename prefix used with creating template  (that was "tatShea")
       to have files written to the same directory. So after a successful run above without the PREFIX, we run
       the script again with filename PREFIX (tatShea) to have it write files for us.
       ```
       wael@yafa:~/op_scripts/tatShea$ osm3s_query < tatShea.op | ~/perl-scripts/gps2wkt.perl tatShea
       encoding remark: Please enter your query and terminate it with CTRL+D.
       runtime remark: Timeout is 180 and maxsize is 536870912.
       wkt;
       "POINT (-111.9780030 33.5826085)"
       "POINT (-111.9778160 33.5827762)"
       "POINT (-111.9778180 33.5826085)"
       "POINT (-111.9780030 33.5827763)"
       /home/wael/perl-scripts/gps2wkt.perl: Wrote POINT WKT to file /home/wael/op_scripts/tatShea/tatShea_Point.csv
       /home/wael/perl-scripts/gps2wkt.perl: Wrote POINT ESRI shapefile to file /home/wael/op_scripts/tatShea/tatShea_Point.shp
       ```
    - on success, "gps2wkt.perl" script tells you what file it wrote. The two commands above are run one after another. [see image](images/tatSheaRunOp2.png)

    This "gps2wkt.perl" script, does not perform any error checking, it is your responsibility
    to check for the correct input for this script. This is why I called both Perl scripts "dirty".

6) See the result in QGIS using ESRI shapefiles produced from previous steps:
    - start new project in QGIS, then drag and drop the bbox shapefile (tatShea_bbox.shp) into window: [see image](images/seeBbox1.png)
    - bounding box is filled by solid color (default), we change the Fill color to "Transparent" by right-clicking over tatShea_Bbox
       layer in the Layer pan: [see image](images/seeBbox2.png)
    - the result after changing Fill color is shown in [see image](images/seeBbox3.png)
    - next we drag and drop "tatShea_Point.shp" file to add another layer in QGIS project [see image](images/seePoints.png)
    - add OpenStreetMap as a new layer by double clicking on it in your "browser pan" of QGIS [see image](images/addMap1.png)
    - bounding box and points layer are underneath OpenStreetMap layer, move OpenStreetMap layer to the bottom by
      left-clicking and dragging  [see image](images/addMap2.png)

**View Geometry**

For geometry viewing; I use my C-program "geometry2wkt", the source code is included in
the "Guide" directory in sub-directory named "geometry2wkt" along with a makefile.
To build the program move to that directory and just run make which will produce
"geoemtry2wkt" executable in that directory.

Program usage:
```
 $ geoemtry2wkt [file ...]
```

Program description:
Program reads its 'file' argument (or a list of files) for geometry result returned by
overpass query.  Program parses query result, formats geometry into Well Known
Text as POINT and as LINESTRING then writes those to two separate files.  WKT file
names are formed from the 'file' argument by first dropping its extension - when present -
then appending "_Point.csv" for WKT file with POINT  and "_Linestring.csv" for WKT file
with LINESTRING. Program calls "ogr2ogr" to convert WKT files to ESRI shapefile if it is
found in the usual path "/usr/bin/ogr2ogr", those will be named as WKT files but with
".shp" file name extension.

When given a file list as arguments, each file gets its own set of output files.

If 'file' argument was omitted, program reads its standard input and writes formatted
WKT for LINESTRING only to standard output and exits.

End program description.

Lets talk about this program for just a little bit. It reads a text file, parses this text
into a GEOMETRY structure, then formats this GEOMETRY structure as Well Known Text
once as POINT and once more as LINESTRING. Program then writes those files to
disk in the same directory where its input file came from. Afterword it calls on
another program in the system - if present - to convert WKT files it has just wrote
into ESRI shapefiles. That is a lot of work! You don't need to concern yourself
about how hard the poor little thing works! It must like what it does.

What you need to know is that it produces a whole lot of files that will
eat up your disk space, the sneaky little thing is wasting your hard disk space.
But you want to use it anyway because you like to see the curved lines, rectangles
triangles and circles it can produce.

Program "geometry2wkt" will read its standard input when started with no argument.
This means it can be used in combination with other programs in a pipe. We used
pipe when we first initialed Overpass database, piping is used also in "op_update_db.sh"
script, pipe usage is very common in Unix / Linux world.

To save your disk space and yourself some grief, use "geometry2wkt" program
in a pipe along with your query for one thing, another thing is stay organized by using
sensible file names for your queries, notice all related files will be placed in one
directory for easier maintenance - delete unwanted files very often.

To demonstrate pipe usage for "geometry2wkt" program; we will use the query in file "skyCrossing.op"
found in "examples/skyCrossing/" directory and assuming "geometry2wkt" is in our current directory:

```
 $  osm3s_query <  ../examples/skyCrossing/skyCrossing.op | ./geoemtry2wkt
```

this command will produce the file with Well Known Text for LINESTRING only, the file will be
written to the terminal. We then use redirection to save this to a disk file:
```
 $  osm3s_query <  ../examples/skyCrossing/skyCrossing.op | ./geoemtry2wkt > ../examples/skyCrossing/skyCrossing.csv
```
this will write "skyCrossing.csv" file with WKT for LINESTRING to our specified directory.

You can use this file to add a new layer in QGIS to view your result as mentioned in QGIS
section above. Add a layer in QGIS start from the top menu:
```
 Layer --> Add Layer --> Add Delimited Text Layer ...
```
and use "skyCrossing.csv" as the source file. Or you can use "ogr2ogr" to convert this
file to shapefile. But you need to practice adding a layer in QGIS from WKT files, a skill
you need to acquire, besides QGIS is good at dealing with WKT files. One more thing,
do not moan about a long command! This is redirection and pipe, use your shell
"tab completion" to write the long command line.

Make all files with geometry2wkt:

The program "geometry2wkt" will write WKT files for POINT and LINESTRING and their
corresponding shapefiles when given the file name with geometry query result.

We will use the same query we used above, here is the source for the query:

```
[out:json]
[bbox: 33.6832823,-112.0239615,33.6917275,-112.0028257];

 way[highway][name~"East Sky Crossing Way", i];

out qt geom;
```

Note that in the setting - first line - and in our "out" statement - last line, we
request geometry output from overpass server.

We save the query result in a file first. Change directory to that of query source
file; that is "Guide/examples/skyCrossing/" and then run the query with
redirection for output as:

```
 $ osm3s_query < skyCrossing.op > skyCrossing.raw
```

this command will write the query result to file "skyCrossing.raw". We pass this file
as argument when calling "geometry2wkt" program.

This program is not in our environment PATH, we need to use full path to the program
to use it, or change directory to where it is at, assume we decided on the later and
have moved to its directory:
```
 $ ./geoemtry2wkt ../examples/skyCrossing/skyCrossing.raw
```
the above command produced the following output on my system ( your paths might be different):
```
wael@yafa:~/overpass-4-slackware/Guide/geometry2wkt$ ./geometry2wkt ../examples/skyCrossing/skyCrossing.raw
geometry2wkt: Wrote geometry POINT WKT file to: /home/wael/overpass-4-slackware/Guide/examples/skyCrossing/skyCrossing_Point.csv
geometry2wkt: Converted WKT file to shapefile: /home/wael/overpass-4-slackware/Guide/examples/skyCrossing/skyCrossing_Point.shp
geometry2wkt: Wrote geometry LINESTRING WKT file to: /home/wael/overpass-4-slackware/Guide/examples/skyCrossing/skyCrossing_Linestring.csv
geometry2wkt: Converted WKT file to shapefile: /home/wael/overpass-4-slackware/Guide/examples/skyCrossing/skyCrossing_Linestring.shp
wael@yafa:~/overpass-4-slackware/Guide/geometry2wkt$
```

Now this program will produce files in the same directory of its argument as follows:
  - skyCrossing_Point.csv : Well Known Text for POINT
  - skyCrossing_Linestring.csv : Well Known Text for LINESTRING

If you have the program "ogr2ogr" on your system, you will get shapefile and its related files also:
  - skyCrossing_Point.shp : ESRI Shapefile for POINT
  - skyCrossing_Linestring.shp : ESRI Shapefile for LINESTRING

Note that I did not list ".dbf", ".prj" and ".shx" produced files in shapefile ".shp" convesion
call to "ogr2ogr" program, those files are required if you want to view your shapefiles with
QGIS, so do not delete any of those files yet.

Program "geometry2wkt" produced layers to show POINTS and LINESTRINGS are illustrated in the following images:

[See Sky Crossing Bbox](images/skyCrossBbox.png)

[See Sky Crossing Linestring](images/skyCrossLinestring.png)

[See Sky Crossing Points](images/skyCrossPoints.png)

[See Sky Crossing All](images/skyCrossMap.png)

Unlike my "dirty" Perl scripts, program "geometry2wkt" does some error checking,
it is not perfect, but program will let you know the reason it failed when it does. For
example if given non-geometry file, "geometry2wkt" will let you know that the input
file was not for geometry file. Another common error is a query result that does not
include any geometry, to show this case I have included an overpass query with an
error - to force this situation - in the "alameda" sub-directory under "examples". The
query in file "alameda-NoGeometry.op" is the trouble query; when run it produces
zero geometry result as shown below:

```
wael@yafa:~$ cd ~/overpass-4-slackware/Guide/examples/alameda/
wael@yafa:~/overpass-4-slackware/Guide/examples/alameda$ osm3s_query < alameda-NoGeometry.op
encoding remark: Please enter your query and terminate it with CTRL+D.
runtime remark: Timeout is 180 and maxsize is 536870912.
{
  "version": 0.6,
  "generator": "Overpass API 0.7.61.8 b1080abd",
  "osm3s": {
    "timestamp_osm_base": "2024-01-27T21:21:15Z",
    "copyright": "The data included in this document is from www.openstreetmap.org. The data is made available under ODbL."
  },
  "elements": [



  ]
}
wael@yafa:~/overpass-4-slackware/Guide/examples/alameda$

```

Piping this result to "geometry2wkt" program will produce:

```
wael@yafa:~/overpass-4-slackware/Guide/examples/alameda$ osm3s_query < alameda-NoGeometry.op | geometry2wkt
encoding remark: Please enter your query and terminate it with CTRL+D.
runtime remark: Timeout is 180 and maxsize is 536870912.
geometry2wkt: Error failed parseGeometry()
 Returned code: <ztNoGeometryFound>
geometry2wkt: Program is exiting with error code: <ztNoGeometryFound>
 This code is for: <Query result has zero geometry. No geometry was found by query script.>
wael@yafa:~/overpass-4-slackware/Guide/examples/alameda$
```

As shown above, the program returned "ztNoGeometryFound" error code on exit. The error
code is also explaied in the program output above with line starting "This code is for:".

A lot can be added about this program, but this is not the time for that now. You can use it
on your own to understand OSM data structures, try to use "writeSegmentWktByNum" function
with small geometry return - use "alameda.op" query example.

Conclusion:

We showed many tools to use with local installed overpass server, in summary we note:

  - The main tool is "osm3s_query" which comes from the developers of the software.

  - Free and well advanced tools are available to use. Some packages installation is not
    easy, but worth the effort.

  - Knowledge of standards for Geographic Computer Information is helpful.

  - A certain knowledge level for Linux / Unix usage is required; not advanced but include:

    1) Input / output redirection
    2) Piping, use output from one program as input for another
    3) Disk usage to keep an eye on ones hard disk space.

  - Silly and simple scripts can be used as tools.

  - Program "geometry2wkt" was introduced to view query result.

To close, we will use our "tools" to see the result for the query we opened this document
with to visualize the city boundary for Tempe, Arizona. The images are produced with two
commands; first get query result in a file (tempeBorder.raw):

```
wael@yafa:~/overpass-4-slackware/Guide/examples/tempeBorder$ osm3s_query < tempeBorder.op > tempeBorder.raw
encoding remark: Please enter your query and terminate it with CTRL+D.
runtime remark: Timeout is 180 and maxsize is 536870912.
wael@yafa:~/overpass-4-slackware/Guide/examples/tempeBorder$
```

the second command is to turn this "tempeBorder.raw" into WKT and shapefiles with:

```
wael@yafa:~/overpass-4-slackware/Guide/examples/tempeBorder$ geometry2wkt tempeBorder.raw
geometry2wkt: Wrote geometry POINT WKT file to: /home/wael/overpass-4-slackware/Guide/examples/tempeBorder/tempeBorder_Point.csv
geometry2wkt: Converted WKT file to shapefile: /home/wael/overpass-4-slackware/Guide/examples/tempeBorder/tempeBorder_Point.shp
geometry2wkt: Wrote geometry LINESTRING WKT file to: /home/wael/overpass-4-slackware/Guide/examples/tempeBorder/tempeBorder_Linestring.csv
geometry2wkt: Converted WKT file to shapefile: /home/wael/overpass-4-slackware/Guide/examples/tempeBorder/tempeBorder_Linestring.shp
wael@yafa:~/overpass-4-slackware/Guide/examples/tempeBorder$
```

Enjoy.

Wael Hammoudeh

Edited 1/29/2024
