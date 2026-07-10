
# Regional OSM Extract And Planet Change Files

OpenStreetMap planet data file is huge and requires more resources than most people
have to process. That is the main reason a lot of people use regional OSM extract
data files.

Then the question pops up; can the smaller planet change files be used to update an
OSM extract data file?

Well the awnser is yes. In this file I explain a method to do just that - update an
OSM regional extract data file - plus derive a differ file for that extract to update
overpass database.

There are a lot of varaibles involved - like planet change files are available for
minutely, hourly or daily updates among others - so we need to set some assumptions
and set our exact goal here.

We assume that the extract data file is a recent regional OSM extract from Geofabrik.de
website. By recent I mean no more than few days old. We also assume that we want to
update our data file and database daily.

Our goal here is to update our region OSM extract data file and to produce a change file
that can be used to update a database produced - based on - from this extract data file.

In short the process is broken into two steps explained below; first we produce a new
extract data file aligned with planet daily change files issuance - using planet change
files, a recent region extract data file and that **region poly file** from Geofabrik.de
website - and in the second step we derive a change file from the two extract data files.

For this discussion, one should be famaliar with OSM change files and how to locate
them on remote servers. A short discussion is **a required read** for this subject
and is available in [README.changeFiles.md](README.changeFiles.md) file. This will be
referred to as "introduction".

---

## Introduction:

Terms and definitions required for this reading are in [README.changeFiles.md](README.changeFiles.md)
in this repository. Note this is the same file included in with my `getdiff` program!

---

