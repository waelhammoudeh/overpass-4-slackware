
## Regional Extract And Daily Planet Change Files

In this file, I explain how to use OSM planet daily change files to update a regional
extract data file and then produce a daily change file for that regional extract.

In this process we first align an extract OSM data file with **planet timing** for
daily change files production time which is at midnight UTC daily, the change files
are calculated from two extract OSM data files. The change files produced can be
used to update databases initialized from the aligned extract OSM data file.

The method described here is used when we do not have access to planet data file
or the resources to process the planet data file.

### Requirements:

I assume the use of a recent regional extracts from Geofabrik as OSM data file.
Any extract OSM data file can be used as long as you know the timestamp for last
included data in your file, use "osmium fileinfo -e" for that. Requirements are:

 - The region polygon (.poly) file. A region *.poly* file from Geofabrik is shared
 between public and internal servers.

 - Osmium: use my SlackBuild to install on Slackware64 system:
   https://github.com/waelhammoudeh/osmium-tool_slackbuild

 - Getdiff: My program to download change files:
   https://github.com/waelhammoudeh/getdiff

### Environment Setup:

Two bash scripts are provided to achieve this goal:

  - extract2planet.sh
  - mk_regional_osc.sh

Also included is "common_functions.sh" file; functions are used by both scripts.

The scripts expect the following directory structure:

<pre>

{WORK_DIR}
    |---getdiff
    |---logs
    |---scripts
    |---region
           |---extract
           |---replication

</pre>

Create a work directory on your system name it whatever you want. From that directory
create the file system structure above with:

```
  $ mkdir -p getdiff logs scripts region/{extract,replication}
```

Place scripts and "common_functions.sh" file in the scripts directory; scrpits use
functions from this file and need to be in the same directory.

For illustrations through out this README, I have created "extract-wd" directory
in my home directory and placed my extract data file "arizona-internal.osm.pbf"
under "region/extract/" directory.

---

For the purpose of this subject one needs to know few definition and understand few
terms presented here in a very short and simplified way.

**Change Files:** Change file is the difference between two OSM data files from two
different points in time. Merging the change file with the older data file results in the
newer data file.

When a new change file is calculated; it is assigned a **timestamp** and a unique
**replication sequence number** (sequence number for short) written to a
corresponding "state.txt" file. Given one variable, to retrieve the other variable
we look in the "state.txt" file for that.

Planet change files are calculated for three different time intervals (called Granularity),
those are minutely, hourly and daily change files calculated at the top of each time period.

**Timestamp and Change file:** We know that each element in OSM file has its own
timestamp, the **file timestamp** indicates that it includes elements with
**up to that timestamp.** Change files cover a defined period of time; has **start**
and **end** time. The **file timestamp** is always the **end time**.
The implied **start time** in **minutely** change file is **one minute before**
its end time, for an **hourly** change file it is **one hour before** its end time,
and for a daily change file the implied starting time is **one day before** its
end time.

**Sequence Number and Change File:** Formally called "replication sequence number" is
a unique number assigned to change file when calculated **by replication service provider.**
For planet change files; sequence numbers are different for each Granularity, which
must be given with each sequence number. Geofabrik sequence numbers are for daily
change files from Geofabrik only. Sequence number is an integer 9 digits or less long.

Timestamps and sequence numbers can be used to locate change file on replication servers.

**Locate Change File By Timestamp:** Files are placed into directory hierarchy on
replication service provider sites. Starting from the top directory we traverse file
system hierarchy using the "Last Modified" time for directory entries and our
timestamp (consider directory "Last Modified" time as its closing time). One way
to do that is locate the closest "Last Modified" time to our timestamp, if this closest
"Last Modified" time is after our timestamp then we look in that directory - we made
it before its closing time. If "Last Modified" time is before our timestamp - we
missed that directory closing time - we look in the next directory up to that with
closest "Latest Modified" time.

**Locate Change File By Sequence Number:** Sequence numbers are used to store files
on disks. The following scheme is used to store change files on disks by converging
sequence number to file system structure:

