
This is the "README-DATA.md" file for overpass Slackware package.

IMPORTANT: This is a work in progress, may also have inaccurate information.

OpenStreetMap (OSM) data is the subject in this file. The aim here is to give you enough information so you know what file to get and where to get that from.

OSM data has three basic element, they are:
 - node: defines one point on a map.
 - way: collection of nodes (points) defines linear features like roads and boundaries.
 - relations: collection of related nodes and ways; which are sometimes used to explain how elements work together.

In addition to those basic elements, you will encounter "Areas" which are not native OSM object but can be created from
closed ways and multipolygon relations.

### Information categories:

OSM data includes various types of information, information can be categorized as follows:

1. **Must-Have Information**: These are the essential attributes that define a geographic feature. For example, a node must have longitude, latitude, and an ID to be a valid point on the map.

2. **Extra Information (Meta Data)**: Beyond the core attributes, elements may include additional meta data. This meta data encompasses elements like version numbers,
creation and modification dates, and user (the mapper) details. This information provides valuable context about the feature's history and evolution. Meta data can be classified as either
"ALL" or "PARTIAL." An element with "ALL" meta data includes comprehensive information, while "PARTIAL" meta data may have certain details omitted, often for privacy reasons
or legal compliance.

3. **Historic (attic) data**: All OSM data are **dated**. The map you usually view are static, they represent the state of elements at one particular moment in time.
Historic data spans from the early days of OSM's collection efforts, historic data files include all versions of elements. This extensive coverage allows users to explore the
historical development of various geographic elements.

In summary; amount of information varies among elements, every element has a unique **ID** and a **DATE**, remember ID and DATE.

### OSM Data File Format:

The OSM common file formats are:

  1- **XML** plain text format: older format, large in size, they are usually compressed to reduce their large size.

  2- **pbf** Protocolbuffer Binary Format: binary format intended as an alternative to the XML format. Newer format, compact, their smaller size makes them more efficient to transfer.

  3- **OPL** format (usually with suffix .osm.opl or just .opl).

  4- **O5M/O5C** format (usually with suffix .o5m or .o5c)

