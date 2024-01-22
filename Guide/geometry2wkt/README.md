## README for geometry2wkt Program

### Usage:
```
 geometry2wkt [file ... ]
```

This program formats the geometry returned by an overpass query into Well Known Text (WKT).
It supports two modes of input: reading from the terminal stream (stdin) or from named file(s).
Terminal Stream Input:

### Terminal Input:

When reading from the terminal, the program outputs the LINESTRING Well Known Text for its input.
To use this mode, pipe the output of an overpass query script into the program. For example:

```
 $ osm3s_query < area-geom.op | geometry2wkt
```

To save the program output to a file, use shell redirection:

```
 $ osm3s_query < area-geom.op | geometry2wkt > area-geom.csv
```

The output will be written to the "area-geom.csv" file in the current directory.

### Named File(s) Input:

When reading from named files, the program produces WKT for the geometry as POINT in one file
and as LINESTRING in another. If the "ogr2ogr" program is available in the system, the program
calls it to convert WKT files to ESRI Shapefiles.

For example, if you have a file "area-geom.out" from an overpass query, you can use the following command:

```
 $ geometry2wkt area-geom.out
```

This command will generate POINT and LINESTRING files with WKT for the geometry. The file names are as follows:

```
 - POINT file: area-geom_Point.csv
 - LINESTRING file: area-geom_Linestring.csv
 ```

 If "ogr2ogr" is available, the program converts these files into ESRI Shapefiles:

 ```
 - POINT file: area-geom_Point.shp
 - LINESTRING file: area-geom_Linestring.shp
```

Note: geometry2wkt accepts a list of files as input as well.