sequence number is placed into a nine-digit long field padded with leading zeros,
the string is then split into 3 fields 3 character each, three slashes are inserted
starting from the left:

 <pre>
    sequence #    # 0s  123456789      separate 3x3  insert slashes

     6756477 ---> (7+2) 006756477 ---> 006 756 477   /006/756/477
      113123 ---> (6+3) 000113123 ---> 000 113 123   /000/113/123
        4537 ---> (4+5) 000004537 ---> 000 004 537   /000/004/537
</pre>

last we append extensions (.osc.gz & .state.txt) to form change file and its corresponding
state.txt file names:

<pre>
     string               change file           state.txt file

   /006/756/477 ---> /006/756/477.osc.gz and /006/756/477.state.txt
   /000/113/123 ---> /000/113/123.osc.gz and /000/113/123.state.txt
   /000/004/537 ---> /000/004/537.osc.gz and /000/004/537.state.txt
</pre>

**Extract OSM Data File Info:** OSM data files contain meta information about the
file. We use **"osmium fileinfo"** to retrieve and view this information, using
the --extended (-e) option with the command gives more information.
Man osmium-fileinfo for its full usage.

Using my extract data file, selected and important lines from "osmium fileinfo -e "
are shown and explained below:

<pre>
File:
  Name: region/extract/arizona-internal.osm.pbf

Header:
    osmosis_replication_base_url=https://osm-internal.download.geofabrik.de/north-america/us/arizona-updates
    osmosis_replication_sequence_number=4535
    osmosis_replication_timestamp=2025-09-03T20:20:35Z

    timestamp=2025-09-03T20:20:35Z

Data:

  Timestamps:
    First: 2007-08-10T17:38:36Z
    Last: 2025-09-03T20:00:57Z

</pre>

 - Name: file name given in the command line

 - base_url: the URL update page for the file

 - sequence_number: sequence number for **last included** change file, start update from
 **next** sequence number; more about this below.

 - timestamp: **(Header)** extract calculation time; extract includes data
 **up to this timestamp** use this timestamp as starting point to bring your
 extract OSM data file in alignment with planet daily update.

 - Timestamps: In *Data* section lists included data timestamps for First and Last
 data elements, if missing "replication_timestamp" in "Header" info; then use timestamp
 for **Last** data as your starting point to bring your OSM data file in alignment
 with planet daily update. Timestamp for Last included data above is
 "Last: 2025-09-03T20:00:57Z".

The Geofabrik download page for extract includes the timestamp for that extract in
the same line it states the extract creation time; something like:

<pre>
This file was last modified 1 day ago and contains all OSM data up to 2025-09-30T20:21:27Z.
</pre>

The information above is set in recent extract files from Geofabrik, it may not
all be set from other extract sources. The **data timestamps** should always be
set in (.osm.pbf) files.

### Geofabrik "state.txt" File Has Planet Minutely Sequence Number:

Back to the sequence number above; use "Locate change file by sequence number" method
described above to locate and view state.txt file for Geofabrik sequence number = 4535:

```
4535 ---> 000004535 ---> /000/005/435.state.txt
```

Locating state.txt file above on Geofabrik server (under update page URL), we find the
file below:

<pre>
 # original OSM minutely replication sequence number 6756480
 timestamp=2025-09-03T20\:20\:35Z
 sequenceNumber=4535
</pre>

Notice the timestamp value matches timestamp from osmium fileinfo output.

The first commented out line is the important part in this file; the sequence number
listed is the last minutely change file included in this extract file from **planet server.**
We locate file with sequence number 6756480 at planet minute server:

```
6756480 ---> 006756480 ---> /006/756/480.state.txt
```

We locate file on planet minute server: "https://planet.osm.org/replication/minute",
this file contents are:

<pre>
#Wed Sep 03 20:21:06 UTC 2025
sequenceNumber=6756480
timestamp=2025-09-03T20\:20\:35Z
</pre>

To update this data file using minutely change files from planet OSM server we start
at minute sequence number **just after** 6756480.

The same state.txt on planet minute server can be found using the timestamp value
listed from osmium fileinfo using "Locate Change File By Timestamp" method described
above.

I have used this method to set my minute begin value for "Range List with getdiff" below.

---

### Time Gap Issue:

For most regional extracts at Geofabrik, extracts are calculated daily usually between
the hours 20:00:00 - 21:00:00. Updating from Geofabrik server is not an issue since
change files are also calculated at the same time.

