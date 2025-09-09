
## Migrate To Daily Planet Update

This file describes how to produce a new updated OSM regional extract file aligned
with planet server daily update using a regional extract from Geofabrik download
server. Planet servers issue daily change files at hour 00:00:00 UTC.

The new OSM data file and databases initialed from it can use **daily** change files
from planet OSM servers for updating to latest data. OSM planet server are at:

 - https://planet.openstreetmap.org/
 - https://planet.osm.org/

The times used in this file are always in UTC time.

### Requirements & Assumptions:

I assume the use of a recent regional extracts from Geofabrik as OSM data file.
The process described here will be applied to an extract **OSM datafile** fetched
from Geofabrik public or internal server. The newly produced OSM data file then
can be used to initial a new database, among other uses.

The region polygon (.poly) file is required. A region *.poly* file from Geofabrik is
shared between public and internal servers.

Required tools are:

 - Osmium: use my SlackBuild to install:
   https://github.com/waelhammoudeh/osmium-tool_slackbuild

 - Getdiff: My program to download change files:
   https://github.com/waelhammoudeh/getdiff

 - Work directory: create a work directory on your system name it whatever you want.
 Under this directory create directories: getdiff, logs, {regionDir} and sub-directory
 there {regionDir}/extract; output OSM data file is written to this last directory.

### Time Gap Issue:

For most regional extracts at Geofabrik, extracts are calculated daily usually between
the hours 20:00:00 - 21:00:00. Updating from Geofabrik server is not an issue since
change files are also calculated at the same time.

The planet daily change files are always issued or calculated at midnight (00:00:00 UTC).

To keep a complete set of data in our OSM data file, we need to collect change files
from planet server to cover the time period difference between Geofabrik and planet
servers and apply those changes to the data file.

### Collecting change files with getdiff:

We construct **one** range list consisting of minutely and hourly change files using
"getdiff" range function. The range function requires the sequence numbers for both
"begin" and "end" arguments. The program will be invoked twice; once to retrieve
minutely change files and the second time to retrieve hourly change files. If you
need to include daily change files, a third invocation will be required.

Any given range to "getdiff" must be 2 or more files! If you need only one file in any
range you will have to download 2 and manually edit the "rangeList.txt" file that
is written by "getdiff" to its work directory.

There is also a limit to how many files you can download in a single session. If
you have too many, you will have to break your range into two or more calls.

I suggest you write a table with two rows; one for minutes and one for hours with
"begin" and "end" heading in the next steps.

Keep in mind the timestamp value you see in "state.txt" file is for latest included
data in corresponding change file. Lets suppose your minute range ended at hour
21:00:00, you start your hour range at that time which ends at the next hour, so
your hour start timestamp in "state.txt" should show 22:00:00. In other words this
timestamp (22:00:00) in hourly "state.txt" file means that change file has data for
the time between 21:00:00 and 22:00:00 hours inclusive.

#### Setting minutely range:

  - Use "osmium fileinfo" on your Geofabrik extract, or check the Geofabrik page:
  "contains all OSM data up to …"

  - This timestamp is your start point.

  - On the planet server minute replication page: https://osm.org/replication/minute,
  locate the corresponding minutely change file and open its state.txt. Copy the
  sequence number ---> this is your "begin" for minute range.

  - Browse to the top of the NEXT hour on the same planet page, locate the corresponding
  minutely change file and open its state.txt. Copy the sequence number ---> this is
  your "end" for minute range.

  Write down your sequence numbers for "begin" and "end" minutely range in your table.

#### Setting hourly range:

  - Switch to hour page on planet server: https://osm.org/replication/hour

  - Your hourly "begin" time will be the timestamp in your minutely "end" state.txt
  file, locate the corresponding hourly change file and open its "state.txt" file
  to retrieve sequence number ---> this is your "begin" for hour.

  - The hourly "end" time will be at 00:00:00 UTC of the next day. Locate change
  file and its corresponding "state.txt" file to retrieve sequence number ---> this
  is your "end" for hour.

  Fill in your hour row in your table with begin and end sequence numbers.