See [OSM File Formats Manual](https://osmcode.org/file-formats-manual/)


### State.txt File for OSM Data Files

Not related to file format; each OSM data file has a corresponding "state.txt" file, this includes planet, regional extract and OSM change files - see below.
This "state.txt" file contains two essential elements:

1. **Sequence Number**: This number uniquely identifies the OSM data file and aids in locating it within a file system.

2. **Timestamp**: The "state.txt" file includes the most recent date (for data) included in the OSM data file. This date provides crucial context about the timeframe this file covers.

Understanding the information within the "state.txt" file helps users navigate and manage OSM data files effectively.

### Change Files: Capturing Data Evolution

Change files play a crucial role in tracking and updating OSM data over time:

Change files, also known as differ files (diff for short) or replication differs, capture the modifications between two OSM data files. These files record changes to objects, including additions,
modifications, and deletions. In short change files are the difference between two OSM data files; an older and a newer one. Change files have (.osc) file name suffix or (.osc.gz) when compressed.

Granularity: Change files come in different time granularities, such as minutely, hourly, or daily. They are considerably smaller in size compared to full OSM data files and provide a means to
efficiently update existing OSM data files or OSM databases.

Assuming we have the older OSM data file, merging this older file with change file(s) - we might need more than one change files - we can generate the new data file.
This process effectively updates the existing data file with the latest changes.

### Internet Sources:

 - http://download.openstreetmap.fr/extracts/
 - https://download.geofabrik.de/
 - https://download.bbbike.org/osm/
 - Local sources; like local government or education institutions.

As you see there are a lot of choices for OSM data. I use and recommend Geofabrik website.

### In (Geofabrik.de) We Trust:

When obtaining OSM data files, Geofabrik.de is a reputable source that offers a wide range of options:

 - **Region-Specific Files**: Geofabrik.de provides organized regional extracts, ranging from continents to countries and sub-regions. These files allow you to focus on the specific geographic area
that interests you.

 - **File Formats and Timing**: Geofabrik.de offers daily regional extract OSM data files in two formats: .osm.bz2 and .osm.pbf. Both formats contain the same data. The (.osm.pbf) files are
 generated directly from the planet data file, then (.osm.bz2) are converted from this  (.osm.pbf) in a low priority process so they are one or more days behind the (.osm.pbf) files.

 - **Historic Regional Extracts**: Additionally, Geofabrik.de provides historic regional extracts in (.osh.pbf) format. These files contain historical versions of elements and are generated weekly.
 Of course historic data files are bigger in size than non-historic files. Please keep in mind that historic functionality in overpass is not supported for limited area database - from extracts.

 - **Last Included Data Date**: The region's main download page lists links to data files along with the last date for data included in each file. This information is crucial for updating your data
file or database.

 - **Accessing All Files**: While not all files may be listed on the main download page, you can use the INDEX page to access other files. The INDEX page URL is the region's URL ending with the
country name followed by a slash.

 - **Public and Internal Servers**: Geofabrik.de offers two download servers: a public server and an internal server. Data files on the public server have partial meta data due to European laws.
Some user information is excluded from these files. The internal server is restricted to openstreetmap.org contributors and can be accessed with an openstreetmap.org account.

 - **Change Files**: Geofabrik.de offers daily change files for all regions they have. They are listed under **{region}-updates** directory entry; where region is your area name. This list is sorted for their
"public server" while it is unsorted for their "internal server", the "state.txt" files are the same in both lists; it is much easier to browse the sorted list when needed.

See the [technical page](https://download.geofabrik.de/technical.html) at geofabrik.de for more info.

 - Geofabrik also provide polygon (.poly) file that describes the extent of each region and
  in most cases shape files for regions. (Get those for your region, you may need them.)

### Osmium Command Line Tools:

Osmium is one program with a collection of tools (commands) to work with OSM data files, see program website [here.](https://osmcode.org/osmium-tool/)
If you work with OSM data files, you need such a program, get my [Slackware package build script]( https://github.com/waelhammoudeh/osmium-tool_slackbuild) and install this package.

One of osmium commands is 'fileinfo' it shows information about an OSM data file; a fairly new OSM data file from 'geofabrik.de' example:

<pre>
wael@yafa:~/osmium-update$ osmium fileinfo <b>--extended</b> arizona-latest-internal.osm.pbf
File:
  Name: arizona-latest-internal.osm.pbf
  Format: PBF
  Compression: none
  Size: 265419524
Header:
  Bounding boxes:
    (-114.8325,30.05891,-109.0437,37.00596)
  With history: no
  Options:
    generator=osmium/1.15.0
    osmosis_replication_base_url=https://osm-internal.download.geofabrik.de/north-america/us/arizona-updates
    osmosis_replication_sequence_number=3763
    osmosis_replication_timestamp=2023-07-18T20:21:43Z
    pbf_dense_nodes=true
    pbf_optional_feature_0=Sort.Type_then_ID
    sorting=Type_then_ID
    timestamp=2023-07-18T20:21:43Z
[======================================================================] 100%
Data:
  Bounding box: (-115.7133191,30.9030825,-108.218831,38.8430606)
  <b>Timestamps:</b>
    First: 2007-08-10T17:38:36Z
    <b>Last: 2023-07-18T19:45:41Z</b>
  Objects ordered (by type and id): yes
  Multiple versions of same object: no
  CRC32: not calculated (use --crc/-c to enable)
  Number of changesets: 0
  Number of nodes: 36140382
  Number of ways: 3758726
  Number of relations: 17465
  Smallest changeset ID: 0
  Smallest node ID: 13265445
  Smallest way ID: 2901206
  Smallest relation ID: 56412
  Largest changeset ID: 0
  Largest node ID: 11053675192
  Largest way ID: 1190465397
  Largest relation ID: 16089412
  Number of buffers: 57276 (avg 696 objects per buffer)
  Sum of buffer sizes: 3632038840 (3.463 GB)
  Sum of buffer capacities: 3757768704 (3.583 GB, 97% full)
Metadata:
  All objects have following metadata attributes: all
  Some objects have following metadata attributes: all
wael@yafa:~/osmium-update$
</pre>

This outputs a lot of information about the source file: 'arizona-latest-internal.osm.pbf'. On the command line I used **--extended** command option to see all information.
For the output I added **bold** for the **Timestamps** and for **Last** under that;
this is the most recent date for data included in this file. This date is needed to update the file or database initialed from this file.


### Choosing your OSM data file:

Quoting from 'geofabrik.de [technical page:](https://download.geofabrik.de/technical.html)
```
pbf files
The .osm.pbf data format is the common format for the exchange of raw OpenStreetMap data. It is fast to read and write and can be directly processed by most programs dealing with OSM data.
Our .osm.pbf files are 100% pure, un-filtered OSM and contain all data and metadata available in OSM for the region; the only thing they don't contain is history, i.e. information about past edits.
```

The **pbf** file format is the recommended file format to use (smaller size and more up to date than .osm.bz2). Stay away from (.osh.pbf) historic files. Historic fuctionality is not supported in
overpass database initialed from a regional extract OSM data file.
When downloading your regional OSM data file, keep a record of the most recent **DATE** included in that file. (It is on the same line with the link).

Wael Hammoudeh

Update: August 9th / 2023
