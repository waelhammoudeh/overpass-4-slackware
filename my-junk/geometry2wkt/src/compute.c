/*
 * compute.c
 *
 *  Created on: Dec 17, 2023
 *  Author: Wael Hammoudeh
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "compute.h"

/* maxSegLon() : maximum longitude in SEGMENT
 * SEGMENT is a linked list of GPS points.
 *
 * Returns: a pointer to element (ELEM *).
 * DL_DATA(elem) ==> (GPS *).
 ***************************************************/
ELEM  *maxSegLon(double *foundValue, SEGMENT *seg){

  /* return pointer to ELEM with maximum longitude in a gps list */
  ELEM    *elem = NULL;
  ELEM    *elemHasMax;
  GPS    *gps, *nextGps;

  double    currentMax, oldMax;

  ASSERTARGS (foundValue && seg);

  /* commented out to use for polygon
     if ( ! TYPE_SEGMENT(seg) ){
     fprintf(stderr, "maxSegLon(): Error parameter seg is not of SEGMENT_LT.\n");
     return elem;
     }
  **/

  if (DL_SIZE(seg) < 1)

    return elem;

  elem = DL_HEAD(seg);
  gps = (GPS *) DL_DATA(elem);
  currentMax = gps->longitude;


  if (DL_SIZE(seg) == 1){

    *foundValue = currentMax;
    return elem;
  }

  elemHasMax = elem;
  while (DL_NEXT(elem)) {

    oldMax = currentMax;
    nextGps = (GPS *) DL_DATA(DL_NEXT(elem));

    currentMax = MAX(oldMax, nextGps->longitude);

    if (currentMax != oldMax){

      elemHasMax = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  elem = elemHasMax;
  *foundValue = currentMax;

  return elem;

} /* END maxSegLon() */

ELEM  *minSegLon(double *foundValue, SEGMENT *seg){

  /* minimum longitude in a gps list - SEGMENT. */
  ELEM    *elem = NULL;
  ELEM    *elemHasMin;
  GPS    *gps, *nextGps;

  double    currentMin, oldMin;

  ASSERTARGS (foundValue && seg);

  /*
    if ( ! TYPE_SEGMENT(seg) ){
    fprintf(stderr, "minSegLon(): Error parameter seg is not of SEGMENT_LT.\n");
    return elem;
    }
  **/

  if (DL_SIZE(seg) < 1)

    return elem;

  elem = DL_HEAD(seg);
  gps = (GPS *) DL_DATA(elem);
  currentMin = gps->longitude;


  if (DL_SIZE(seg) == 1){

    *foundValue = currentMin;
    return elem;
  }

  elemHasMin = elem;
  while (DL_NEXT(elem)) {

    oldMin = currentMin;
    nextGps = (GPS *) DL_DATA(DL_NEXT(elem));

    currentMin = MIN(oldMin, nextGps->longitude);

    if (currentMin != oldMin){

      elemHasMin = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  elem = elemHasMin;
  *foundValue = currentMin;

  return elem;

} /* END minSegLon() */

/* maxSegLat() : maximum latitude in a SEGMENT.
 *
 *
 * Returns: (ELEM *) in SEGMENT; DL_DATA(elem) --> (GPS *)
 ******************************************************/
ELEM  *maxSegLat(double *foundValue, SEGMENT *seg){

  /* maximum latitude in a gps list */
  ELEM    *elem = NULL;
  ELEM    *elemHasMax;
  GPS    *gps, *nextGps;

  double    currentMax, oldMax;


  ASSERTARGS (foundValue && seg);

  /*
    if ( ! TYPE_SEGMENT(seg) ){
    fprintf(stderr, "maxSegLat(): Error parameter seg is not of SEGMENT_LT.\n");
    return elem;
    }
  **/

  if (DL_SIZE(seg) < 1)

    return elem;

  elem = DL_HEAD(seg);
  gps = (GPS *) DL_DATA(elem);
  currentMax = gps->latitude;


  if (DL_SIZE(seg) == 1){

    *foundValue = currentMax;
    return elem;
  }

  elemHasMax = elem;
  while (DL_NEXT(elem)) {

    oldMax = currentMax;
    nextGps = (GPS *) DL_DATA(DL_NEXT(elem));

    currentMax = MAX(oldMax, nextGps->latitude);

    if (currentMax != oldMax){

      elemHasMax = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  elem = elemHasMax;
  *foundValue = currentMax;

  return elem;

} /* END maxSegLat() */

ELEM  *minSegLat(double *foundValue, SEGMENT *seg){

  /* minimum longitude in a gps list */
  ELEM    *elem = NULL;
  ELEM    *elemHasMin;
  GPS    *gps, *nextGps;

  double    currentMin, oldMin;

  ASSERTARGS (foundValue && seg);

  /*
    if ( ! TYPE_SEGMENT(seg) ){
    fprintf(stderr, "minSegLat(): Error parameter seg is not of SEGMENT_LT.\n");
    return elem;
    }
  **/

  if (DL_SIZE(seg) < 1)

    return elem;

  elem = DL_HEAD(seg);
  gps = (GPS *) DL_DATA(elem);
  currentMin = gps->latitude;


  if (DL_SIZE(seg) == 1){

    *foundValue = currentMin;
    return elem;
  }

  elemHasMin = elem;
  while (DL_NEXT(elem)) {

    oldMin = currentMin;
    nextGps = (GPS *) DL_DATA(DL_NEXT(elem));

    currentMin = MIN(oldMin, nextGps->latitude);

    if (currentMin != oldMin){

      elemHasMin = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  elem = elemHasMin;
  *foundValue = currentMin;

  return elem;

} /* END minSegLat() */

ELEM *maxGeomLon (double *foundValue, GEOMETRY *geom){

  /* find maximum longitude in geometry,
   * Returns a pointer to element (ELEM *) in geom.
   * The data pointer is for a SEGMENT .
   * If you need (GPS *), you need to call maxSegLon().
   *
   *************************************************/

  ELEM    *elemWithMax = NULL;

  SEGMENT    *seg, *nextSeg;
  ELEM    *elem, *gpsElem;
  double    currentValue, oldValue, value4List;

  ASSERTARGS(foundValue && geom);

  if ( ! TYPE_GEOMETRY(geom)  ){
    fprintf(stderr, "maxGeomLon(): Error parameter geom is not of GEOMETRY_LT.\n");
    return elemWithMax;
  }

  if (DL_SIZE(geom) < 1){

    fprintf(stderr, "maxGeomLon(): Error parameter geom is empty list.\n");
    return elemWithMax;
  }

  elem = DL_HEAD(geom);

  seg = (SEGMENT *) DL_DATA(elem);

  gpsElem = maxSegLon (&currentValue, seg);
  if ( ! gpsElem ){
    fprintf(stderr, "maxGeomLon(): Error failed maxSegLon() for head segment.\n");
    return elemWithMax;
  }

  elemWithMax = elem;
  *foundValue = currentValue;

  while (DL_NEXT(elem)){

    oldValue = currentValue;

    nextSeg = (SEGMENT *) DL_DATA(elem->next);

    gpsElem = maxSegLon (&value4List, nextSeg);
    if ( ! gpsElem ){

      fprintf(stderr, "maxGeomLon(): Error failed maxSegLon() function.\n");

      elemWithMax = NULL;
      *foundValue = 0;
      return elemWithMax;
    }

    currentValue = MAX(oldValue, value4List);
    if (currentValue != oldValue){

      elemWithMax = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  *foundValue = currentValue;

  return elemWithMax;

} /* END maxGeomLon() */

ELEM *minGeomLon (double *foundValue, GEOMETRY *geom){

  /* find the list with MINIMUM longitude in geometry,
   * returns (ELEM *), DL_DATA(elem) --> pointer to Segment,
   * and sets foundValue.
   *************************************************/

  ELEM    *elemWithMin = NULL;

  SEGMENT    *seg, *nextSeg;
  ELEM    *elem, *gpsElem;
  double    currentValue, oldValue, value4List;

  ASSERTARGS(foundValue && geom);

  if ( ! TYPE_GEOMETRY(geom)  ){
    fprintf(stderr, "minGeomLon(): Error parameter geom is not of GEOMETRY_LT.\n");
    return elemWithMin;
  }

  if (DL_SIZE(geom) < 1){
    fprintf(stderr, "minGeomLon(): Error parameter geom is empty list.\n");
    return elemWithMin;
  }

  elem = DL_HEAD(geom);
  seg = (SEGMENT *) DL_DATA(elem);

  gpsElem = minSegLon(&currentValue, seg);
  if ( ! gpsElem ){
    fprintf(stderr, "minGeomLon(): Error failed minSegLon() function for head segment.\n");
    return elemWithMin;
  }

  elemWithMin = elem;
  *foundValue = currentValue;

  while (DL_NEXT(elem)){

    oldValue = currentValue;

    nextSeg = (SEGMENT *) DL_DATA(elem->next);

    gpsElem = minSegLon(&value4List, nextSeg);
    if ( ! gpsElem ){
      fprintf(stderr, "minGeomLon(): Error failed minSegLon() for next segment.\n");

      elemWithMin = NULL;
      *foundValue = 0;

      return elemWithMin;
    }

    currentValue = MIN(oldValue, value4List);
    if (currentValue != oldValue){

      elemWithMin = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  *foundValue = currentValue;

  return elemWithMin;

} /* END minGeomLon() */

ELEM *maxGeomLat(double *foundValue, GEOMETRY *geom){

  /* find MAXIMUM latitude in geometry,
   * returns a pointer to ELEM with SEGMENT which has maximum latitude
   * and sets foundValue.
   *************************************************/

  ELEM    *elemWithMax = NULL;

  SEGMENT    *seg, *nextSeg;
  ELEM    *elem, *gpsElem;
  double    currentValue, oldValue, value4List;

  ASSERTARGS(foundValue && geom);

  if ( ! TYPE_GEOMETRY(geom)  ){
    fprintf(stderr, "maxGeomLat(): Error parameter geom is not of GEOMETRY_LT.\n");
    return elemWithMax;
  }

  if (DL_SIZE(geom) < 1){
    fprintf(stderr, "maxGeomLat(): Error parameter geom is empty list.\n");
    return elemWithMax;
  }

  elem = DL_HEAD(geom);
  seg = (SEGMENT *) DL_DATA(elem);

  gpsElem = maxSegLat(&currentValue, seg);
  if ( ! gpsElem ){
    fprintf(stderr, "maxGeomLat(): Error failed maxSegLat() function for head segment.\n");
    return elemWithMax;
  }

  elemWithMax = elem;
  *foundValue = currentValue;

  while (DL_NEXT(elem)){

    oldValue = currentValue;

    nextSeg = (DLIST *) DL_DATA(elem->next);

    gpsElem = maxSegLat(&value4List, nextSeg);
    if ( ! gpsElem ){
      fprintf(stderr, "maxGeomLat(): Error failed maxSegLat() for next segment.\n");

      elemWithMax = NULL;
      *foundValue = 0;

      return elemWithMax;
    }

    currentValue = MAX(oldValue, value4List);
    if (currentValue != oldValue){

      elemWithMax = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  *foundValue = currentValue;

  return elemWithMax;

} /* END maxGeomLat() */

ELEM *minGeomLat(double *foundValue, GEOMETRY *geom){

  /* find the list with MINIMUM latitude in geometry,
   * returns (gpsDL) DLIST and sets foundValue.
   *************************************************/

  ELEM    *elemWithMin = NULL;

  //  DLIST    *gpsDL, *nextGpsDL;
  SEGMENT    *seg, *nextSeg;
  ELEM    *elem, *gpsElem;
  double    currentValue, oldValue, value4List;

  ASSERTARGS(foundValue && geom);

  if ( ! TYPE_GEOMETRY(geom)  ){
    fprintf(stderr, "minGeomLat(): Error parameter geom is not of GEOMETRY_LT.\n");
    return elemWithMin;
  }

  if (DL_SIZE(geom) < 1){
    fprintf(stderr, "minGeomLat(): Error parameter geom is empty list.\n");
    return elemWithMin;
  }

  elem = DL_HEAD(geom);
  seg = (SEGMENT *) DL_DATA(elem);

  gpsElem = minSegLat(&currentValue, seg);
  if ( ! gpsElem ){
    fprintf(stderr, "minGeomLat(): Error failed minSegLat() function for head segment.\n");
    return elemWithMin;
  }

  elemWithMin = elem;
  *foundValue = currentValue;

  while (DL_NEXT(elem)){

    oldValue = currentValue;

    nextSeg = (SEGMENT *) DL_DATA(elem->next);

    gpsElem = minSegLat(&value4List, nextSeg);
    if ( ! gpsElem ){
      fprintf(stderr, "minGeomLat(): Error failed minSegLat() function for next segment.\n");

      elemWithMin = NULL;
      *foundValue = 0;

      return elemWithMin;
    }

    currentValue = MIN(oldValue, value4List);
    if (currentValue != oldValue){

      elemWithMin = DL_NEXT(elem);
    }

    elem = DL_NEXT(elem);
  }

  *foundValue = currentValue;

  return elemWithMin;

} /* END minGeomLat() */


int gps2String(GPS_STRING *gpsStr, GPS *gps){

  /* we compare GPS points as STRINGS, computation function.
   * convert GPS structure to GPS_STRING structure,
   * longitude & latitude are printed with 10.7f% directive.
   * client allocates memory for destination gpsStr structure.
   * Longitude & latitude values in gps are checked to be
   * valid values in ARIZONA.
   *
   * ARIZONA POINTS ONLY. ARIZONA POINTS ONLY.
   * ARIZONA POINTS ONLY. ARIZONA POINTS ONLY.
   *
   * LONGITUDE_OK() & LATITUDE_OK() are defined in the
   * "op_query.h" file. In case you need to change those.
   *******************************************************/

  ASSERTARGS (gpsStr && gps);

  if ( ! LONGITUDE_OK(gps->longitude) ){
    fprintf(stderr, "gps2String(): Error invalid value for longitude <%10.7f> in Arizona.\n",
	    gps->longitude);
    return ztInvalidArg;
  }

  if ( ! LATITUDE_OK(gps->latitude) ){
    fprintf(stderr, "gps2String(): Error invalid value for latitude <%10.7f> in Arizona.\n",
	    gps->latitude);
    return ztInvalidArg;
  }

  sprintf(gpsStr->longitude, "%10.7f", gps->longitude);

  sprintf(gpsStr->latitude, "%10.7f", gps->latitude);

  return ztSuccess;

} /* END gps2String() */

int arePointsEqual(GPS *p1, GPS *p2){

  /* arePointsEqual() : are 2 points equal? converts GPS to string & compare */

  ASSERTARGS (p1 && p2);

  GPS_STRING    firstPointStr, secondPointStr;
  int    result;

  result = gps2String(&firstPointStr, p1);
  if (result != ztSuccess){
    fprintf(stderr, "arePointsEqual(): Error could not convert first point to string!\n");
    return FALSE;
  }

  result = gps2String(&secondPointStr, p2);
  if (result != ztSuccess){
    fprintf(stderr, "arePointsEqual(): Error could not convert second point to string!\n");
    return FALSE;
  }

  if ( (strcmp(firstPointStr.longitude, secondPointStr.longitude) == 0) &&
       (strcmp(firstPointStr.latitude, secondPointStr.latitude) == 0) ){

    return TRUE;
  }

  return FALSE;

} /* END arePointsEqual() */

int isClosedSegment(SEGMENT *seg){

  /* circles in OSM data come in one segment, triangle is not considered a circle **/

  GPS    *headGps, *tailGps;

  ASSERTARGS(seg);

  if (DL_SIZE(seg) < 5)

    return FALSE;

  headGps = (GPS *) DL_DATA(DL_HEAD(seg));

  tailGps = (GPS *) DL_DATA(DL_TAIL(seg));

  if (arePointsEqual (headGps, tailGps) == TRUE)

    return TRUE;

  return FALSE;

} /* END isClosedSegment() **/


GPS *polygonCenter(POLYGON *polygon){

  static GPS    *cntrGps = NULL;

  double maxLongitude, minLongitude;
  double maxLatitude, minLatitude;

  ELEM    *elem;

  ASSERTARGS(polygon);

  if(isPolygon(polygon) != TRUE){
    fprintf(stderr, "polygonCenter(): Error invalid POLYGON in parameter 'polygon'.\n");
    return cntrGps;
  }

  elem = maxSegLon(&maxLongitude, polygon);
  if ( ! elem){
    fprintf(stderr, "polygonCenter(): Error failed maxSegLon() function.\n");
    return cntrGps;
  }

  elem = minSegLon(&minLongitude, polygon);
  if ( ! elem){
    fprintf(stderr, "polygonCenter(): Error failed minSegLon() function.\n");
    return cntrGps;
  }

  elem = maxSegLat(&maxLatitude, polygon);
  if ( ! elem){
    fprintf(stderr, "polygonCenter(): Error failed maxSegLat() function.\n");
    return cntrGps;
  }

  elem = minSegLat(&minLatitude, polygon);
  if ( ! elem){
    fprintf(stderr, "polygonCenter(): Error failed minSegLat() function.\n");
    return cntrGps;
  }

  cntrGps = (GPS *) malloc(sizeof(GPS));
  if( ! cntrGps){
    fprintf(stderr, "polygonCenter(): Error allocating memory.\n");
    return cntrGps;
  }

  cntrGps->longitude = (maxLongitude + minLongitude) / 2.0;
  cntrGps->latitude = (maxLatitude+ minLatitude) / 2.0;

  return cntrGps;

} /* END polygonCenter() **/

/* isPolygon(): is polygon argument good as POLYGON?
 * returns TRUE or FALSE.
 * Polygon must have at least 3 vertices, list type == POLYGON_LT and closed;
 * closed means first GPS must equal last GPS.
 *
 */
int isPolygon(POLYGON *polygon){

  GPS    *headGps, *tailGps;

  ASSERTARGS(polygon);

  if ( ! TYPE_POLYGON(polygon) )

    return FALSE;

  if (DL_SIZE(polygon) < 4)

    return FALSE;

  headGps = (GPS *) DL_DATA(DL_HEAD(polygon));
  tailGps = (GPS *) DL_DATA(DL_TAIL(polygon));

  if (arePointsEqual(headGps, tailGps) != TRUE)

    return FALSE;

  return TRUE;

} /* END isPolygon() **/

