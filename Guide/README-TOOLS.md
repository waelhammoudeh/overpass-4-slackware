**Tools And Workflow**

Now you have setup your own overpass server on your own machine, wondering how to
use it. We assume you want to learn how to write overpass queries, overpass query syntax is not complicated.
The hard part is acquiring the knowldge of how OSM is structured and stored in a database.

In this section of the Guide, I list some programs and applications that will aid in working
with your newly setup local overpass server. Tools include applications to visualize OSM data.
In the workflow section below; I include couple perl scripts and a C-program which will aid in
constucting overpass queries.

I assume you followed my Guide for setting up OSM overpass server in your system; including the Web interface setup.
External applications usage is beyound the scope of this document, please seek each application help system.

## Tools

### Tools included with Overpass software package:

 **osm3s_query:**

This program was mentioned in README-SETUP.md file - section:

```
 - Interactive mode: you enter your query statements in the terminal and end your input with "Ctrl D".
 - Batch mode: you write your query in a text file; like the example above then use shell redirection for input.
 - You can use c-programming comment style in your input file in batch mode - please see "test-first.op" and "test-area.op" files in the Guide.
 - You avoid network code / translation by using "osm3s_query" directly.
```

Write your query in a text file using your favorite text editor then save it to a file.
Assuming you have a query in a file named "myscript.op", query your server with "osm3s_query" command
using the following syntax:
```
 $ osm3s_query < myscript.op
```

The program will output query result to your terminal. Of course you can redirect that to a file as:

```
 $ osm3s_query < myscript.op > myscript_result.txt
```

The query result will be written to "myscript_result.txt" in your current directory.

Feel free to experiment with both modes of this program.

 **Query Form:**
I mentioned in README.SlackBuild file that I keep the "index.html" from an old version
of overpass source. With your complete setup - including WEB setup, typing "http://localhost/"
in your web browser address bar (location bar) should show this old index page. I refer to this old HTML page as [Local Overpass API.](images/op_index.png)

Included in this old "index.html" is the "Query and Convert Forms" and links to old documentations.
In the "Query" form, you can type your overpass query and submit it to your own server with the "Query" button.
The query answer will be stored in your "Downloads" directory in file named "interpreter" which gets an incremental number for each new query.

 **Transactions.log file:**
Your queries are saved in this file; if you forget or misplace a query you wrote, look for it in this file.


### Overpass Turbo

let me start by thanking all developers for their great product, that was a lot
of efforts. Probably most of you have used this web application already. The help
pages are great.

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
tags their values. Knowing those tags will help you construct better overpass query.

Another great function from JOSM is copying bounds for selected bounding box.
Under the download function the following tabs are available:
Slippy Map, Bookmarks, Bounding Box, Areas around places and Tile Numbers.

You highlight (set / choose) your bounding box under the "Slippy Map" tab using
your mouse, then go to "Bounding Box" tab and click on "Copy bounds" button.
Your bounding box will be copied to your clipboard. You can "paste" that into
other applications in your system including your terminal emulator or your favorite
text editor. The bounding box bounds are formatted as required by overpass.

### Well Known Text

Well, this is not a program but a standard for writting geometric entities as human
readable text.

WKT - for short; is an Open Geospatial Consortium (OGC) standard that is used to represent spatial
data in a textual format.

It is recognized and used by virually all GIS software including QGIS.

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

QGIS can open Shapefiles and accepts them in darg-and-drop operation. To add a layer
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
to disk with directories and filenames constucted as follows:

 $HOME/op_scripts/$PREFIX/$PREFIX.op  ===> overpass query template \
 $HOME/op_scripts/$PREFIX/$PREFIX_Bbox.csv ===> Well Know Text file for bounding box \
 $HOME/op_scripts/$PREFIX/$PREFIX_Bbox.shp ===> ESRI shapefile for Bounding box

This file system structure keeps all your overpass scripts in one directory named "op_scripts"
in your $HOME directory with sub-directory created for each PREFIX you use.

**View Nodes Walk-through:**

Let us try to find the intersection of Tatum & Shea Boulevards in north Phoenix.
Using overpass query the result will be a node or maybe nodes for roads intersection.

1) Utilize our handy-dandy (and dirty) "bbox2template.perl" script; we first select / set bounding box using JOSM:
    - selected bbox from JOSM: this is accessed through the "Download" function / button in JOSM.
    - from the "Slippy Map" tab, highlight bounding box to include our intersection. ===> [see image](images/tatSheaSelect1.png) \
      Note values fo selected bounding box is displayed as soon as we let go of the mouse on the status bar: \
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
    - ensure your query statements are correct and produce the desired result

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

6) See the result in QGIS using ESRI shapefiles produced from prevoius steps:
    - start new project in QGIS, then drag and drop the bbox shapefile (tatShea_bbox.shp) into window: [see image](images/seeBbox1.png)
    - bounding box is filled by solid color (default), we change the Fill color to "Transparent" by right-clicking over tatShea_Bbox
       layer in the Layer pan: [see image](images/seeBbox2.png)
    - the result after changing Fill color is shown in [see image](images/seeBbox3.png) \
    - next we drag and drop "tatShea_Point.shp" file to add another layer in QGIS project [see image](images/seePoints.png)
    - add OpenStreetMap as a new layer by double clicking on it in your "browser pan" of QGIS [see image](images/addMap1.png)
    - bounding box and points layer are underneath OpenStreetMap layer, move OpenStreetMap layer to the bottom by
      left-clicking and dragging  [see image](images/addMap2.png)

**View Geometry**

For geometry viewing; I use my C-program "geometry2wkt", the source code is included in directory "geometry2wkt" along with a makefile.
To build the program move to that directory and just run make which will produce "geoemtry2wkt" executable in that directory.

I use this program with saved query result as file. Program writes files to the same directory of its input file.

An example simple query with all generated files are in "example_skyCrossing" directory.

Overpass query used is this simple query below: (this is file: skyCrossing.op)

```
[out:json]
[bbox: 33.6832823,-112.0239615,33.6917275,-112.0028257];

 way[highway][name~"East Sky Crossing Way", i];

out qt geom;
```

To make bounding box file, use "bbox2template.perl" script; start script in a terminal then copy
the line below as its input:
```
33.6832823,-112.0239615,33.6917275,-112.0028257
```

Run query and save its result in "skyCrossing.geom" file:
```
 $ osm3s_query < ~/op_scripts/skyCrossing/skyCrossing.op > ~/op_scripts/skyCrossing/skyCrossing.geom
```

Move to the directory where you built "geoemtry2wkt" program; where the executable is in your system.

Next make files from saved geometry file using geometry2wkt program:

```
 $ cd ~/tools_workflow/geometry2wkt/    --- this is where geoemtry2wkt executable is found
 $ ./geometry2wkt ~/op_scripts/skyCrossing/skyCrossing.geom
```

Program "geometry2wkt" produces layers to show POINTS and LINESTRINGS.

[See Sky Crossing Bbox](images/skyCrossBbox.png)

[See Sky Crossing Linestring](images/skyCrossLinestring.png)

[See Sky Crossing Points](images/skyCrossPoints.png)

[See Sky Crossing All](images/skyCrossMap.png)

FIRST Draft dated 1/21/2024
