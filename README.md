
# Guide to Installing and Setting Up an Overpass Server on Slackware64 15.0

This guide describes how to install and configure an Overpass API server on a Linux
machine running **Slackware64 15.0**. The focus here is on creating a
**limited-area database initialized from an OSM extract** rather than the full planet.

Using a regional extract greatly reduces disk space requirements. The trade-off is
that such a database does **not support historical functionality** (attic data).
However, by keeping your database updated with the latest OSM diffs, you can always
query up-to-date data for your chosen region.

---

## Prerequisites

We assume you:

- Have basic familiarity with the Linux command line.
- Understand OSM data files and their formats.

We’ll use extracts from **[Geofabrik.de](https://www.geofabrik.de/data/download.html)**.
Their site also explains the available data formats.

---

## Hardware Requirements

The original Overpass developer’s hardware recommendation (maybe outdated) suggested:

- 1 GB RAM
- SSD storage
- 200–300 GB disk space for a full planet database (with meta and attic, full compression)

For modern systems, we recommend:

- **4 GB RAM (minimum)**
- **Fast SSD or NVMe drive**
- **64-bit processor, decent speed**

Disk space depends heavily on the region you’re working with (based on the number of
OSM objects: nodes, ways, relations).

In this guide, we initialize databases with **full metadata** and **full compression**,
but without historical (attic) data.

Example sizes after initialization with my `op_initial_db.sh` script:

```
        Region               |    File Size       |  Database Size Compressed(gz)
---------------------------------------------------------------------------
arizona-internal.osm.pbf     | 292  MB (0.29 GB)  |    4331 MB (4.3 GB)
california-internal.osm.pbf  | 1324 MB (1.3 GB)   |    9181 MB (9.0 GB)
```

**Rule of thumb:** Expect about 10 GB of disk space for the database of a typical
country, plus an equal amount of space for update files.

---

## Software Requirements

1. **Overpass API**
   - Download the latest release [here](https://dev.overpass-api.de/releases/).
   - Use the included `overpass.SlackBuild` script to compile and install the package.

2.  **Region OSM Data File**
   - Download your region’s OSM data file from the [Geofabrik download server](https://download.geofabrik.de).
   - The files are organized geographically — you can select your country, a sub-region,
   or even a whole continent (depending on your disk space).
   - The required format is the common **`.osm.pbf`** file **with full metadata**.
   - ⚠️ **Do not use** `.osh.pbf` files (these contain historical data, which is not
   supported in extract-initialized databases).

3. **Osmium Tool**
   - Required for converting PBF/other formats to Overpass-compatible XML.
   - Get my SlackBuild from GitHub:
   [osmium-tool_slackbuild](https://github.com/waelhammoudeh/osmium-tool_slackbuild).
   - My initialization scripts require Osmium to be installed.

4. **Getdiff Program**
  - My own program written in "c" to download "differs" OSM change files to
  update database.
  - Get the program from my [repository](https://github.com/waelhammoudeh/getdiff).

5. **Optional but recommended for OSM work**
   - **GDAL** library
   - **JOSM** editor
   - **QGIS** desktop GIS

## Planet Overpass

Originally overpass server was initialed from planet file without historical data.
Historical data was accumulated with minutely updates and still being added with
the updates. Keeping this fact in mind one can use most of the scripts here to run
his / her own instance of overpass server with full planet with meta plus attic data.

## File System Structure:

Scripts included here assume the following file system structure:

<pre>
/var/lib/overpass/
      |--- database/
      |--- getdiff/
      |--- logs/
      |--- sources/
      |--- region
</pre>

where:

/var/lib/overpass: overpass user home directory

/var/lib/overpass/database: where we initial overpass database

/var/lib/overpass/getdiff: getdiff work directory for updating overpass

/var/lib/overpass/logs: overpass scripts log files

/var/lib/overpass/sources: OSM data files used to initial databases

/var/lib/overpass/region: updated OSM data files (extracts) and region change files.

### DISCLAIMER:
I am NOT an expert on "overpassAPI". Information here may not be accurate, use
at your own risk. I mention other websites, they all have rules and there are laws
to abide by, read the rules and follow the law please. Be in the know.

Wael Hammoudeh

August 26/2025