The planet daily change files are always issued or calculated at midnight (00:00:00 UTC).

To keep a complete set of data in our OSM data file, we need to collect change files
from planet server to cover the time period difference between Geofabrik and planet
servers and apply those changes to the data file. The time period is usually less
than 4 hours for most extracts from Geofabrik, it will always be less than 24 hours
for any extract.

Use "osmium fileinfo" on your extract OSM data file to retrieve your timestamp value.
We use timestamp listed in the *Header* info, if that is not available then use the
timestamp for last included data as mentioned earlier.

### Range List With "getdiff" Program:

We construct **one** range list consisting of minutely and hourly change files to
cover the "gap period" using "getdiff" range function. The range function requires
the sequence numbers for both "begin" and "end" arguments. Sequence number for
change file is in its corresponding "state.txt" file, we locate change file from the
given timestamp using the method described earlier so we can retrieve sequence
number.

The program will be invoked twice; once to retrieve minutely change files and the
second time to retrieve hourly change files. If you need to include daily change
files, a third invocation will be required. The program downloads change files in
time sorted order for each invocation, however you do need to start with minutes
before moving to hours.

Any given range to "getdiff" must be 2 or more files! If you need only one file in
any range you will have to download 2 and manually edit the "rangeList.txt" file
that is written by "getdiff" to its work directory.

There is also a limit to how many files you can download in a single session (61
pairs). If you have more, you will have to break your range into two or more calls.
If your extract data file is older than 2 months, you should use more recent extract.

Another point about "getdiff", you can download "state.txt" files only with the
option *--text* (short option -t). This option may not stay in future getdiff release!

I suggest you write a table with two rows; one for minutes and one for hours with
"begin" and "end" heading in the next steps.

Using my extract file as an example; with timestamp = 2025-09-03T20:20:35Z and ignore
the seconds part we draw a time line to cover for needed minutes as:

<pre>
timestamp  first_minute_end                                        next_hour
   |            |                                                      |
   |------------|------------------- cut ------------------------------|
   |            |                                                      |
 20:20        20:21                                                  21:00
</pre>

For the required hour range we start at where we ended for minutes to midnight:

<pre>
end_minutes  first_hour_end                                          next_day (2025-09-04)
   |              |                                                      |
   |--------------|------------------- cut ------------------------------|
   |              |                                                      |
 21:00          22:00                                                  00:00
</pre>

#### Setting minutely range:

  - The objective is to collect minute change files to get timestamp to the top of
  the hour; if you are lucky with a timestamp already at the top of hour then you
  do not need any minute change files.

  **begin value:**

  - If your extract is a recent file from Geofabrik, then locate "state.txt" file
  for replication sequence number from your "osmium fileinfo", where the first line
  has last included planet minutely sequence number in your extract, your "begin"
  value for getdiff is **just after** this sequence number. See 'Geofabrik "state.txt"
  file has planet minutely sequence number' above.

  For my extract fileinfo where replication sequence = 4535, on Geofabrik site, that
  "state.txt" (/000/004/535.state.txt) has planet minute sequence number 6756480:

  <pre>
  # original OSM minutely replication sequence number 6756480
  </pre>

  my minute "begin" value is  6756481.

  - Otherwise you use your extract timestamp (if not available then use last data
  timestamp) to locate change file and its corresponding "state.txt" file on the
  planet server minute replication page "https://osm.org/replication/minute",
  using method 'Locate change file by timestamp' explained earlier. The sequence
  number you find in that "state.txt" file is for last included data in your extract,
  your value for "begin" is the sequence number **just after** that one.

  **end value:**

  - We stop at the top of the hour; that is next hour with minutes 00. Browse to the
  top of the hour (minutes = 00) on the same minutely planet page. Locate the
  corresponding minutely change file and open its state.txt. Copy the sequence
  number, this is your "end" value for minute range.

  For my extract with timestamp starting at "20:20" (ignoring seconds); next hour
  is "21:00" and my end value for getdiff is 6756519.

