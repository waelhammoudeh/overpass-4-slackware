/*
 * compute.h
 *
 *  Created on: Dec 17, 2023
 *  Author: Wael Hammoudeh
 */

#ifndef COMPUTE_H_
#define COMPUTE_H_

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



ELEM  *maxSegLon(double *foundValue, SEGMENT *seg);
ELEM  *minSegLon(double *foundValue, SEGMENT *seg);

ELEM  *maxSegLat(double *foundValue, SEGMENT *seg);
ELEM  *minSegLat(double *foundValue, SEGMENT *seg);

ELEM  *maxGeomLon(double *foundValue, GEOMETRY *geom);
ELEM  *minGeomLon(double *foundValue, GEOMETRY *geom);

ELEM  *maxGeomLat(double *foundValue, GEOMETRY *geom);
ELEM  *minGeomLat(double *foundValue, GEOMETRY *geom);


int gps2String(GPS_STRING *gpsStr, GPS *gps);

int arePointsEqual(GPS *p1, GPS *p2);

int isClosedSegment(SEGMENT *seg);

GPS *polygonCenter(POLYGON *polygon);

int isPolygon(POLYGON *polygon);


#endif /* MYINCLUDE_COMPUTE_H_ */
