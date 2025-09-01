/*
 * formatWKT.c
 *
 *  Created on: Dec 16, 2023
 *  Author: Wael Hammoudeh
 *
 *  functions to format our defined structures into Well Known Text
 *  Well Known entities produced include: Point,Linestring and Polygon
 *
 *********************************************************************/

#include <stdio.h>
#include <string.h>

#include "formatWkt.h"

static char *gps2PolyVertex(GPS *gps);


// old static functions bellow
static int wktLinestringCount (char *line, ELEM *startGps, int iCount);

static char *formatPolyVertex(GPS *gps);

/* gps2WktPoint(): 
 * formats one GPS into POINT Well Known Text
 * function allocates memory for destination in parameter 'destStr'
 *
 * Output format example:
 * "POINT (-111.9609191 33.3863240)"
 * "POINT (-111.9609191 -33.3863240)"
 *
 * Note that the above string ends with a linefeed character.
 * The string length is 35 characters.
 *
 * Returns 
 *  - ztSuccess on success
 *  - ztMemoryAllocate on failure
 *
 *********************************************************************/

int gps2PointWkt(char **destStr, GPS *gps){

  int   bufferSize = POINT_WKT_SIZE;
  int   result;

  ASSERTARGS (destStr && gps);

  /* do NOT skip test. bad gps could overflow fixed length buffer **/
  if(! OK_AZ_GPS(gps))

    return ztInvalidGpsValue;

  /* allocate memory **/
  *destStr = (char *)malloc(bufferSize * sizeof(char));
  if(!(*destStr)){
    fprintf (stderr, "gps2PointWkt(): Error allocating memory.\n");
    *destStr = NULL;
    return ztMemoryAllocate;
  }

  /* write formatted WKT POINT **/
  result = snprintf(*destStr, bufferSize, "\"POINT (%10.7f %10.7f)\"",
                    gps->longitude, gps->latitude);
  if(result < 0 || result >= bufferSize){
    fprintf (stderr, "gps2PointWkt(): Error failed snprintf()\n");
    free(*destStr);
    *destStr = NULL;
    return ztFailedLibCall;
  }

  return ztSuccess;

} /* END gps2PointWkt() */

char *gps2PointWktCh(GPS *gps){

  static char *wktStr = NULL;

  int   bufferSize = POINT_WKT_SIZE; /* from "formatWkt.h": #define POINT_WKT_SIZE 36 **/
  int   result;

  ASSERTARGS(gps);

  /* do NOT skip test. bad gps could overflow fixed length buffer **/
  if(! OK_AZ_GPS(gps)) return wktStr;

  /* allocate memory **/
  wktStr = (char *)malloc((bufferSize + 1) * sizeof(char));
  if(!wktStr){
    fprintf (stderr, "gps2PointWktCh(): Error allocating memory.\n");
    return wktStr;
  }

  /* write formatted WKT POINT **/
  result = snprintf(wktStr, bufferSize, "\"POINT (%10.7f %10.7f)\"",
                    gps->longitude, gps->latitude);
  if(result < 0 || result >= bufferSize){
    fprintf (stderr, "gps2PointWktCh(): Error failed snprintf()\n");
    free(wktStr);
    wktStr = NULL;
    return wktStr;
  }

  return wktStr;

} /* END gps2PointWktCh() **/

int gpsList2PointWktStrList (STRING_LIST *strList, GPS_LIST *gpsList){

  ASSERTARGS(strList && gpsList);

  if (DL_SIZE(gpsList) == 0){
    fprintf(stderr, "gpsList2PointWkStrList(): Error empty list in source parameter 'gpsList'.\n");
    return ztListEmpty;
  }
  if(! TYPE_GPS_LIST(gpsList) ){
    fprintf(stderr, "gpsList2PointWkStrList(): Error parameter 'gpsList' is not of type GPS_LT.\n");
    return ztInvalidArg;
  }

  if (DL_SIZE(strList) != 0){
    fprintf(stderr, "gpsList2PointWkStrList(): Error destination list in parameter 'gpsList' is NOT empty.\n");
    return ztListNotEmpty;
  }
  if(! TYPE_STRING_LIST(strList) ){
    fprintf(stderr, "gpsList2PointWkStrList(): Error parameter 'strList' is not of type STRING_LT.\n");
    return ztInvalidArg;
  }

  ELEM  *elem;
  GPS   *gps;
  int   result;

  elem = DL_HEAD(gpsList);
  while(elem){

    gps = (GPS *)DL_DATA(elem);

    if(!gps){
      fprintf(stderr,"gpsList2PointWkStrList(): Error could not retrieve gps; bad pointer!\n");
      return ztFatalError;
    }

    char  *wktStr = NULL;

    wktStr = gps2PointWktCh(gps);
    if(! wktStr){
      fprintf(stderr, "gpsList2PointWkStrList(): Error failed gps2PointWktCh() function.\n");
      return ztMemoryAllocate;
    }

    result = insertNextDL (strList, DL_TAIL(strList), (void *) wktStr);
    if (result != ztSuccess){
      fprintf(stderr, "gpsList2PointWkStrList(): Error returned by insertNextDL().\n");
      return result;
    }

    elem = DL_NEXT(elem);
  }

  return ztSuccess;

} /* END gpsList2PointWkStrList() **/


