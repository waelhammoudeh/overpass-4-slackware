/*
 * primitives.h
 *
 *  Created on: Nov 5, 2023
 *      Author: wael
 *
 *  rewrite from older version 11/5/2023
 *  This file includes basic structures
 */

#ifndef PRIMITIVES_H_
#define PRIMITIVES_H_

#include "list.h"

/* basic type definitions **/

typedef struct GPS_ {

  double  longitude, latitude;

} GPS;

/* gps as string; compare points **/
typedef struct GPS_STRING_ {

	char    longitude[15];
	char    latitude[15];

} GPS_STRING;

typedef struct MCHB_ { /* Maricopa County Hundred Block point */

  int    ns, ew;

} MCHB;

typedef struct POINT_ {

  GPS		gps;
  MCHB		mchb;
  char		*name;

} POINT;

/* BBOX: bounding box **/
typedef struct BBOX_ {

  GPS    sw, ne;

} BBOX;

typedef struct LINE_ {

	GPS *gps1,
	    *gps2;

} LINE;

typedef enum DIRECTION_ {

	EAST = 1,
	WEST,
	NORTH,
	SOUTH

} DIRECTION;

typedef enum PLACEMENT_ {

	HORIZONTAL = 1,
	VERTICAL,
	DIAGONAL

} PLACEMENT;

#define OK_PLACEMENT(x) ((x == HORIZONTAL) || (x == VERTICAL))

/* List Type constant */
#define STRING_LT   1
#define	GPS_LT      2
#define	SEGMENT_LT  3
#define	GEOMETRY_LT 4
#define POLYGON_LT  5
#define FRQNCY_LT   6
#define LIST_STRL_LT 7

typedef DLIST STRING_LIST;
typedef DLIST GPS_LIST;
typedef DLIST SEGMENT;
typedef DLIST GEOMETRY;
typedef DLIST POLYGON;
typedef DLIST FRQNCY_LIST;
typedef DLIST LIST_STR_LIST;

#define TYPE_STRING_LIST(list) ((list)->listType == STRING_LT)
#define TYPE_GPS_LIST(list) ((list)->listType == GPS_LT)
#define TYPE_SEGMENT(list) ((list)->listType == SEGMENT_LT)
#define TYPE_GEOMETRY(geometry) ((geometry)->listType == GEOMETRY_LT)
#define TYPE_POLYGON(list) ((list)->listType == POLYGON_LT)
#define TYPE_FRQNCY_LIST(list) ((list)->listType == FRQNCY_LT)
#define TYPE_LIST_STR_LIST(list) ((list)->listType == LIST_STRL_LT)

/* functions prototypes **/

STRING_LIST *initialStringList();

GPS_LIST *initialGpsList();

void zapGpsList(GPS_LIST **gpsList);

SEGMENT *initialSegment();

GEOMETRY *initialGeometry();

POLYGON *initialPolygon();

void zapPolygon(void **poly);

FRQNCY_LIST *initialFrqncyList();

GPS *initialGps();

void zapGps(void **gps);

#ifndef ZAP_STRING

void zapString(void **string);

#endif

LINE *initialLine();

void zapLine(void **line);

BBOX *initialBbox();

void zapBbox(void **bbox);

int isBbox(BBOX *bbox);

int line2GpsList(GPS_LIST *gpsList, LINE *line);

int line2Segment(SEGMENT *segment, LINE *line);

POLYGON *bbox2Polygon(BBOX *bbox);

LINE *getBoxLine(BBOX *box, DIRECTION which);

void fprintGps (FILE *toFile, GPS *gps);

void fprintGpsList (FILE *toFile, DLIST *gpsList, char *heading);

void fprintSegment(FILE *toFile, SEGMENT *segment, char *heading);

void fprintPolygon(FILE *toFile, POLYGON *poly, char *heading);

void fprintGeometry(FILE *toFile, GEOMETRY *geometry);

void fprintBbox (FILE *toFP, BBOX *bbox);

void fprintStringList (FILE *toFP, DLIST *stringList);

LIST_STR_LIST *initialListStrList();

void zapListStrList(void **list);

void fprintListStrList(FILE *toFP, LIST_STR_LIST *listListStr);

void zapStringList(void **strList);

void zapSegment(void **seg);

void zapGeometry(GEOMETRY **geom);




/* ARIZONA ONLY ... ARIZONA ONLY .... ARIZONA ONLY
 *
 * LONGITUDE_OK(i) and LATITUDE_OK(i) are both
 *  macros to validate longitude and latitude values in
 *  the state of Arizona ONLY.
 *
 * CHANGE THOSE VALUES FOR YOUR LOCAL AREA.
 *
 * SW & NE points copied in QGIS window
 * 31.090,-115.173
 * 37.172,-108.853
 *
 * ARIZONA ONLY ... ARIZONA ONLY .... ARIZONA ONLY
 **********************************************************/

#define LONGITUDE_OK(i) (((i) > -115.2 && (i) < -108.0))
#define LATITUDE_OK(i) (((i) > 31.0 && (i) < 37.2))

#define OK_AZ_GPS(gps) ( (LONGITUDE_OK((gps)->longitude)) && (LATITUDE_OK((gps)->latitude)) )

int text2StringList(STRING_LIST *strList, char *text);

#define COUNT_80 80

void fprintGpsListGeneric (FILE *toFile, POLYGON *gpsList, char *heading);

#endif /* PRIMITIVES_H_ **/