#### Setting hourly range:

  - For hours we continue from the time we ended at minutes with the objective to
  reach midnight UTC time; that is zero hour of next day. Remember the implied start
  time for change files mentioned earlier.

  - The timestamp you ended minutes with will be the start for your next hour; that
  next hour will end at that timestamp **plus** an hour, that is what you use to
  locate your hourly "begin" sequence number value.

  - Switch to hour page on planet server: https://osm.org/replication/hour

  - Use timestamp in your minutely "end" state.txt file **plus** one hour to locate
  the hourly change file and open its corresponding "state.txt" file to retrieve the
  sequence number, this is your "begin" value for hour.

  For my example extract; my minutes ended at 21:00, my first hour has to end an
  hour later or timestamp with 22:00 (ignoring seconds), I locate files with that
  timestamp and my hour "begin" value is ( 113751 ).

  - The hourly "end" time will be at 00:00:00 UTC of the next day. Locate change
  file and its corresponding "state.txt" file to retrieve sequence number, this
  is your "end" for hour.

  For my extract; the "end" value is when date changes from 9/3 to 9/4 with all
  zeros for time, I located change file and got sequence number from its state.txt
  with value 113753; my hour "end" value is ( 113753 ).

  Fill in your hour row in your table with begin and end sequence numbers.

#### Invoking getdiff:

In your new getdiff directory (see Environment Setup) create "getdiff.conf" file
with DIRECTORY directive, set its value to the path to your work directory:

 ```
  DIRECTORY = /path/to/WORK_DIR
 ```
replace "/path/to/WORK_DIR"  with real path to your work directory.

The file is needed because most of you have "getdiff.conf" somewhere and we need
to keep things separate for you.

We invoke "getdiff" with the following arguments from WORK_DIR directory:

  * -c getdiff/getdiff.conf  ---> path to configure file to use
  * -s https://planet.osm.org/replication/minute ---> source URL for planet minute
  * -b begin_value ---> begin sequence number; mine is: ( -b 6756481 )
  * -e end_value ---> end sequence number; mine is: ( -e 6756519 )

the full command with its arguments from WORK_DIR is below:

```
  $ getdiff -c getdiff/getdiff.conf -s https://planet.osm.org/replication/minute -b 6756481 -e 6756519
```

The above command will download the minutely range files (change and state.txt).
Find your files in: "{WORK_DIR}/getdiff/planet/minute" directory.

The "getdiff" program also writes a sorted list of downloaded files to "rangeList.txt"
file in its work directory: {WORK_DIR}/getdiff/rangeList.txt, do not remove.

Now we do the second invocation to fetch the hourly range, we change the **source**
and sequence numbers for begin & end values:

  * -s https://planet.osm.org/replication/hour

the full command with arguments from {WORK_DIR} is below:

```
  $ getdiff -c getdiff/getdiff.conf -s https://planet.osm.org/replication/hour -b 113751 -e 113753
```

This command downloads the hourly range change files and their corresponding
state.txt files to: "{WORK_DIR}/getdiff/planet/hour/" directory.

The program also appends a sorted list of downloaded files to the **same "rangeList.txt" file**
from the previous minutely command in its work directory.

Check "getdiff.log" file in its work directory and inspect the produced "rangeList.txt"
file, do not edit this file - unless one single file is needed!

My "rangeList.txt" file had 39 minutely change files and 3 hourly change files.

Values used in my commands were for the my extract example with "osmium fileinfo"
mentioned earlier, my full produced "rangeList.txt" file contents is below:

```
/minute/006/756/481.osc.gz
/minute/006/756/481.state.txt
/minute/006/756/482.osc.gz
/minute/006/756/482.state.txt
/minute/006/756/483.osc.gz
/minute/006/756/483.state.txt
/minute/006/756/484.osc.gz
/minute/006/756/484.state.txt
/minute/006/756/485.osc.gz
/minute/006/756/485.state.txt
/minute/006/756/486.osc.gz
/minute/006/756/486.state.txt
/minute/006/756/487.osc.gz
/minute/006/756/487.state.txt
/minute/006/756/488.osc.gz
/minute/006/756/488.state.txt
/minute/006/756/489.osc.gz
/minute/006/756/489.state.txt
/minute/006/756/490.osc.gz
/minute/006/756/490.state.txt
/minute/006/756/491.osc.gz
/minute/006/756/491.state.txt
/minute/006/756/492.osc.gz
/minute/006/756/492.state.txt
/minute/006/756/493.osc.gz
/minute/006/756/493.state.txt
/minute/006/756/494.osc.gz
/minute/006/756/494.state.txt
/minute/006/756/495.osc.gz
/minute/006/756/495.state.txt
/minute/006/756/496.osc.gz
/minute/006/756/496.state.txt
/minute/006/756/497.osc.gz
/minute/006/756/497.state.txt
/minute/006/756/498.osc.gz
/minute/006/756/498.state.txt
/minute/006/756/499.osc.gz
/minute/006/756/499.state.txt
/minute/006/756/500.osc.gz
/minute/006/756/500.state.txt
/minute/006/756/501.osc.gz
/minute/006/756/501.state.txt
/minute/006/756/502.osc.gz
/minute/006/756/502.state.txt
/minute/006/756/503.osc.gz
/minute/006/756/503.state.txt
/minute/006/756/504.osc.gz
/minute/006/756/504.state.txt
/minute/006/756/505.osc.gz
/minute/006/756/505.state.txt
/minute/006/756/506.osc.gz
/minute/006/756/506.state.txt
/minute/006/756/507.osc.gz
/minute/006/756/507.state.txt
/minute/006/756/508.osc.gz
/minute/006/756/508.state.txt
/minute/006/756/509.osc.gz
/minute/006/756/509.state.txt
/minute/006/756/510.osc.gz
/minute/006/756/510.state.txt
/minute/006/756/511.osc.gz
/minute/006/756/511.state.txt
/minute/006/756/512.osc.gz
/minute/006/756/512.state.txt
/minute/006/756/513.osc.gz
/minute/006/756/513.state.txt
/minute/006/756/514.osc.gz
/minute/006/756/514.state.txt
/minute/006/756/515.osc.gz
/minute/006/756/515.state.txt
/minute/006/756/516.osc.gz
/minute/006/756/516.state.txt
/minute/006/756/517.osc.gz
/minute/006/756/517.state.txt
/minute/006/756/518.osc.gz
/minute/006/756/518.state.txt
/minute/006/756/519.osc.gz
/minute/006/756/519.state.txt
/hour/000/113/751.osc.gz
/hour/000/113/751.state.txt
/hour/000/113/752.osc.gz
/hour/000/113/752.state.txt
/hour/000/113/753.osc.gz
/hour/000/113/753.state.txt
```

### Script "extract2planet.sh":

The script "extract2planet.sh" brings specified extract data file in alignment
with planet daily change files issuance time using "rangeList.txt" produced by
getdiff program and regional extract polygon file. Script usage is:

```
    extract2planet.sh <data_file> <poly_file> <list_file>
        <data_file>: OSM region extract data file
        <poly_file>: region polygon (.poly) file. (Available from Geofabrik site)
        <list_file>: range list file "rangeList.txt" produced by getdiff.
```

Script produces a new extract OSM data file with files in the "rangeList.txt" merged
into its input OSM data file utilizing "osmium merge-changes" function. The new
data file is placed into "region/extract/" directory, the new file is named as the
input data file with an appended date separated by an underscore:

original-name.osm.pbf ----> original-name_YYYY-MM-DD.osm.pbf

The date is for year, month and day from last change file in "rangeList.txt" file.
**Please do not use underscore in your data file name.**

To execute the script place your polygon file under "region/" directory and your
extract data file under "region/extract/" directory and from work directory run
the script. This is the command I used for my example data file:

```
 $ scripts/extract2planet.sh region/extract/arizona-internal.osm.pbf region/arizona.poly getdiff/rangeList.txt
 ```

This command produced "arizona-internal_2025-09-04.osm.pbf" under "region/extract/"
directory.

Run "osmium fileinfo -e" on your new data file, here is partial list for mine:

<pre>
wael@yafa:~/extract-wd$ osmium fileinfo -e region/extract/arizona-internal_2025-09-04.osm.pbf
File:
  Name: region/extract/arizona-internal_2025-09-04.osm.pbf
  Format: PBF
  Compression: none
  Size: 306114997