#### Create "getdiff" directory:

  In your **work** directory create "getdiff" directory. In that directory create
  a new configuration file with the name "getdiff.conf" with following lines:

  ```
  # This is a brief getdiff.conf
  DIRECTORY = /path/to/{WORK}

  # replace "/path/to/{WORK}"  with real path to your work directory.
  ```

  The file is needed because most of you have "getdiff.conf" somewhere and we need
  to keep things seperate for you.

  save your changes to "getdiff.conf" file. This DIRECTORY setting tells "getdiff"
  to make its work directory at: {region}/getdiff. The program creates "planet"
  with "minute", "hour" and "day" sub-directories; that is where you can find the
  downloaded change files. A "geofabrik" directory entry is also created.

  We invoke "getdiff" with the following arguments from {WORK} directory:

    -c getdiff/getdiff.conf  ---> path to configure file to use
    -s https://planet.osm.org/replication/minute ---> source URL for planet minute (hour later)
    -b sequence_number ---> minute begin sequence number
    -e sequence_number ---> minute end sequence number

  $ getdiff -c getdiff/getdiff.conf -s https://planet.osm.org/replication/minute -b 6742364 -e 6742402

  The above command will download the minutely range files (change and state.txt).
  Find the files in: {region}/getdiff/planet/minute directory.

  The "getdiff" file we also write a sorted list of downloaded files to "rangeList.txt"
  file in its work directory: {region}/getdiff/rangeList.txt

  Now we do the second invocation to fetch the hourly range, we change the source
  and sequence numbers for begin & end:

  $ getdiff -c getdiff/getdiff.conf -s https://planet.osm.org/replication/hour -b 113511 -e 113513

  This command above downloads the hourly range change files and their corresponding
  state.txt files to: {region}/getdiff/planet/hour/ directory.

  The program also appends a sorted list of downloaded files to "rangeList.txt" file
  in its work directory.

  Check "getdiff.log" file in its work directory and inspect the produced "rangeList.txt"
  file, do not edit this file.

  In the commands above, I have used real sequence numbers for an extract file I had
  downloaded from Geofabrik. Below is the output from "osmium fileinfo" for that file:

```
wael@regrets:~$ osmium fileinfo /var/lib/overpass/sources/california-latest-internal.osm.pbf
File:
  Name: /var/lib/overpass/sources/california-latest-internal.osm.pbf
  Format: PBF
  Compression: none
  Size: 1387283693
Header:
  Bounding boxes:
    (-125.8935,32.48171,-114.1291,42.01618)
  With history: no
  Options:
    generator=osmium/1.15.0
    osmosis_replication_base_url=https://osm-internal.download.geofabrik.de/north-america/us/california-updates
    osmosis_replication_sequence_number=4525
    osmosis_replication_timestamp=2025-08-24T20:21:35Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2025-08-24T20:21:35Z
wael@regrets:~$
```

My commands above produced "rangeList.txt" file contents below:

```
/minute/006/742/364.osc.gz
/minute/006/742/364.state.txt
/minute/006/742/365.osc.gz
/minute/006/742/365.state.txt
/minute/006/742/366.osc.gz
/minute/006/742/366.state.txt
/minute/006/742/367.osc.gz
/minute/006/742/367.state.txt
/minute/006/742/368.osc.gz
/minute/006/742/368.state.txt
/minute/006/742/369.osc.gz
/minute/006/742/369.state.txt
/minute/006/742/370.osc.gz
/minute/006/742/370.state.txt
/minute/006/742/371.osc.gz
/minute/006/742/371.state.txt
/minute/006/742/372.osc.gz
/minute/006/742/372.state.txt
/minute/006/742/373.osc.gz
/minute/006/742/373.state.txt
/minute/006/742/374.osc.gz
/minute/006/742/374.state.txt
/minute/006/742/375.osc.gz
/minute/006/742/375.state.txt
/minute/006/742/376.osc.gz
/minute/006/742/376.state.txt
/minute/006/742/377.osc.gz
/minute/006/742/377.state.txt
/minute/006/742/378.osc.gz
/minute/006/742/378.state.txt
/minute/006/742/379.osc.gz
/minute/006/742/379.state.txt
/minute/006/742/380.osc.gz
/minute/006/742/380.state.txt
/minute/006/742/381.osc.gz
/minute/006/742/381.state.txt
/minute/006/742/382.osc.gz
/minute/006/742/382.state.txt
/minute/006/742/383.osc.gz
/minute/006/742/383.state.txt
/minute/006/742/384.osc.gz
/minute/006/742/384.state.txt
/minute/006/742/385.osc.gz
/minute/006/742/385.state.txt
/minute/006/742/386.osc.gz
/minute/006/742/386.state.txt
/minute/006/742/387.osc.gz
/minute/006/742/387.state.txt
/minute/006/742/388.osc.gz
/minute/006/742/388.state.txt
/minute/006/742/389.osc.gz
/minute/006/742/389.state.txt
/minute/006/742/390.osc.gz
/minute/006/742/390.state.txt
/minute/006/742/391.osc.gz
/minute/006/742/391.state.txt
/minute/006/742/392.osc.gz
/minute/006/742/392.state.txt
/minute/006/742/393.osc.gz
/minute/006/742/393.state.txt
/minute/006/742/394.osc.gz
/minute/006/742/394.state.txt
/minute/006/742/395.osc.gz
/minute/006/742/395.state.txt
/minute/006/742/396.osc.gz
/minute/006/742/396.state.txt
/minute/006/742/397.osc.gz
/minute/006/742/397.state.txt
/minute/006/742/398.osc.gz
/minute/006/742/398.state.txt
/minute/006/742/399.osc.gz
/minute/006/742/399.state.txt
/minute/006/742/400.osc.gz
/minute/006/742/400.state.txt
/minute/006/742/401.osc.gz
/minute/006/742/401.state.txt
/minute/006/742/402.osc.gz
/minute/006/742/402.state.txt
/hour/000/113/511.osc.gz
/hour/000/113/511.state.txt
/hour/000/113/512.osc.gz
/hour/000/113/512.state.txt
/hour/000/113/513.osc.gz
/hour/000/113/513.state.txt
```

### Script "extract2planet.sh":

The script "extract2planet.sh" (in the scripts directory) uses the range list made
above to produce an updated OSM extract data file, script usage:

```
    extract2planet.sh <data_file> <poly_file> <list_file>
        <data_file>: recent region extract from Geofabrik.de
        <poly_file>: region polygon (.poly) file, available from Geofabrik site.
        <list_file>: range list file "rangeList.txt" produced by getdiff.
```

The data file is your region OSM data file from Geofabrik that was used to construct
the range list above. The poly file is from Geofabrik for your region, again those
are the same file for public and internal servers. The list file is the range list
file produced by getdiff above.

This script uses functions from "common_functions.sh" file, place both this script
and "common_functions.sh" files in the same directory.

**Change regionName** in the script to your own region name.

The script writes the new OSM data file to {region}/extract directory, which you
need to create. The new data file will have the same name as the original data
file name with an appended date (from last state.txt) separated by an underscore
character. Please do **NOT use underscore** in your original data file name.

I suggest the following file system structure:

{WORK_DIR}
    |---getdiff
    |---logs
    |---scripts
    |---region
           |---extract


Create and name {WORK_DIR} any where you want, replace region above with your own
region name. Place the script and "common_functions.sh" under "scripts" directory.
The script file needs to set executable, use "chmod +x" for that.

The new produced OSM extract data file can be used to initialize databases including
overpass database.

Hope someone will find this helpful, good luck to all of you.

Wael Hammoudeh

September 8, 2025




