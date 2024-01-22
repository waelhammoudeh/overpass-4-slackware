/*
 * fileio.h
 *
 *  Created on: Dec 19, 2018
 *      Author: wael
 */

#ifndef FILEIO_H_
#define FILEIO_H_

#ifndef PRIMITIVES_H_
#include "primitives.h"
#endif

#ifndef FORMATWKT_H_
#include "formatWkt.h"
#endif

/* MAX_TEXT maximum line string length.
 *
 * seems that OSM data has maximum line length of 256 characters,
 * probably we should use 256 here.
 * 256 256 256 256 256 256 256 256 256 256 256 256 256 256 256 256
 * 256 256 256 256 256 256 256 256 256 256 256 256 256 256 256 256
 *
 **************************************************************/
#define MAX_TEXT 512

/* change this path if you have it somewhere else */
#define OGR2OGR_EXEC "/usr/bin/ogr2ogr"


int file2StringList(STRING_LIST *strList, const char *filename);

int stringList2File(const char *filename, STRING_LIST *list);

ELEM* findElemSubString (STRING_LIST *list, char *subString);

int removeFile(const char *filename);

int renameFile(const char *oldName, const char *newName);

FILE *prepWktFile(const char *file);

int writeGpsWkt(char *file, GPS *gps);

int writeWktStrList(char *file, DLIST *entity, int strListFun(STRING_LIST *, DLIST *));

int writeGeomWkt(char *destFile, GEOMETRY *geom, WKT_ENTITY wktEntity);

int writeBboxWktPolygon(char *toFile, BBOX *bbox);

int wkt2Shapefile (char *infile);

int writeSegmentWktByNum(GEOMETRY *geometry, int segNum, char *toDir, char *fPrefix);


#endif /* FILEIO_H_ */