int seg2PointWktStrList(STRING_LIST *strList, SEGMENT *seg){

  int  result;

  ASSERTARGS(strList && seg);

  if (DL_SIZE(seg) == 0){
    fprintf(stderr, "seg2PointWktStrList() : Error source parameter 'seg' is Empty list.\n");
    return ztInvalidArg;
  }
  if ( ! TYPE_SEGMENT(seg) ){
    fprintf(stderr, "seg2PointWktStrList() : Error parameter 'seg' is not of SEGMENT_LT type.\n");
    return ztInvalidArg;
  }

  if (DL_SIZE(strList) != 0){
    fprintf(stderr, "seg2PointWktStrList() : Error destination parameter 'strList' is NOT empty list.\n");
    return ztInvalidArg;
  }
  if ( ! TYPE_STRING_LIST(strList) ){
    fprintf(stderr, "seg2PointWktStrList() : Error parameter 'strList' is not of STRING_LT type.\n");
    return ztInvalidArg;
  }


  /* we fake listType, to call gpsList2PointWkt(). */
  seg->listType = GPS_LT;

  result = gpsList2PointWktStrList(strList, seg);

  /* reset listType back to SEGMENT_LT */
  seg->listType = SEGMENT_LT;

  if(result != ztSuccess){
    fprintf(stderr, "segt2PointWktStrList() : Error failed gpsList2PointWktStrList() function.\n");
    return result;
  }

  return ztSuccess;

} /* END seg2PointWktStrList() */

/**
 * wktLinestringFit():
 *
 * Generates a Well Known Text (WKT) representation of a LINESTRING from
 * a list of GPS points with maximum GPS count equal to 'fitCount' and
 * starting at GPS point in 'start' element.
 *
 * function allocates memory for destination buffer 'dest'.
 *
 * Parameters:
 *  - dest: Character pointer to pointer to generated LINESTRING WKT format.
 *  - start: Element in segment with GPS to start LINESTRING from.
 *  - fitCount: Maximum count of GPS points to be included in the LINESTRING.
 *
 * Return:
 *  - ztSuccess
 *  - ztInvalidArg
 *  - ztMemoryAllocate
 *
 * Note:
 *   The fixed count is to generate 'LINESTRING' with maximum length of 256
 *   characters to avoid the warning message from "ogr2ogr" when converting
 *   WKT to shape file format.
 *
 *   Using the print specifier "%10.7f %10.7f,"; ten GPS points will fit in
 *   this 256 buffer for most of the earth. The buffer needs to be bigger for
 *   the South-West quarter of the earth where both longitude and latitude
 *   are negative.
 *   If you are south of the Equator and west the Meridian and do not want the
 *   warning from "ogr2ogr", you can use nine GPS points as maximum count. All
 *   you need to do in this case is change the 'numFit' variable in the function
 *   "seg2LinestringWktStrList()" from LS_FIT_10 to LS_FIT_9. Those are defined
 *   values in "formatWKT.h" header file.
 *
 ****************************************************************************/