## Requirements:

 1) [osmium tools](https://github.com/waelhammoudeh/osmium-tool_slackbuild)
 2) The [getdiff program](https://github.com/waelhammoudeh/getdiff) to download change files.
 3) Web browser (like Google Chrome or Mozilla Firefox)
 4) Poly file for your region extract; many are available from [Geofabrik.de](https://download.geofabrik.de/) website.

 Two bash scripts are provided in the "scripts" directory on this repository.

```
extract_planet/
├── getdiff
│   └── getdiff.conf
├── logs
├── region
│   ├── arizona.poly
│   ├── replication
│   └── extract
│       └── arizona_2026-06-30T20:21.26Z.osm.pbf
├── scripts
│   ├── common_functions.sh
│   ├── extract2planet.sh
│   └── mk_regional_osc.sh
└── tmp
```

Provided scripts expect the file system structure outlined in the above tree, to
create this structure from your home directory, use the following commands:
```
  $ cd ~
 ~$ mkdir -p extract_planet/{getdiff,logs,scripts,tmp,region/{replication,extract}}
```

Copy the three scripts files from the "scripts" directory in this repository to
"extract_planet/scripts" directory and place your region poly file in directory
"extract_planet/region".

Note to "overpass" users; this is the same file system structure created in the
"overpass" user home directory, without the "scripts" directory, scripts themslves
are installed to "/usr/local/bin/" by my "overpass.SlackBuild" build script.

We will write "getdiff.conf" file and copy extract data file with new formated
name below.

---

# 1) Make a new regional extract data file:

We decided on daily updates from planet server, and OSM planet server issues daily
change files at midnight UTC time. This means our region extract data file should
or must have data up to midnight if we do not want to lose data on updates. Is
that the case in our original extract data file from Geofabrik.de? To find out we
run `osmium fileinfo` on it - assume your file is in your current directory and named
with "myregion.osm.pbf", then you issue:

```
  ~$ osmium fileinfo myregion.osm.pbf
```

For illustrations I will use my recent downloaded file from Geofabrik with the
command and output below:

```
overpass@regrets:~/sources$ osmium fileinfo arizona-260630-internal.osm.pbf
File:
  Name: arizona-260630-internal.osm.pbf
  Format: PBF
  Compression: none
  Size: 325521693
Header:
  Bounding boxes:
    (-114.8325,30.05891,-109.0437,37.00596)
  With history: no
  Options:
    generator=osmium/1.16.0
    osmosis_replication_base_url=https://osm-internal.download.geofabrik.de/north-america/us/arizona-updates
    osmosis_replication_sequence_number=4833
    osmosis_replication_timestamp=2026-06-30T20:21:26Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2026-06-30T20:21:26Z
overpass@regrets:~/sources$
```

We note the timestamp from this output; which is shown here:
```
    osmosis_replication_timestamp=2026-06-30T20:21:26Z
```
this timestamp - from the clock part of 20:21:26Z (HH:MM:SS) - puts this file 3 hours
and 38 minutes away from midnight (ignoring the seconds part). This is a **time gap**
which we need to fill. This is done by filling the time gap with change files from
planet OSM server then add them to our extract data file.

## 1.1) Fill Time Gap:

To fill the above time gap, we collect minute change files from planet OSM **minutely**
replication to get us to the next hour (21:00) UTC, we dropped the seconds here.
We then move to planet OSM **hourly** replication to collect 3 hours to get us to
midnight UTC time.

We use my `getdiff` program to collect and download change files, and for that we
provide `getdiff` with arguments for `begin` and `end` as **sequence numbers** for
the desired change files to download a range of files.

From the above given information to cover the "gap" in minutes and hours, we make
the following table with 2 rows (minutes and hours) to fill the required sequence
numbers for begin and end:

```
            begin Timestamp      begin Seq Num   end Seq Num    end Timestamp
-------------------------------------------------------------------------------
minutes    2026-06-30 20:21                                    2026-06-30 21:00

hours      2026-06-30 21:00                                    2026-07-01 00:00
```

We start with the "begin Sequence Number" for minute. Our regional extract OSM data
file was from Geofabrik.de as assumed in the begining, and the "state.txt" files
from Geofabrik.de include the last minutely sequence number from planet OSM server.

For my example extract data file with `omsmium fileinfo` output above, the planet
minutely sequence number will be in "state.txt" in "arizona-updates" page at
Geofabrik.de website with sequence number 4833 as seen in the output above.

Another fact mentioned in the introduction is that "state.txt" files are shared
between the INTERNAL and PUBLIC servers at Geofabrik.de website, so to locate the
required "state.txt" with sequence number 4833 you may drop "osm-internal" part
for the INTERNAL server and use the PUBLIC server:
```
https://download.geofabrik.de/north-america/us/arizona-updates
```

Now on the "arizona-update" page we need to locate change file with sequece number
4833 and look in its corresponding "state.txt" file: that method said to pad a 9
digit string with leading zeros and insert slashes every 3 digits:
```
4833 --> 000 004 833 --> 000/004/833.state.txt
```

you can append that to the update page (in your browser address bar) as below:
```
https://download.geofabrik.de/north-america/us/arizona-updates/000/004/833.state.txt
```

Here is that file contents:
```
# original OSM minutely replication sequence number 7179408
timestamp=2026-06-30T20\:21\:26Z
sequenceNumber=4833
```
Note the first line with minutely sequence number 7179408, this is on planet OSM
site. On "planet.osm.org/replication/minute" website we locate file with sequence
number 7179408, then move to file just **AFTER** it - we were looking at last included
data in our extract file, looking in the next "state.txt" file we get sequece
number 7179409 as our value for minutes "begin"; while on that page we scroll up
to reach next hour for minute "end" at time 21:00 per our table, then look inside
that "state.txt" file to retrieve sequece number 7179446. Filling in values in our
table makes it look like this:

```
            begin Timestamp      begin Seq Num   end Seq Num    end Timestamp
-------------------------------------------------------------------------------
minutes    2026-06-30 20:21        7179409        7179446      2026-06-30 21:00

hours      2026-06-30 21:00                                    2026-07-01 00:00
```

For the hours sequence numbers, we move to the hour replication page on planet OSM site:
```
"https://planet.osm.org/replication/hour"
```
to locate change files by given "Timestamp" in our table above for "begin" which is
2026-06-30 21:00, from the root page we click on the only directory listed as "000/"
on the next page we find the closest "Last modified" time to our timestamp - in
recent directories since our timestamp is recent - we find "2026-07-02 22:02" is the
closest - second from top 'as of this writing' - for directory listed as "120/", we click on that
and see a list of 1000 files! To find your file fast use your keyboard type "Ctl F"
then in the search box start typing our timestamp ... on Firefox I typed "2026-06"
and it scrolled up the page to where I can spot 2026-06-30 23:02 to 2026-06-30 15:02,
that made it easier now to get a better match to our timestamp which happens for file
"950.state.txt" with "Last modified" time 2026-06-30 21:02, we look inside that file
and it turns out to include data ending at our timestamp - so we need the file just
after this "950.state.txt" which is the one above it with 120951 sequence number.

We found sequence number 120951 for "begin Timestamp" and sequence number 120953 for
"end Timestamp". Now our updated table looks like this below:

```
            begin Timestamp      begin Seq Num   end Seq Num    end Timestamp
-------------------------------------------------------------------------------
minutes    2026-06-30 20:21        7179409        7179446      2026-06-30 21:00

hours      2026-06-30 21:00        120951         120953       2026-07-01 00:00
```

As I am writing this, today is July 3rd/2026 which makes my extract data file three
days old, I will add one daily change file to be included in the data file. So we
continue from last included timestamp, I need the planet daily change file that
ends on July 2nd at midnight. Locating that change file on planet daily replication
website I get sequece number 5041; using this as "begin" and "end" sequence number
and updating my table for that results in the table shown below:

```
            begin Timestamp      begin Seq Num   end Seq Num    end Timestamp
-------------------------------------------------------------------------------
minutes    2026-06-30 20:21        7179409        7179446      2026-06-30 21:00

hours      2026-06-30 21:00        120951         120953       2026-07-01 00:00

days       2026-07-01 00:00          5041           5041       2026-07-02 00:00
```

Now our table is complete, we call `getdiff` program to download change files for
us. Before we do this, we create the following "getdiff.conf" file in its directory
we created earlier; replace {YOUR-HOME-DIR} with your actual home directory:

```
DIRECTORY={YOUR-HOME-DIR}/extract_planet/
LOG_FILE={YOUR-HOME-DIR}/extract_planet/logs/getdiff.log
VERBOSE=on
```

we call `getdiff` three times - once for each time period in our table - passing
it the above configuration file with `-c` option; with this configuration, program
saves downloaded change files to "{YOUR-HOME-DIR}/extract_planet/getdiff/planet/" directory
and writes its log file to "{YOUR-HOME-DIR}/extract_planet/logs/getdiff.log". The program
appends downloaded filenames to "rangeList.txt" file in "{YOUR-HOME-DIR}/extract_planet/getdiff"
directory.

For each call we change the `-s` for source URL, the `-b` and `-e` for begin and
end options. The calls to `getdiff` below are assumed to be from directory created
in "Requirements" section above "{HOME}/extract_planet" directory:

```
  ~$ cd {HOME}/extract_planet
```

download minutely change files with the following command (broken into lines for reading):
```
 wael@regrets:~/extract_planet$ getdiff
                                -c getdiff/getdiff.conf \
                                -s https://planet.osm.org/replication/minute \
                                -b 7179409 \
                                -e 7179446
```

you may / should inspect "rangeList.txt" file and look into "getdiff.log" file.

download hourly change files with:
```
 wael@regrets:~/extract_planet$ getdiff
                               -c getdiff/getdiff.conf \
                               -s https://planet.osm.org/replication/hour \
                               -b 120951 \
                               -e 120953
```

newly downloaded filenames are **appended to the same "rangeList.txt" file,** check it out.

download the one daily change file with:
```
 wael@regrets:~/extract_planet$ getdiff
                                -c getdiff/getdiff.conf \
                                -s https://planet.osm.org/replication/day \
                                -b 5041 \
                                -e 5041
```

note that we specified values for "begin" and "end" options; telling `getdiff` to
use "rangeList.txt" file. We used the same values for both.

My final "rangeList.txt" file had 84 lines; top and bottom parts are shown below:

```
/minute/007/179/409.osc.gz
/minute/007/179/409.state.txt
/minute/007/179/410.osc.gz
/minute/007/179/410.state.txt

   --- cut ---

/hour/000/120/953.osc.gz
/hour/000/120/953.state.txt
/day/000/005/041.osc.gz
/day/000/005/041.state.txt
```

Now we have collected change files to cover the **gap** time, we merge those change
files into our extract data file to produce a new extract data file that is aligned
with planet OSM daily change files issuance time.

## 1.2) Merge change files:

To merge collected change files into extract data file, we use the provided script
"extract2planet.sh, the script usage is:

```
wael@regrets:~/extract_planet$ scripts/extract2planet.sh
opDir is: /home/wael/extract_planet
usage:

extract2planet.sh <data_file> <poly_file> <list_file>
 data_file: Extract data file to update
 poly_file: Region polygon (.poly) file.
 list_file: Filename with change files list to merge.
wael@regrets:~/extract_planet$

```

the "data_file" will be our region extract data file, the "poly_file" is our region
poly file and the "list_file" is the "rangeList.txt" file produced by `getdiff` in
the previous step.

The script produces a new extract data file in "extract_planet/region/extract/"
directory, the new filename is formated with the region name and full timestamp
(without back slashes) separated by an underscore character as follows:
```
 region_YYYY-MM-DDTHH:MM:SSZ.osm.pbf
```

the "timestamp" part is from the last merged change file timestamp. To be consistent
with this, we rename our orginal extract data file with its timestamp and copy it to
"extract_planet/region/extract/" directory before we call the script.

For my example arizona data file, I copied it as follows:
```
wael@regrets:~/extract_planet$ cp /var/lib/overpass/sources/arizona-260630-internal.osm.pbf \
                                  region/extract/arizona_2026-06-30T20:21:26Z.osm.pbf
```

We execute "extract2planet.sh" script as follows:

```
wael@regrets:~/extract_planet$ scripts/extract2planet.sh \
                                     region/extract/arizona_2026-06-30T20\:21\:26Z.osm.pbf \
                                     region/arizona.poly \
                                     getdiff/rangeList.txt
```

Bash completion function adds (inserts) back slashes!

Script produces intermediate file in "extract_planet/tmp" directory - those should
be removed - you may inspect those files.

script writes its progress to the terminal and to log file in directory "logs" file:
"extract_planet/logs/extract2planet.log" file.

Hopefully everything works okay for you and you get a similar lines toward the end
of the script output as mine below:

```
 [extract2planet] Successfully made new extract OSM data file contains all OSM data up to: 2026-07-02T00:00:00Z
 [extract2planet] New OSM data file was written to: /home/wael/extract_planet/region/extract/arizona_2026-07-02T00:00:00Z.osm.pbf
 [extract2planet] extract2planet is done
```

We then run `osmium fileinfo` on this new file:
```
wael@regrets:~/extract_planet$ osmium fileinfo region/extract/arizona_2026-07-02T00:00:00Z.osm.pbf
File:
  Name: region/extract/arizona_2026-07-02.osm.pbf
  Format: PBF
  Compression: none
  Size: 324562712
Header:
  Bounding boxes:
    (-114.8224,31.32659,-109.0437,37.00596)
  With history: no
  Options:
    generator=osmium/1.19.0
    osmosis_replication_base_url=https://planet.osm.org/replication/day
    osmosis_replication_sequence_number=5041
    osmosis_replication_timestamp=2026-07-02T00:00:00Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2026-07-02T00:00:00Z
```

Compare the **timestamp** from the original extract data file with that from the new
extract data file:

```
Original: osmosis_replication_timestamp=2026-06-30T20:21:26Z

New     : osmosis_replication_timestamp=2026-07-02T00:00:00Z
```

New extract data file timestamp is **2026-07-02T00:00:00Z** and the original extract
data file timestamp was **2026-06-30T20:21:26Z**, this verifies that the operation
was successful.

You can use **`-e, --extended`** option with `osmium fileinfo` for better verification
with timestamps for data.

Now we have two extract data files we can produce a change file from both using
`osmium tool`. Note here that in this case the change file will not be for standard
time interval; it will be for one day plus 3 hours and 38 minutes.

This daily aligned extract data file can be updated with daily, hourly or minutely
planet change files.

This new daily aligned extract data file can be used to initialize databases such
as "overpass" database. Those databases can be updated with extract change files
produced by method shown below.

From here we move on to the second step of creating daily change file - in standard
time interval - for our regional extract data file.

## 2) Derive daily change file for regional extract:

The change file in the previous step was not in a standard time period because the
timestamp difference between the two extract data files was not exactly one day.

Now we can merge only one daily planet change file with the aligned extract and
the timestamp difference will be exactly one day between the aligned extract file
from the previous step and the newer extract data file we produce.

We will use our "mk_regional_osc.sh" script in this step; which takes a list of
planet change files and produces a new extract data file and an extract change
file for each planet change file in the list. The list will produced by our `getdiff`
program for planet change files downloaded from planet OSM daily replication server.

We setup `getdiff` to download daily change files from planet OSM server. We edit
our `getdiff.conf` file adding 2 new keys and values as follows:

```
# getdiff.conf for daily planet OSM change files

DIRECTORY=/home/wael/extract_planet
LOG_FILE=/home/wael/extract_planet/logs/getdiff.log
VERBOSE=on

SOURCE=https://planet.osm.org/replication/day

BEGIN=5042
```

We added SOURCE and BEGIN keys with above values, the "SOURCE" is set to planet OSM
daily replication and the "BEGIN" value is the sequence number for change file to
start the download from.

We get the value for "BEGIN" by locating change file on "SOURCE" website using either
the timestamp or sequence number from `osmium fileinfo` output for our extract
data file to update; in this case the one we just made in the previous setp with
output above for my extract for "arizona_2026-07-02T00:00:00Z.osm.pbf" file.

We execute `getdiff` now with one option that is `-c getdiff/getdiff.conf` telling
it to use our newely edited configuration file (not its default configure file):
```
wael@regrets:~/extract_planet$ getdiff -c getdiff/getdiff.conf
```

Calling `getdiff` with just "BEGIN / --begin" value set, makes the program look for
the "end" value from the remote server and now it will append downloaded filenames
to **newerFiles.txt** file not "rangeList.txt". The program gets sequence number for
"end" from the latest `state.txt` file on the root page for the "SOURCE / --source".
Before it exits, the program writes the sequence number for last downloaded file in
the **previous.seq** file in its work directory and with that file presence the
"BEGIN / --begin" value is ignored.

The command above should download few change files - since our extract is fairly
recent - see "newerFiles.txt" and inspect the log file to see your files.

The script "mk_regional_osc.sh" is used to make regional change files from a list
of planet change files, script usage is:

```
usage:

mk_regional_osc.sh <list_file>
 list_file: file name with a list of planet change and state.txt files.
```

The "list_file" will be "newerFiles.txt" from `getdiff` program. For each planet
change file pair (include state.txt file here), script produces a new updated extract
data file in "region/extract" directory and change file with its "state.txt" for
the regional extract under "region/replication" directory.


**Before** using "mk_regional_osc.sh" script; you need to set two varaibles in the
script and create "target.name" file in the "region" directory.

The variables to set are in the top of the script:

  - **polyFileName**
  - **regionName**

The "polyFileName" is your area poly file from Geofabrik.de which was copied to
the "region" directory in the previous step. Only file name is needed here.

The "regionName" is your region (area) name; used in produced "state.txt" files -
this should be a short name.

The "target.name" file is a text file with lastest extract data filename. Initially
this is the file made in the previous step with the "timestamp" part in its name. The
"target.name" file is created in the "region" directory with command like:

```
wael@regrets:~/extract_planet$ echo "arizona_2026-07-02T00:00:00Z.osm.pbf" > region/target.name
```

Script produces a new extract data file for each planet change file and updates the
filename in "target.name" file.

With this setup - **and I hope your extract data file is recent! -** we are ready
to run "mk_regional_osc.sh" script:

```
wael@regrets:~/extract_planet/region/extract$ scripts/mk_regional_osc.sh getdiff/newerFiles.txt
```

For each planet change file script will produce a new extract data file in directory
"region/extract" plus a pair of change file with its corresponding state.txt file
for the extract region in "region/replication" directory. The script appends the
names of newely made change and state.txt files to **"oscList.txt"** file in "region"
directory - note that the script does NOT maintain this file, update script or
program is expected to use and maintain this file. The script write the sequence
number from last planet change file to "replicate_id" file in "region" directory,
finally the script updates the name of last extract data file in "target.name"
file in "region" directory.

The **"oscList.txt"** file is similar to "newerFiles.txt" file; it contains a list
of filenames pair(s) - change file and its corresponding state.txt file. The list
is sorted with newest last. The list is inteded to be used by an update script or
program which **should maintain** the file.

List produced by the above command (executed on July 6th/2026) is shown below:

```
/000/005/042.osc.gz
/000/005/042.state.txt
/000/005/043.osc.gz
/000/005/043.state.txt
/000/005/044.osc.gz
/000/005/044.state.txt
/000/005/045.osc.gz
/000/005/045.state.txt
```

An example for produced "state.txt" file shows (045.state.txt) listed above:
```
# Mon Jul  6 08:15:06 UTC 2026, Arizona region OSC. Original planet daily OSC sequence number 5045
sequenceNumber=5045
timestamp=2026-07-06T00:00:00Z
```

The script writes its progress to standard output and log file "mk_regional_osc.log"
in "logs" directory.

Wael Hammoudeh

July 10/2026
