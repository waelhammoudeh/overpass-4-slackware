/*
 * formatWkt.h
 *
 *  Created on: Dec 17, 2023
 *  Author: Wael Hammoudeh
 */

#ifndef FORMATWKT_H_
#define FORMATWKT_H_

#ifndef ZTERROR_H_
#include "ztError.h"
#endif

#ifndef DLIST_H_
#include "list.h"
#endif

#ifndef UTIL_H_
#include "util.h"
#endif

#ifndef PRIMITIVES_H_
#include "primitives.h"
#endif


#ifndef COMPUTE_H_
#include "compute.h"
#endif

#ifndef LONG_LINE
#define LONG_LINE 1024
#endif

#define POINT_WKT_SIZE 36

/* number of GPS points to fit in formatted LINESTRNG as WKT **/
#define ODD_QRTR_MAX 9
#define THREE_QRTR_MAX 10

#define LS_FIT_10 10
#define LS_FIT_9  9

typedef enum WKT_ENTITY_ {

	WKT_POINT = 1,
	WKT_LINESTRING,
	WKT_POLYGON

} WKT_ENTITY;

int gps2PointWkt(char **destStr, GPS *gps);

char *gps2PointWktCh(GPS *gps);

int gpsList2PointWktStrList (STRING_LIST *strList, GPS_LIST *gpsList);

int seg2PointWktStrList(STRING_LIST *strList, SEGMENT *seg);

int wktLinestringFit(char **dest, ELEM *start, int fitCount);

int seg2LinestringWktStrList (STRING_LIST *strList, SEGMENT *seg);

int geom2WktListListStr(LIST_STR_LIST *listListStr, GEOMETRY *geom,
		int seg4Wkt(STRING_LIST *list, SEGMENT *seg));

int poly2PointWktStrList(STRING_LIST *strList, POLYGON *poly);

int poly2LinestringWktStrList (STRING_LIST *strList, POLYGON *poly);

int poly2PolygonWktChar(char **wktDest, POLYGON *poly);









int gpsList2PointWkt (char **wktStr, GPS_LIST *gpsList);

int seg2PointWkt(char **wktDest, SEGMENT *seg);

int seg2LinestringWkt (char **dest, SEGMENT *seg);

int geom2PointWkt (char **destStr, GEOMETRY *geom);

int geom2LinestringWkt (char **destStr, GEOMETRY *geom);

int poly2PointWkt(char **wktDest, POLYGON *poly);

int poly2PolygonWkt9(char **wktDest, POLYGON *poly);

int poly2PolygonWktU(char **wktDest, POLYGON *poly);

int bbox2PolygonWkt(char **wktStr, BBOX *bbox);

int line2PointWkt(char **dstCh, LINE *line);

int line2LinestringWkt(char **dstCh, LINE *line);

int catWktStringList (char **destStr,  STRING_LIST *wktStrList);

int sizeLongestStrList(STRING_LIST *strList);



#endif /* FORMATWKT_H_ */
