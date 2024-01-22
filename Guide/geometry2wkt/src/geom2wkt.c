/*
 * geometry2wkt.c
 *
 *  Created on: who knows when!
 *      Author: Wael Hammoudeh
 *
 *  Program formats overpass geometry output into Well Known Text.
 *
 *  When input is read from 'stdin', program formats geometry into LINESTRING
 *  WKT writing its output to 'stdout'.
 *
 *  If given a file name - or a list of file names - program produces separate
 *  files with WKT for POINT and LINESTRING.
 *
 *  WKT files are converted to ESRI shapefiles if "ogr2ogr" program is found
 *  in the system. The "ogr2ogr" program comes with GDAL library.
 *
 **************************************************************************/

#include <stdlib.h>
#include <string.h>

#include "util.h"
#include "list.h"
#include "fileio.h"
#include "ztError.h"
#include "formatWkt.h"
#include "qstrings.h"

int main(int argc, char* const argv[]) {

  char  *progName;
  int   result;

  STRING_LIST   *geomStrList = NULL;
  GEOMETRY      *geometry = NULL;
  LIST_STR_LIST *listListStr = NULL;


  /* set program name **/
  if(strchr(argv[0], '/'))
    progName = lastOfPath(argv[0]);
  else
    progName = argv[0];


  if(argc == 1){

    /* read geometry from stdin and make ONLY LINESTRING WKT to stdout **/

    /* initial STRING_LIST; input is placed into this STRING_LIST **/

    geomStrList = initialStringList();
    if(!geomStrList){
      fprintf(stderr, "%s: Error failed initialStringList().\n", progName);
      return ztMemoryAllocate;
    }

    /* with second argument 'NULL', file2StringList() reads from terminal 'stdin' **/
    result = file2StringList(geomStrList, NULL);
    if(result != ztSuccess){
      fprintf(stderr, "%s: Error failed file2StringList()\n", progName);
      goto CLEANUP;
    }

    /* we need GEOMETRY (list) to parse geometry into **/
    geometry = initialGeometry();
    if(!geometry){
      fprintf(stderr, "%s: Error failed initialGeometry().\n", progName);
      result = ztMemoryAllocate;
      goto CLEANUP;
    }

    result = parseGeometry(geometry, geomStrList);
    if(result != ztSuccess){
      fprintf(stderr, "%s: Error failed parseGeometry()\n Returned code: <%s>\n",
    		  progName, ztCode2ErrorStr(result));
      goto CLEANUP;
    }

    /* we could write POINT & LINESTRING to files ... (use progName as prefix)
     * or write all files as below.
     *
     ********************************************************************/

    /* list of STRING_LIST is needed to hold geometry WKT **/
    listListStr = initialListStrList();
    if(!listListStr){
      fprintf(stderr, "%s: Error failed initialListStrList().\n", progName);
      result = ztMemoryAllocate;
      goto CLEANUP;
    }

    result = geom2WktListListStr(listListStr, geometry, seg2LinestringWktStrList);
    if(result != ztSuccess){
      fprintf(stderr, "%s: Error failed geom2WktListListStr()\n", progName);
      goto CLEANUP;
    }

    fprintf(stdout, "wkt;\n"); /* in case you want to save file; start with "wkt;" string **/

    fprintListStrList(NULL, listListStr); /* writes to 'stdout' - terminal **/

    goto CLEANUP;

  }

  /* argc != 1; we have a geometry file, or maybe a list of files **/

  char  *inputfile;

  char  *pointSuffix = "_Point.csv";
  char  *linestringSuffix = "_Linestring.csv";

  char  wktPointFile[PATH_MAX] = {0};
  char  wktLinestringFile[PATH_MAX] = {0};

  //int writeGeomWkt(char *destFile, GEOMETRY *geom, WKT_ENTITY wktEntity)

  for(int i=1; i < argc; i++){

    inputfile = argv[i];

    geomStrList = initialStringList();
    if(!geomStrList){
      fprintf(stderr, "%s: Error failed initialStringList().\n", progName);
      result = ztMemoryAllocate;
      goto CLEANUP;
    }

    result = file2StringList(geomStrList, inputfile);
    if(result != ztSuccess){
      fprintf(stderr, "%s: Error failed file2StringList()\n", progName);
      goto CLEANUP;
    }

    geometry = initialGeometry();
    if(!geometry){
      fprintf(stderr, "%s: Error failed initialGeometry().\n", progName);
      result = ztMemoryAllocate;
      goto CLEANUP;
    }

    result = parseGeometry(geometry, geomStrList);
    if(result != ztSuccess){
      fprintf(stderr, "%s: Error failed parseGeometry()\n Returned code: <%s>\n", progName, ztCode2ErrorStr(result));
      goto CLEANUP;
    }

    /* make output file name; we drop extension then append "_Point.csv"
     * for WKT POINT.
     *******************************************************************/
    sprintf(wktPointFile, "%s%s", dropExtension(inputfile), pointSuffix);

    result = writeGeomWkt(wktPointFile, geometry, WKT_POINT);
    if(result != ztSuccess){
      fprintf(stderr, "%s: Error failed writeGeomWkt() for POINT.\n", progName);
      goto CLEANUP;
    }

    /* LINESTRING file gets a different name with "_Linestring.csv" **/
    sprintf(wktLinestringFile, "%s%s", dropExtension(inputfile), linestringSuffix);

    result = writeGeomWkt(wktLinestringFile, geometry, WKT_LINESTRING);
    if(result != ztSuccess){
      fprintf(stderr, "%s: Error failed writeGeomWkt() for LINESTRING.\n", progName);
      goto CLEANUP;
    }

    zapStringList((void **) &geomStrList);

    zapGeometry(&geometry);

  }

  CLEANUP:

  if(geomStrList)
    zapStringList((void **) &geomStrList);

  if(geometry)
    zapGeometry(&geometry);

  if(listListStr)
	zapListStrList((void **) &listListStr);

  return result;
}