int wktLinestringFit(char **dest, ELEM *start, int fitCount){

  ELEM *elem;
  GPS  *gps;

  int   maxFit = fitCount;

  char  tmpBuff[512] = {0};
  char  *heading = "\"LINESTRING(";

  ASSERTARGS(dest && start);

  if( ! DL_NEXT(start)){
    fprintf(stderr, "wktLinestringFit(): Error no next point to 'start' parameter!\n"
	    "Can not make line with single point.\n");
    return ztInvalidArg;
  }

  sprintf(tmpBuff, "%s", heading);

  int numWritten = 0;

  elem = start;

  while(elem && numWritten < maxFit){

    gps = (GPS *) DL_DATA(elem);

    if (DL_NEXT(elem) && (numWritten < (maxFit - 1)))

      sprintf(tmpBuff + strlen(tmpBuff), "%10.7f %10.7f,", gps->longitude, gps->latitude);

    else

      sprintf(tmpBuff + strlen(tmpBuff), "%10.7f %10.7f)\"\n", gps->longitude, gps->latitude); //added linefeed character

    numWritten++;

    elem = DL_NEXT(elem);

  }

  *dest = (char *)malloc((strlen(tmpBuff) + 1) * sizeof(char));
  if(! *dest ){
    fprintf(stderr, "wktLinestringFit(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }

  strcpy(*dest, tmpBuff);

  return ztSuccess;

} /* END wktLinestringFit() **/

/* seg2LinestringWktStrList():
 *
 * each "LINESTRING" is in an element of 'strList'; data pointer in the
 * element is a pointer to character string.
 * when segment size is numFit or less, 'strList' will have NLY one element.
 *
 */

int seg2LinestringWktStrList (STRING_LIST *strList, SEGMENT *seg){

  ELEM *elem;

  int  result;
  int  numSent = 0;
  int  increment;
  int  numFit = LS_FIT_10; /* use LS_FIT_9 for South America **/

  ASSERTARGS(strList && seg);

  if (DL_SIZE(strList) != 0){
    fprintf(stderr, "seg2LinestringWktStrList() : Error destination parameter 'strList' is NOT empty list.\n");
    return ztInvalidArg;
  }
  if ( ! TYPE_STRING_LIST(strList) ){
    fprintf(stderr, "seg2LinestringWktStrList() : Error parameter 'strList' is not of STRING_LT type.\n");
    return ztInvalidArg;
  }

  if (DL_SIZE(seg) == 0){
    fprintf(stderr, "seg2LinestringWktStrList() : Error source parameter 'seg' is Empty list.\n");
    return ztInvalidArg;
  }
  if ( ! TYPE_SEGMENT(seg) ){
    fprintf(stderr, "seg2LinestringWktStrList() : Error parameter 'seg' is not of SEGMENT_LT type.\n");
    return ztInvalidArg;
  }

  elem = DL_HEAD(seg);
  numSent = 0;

  while(numSent < DL_SIZE(seg)){

    char *newLine; /* wktLinestringFit() allocates memory for us **/

    result = wktLinestringFit(&newLine, elem, numFit);
    if(result != ztSuccess){
      fprintf(stderr, "seg2LinestringWktStrList(): Error failed wktLinestringFit() function.\n");
      return result;
    }

    result = insertNextDL(strList, DL_TAIL(strList), (void *) newLine);
    if(result != ztSuccess){
      fprintf(stderr, "seg2LinestringWktStrList(): Error failed insertNextDL() function.\n");
      return result;
    }

    /* after first loop we start at last GPS sent from previous loop. **/

    increment = (numSent ? (numFit - 1) : numFit);

    numSent += increment;

    if(numSent >= DL_SIZE(seg))

      break;

    int i = 0;
    while(DL_NEXT(elem) && i < (numFit - 1)){
      i++;
      elem = DL_NEXT(elem);
    }

  }

  return ztSuccess;

} /* END seg2LinestringWktStrList() **/

/* geom2WktListListStr()
 * third parameter is a function pointer; pass seg2PointWktStrList() to make
 * POINT wkt for the geometry, or seg2LinestringWktStrList() to make LINESTRING
 * wkt for the geometry.
 *
 ************************************************************************/

int geom2WktListListStr(LIST_STR_LIST *listListStr, GEOMETRY *geom, int seg4Wkt(STRING_LIST *list, SEGMENT *seg)){

  ELEM    *elem;
  SEGMENT *seg;
  int     result;

  ASSERTARGS(listListStr && geom && seg4Wkt);

  if(DL_SIZE(geom) == 0){
    fprintf(stderr, "geom2WktListListStr() : Error source parameter 'geom' is Empty list.\n");
    return ztListEmpty;
  }
  if ( ! TYPE_GEOMETRY(geom) ){
    fprintf(stderr, "geom2WktListListStr() : Error parameter 'geom' is not of GEOMETRY_LT type.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(listListStr) != 0){
    fprintf(stderr, "geom2WktListListStr() : Error destination parameter 'listListStr' is NOT empty list.\n");
    return ztListNotEmpty;
  }

  if(! TYPE_LIST_STR_LIST(listListStr)){
    fprintf(stderr, "geom2WktListListStr() : Error parameter 'listListStr' is not of LIST_STRL_LT type.\n");
    return ztInvalidArg;
  }

  elem = DL_HEAD(geom);
  while(elem){

    seg = (SEGMENT *)DL_DATA(elem);

    if(!seg){
      fprintf(stderr, "geom2WktListListStr() : Error failed to retrieve segment from geometry!\n");
      return ztFatalError;
    }

    STRING_LIST *newList;

    newList = (STRING_LIST *)initialStringList();
    if( ! newList ){
      fprintf(stderr, "geom2WktListListStr() : Error failed initialStringList().\n");
      return ztMemoryAllocate; /* maybe partially filled listListStr now? **/
    }

    result = seg4Wkt(newList, seg);
    if(result != ztSuccess){
      fprintf(stderr, "geom2WktListListStr() : Error failed seg4Wkt().\n");
      return result; /* maybe partially filled listListStr now? **/
    }

    result = insertNextDL(listListStr, DL_TAIL(listListStr), (void *) newList);
    if(result != ztSuccess){
      fprintf(stderr, "geom2WktListListStr() : Error failed insertNextDL().\n");
      return result; /* maybe partially filled listListStr now? **/
    }

    elem = DL_NEXT(elem);
  }

  return ztSuccess;

} /* END geom2WktListListStr() **/


/* poly2PointWktStrList(): formats POLYGON pointed to by parameter poly as POINT in
 * Well Known Text format.
 *
 *
 **********************************************************************/

int poly2PointWktStrList(STRING_LIST *strList, POLYGON *poly){

  int    result;

  ASSERTARGS(strList && poly);

  if(isPolygon(poly) == FALSE){
    fprintf(stderr, "poly2PointWktStrList(): Error invalid polygon in parameter poly.\n");
    return ztInvalidArg;
  }

  /* we fake listType, to call gpsList2WktPoint(). */
  poly->listType = GPS_LT;

  result = gpsList2PointWktStrList(strList, poly);

  /* reset listType back to POLYGON_LT */
  poly->listType = POLYGON_LT;

  if(result != ztSuccess){
    fprintf(stderr, "poly2PointWktStrList() : Error failed gpsList2WktPointStrList() function.\n");
    return result;
  }

  return ztSuccess;

} /* END poly2PointWktStrList() */

int poly2LinestringWktStrList (STRING_LIST *strList, POLYGON *poly){

  int    result;

  ASSERTARGS(strList && poly);

  if(isPolygon(poly) == FALSE){
    fprintf(stderr, "poly2LinestringWktStrList(): Error invalid polygon in parameter poly.\n");
    return ztInvalidArg;
  }

  /* we fake listType, to call seg2LinestringWktStrList(). */
  poly->listType = SEGMENT_LT;

  result = seg2LinestringWktStrList(strList, poly);

  /* reset listType back to POLYGON_LT */
  poly->listType = POLYGON_LT;

  if(result != ztSuccess){
    fprintf(stderr, "poly2LinestringWktStrList() : Error failed seg2LinestringWktStrList() function.\n");
    return result;
  }

  return ztSuccess;

} /* END poly2LinestringWktStrList() **/


/* poly2PolygonWktChar(): formats polygon as POLYGON WKT unlimited list size.
 *
 */

int poly2PolygonWktChar(char **wktDest, POLYGON *poly){

  char  *head = "\"POLYGON((";
  char  *end = "))\"\n";       /* line feed included in end **/
  int   sizeVertex = 25 + 1;   /* |-111.9392823 33.4653292,| -- 25 comma included;
                                  + 1 for another minus sign in front of latitude
                                  as: -33.4653292 **/
  int   sizeRequired;

  char *buffer;


  ASSERTARGS(wktDest && poly);

  if(isPolygon(poly) == FALSE){
    fprintf(stderr, "poly2PolygonWktChar(): Error invalid polygon in parameter 'poly'.\n");
    return ztInvalidArg;
  }

  sizeRequired = strlen(head) + strlen(end) + (DL_SIZE(poly) * sizeVertex) + 1;
  /* last has no comma, that is NULL space; no + 1 is needed here, but does not hurt! **/

  /* memory is allocated at caller pointer **/
  *wktDest = (char *)malloc((sizeRequired)* sizeof(char));
  if(! *wktDest){
    fprintf(stderr, "poly2PolygonWktChar(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }
  memset(*wktDest, 0, sizeRequired);

  /* simpler code might be as follows:
   *
   * (*wktDest)[0] = '\0'; //set only first character to NULL, no memset()
   * strcat(*wktDest, head); //use strcat() instead of sprintf()
   *
   *
   ***************************************************/

  buffer = *wktDest;

  sprintf(buffer, "%s", head);

  ELEM  *elem;
  GPS   *gps;
  char  *vertexStr;

  elem = DL_HEAD(poly);
  while(elem){

    gps = DL_DATA(elem);
    if(!gps){
      fprintf(stderr, "poly2PolygonWktChar(): Error; fatal failed to retrieve 'gps' from element.\n");
      return ztFatalError;
    }

    vertexStr = gps2PolyVertex(gps);
    if(!vertexStr){
      fprintf(stderr, "poly2PolygonWktChar(): Error failed gps2PolyVertex().\n");
      return ztMemoryAllocate;
    }


    if (strlen(buffer) + strlen(vertexStr) + strlen(end) > sizeRequired) {
      fprintf(stderr, "poly2PolygonWktChar(): Buffer overflow might occur. Aborting.\n");
      free(*wktDest);
      return ztFatalError;
    }

    sprintf(buffer + strlen(buffer), "%s", vertexStr);

    if(elem != DL_TAIL(poly))

      sprintf(buffer + strlen(buffer), ",");

    free(vertexStr);
    vertexStr = NULL;

    elem = DL_NEXT(elem);
  }

  sprintf(buffer + strlen(buffer), "%s", end);

  return ztSuccess;

} /* END   poly2PolygonWktChar() **/

/* gpsPolyVertex():  formats one GPS point WITHOUT comma **/
static char *gps2PolyVertex(GPS *gps){

  char     buf[32] = {0};
  char     *str;

  ASSERTARGS(gps);

  sprintf(buf, "%11.7f %10.7f", gps->longitude, gps->latitude);

  str = strdup(buf);

  return str;

} /* formatPolyVertex() **/


int bbox2PolygonWkt(char **wktStr, BBOX *bbox){

  POLYGON  *poly;
  char     *polyWkt;
  int      result;

  ASSERTARGS(wktStr && bbox);

  if(isBbox(bbox) == FALSE){
    fprintf(stderr, "bbox2PolygonWkt(): Error invalid bounding box in parameter bbox.\n");
    return ztInvalidArg;
  }

  poly = bbox2Polygon(bbox);

  if( ! poly){
    fprintf(stderr, "bbox2PolygonWkt(): Error failed bbox2Polygon() function.\n");
    return ztMemoryAllocate;
  }

  result = poly2PolygonWktChar(&polyWkt, poly);
  if(result != ztSuccess){
    fprintf(stderr, "bbox2PolygonWkt(): Error failed poly2WktPolygon9() function.\n");
    return result;
  }

  /* set client wktStr **/
  *wktStr = polyWkt;

  zapPolygon((void **) &poly);

  return ztSuccess;

} /* END bbox2PolygonWkt() **/














/*** SINGLE WKT STRING GOT TO GO ... USE STRING_LIST INSTEAD ***/


/* gpsList2PointWkt():
 * formats a list of GPS points into one string in wktStr
 * function allocates memory for destination
 *
 *
 * Return:
 *  - ztSuccess: on success
 *  - ztListEmpty: error source list can not be empty
 *  - ztMemoryAllocate: on failure
 *
 ****************************************************************************/

int gpsList2PointWkt (char **wktStr, GPS_LIST *gpsList){

  char    *tmpBuf;
  size_t  currentSize;
  size_t  bucketSize = 8400; /* or page size; memory amount we allocate
                                I ignore size member in gpsList;; stupid USE TO SET bucket size **/

  /* (33 + 1 + 1) * 60 * 4 = 8400 ===> ( 1 line * 60 (lines/screen) * 4 screens)
   * 33 string length + 1 null character + 1 linefeed character */

  char    *newWKT;
  ELEM    *elem;
  GPS     *gps;
  int     result;

  ASSERTARGS(wktStr && gpsList);

  if (gpsList->listType != GPS_LT){
    fprintf(stderr, "gpsList2PointWkt(): Error parameter 'gpsList' is not of type GPS_LT.\n");
    return ztInvalidArg;
  }
  if (DL_SIZE(gpsList) == 0){
    fprintf(stderr, "gpsList2PointWkt(): Error parameter 'gpsList' is for an Empty list.\n");
    return ztListEmpty;
  }

  /* start with an extra 7 bytes below is keeping my fingers crossed for good luck, seriously. */
  tmpBuf = (char *) malloc(sizeof(char) * (bucketSize + 7));
  if ( ! tmpBuf){
    fprintf (stderr, "gpsList2WktPoint(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }
  memset(tmpBuf, 0, bucketSize + 7);

  currentSize = bucketSize + 7;

  elem = DL_HEAD(gpsList);
  while(elem){

    gps = (GPS *) DL_DATA(elem);

    result = gps2PointWkt(&newWKT, gps);
    if ( result != ztSuccess ){
      fprintf (stderr, "gpsList2WktPoint(): Error failed gps2WktPoint() function.\n");
      return result;
    }

    /* is there room left in buffer */
    if (strlen(tmpBuf) + strlen(newWKT) > currentSize){

      tmpBuf = realloc(tmpBuf, currentSize + bucketSize);
      if ( ! tmpBuf ){
        fprintf (stderr, "gpsList2WktPoint(): Error reallocating memory.\n");
        return ztMemoryAllocate;
      }
      memset(tmpBuf + currentSize, 0, bucketSize);

      currentSize += bucketSize;
    }

    sprintf(tmpBuf + strlen(tmpBuf), "%s", newWKT);

    elem = DL_NEXT(elem);
  }

  /* each formated WKT GPS has a linefeed, we do not add any here */

  /* set wktStr */
  *wktStr = strdup(tmpBuf);

  if ( ! *wktStr ){
    fprintf (stderr, "gpsList2WktPoint(): Error failed strdup() function.\n");
    return ztMemoryAllocate;
  }

  free(tmpBuf);

  return ztSuccess;;

} /* END gpsList2PointWkt() **/


int seg2PointWkt(char **wktDest, SEGMENT *seg){

  int  result;

  ASSERTARGS(wktDest && seg);

  if (seg->listType != SEGMENT_LT){
    fprintf(stderr, "seg2PointWkt() : Error parameter 'seg' is not of SEGMENT_LT type.\n");
    return ztInvalidArg;
  }

  if (DL_SIZE(seg) == 0){
    fprintf(stderr, "seg2PointWkt() : Error source parameter 'seg' is Empty list.\n");
    return ztInvalidArg;
  }

  /* we fake listType, to call gpsList2PointWkt(). */
  seg->listType = GPS_LT;

  result = gpsList2PointWkt(wktDest, seg);

  /* reset listType back to SEGMENT_LT */
  seg->listType = SEGMENT_LT;

  if(result != ztSuccess){
    fprintf(stderr, "segt2PointWkt() : Error failed gpsList2PointWkt() function.\n");
    return result;
  }

  return ztSuccess;

} /* END seg2PointWkt() */

/* seg2LinestringWkt(): formats SEGMENT list as LINESTRING Well Known Text with
 * each line being at most 256 characters long including null and linefeed characters.
 * function allocates memory for destination.
 *
 * ogr2ogr will truncate lines longer than 254 characters
 * 256 is max line length, 1 character for \n and one for \0 --> max capacity is 254

 * Return:
 *
 ****************************************************************************/
int seg2LinestringWkt (char **dest, SEGMENT *seg){

  char  *buf;
  int   lineLength = 256;
  char  myLine[lineLength];
  int   bucketSize = lineLength * 60 * 2; /* initial buffer size and its reallocation increment */
  int   currentSize;
  char  *lineHead = "\"LINESTRING(";
  int   countPerLine, iCount;
  ELEM  *startElem;
  int   result;

  ASSERTARGS (dest && seg);

  if(seg->listType != SEGMENT_LT){
    fprintf(stderr, "seg2LinestringWkt(): Error source parameter 'seg' is not of SEGMENT_LT type.\n");
    return ztInvalidArg;
  }
  if (DL_SIZE(seg) < 2){
    fprintf(stderr, "seg2LinestringWkt(): Error list size in parameter seg is < 2; can not make a line.\n");
    if (DL_SIZE(seg) == 0){
      fprintf(stderr, "seg2LinestringWkt(): That segment is EMPTY!\n");
    }
    else { /* segment must have JUST one gps; try to show that. **/

      GPS *gps;
      startElem = DL_HEAD(seg);
      gps = (GPS *) DL_DATA(startElem);
      if (gps){
        fprintf(stderr, "seg2LinestringWkt(): Segment has one \"Unchecked\" GPS:\n");
        fprintGps(stderr, gps);
      }
    }
    return ztInvalidArg;
  }

  buf = (char *) malloc(sizeof(char) * bucketSize);
  if ( ! buf ){
    fprintf(stderr, "seg2LinestringWkt(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }
  memset(buf, 0, bucketSize * sizeof(char));

  currentSize = bucketSize;

  /* figure out how many GPS points fit per line:
   *  one GPS : |-111.8569939 33.4348566,| ===> takes 24 characters!
   *  (-4) quote marks + linefeed + null */
  
  countPerLine = (lineLength - strlen(lineHead) - 4) / 24;

  int    sent = 0;

  startElem = DL_HEAD(seg);

  do {

    sprintf(myLine, "%s", lineHead);

    result = wktLinestringCount (myLine + strlen(myLine), startElem, countPerLine);
    if (result != ztSuccess){
      fprintf(stderr, "seg2LinestringWkt(): Error failed wktLinestringCount() function.\n");
      return result;
    }

    if (strlen(buf) + strlen(myLine) > currentSize){

      buf = realloc(buf, currentSize + bucketSize);
      if ( ! buf ){
        fprintf(stderr, "seg2LinestringWkt(): Error failed to reallocate memory.\n");
        return ztMemoryAllocate;
      }
      memset(buf + currentSize, 0, bucketSize);

      currentSize += bucketSize;
    }

    sprintf(buf + strlen(buf), "%s\n", myLine); /* add line to page */

    if (sent == 0)
      sent = countPerLine;
    else
      sent += (countPerLine - 1);

    /* after first time, we start at LAST element from PREVIOUS lot sent */

    /* move start element pointer by one LESS than countPerLine */
    for (iCount = 0; iCount < countPerLine - 1; iCount++){

      if (DL_NEXT(startElem))

        startElem = DL_NEXT(startElem);
    }

    if ( ! DL_NEXT(startElem) && (sent < DL_SIZE(seg)) ){

      fprintf(stderr, "seg2LinestringWkt(): Error trying to start at LAST element.\n");
      return ztUnknownError;
    }

  } while (sent < DL_SIZE(seg));

  *dest = strdup(buf);

  if ( ! *dest ){
    fprintf(stderr, "seg2LinestringWkt(): Error allocating memory, strdup() failed.\n");
    return ztMemoryAllocate;
  }

  return ztSuccess;

} /* END seg2LinestringWkt() **/

/* wktLinestringCount(): called by segment2WktLinestring().
 *
 * wktLinestringCount() : writes at most iCount formated GPS points into parameter
 * "line", parameter startGps is ELEM from DLIST of GPS points (where the
 * data member is a pointer to GPS structure).
 *
 * Caller is responsible for destination "line" memory allocation, no check is done here.
 *
 * Return:
 ******************************************************************************/

static int wktLinestringCount (char *line, ELEM *startGps, int iCount){

  ASSERTARGS (line && startGps);

  if ( ! iCount )

    return ztInvalidArg;

  ELEM    *elem;
  GPS     *gps;
  int     iDone = 0;

  /* we need at least 2 GPS points to make LINESTRING */
  if (DL_NEXT(startGps) == NULL){
    fprintf(stderr, "wktLinestringCount(): Error can not make LINESTRING with ONE point.\n");
    return ztInvalidArg;
  }

  elem = startGps;
  while (elem){

    gps = (GPS *) DL_DATA(elem);

    if (DL_NEXT(elem) && (iDone < (iCount - 1)))

      sprintf(line + strlen(line), "%10.7f %10.7f,", gps->longitude, gps->latitude);

    else

      sprintf(line + strlen(line), "%10.7f %10.7f)\"", gps->longitude, gps->latitude);

    iDone++;
    if (iDone == iCount)

      break;

    elem = DL_NEXT(elem);
  }

  return ztSuccess;

} /* END wktLinestringCount() */





int geom2PointWkt (char **destStr, GEOMETRY *geom){

  /* GEOMETRY wkt 4 POINT are made per segment, each segment wkt string is
   * placed into a list of strings, then catWktStringList() is called to combine
   * them into one single string.
   ************************************************************************/

  STRING_LIST    *wktStrList;
  char    *wktString;
  ELEM    *elem;
  SEGMENT    *seg;
  char     *combinedStr;
  int    result;

  ASSERTARGS(destStr && geom);

  if(geom->listType != GEOMETRY_LT){
    fprintf(stderr, "geom2PointWkt(): Error geom parameter is not GEOMETRY_LT.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(geom) == 0){
    fprintf(stderr, "geom2PointWkt(): Error geometry list is empty.\n");
    return ztListEmpty;
  }

  wktStrList = initialStringList();
  if( ! wktStrList ){
    fprintf(stderr, "geom2PointWkt(): Error failed initialStringList() function.\n");
    return ztMemoryAllocate;
  }

  elem = DL_HEAD(geom);
  while(elem){

    seg = (SEGMENT *) DL_DATA(elem);

    result = seg2PointWkt(&wktString, seg);
    if (result != ztSuccess){
      fprintf(stderr, "geom2PointWkt(): Error failed segment2WktPoint() function.\n");
      return result;
    }

    /* insert wkt string into list **/
    result = insertNextDL(wktStrList, DL_TAIL(wktStrList), (void *) wktString);
    if ( result != ztSuccess ){
      fprintf(stderr, "geom2PointWkt(): Error failed insertNextDL() function.\n");
      return result;
    }

    elem = DL_NEXT(elem);
  }

  result = catWktStringList(&combinedStr, wktStrList);
  if(result != ztSuccess){
    fprintf(stderr, "geom2PointWkt(): Error failed catWktStringList() function.\n");
    return result;
  }

  /* set *destStr now **/
  *destStr = combinedStr;

  return ztSuccess;

} /* END geom2PointWkt() */

int geom2LinestringWkt (char **destStr, GEOMETRY *geom){

  /* GEOMETRY wkt 4 LINESTRING are made per segment, each segment wkt string is
   * placed into a list of strings, then catWktStringList() is called to combine
   * them into one single string.
   ************************************************************************/

  STRING_LIST    *wktStrList;
  char    *wktString;
  ELEM    *elem;
  SEGMENT    *seg;
  char     *combinedStr;
  int    result;

  ASSERTARGS(destStr && geom);

  if(geom->listType != GEOMETRY_LT){
    fprintf(stderr, "geom2LinestringWkt(): Error geom parameter is not GEOMETR_LT.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(geom) == 0){
    fprintf(stderr, "geom2LinestringWkt(): Error geometry list is empty.\n");
    return ztListEmpty;
  }

  wktStrList = initialStringList();
  if( ! wktStrList ){
    fprintf(stderr, "geom2LinestringWkt(): Error failed initialStringList() function.\n");
    return ztMemoryAllocate;
  }

  elem = DL_HEAD(geom);
  while(elem){

    seg = (SEGMENT *) DL_DATA(elem);

    if (DL_SIZE(seg) < 2){
      fprintf(stdout, "geom2LinestringWkt(): Warning malformed segment with <%d> GPS point/s. Skipped!!\n", DL_SIZE(seg));

      GPS *gps;
      gps = (GPS *)DL_DATA(DL_HEAD(seg));
      fprintGps(stdout, gps);

      elem = DL_NEXT(elem);
      continue;
    }

    result = seg2LinestringWkt(&wktString, seg);
    if (result != ztSuccess){
      fprintf(stderr, "geom2LinestringWkt(): Error failed segment2WktLinestring() function.\n");
      return result;
    }

    /* insert wkt string into list **/
    result = insertNextDL(wktStrList, DL_TAIL(wktStrList), (void *) wktString);
    if ( result != ztSuccess ){
      fprintf(stderr, "geom2LinestringWkt(): Error failed insertNextDL() function.\n");
      return result;
    }

    elem = DL_NEXT(elem);
  }

  result = catWktStringList(&combinedStr, wktStrList);
  if(result != ztSuccess){
    fprintf(stderr, "geom2LinestringWkt(): Error failed catWktStringList() function.\n");
    return result;
  }

  /* set *destStr now **/
  *destStr = combinedStr;

  return ztSuccess;

} /* END geom2LinestringWkt() */

/* poly2PointWkt(): formats POLYGON pointed to by parameter poly as POINT in
 * Well Known Text format.
 * THIS FUNCTION DOES NOT REMOVE THE DUPLICATE HEAD & TAIL POINTS; THE GPS LISTED
 * TWICE IS THE HEAD & TAIL OF THE POLYGON. Is this a bug?!
 *
 **********************************************************************/

int poly2PointWkt(char **wktDest, POLYGON *poly){

  int    result;

  ASSERTARGS(wktDest && poly);

  if(isPolygon(poly) == FALSE){
    fprintf(stderr, "poly2PointWkt(): Error invalid polygon in parameter poly.\n");
    return ztInvalidArg;
  }

  /* we fake listType, to call gpsList2WktPoint(). */
  poly->listType = GPS_LT;

  result = gpsList2PointWkt(wktDest, poly);

  /* reset listType back to POLYGON_LT */
  poly->listType = POLYGON_LT;

  if(result != ztSuccess){
    fprintf(stderr, "poly2PointWkt() : Error failed gpsList2WktPoint() function.\n");
    return result;
  }

  return ztSuccess;

} /* END poly2PointWkt() */

/* polygon2WktPolygon9() :: formats POLYGON into Well Known Text "POLYGON" limiting
 * the number of vertices to 9 - that is nine vertices maximum.
 *
 * Maximum vertices allowed is 9 point (latitude, longitude).
 * The maximum is set to avoid 'ogr2ogr' warning about field being truncated.
 * The nine points will fit into a line of length 254 characters with the format
 * specified in this function
 * lineHead --> "POLYGON (( == 11 characters
 * lineTail --> ))" == 3 characters.
 * lastPoint --> -111.934891 33.392867 == 22 characters
 * above total is: (11 + 3 + 22) = 36 characters.
 * Add one space and a comma to point --> 24 characters
 * so:: 256 - (36 + 2) = 218 characters left in the line.
 * 218 / 24 ~ 9 points.
 *
 *************************************************************************/
int poly2PolygonWkt9(char **wktDest, POLYGON *poly){

  ELEM    *elem;
  GPS     *gps;

  int     bufferSize = 255; /* linefeed is NOT added here */
  char     myBuffer[256] = {0};
  char    pointBuf[32];

  int    maxAllowed = 9;

  ASSERTARGS(wktDest && poly);

  if(isPolygon(poly) == FALSE){
    fprintf(stderr, "poly2PolygonWkt9(): Error invalid polygon in parameter poly.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(poly) > maxAllowed){
    fprintf(stderr, "poly2PolygonWkt9(): Error polygon has more than <%d> vertices.\n", maxAllowed);
    /* maybe suggest to use poly2WktLine() - yet to write. ***/
    return ztInvalidArg;
  }

  sprintf(myBuffer, "\"POLYGON(("); /* two parentheses are required with POLYGON */

  elem = DL_HEAD(poly);
  while(DL_NEXT(elem)){ /* do NOT write last GPS yet **/

    gps = (GPS *)DL_DATA(elem);

    sprintf(pointBuf, "%10.6f %10.6f,", gps->longitude, gps->latitude);

    if (strlen(myBuffer) + strlen(pointBuf) > bufferSize){
      fprintf(stderr, "poly2PolygonWkt9(): Error fixed buffer length will overflow.\n");
      return ztUnknownError;
    }

    sprintf(myBuffer + strlen(myBuffer), "%s", pointBuf);

    elem = DL_NEXT(elem);

  }

  /* now write last GPS: it does NOT include a comma */
  elem = DL_TAIL(poly);
  gps = (GPS *)DL_DATA(elem);

  /* close WKT string **/
  sprintf(pointBuf, "%10.6f %10.6f))\"", gps->longitude, gps->latitude);

  if (strlen(myBuffer) + strlen(pointBuf) > bufferSize){
    fprintf(stderr, "poly2PolygonWkt9(): Error fixed buffer length will overflow.\n");
    return ztUnknownError;
  }

  sprintf(myBuffer + strlen(myBuffer), "%s", pointBuf);

  *wktDest = strdup(myBuffer);

  if ( ! *wktDest ){
    fprintf(stderr, "poly2PolygonWkt9(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }

  return ztSuccess;

} /* END poly2WktPolygon9() **/

/* poly2PolygonWktU(): formats polygon as POLYGON WKT unlimited list size.
 *
 */

int poly2PolygonWktU(char **wktDest, POLYGON *poly){

  ELEM    *elem;
  GPS     *gps;

  int    bucketSize = 1024;
  int    currentSize;
  char     *buf;
  char     *vertexStr;
  int     closeSize = 4; /* ))" + line feed character **/

  ASSERTARGS(wktDest && poly);

  if(isPolygon(poly) == FALSE){
    fprintf(stderr, "poly2PolygonWktU(): Error invalid polygon in parameter poly.\n");
    return ztInvalidArg;
  }

  buf = (char *) malloc(sizeof(char) * bucketSize);
  if ( ! buf ){
    fprintf(stderr, "poly2PolygonWktU(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }
  memset(buf, 0, bucketSize);

  currentSize = bucketSize;

  sprintf(buf, "\"POLYGON((");

  elem = DL_HEAD(poly);
  while(elem){

    gps = (GPS *)DL_DATA(elem);

    vertexStr = formatPolyVertex(gps);
    if( ! vertexStr ){
      fprintf(stderr, "poly2PolygonWktU(): Error failed formatPolyVertex() function.\n");
      return ztMemoryAllocate;
    }

    if ((strlen(buf) + strlen(vertexStr) + closeSize) > currentSize){

      buf = realloc(buf, currentSize + bucketSize);
      if( ! buf ){
        fprintf(stderr, "poly2PolygonWktU(): Error reallocating memory.\n");
        return ztMemoryAllocate;
      }
      memset(buf + currentSize, 0, bucketSize);

      currentSize += bucketSize;
    }

    if(DL_NEXT(elem))

      sprintf(buf + strlen(buf), "%s,", vertexStr); /* with comma **/

    else

      sprintf(buf + strlen(buf), "%s", vertexStr); /* NO comma for last one **/

    elem = DL_NEXT(elem);
  }

  /* we have room in buffer for closing characters --
   * we do not add line feed here! **/

  sprintf(buf + strlen(buf), "))\"");

  *wktDest = buf; /* set caller pointer **/

  return ztSuccess;

} /* END   poly2PolygonWktU() **/

/* formatPolyVertex():  formats one GPS point WITHOUT comma **/
static char *formatPolyVertex(GPS *gps){

  char     buf[128] = {0};
  char     *str;

  ASSERTARGS(gps);

  sprintf(buf, "%11.7f %10.7f", gps->longitude, gps->latitude);

  str = strdup(buf);

  return str;

} /* formatPolyVertex() **/

int line2PointWkt(char **dstCh, LINE *line){

  char    *strGps1, *strGps2;
  int    result;
  char     *myBuf;

  ASSERTARGS(dstCh && line);

  if( ! (line->gps1 && line->gps2) ){
    fprintf(stderr, "line2PointWkt(): Error line members pointers not set.\n");
    return ztInvalidArg;
  }

  /* int gps2WktPoint (char **destStr, GPS *gps) */

  result = gps2PointWkt(&strGps1, line->gps1);
  if(result != ztSuccess){
    fprintf(stderr, "line2PointWkt(): Error failed gps2WktPoint() function.\n");
    return result;
  }

  result = gps2PointWkt(&strGps2, line->gps2);
  if(result != ztSuccess){
    fprintf(stderr, "line2PointWkt(): Error failed gps2WktPoint() function.\n");
    return result;
  }

  myBuf = (char *)malloc(sizeof(char) * (strlen(strGps1) + strlen(strGps2) + 1));
  if( ! myBuf ){
    fprintf(stderr, "line2PointWkt(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }

  sprintf(myBuf, "%s%s", strGps1, strGps2);

  *dstCh = myBuf;

  return ztSuccess;

} /* END line2PointWkt() **/

int line2LinestringWkt(char **dstCh, LINE *line){

  char     *myBuf;
  char     tmpBuf[LONG_LINE] = {0};

  ASSERTARGS(dstCh && line);

  if( ! (line->gps1 && line->gps2) ){
    fprintf(stderr, "line2LinestringWkt(): Error line members pointers not set.\n");
    return ztInvalidArg;
  }

  // "\"LINESTRING;   ("sprintf(line + strlen(line), "%10.7f %10.7f,", gps->longitude, gps->latitude);
  sprintf(tmpBuf, "\"LINESTRING(%10.7f %10.7f, %10.7f %10.7f)\"",
	  line->gps1->longitude, line->gps1->latitude, line->gps2->longitude, line->gps2->latitude);

  myBuf = strdup(tmpBuf);

  if( ! myBuf ){
    *dstCh = NULL;
    fprintf(stderr, "line2LinestringWkt(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }

  *dstCh = myBuf;

  return ztSuccess;

} /* END line2LinestringWkt() **/

int catWktStringList (char **destStr,  STRING_LIST *wktStrList){

  char*retPtr = NULL;

  int    baseSize;
  int    bucketSize;
  int    bufferSize;

  char    *myBuffer;

  char    *wktString;
  ELEM     *elem;

  ASSERTARGS(destStr && wktStrList);

  if (wktStrList->listType != STRING_LT){
    fprintf(stderr, "catWktStringList(): Error wktStrList parameter is not STRING_LT.\n");
    return ztInvalidArg;
  }

  if (DL_SIZE(wktStrList) == 0){
    fprintf(stderr, "catWktStringList(): Error wktStrList parameter is Empty list.\n");
    return ztListEmpty;
  }

  /* TODO: do not allow mixed WKT types **/

  /* set baseSize to string length of largest string in the list,
   * if this fails, there is something serious wrong with the list
   * or the code, so do not try to replace baseSize! */

  //baseSize = sLargestStrStringList(wktStrList);
  baseSize = sizeLongestStrList(wktStrList);
  if(baseSize == 0){
    fprintf(stderr, "catWktStringList(): Error failed sizeLongestStrList() function.\n");
    return ztUnknownError;
  }

  /* set bucketSize */
  bucketSize = baseSize *  24; /* try 32 instead, if you get too many reallocation */

  myBuffer = (char *) malloc(bucketSize);
  if ( ! myBuffer ){
    fprintf(stderr, "catWktStringList(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }
  memset(myBuffer, 0, bucketSize);

  bufferSize = bucketSize;

  elem = DL_HEAD(wktStrList);
  while(elem){

    wktString = (char *) DL_DATA(elem);

    if ( ! wktString ){
      fprintf(stderr, "catWktStringList(): Error data pointer for string is NULL.\n");
      return ztFatalError;
    }

    if (strlen(myBuffer) + strlen(wktString) > bufferSize){

      myBuffer = (char *) realloc(myBuffer, bufferSize + bucketSize);
      if ( ! myBuffer ){
        fprintf(stderr, "catWktStringList(): Error reallocating memory.\n");
        return ztMemoryAllocate;
      }
      memset(myBuffer + bufferSize, 0, bucketSize);

      bufferSize += bucketSize;

    }

    /* insert black line after string if it is not the last one. */
    if (DL_NEXT(elem))
      sprintf(myBuffer + strlen(myBuffer), "%s\n", wktString);
    else
      sprintf(myBuffer + strlen(myBuffer), "%s", wktString);

    elem = DL_NEXT(elem);
  }

  retPtr = (char *) malloc(sizeof(char) * (strlen(myBuffer) + 1));
  if ( ! retPtr ){
    fprintf(stderr, "catWktStringList(): Error allocating memory.\n");
    return ztMemoryAllocate;
  }

  strcpy(retPtr, myBuffer);
  *destStr = retPtr;

  memset(myBuffer, 0, bufferSize);
  free(myBuffer);

  return ztSuccess;

} /* END catWktStringList() */

/* sizeLongestStrList(): returns the size (strlen) of longest string in
 * the string list parameter.
 *
 ************************************************************/
int sizeLongestStrList(STRING_LIST *strList){

  int    size = 0;
  char    *str;
  ELEM    *elem;

  ASSERTARGS(strList);

  if (DL_SIZE(strList) == 0)

    return size;

  elem = DL_HEAD(strList);
  while(elem){

    str = (char *) DL_DATA(elem);

    if (strlen(str) > size)

      size = strlen(str);

    elem = DL_NEXT(elem);
  }

  return size;

} /* END sizeLongestStrList() */