Header:
  Bounding boxes:
    (-114.8224,31.32659,-109.0437,37.00596)
  With history: no
  Options:
    generator=osmium/1.18.0
    osmosis_replication_base_url=yafa.local:/home/wael/extract-wd/region/replication
    osmosis_replication_sequence_number=113753
    osmosis_replication_timestamp=2025-09-04T00:00:00Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2025-09-04T00:00:00Z
[======================================================================] 100%
Data:
  Bounding box: (-115.7134915,30.9030825,-106.7050181,38.8430679)
  Timestamps:
    First: 2007-08-10T17:38:36Z
    Last: 2025-09-03T23:43:03Z

</pre>

comparing timestamps between our input file and our new output file we can see that
Header timestamp changed from 2025-09-03T20:20:35Z to 2025-09-04T00:00:00Z and the
Data Last timestamp changed from 2025-09-03T20:00:57Z to 2025-09-03T23:43:03Z. This
change reflects the merged data from the change files.

This new extract data file can be used to initialize databases such as overpass,
those databases can then be updated using change files produced by our next
script.

If you are **using overpass**, skip the rest of this file and **continue** with
**OP_FROM_PLANET.md** file, where you use this planet aligned extract data file
to initialize your new overpass database.

### Script "mk_regional_osc.sh":

Script makes change files for regional extract data file from planet change files,
script usage is:

```
 mk_regiom_osc.sh <list_file>
  <list_file>: file with change and state.txt files list from planet osm server.
```

This <list_file> is produced by "getdiff" program and similar to rangeList.txt.
The script updates the extract data file then computes the extract change file.
Extarcts data files are written to "region/extract/" directory and change files
are written to "region/replication/" directory.

This script is part of overpass database update automation process. Script setup
consist of three steps; change variables in the script, create "target.name" file
and setup and run "getdiff".

To use the script set / change variable in the script (all on the top part):

**Script Variables:**

To use the script set / change variable in the script (all on the top part):

  - set to your region poly file name ONLY, place file in your region directory\
  polyFileName=arizona.poly

  - set to your area or region name, use short name\
  regionName=Arizona

  - change opDir value to your work directory
```
  # opDir=/var/lib/overpass\
  opDir=/home/wael/extract-wd
```

**Create target.name:**

  - write your new extract data file name to "target.name" file in your "region/"
  directory; from your work directory do:

  ```
    $ echo "arizona-internal_2025-09-04.osm.pbf" > region/target.name
  ```

**Setup and Run "getdiff":**

  - use "getdiff" program to download planet change file; edit your "getdiff.conf"
  file (with just the "DIRECTORY" directive) to include 2 additional directives as
  follows:

  <pre>
  DIRECTORY = /path/to/WORK_DIR

  SOURCE = https://planet.osm.org/replication/day

  BEGIN = sequence_number

  </pre>

The sequence_number value is your daily planet change file to update the new extract
data file, use the timestamp in your new data file to locate change file on the planet
daily server (SOURCE above) using "Locate Change File By Timestamp" method. For my
example data file that value was 4741.

Run "getdiff" program with your configuration file from your work directory:

```
  $ getdiff -c getdiff/getdiff.conf
```

This command will download change files from planet server and produce a list of
those files and their "state.txt" files in "newerFiles.txt" file in getdiff directory.

**Run "mk_regional_osc.sh" Script:**

From your work directory run the script with "newerFiles.txt" as an argument:

```
  $ scripts/mk_regional_osc.sh getdiff/newerFiles.txt
```

For each planet daily change file in "newerFiles.txt" list, the script produces
a new updated extract data file in "region/extract/" directory and a daily change
file with its corresponding state.txt file for the extract in "region/replication/"
directory. The script writes its progress to standard output (terminal) and to its
log file in "logs/mk_regional_osc.log", take a look in the log file. In addition,
the script writes change files and state.txt files names to "oscList.txt" in the
"region/" directory, the list is used to automate database update, see my usage
and implementation for overpass in the "OP_FROM_PLANET.md" file.

Change files produced by this script can be used to update databases initialized
from the extract data file.

One warning about disk space; the updated regional extract data files are large
files and you do not want to keep too many of them around.

Hope somebody will find this useful.

Wael Hammoudeh

October 10/2025
