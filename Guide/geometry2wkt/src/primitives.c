/* primitives.c
 * date 1/17/2023
 * Wael
 *
 * NOTE: In DLIST structure, listType member was added. This file expands on that.
 * Everything here is AFTER listType; some functions in wkt_format.c file have
 * two versions, the ones with 2 in the end are the newer functions and were AFTER
 * listType was added. This note is to be removed after fixing duplicate functions.
 *
 *****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "primitives.h"

#include "util.h"
#include "ztError.h"


GPS *initialGps(){

  GPS    *newGps;

  newGps = (GPS *) malloc(sizeof(GPS));
  if(! newGps){
    fprintf(stderr, "initialGps(): Error allocating memory.\n");
    return NULL;
  }
  memset(newGps, 0, sizeof(GPS));

  return newGps;

} /* END initialGps() */

/* zapGps():
 *
 * use (void**) for parameter to match destroy member in LIST.
 *
 ***********************************************************/
void zapGps(void **gps){

  GPS *myGps;

  myGps = *gps;

  if(myGps){

    free(myGps);
    *gps = NULL;
  }

  return;

} /* END zapGps() */

void fprintGps (FILE *toFile, GPS *gps){

  /* prints [longitude, latitude] format %10.7% -
   * no header (label / title)
   * just numbers and brackets + comma delimiter + linefeed. */

  FILE    *dstPtr;

  ASSERTARGS(gps);

  if ( ! toFile)

    dstPtr = stdout;

  else

    dstPtr = toFile;

  fprintf(dstPtr, " [%10.7f, %10.7f]\n", gps->longitude, gps->latitude);

  return;

} /* END fprintGps() */

void zapString(void **string){

  char *myStr = (char *) *string;

  if(myStr){
    free(myStr);
    *string = NULL;
  }

  return;

} /* END zapString() **/


LINE *initialLine(){

  LINE    *line;

  line = (LINE *) malloc(sizeof(LINE));
  if( ! line ){
    fprintf(stderr, "initialLine(): Error allocating memory.\n");
    return line;
  }

  line->gps1 = initialGps();
  if( ! line->gps1 ){
    fprintf(stderr, "initialLine(): Error allocating memory.\n");
    free(line);
    line = NULL;
    return line;
  }

  line->gps2 = initialGps();
  if( ! line->gps2 ){
    fprintf(stderr, "initialLine(): Error allocating memory.\n");
    free(line->gps1);
    free(line);
    line = NULL;
    return line;
  }

  return line;

} /* END initialLine() */

void zapLine(void **line){

  LINE *myLine;

  ASSERTARGS(line);

  myLine = (LINE *) *line;

  if( ! myLine)

    return;

  if(myLine->gps1)

    free(myLine->gps1);

  if(myLine->gps2)

    free(myLine->gps2);

  memset(myLine, 0, sizeof(LINE));

  free(myLine);

  return;

} /* END zapLine() */

BBOX *initialBbox(){

  /* BBOX members (sw & ne) are NOT pointers! **/

  BBOX *newBox;

  newBox = (BBOX *) malloc(sizeof(BBOX));
  if ( ! newBox ){
    fprintf(stderr, "initialBbox(): Error allocating memory.\n");
    return newBox;
  }
  memset(newBox, 0, sizeof(BBOX));

  return newBox;

} /* END initialBbox() */

void zapBbox(void **bbox){

  BBOX *myBox;

  myBox = (BBOX *) *bbox;
  if(myBox){
    memset(myBox, 0, sizeof(BBOX));
    free(myBox);
    *bbox = NULL;
  }

  return;

} /* END zapBbox() */

void fprintBbox (FILE *toFP, BBOX *bbox){

  /* Output format as follows:
   * (swLatitude, swLongitude, neLatitude, neLongitude) */

  FILE    *destFP;

  ASSERTARGS(bbox);

  if ( ! toFP)
    destFP= stdout;
  else
    destFP = toFP;

  fprintf(destFP, "fprintBbox(): Bounding Box format:\n"
	  "(swLatitude, swLongitude, neLatitude, neLongitude)\n");

  fprintf(destFP, "(%10.7f, %10.7f, %10.7f, %10.7f)\n",
	  bbox->sw.latitude, bbox->sw.longitude,
	  bbox->ne.latitude, bbox->ne.longitude);

  return;

} /* END fprintBbox() */


STRING_LIST *initialStringList(){

  STRING_LIST *newList;

  newList = (STRING_LIST *) malloc(sizeof(STRING_LIST));
  if (! newList ){
    fprintf(stderr, "initialStringList(): Error allocating memory.\n");
    return newList;
  }

  //initialDL((DLIST *) newList, NULL, NULL);
  initialDL((DLIST *) newList, zapString, NULL);
  newList->listType = STRING_LT;

  return newList;

} /* END initialStringList() */

void zapStringList(void **strList){

  STRING_LIST *myStrList;

  ASSERTARGS(strList);

  myStrList = (STRING_LIST *) *strList;

  if(myStrList && myStrList->listType == STRING_LT){

    destroyDL(myStrList);
    free(myStrList);
    *strList = NULL;
  }

  return;

} /* END zapStringList() **/

/* fprintStringList():
 * prints string list to specified open FILE pointer or to screen
 * if FILE pointer is not specified.
 *
 * function provides linefeed character if it is not included in
 * the string, one linefeed character is provided after all strings
 * are printed.
 *
 ***************************************************************/

void fprintStringList (FILE *toFP, STRING_LIST *stringList){

  FILE  *dstFP;
  ELEM  *elem;
  char  *string;

  ASSERTARGS (stringList);

  if (DL_SIZE(stringList) == 0)

    return;

  if ( ! toFP)

    dstFP= stdout;

  else

    dstFP = toFP;

  elem = DL_HEAD(stringList);
  while (elem){

    string = (char *) DL_DATA(elem);

    if(string[strlen(string) - 1] == '\n')

      fprintf(dstFP, "%s", string);

    else

      fprintf(dstFP, "%s\n", string);

    elem = DL_NEXT(elem);
  }

  fprintf(dstFP, "\n");

  return;

} /* END fprintStringList() **/


LIST_STR_LIST *initialListStrList(){

  LIST_STR_LIST *newListStrList;

  newListStrList = (LIST_STR_LIST *)malloc(sizeof(LIST_STR_LIST));
  if(!newListStrList){
    fprintf(stderr, "initialListStrList(): Error allocating memory.\n");
    return newListStrList;
  }
  initialDL(newListStrList, zapStringList, NULL);
  newListStrList->listType = LIST_STRL_LT;

  return newListStrList;
}

void zapListStrList(void **list){

  LIST_STR_LIST *myList;

  ASSERTARGS(list);

  myList = (LIST_STR_LIST *) *list;

  if(myList && myList->listType == LIST_STRL_LT){

    destroyDL(myList);
    free(*list);
    *list = NULL;
  }

  return;

} /* END zapListStrList() **/

void fprintListStrList(FILE *toFP, LIST_STR_LIST *listListStr){

  FILE        *dstFP;
  ELEM        *elem;
  STRING_LIST *strList;

  ASSERTARGS(listListStr);

  if(listListStr->listType != LIST_STRL_LT)

    return;

  if (DL_SIZE(listListStr) == 0)

    return;

  if(toFP)

    dstFP = toFP;

  else

    dstFP = stdout;

  elem = DL_HEAD(listListStr);
  while (elem){

    strList = (STRING_LIST *) DL_DATA(elem);

    if(strList->listType != STRING_LT)

      return;

    fprintStringList(toFP, strList);

    elem = DL_NEXT(elem);
  }

  fprintf(dstFP, "\n");

  return;

}

GPS_LIST *initialGpsList(){

  GPS_LIST *newGpsList;

  newGpsList = (GPS_LIST *) malloc(sizeof(GPS_LIST));
  if (! newGpsList ){
    fprintf(stderr, "initialGpsList(): Error allocating memory.\n");
    return newGpsList;
  }
  initialDL((DLIST *) newGpsList, zapGps, NULL);

  newGpsList->listType = GPS_LT;

  return newGpsList;

} /* END initialGpsList() */

void zapGpsList(GPS_LIST **gpsList){

  GPS_LIST    *list;

  ASSERTARGS(gpsList);

  list = (GPS_LIST *) *gpsList;

  if(list && list->listType == GPS_LT){

    destroyDL(list);
    free(list);
    *gpsList = NULL;
  }

  return;

} /* END zapGpsList() */

/* fprintGpsListGeneric():
 * function to print GPS list in general; GPS list is where the pointer to
 * 'data' member of element in the list is of type pointer to GPS structure.
 * three lists qualify as GPS lists; those are: GPS_LIST, SEGMENT and POLYGON.
 *
 * Parameters:
 *  - toFile: FILE pointer to an open file, stdout is accepted and is the
 *            default if toFile is NULL.
 *  - gpsList: a pointer to one the mentioned lists above.
 *  - heading: character pointer to string to output as first line with maximum
 *             length of 80 characters.
 *             when heading is longer than 80 characters, it is truncated with
 *             string "HEADING TRUNCATED:" prepended to the remainders.
 *             heading can be NULL or an empty string.
 *
 * Return:
 * void; however an error message is printed to standard error if list type is
 * NOT one of the three mentioned.
 *
 * Note: this same function is called by the THREE following functions:
 *       - fprintGpsList()
 *       - fprintSegment()
 *       - fprintPolygon()
 *
 ******************************************************************************/
/**
 * @brief Prints GPS lists of various types to a specified file or stdout.
 *
 * This function prints the contents of GPS lists where the 'data' member
 * of each element in the list is a pointer to a GPS structure. The function
 * supports three qualifying lists: GPS_LIST, SEGMENT, and POLYGON.
 *
 * @param toFile FILE pointer to an open file. If set to NULL, output is directed
 *               to stdout by default.
 * @param gpsList Pointer to one of the qualifying GPS lists (GPS_LIST, SEGMENT, POLYGON).
 * @param heading Character pointer to a string to be displayed as the first line of
 *               output. Maximum length allowed is 80 characters. If longer, the heading
 *               is truncated with "HEADING TRUNCATED:" prepended to the remainder.
 *               This parameter can be NULL or an empty string.
 *
 *******************************************************************************/
/**
 * @brief Prints GPS lists of various types to a specified file or stdout.
 *
 * This function prints the contents of GPS lists where the 'data' member
 * of each element in the list is a pointer to a GPS structure. The function
 * supports three qualifying lists: GPS_LIST, SEGMENT, and POLYGON.
 *
 * @param toFile FILE pointer to an open file. If set to NULL, output is directed
 *               to stdout by default.
 * @param gpsList Pointer to one of the qualifying GPS lists (GPS_LIST, SEGMENT, POLYGON).
 * @param heading Character pointer to a string to be displayed as the first line of
 *               output. Maximum length allowed is 80 characters. If longer, the heading
 *               is truncated with "HEADING TRUNCATED:" prepended to the remainder.
 *               This parameter can be NULL or an empty string.
 *
 * @note One linefeed character is added after the provided 'heading' (if present),
 *       and one linefeed character is added after the list is printed.
 *
 *       LINEFEED included
 */




void fprintGpsListGeneric(FILE *toFile, GPS_LIST *gpsList, char *heading){

  FILE  *dstFP;
  GPS   *gps;
  ELEM  *elem;

  int   maxHeadingLength = COUNT_80;
  char  newHeading[COUNT_80] = "HEADING TRUNCATED: ";

  ASSERTARGS(gpsList);

  if((gpsList->listType != GPS_LT) &&
     (gpsList->listType != SEGMENT_LT) &&
     (gpsList->listType != POLYGON_LT) ){

    fprintf(stderr, "fprintGpsListGeneric(): Error invalid list type for second parameter.\n"
	    " This GENERIC function is only the following lists: GPS_LIST, SEGMENT and POLYGON.\n");
    return;
  }

  if ( ! toFile)
    dstFP= stdout;
  else
    dstFP = toFile;

  if (DL_SIZE(gpsList) == 0)

    return;

  if(heading && strlen(heading)){

    if(strlen(heading) > maxHeadingLength)
      snprintf(newHeading + strlen(newHeading), maxHeadingLength - strlen(newHeading) - 1, "%s\n", heading);
    else
      sprintf(newHeading, "%s\n", heading);

    fprintf(dstFP, "%s\n", newHeading);
  }

  elem = DL_HEAD(gpsList);
  while(elem){

    gps = (GPS *) DL_DATA(elem);
    fprintGps(dstFP, gps);

    elem = DL_NEXT(elem);
  }

  fprintf(dstFP, "\n");

  return;

} /* END fprintGpsListGeneric() */

void fprintGpsList(FILE *toFile, GPS_LIST *gpsList, char *heading){

  return fprintGpsListGeneric(toFile, gpsList, heading);

}

SEGMENT *initialSegment(){

  SEGMENT *newSeg;

  newSeg = (SEGMENT *)malloc(sizeof(SEGMENT));
  if (! newSeg){
    fprintf(stderr, "initialSegment(): Error allocating memory.\n");
    return newSeg;
  }
  initialDL(newSeg, zapGps, NULL);

  newSeg->listType = SEGMENT_LT;

  return newSeg;

} /* END initialSegment() */

/* zapSegment():
 *
 * parameter is of TYPE void; not SEGMENT
 *
 *********************************************/

void zapSegment(void **seg){

  SEGMENT  *mySeg;

  ASSERTARGS(seg);

  mySeg = (SEGMENT *) *seg;

  if(mySeg && mySeg->listType == SEGMENT_LT){

    destroyDL(mySeg);
    free(mySeg);
    *seg = NULL;
  }

  return;

} /* END zapSegment() */

void fprintSegment(FILE *toFile, SEGMENT *seg, char *heading){

  return fprintGpsListGeneric(toFile, seg, heading);

}

GEOMETRY *initialGeometry(){

  GEOMETRY *newG;

  newG = (GEOMETRY *)malloc(sizeof(GEOMETRY));
  if (! newG){
    fprintf(stderr, "initialGeometry(): Error allocating memory.\n");
    return newG;
  }
  initialDL(newG, zapSegment, NULL);

  newG->listType = GEOMETRY_LT;

  return newG;

} /* END initialGeometry() */

void zapGeometry(GEOMETRY **geom){

  GEOMETRY  *myGeom;

  ASSERTARGS(geom);

  myGeom = (GEOMETRY *) *geom;

  if(myGeom && myGeom->listType == GEOMETRY_LT){

    destroyDL(myGeom);
    free(myGeom);
    *geom = NULL;
  }

  return;

} /* END zapGeometry() */

void fprintGeometry(FILE *toFile, GEOMETRY *geometry){

  FILE    *dstFP;
  ELEM    *elem;
  SEGMENT    *seg;

  ASSERTARGS(geometry);

  if (DL_SIZE(geometry) == 0)  return;

  if ( ! toFile)

    dstFP= stdout;

  else

    dstFP = toFile;

  fprintf(dstFP, "fprintGeometry(): Geometry size is: <%d> segments.\n", DL_SIZE(geometry));

  int count = 1;

  elem = DL_HEAD(geometry);
  while(elem){

    seg = (SEGMENT *)DL_DATA(elem);

    fprintf(dstFP, "fprintGeometry(): Segment number <%d of %d> is below:\n", count, DL_SIZE(geometry));

    fprintSegment(dstFP, seg, NULL);

    // fprintf(dstFP, "\n");

    count++;

    elem = DL_NEXT(elem);
  }

  fprintf(dstFP, "\n");

  return;

} /* END fprintGeometry() **/

POLYGON *initialPolygon(){

  POLYGON *newPoly;

  newPoly = (POLYGON *)malloc(sizeof(POLYGON));
  if (! newPoly){
    fprintf(stderr, "initialPolygon(): Error allocating memory.\n");
    return newPoly;
  }

  initialDL((DLIST *)newPoly, zapGps, NULL);
  //initialDL((DLIST *)newPoly, NULL, NULL);
  newPoly->listType = POLYGON_LT;

  return newPoly;

} /* END initialPolygon() */

void fprintPolygon(FILE *toFile, POLYGON *poly, char *heading){

  return fprintGpsListGeneric(toFile, poly, heading);

}

void zapPolygon(void **poly){

  POLYGON *myPoly;

  ASSERTARGS(poly);

  myPoly = (POLYGON *) *poly;

  if(myPoly && myPoly->listType == POLYGON_LT){

    destroyDL(myPoly);
    free(myPoly);
    *poly = NULL;
  }

  return;

} /* END zapPolygon() */

FRQNCY_LIST *initialFrqncyList(){

  FRQNCY_LIST *newFL;

  newFL = (FRQNCY_LIST *)malloc(sizeof(FRQNCY_LIST));
  if (! newFL){
    fprintf(stderr, "initialFrqncyList(): Error allocating memory.\n");
    return newFL;
  }

  initialDL((DLIST *)newFL, NULL, NULL);
  newFL->listType = FRQNCY_LT;

  return newFL;

} /* END initialFrqncyList() */
















/* line2GpsList() : caller initials gpsList, we just insert GPS points.
 * what is this for!?
 * *****************************************************/
int line2GpsList(GPS_LIST *gpsList, LINE *line){

  int    result;

  ASSERTARGS(gpsList && line);

  if( ! (line->gps1 && line->gps2) ){
    fprintf(stderr, "line2GpsList(): Error seems line structure is uninitialized!\n");
    return ztInvalidArg;
  }

  if (gpsList->listType != GPS_LT){
    fprintf(stderr, "line2GpsList(): Error parameter gpsList is not GPS_LT list type.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(gpsList) != 0){
    fprintf(stderr, "line2GpsList(): Error parameter gpsList is not Empty list.\n");
    return ztInvalidArg;
  }

  result = insertNextDL(gpsList, DL_TAIL(gpsList), (void *) line->gps1);
  if(result != ztSuccess){
    fprintf(stderr, "line2GpsList(): Error failed insertNextDL() function.\n");
    return ztMemoryAllocate;
  }

  result = insertNextDL(gpsList, DL_TAIL(gpsList), (void *) line->gps2);
  if(result != ztSuccess){
    fprintf(stderr, "line2GpsList(): Error failed insertNextDL() function.\n");
    return ztMemoryAllocate;
  }

  return ztSuccess;

} /* END line2GpsList() */

/* line2Segment() : caller initials segment, we just insert GPS points */
int line2Segment(SEGMENT *segment, LINE *line){

  int    result;

  ASSERTARGS(segment && line);

  if( ! (line->gps1 && line->gps2) ){
    fprintf(stderr, "line2Segment(): Error seems line structure is uninitialized!\n");
    return ztInvalidArg;
  }

  if (segment->listType != SEGMENT_LT){
    fprintf(stderr, "line2Segment(): Error parameter segment is not SEGMENT type.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(segment) != 0){
    fprintf(stderr, "line2Segment(): Error parameter segment is not Empty list.\n");
    return ztInvalidArg;
  }

  result = insertNextDL(segment, DL_TAIL(segment), (void *) line->gps1);
  if(result != ztSuccess){
    fprintf(stderr, "line2Segment(): Error failed insertNextDL() function.\n");
    return ztMemoryAllocate;
  }

  result = insertNextDL(segment, DL_TAIL(segment), (void *) line->gps2);
  if(result != ztSuccess){
    fprintf(stderr, "line2Segment(): Error failed insertNextDL() function.\n");
    return ztMemoryAllocate;
  }

  return ztSuccess;

} /* END line2Segment() */

/* bbox2Polygon(BBOX *bbox): converts valid overpass bounding box to POLYGON.
 * function allocates memory and initials POLYGON then fills list.
 *
 * Moving counter-clockwise starting at south west corner.
 *
 * Returns a pointer to newly allocated and filled POLYGON or NULL on error.
 *
 * Errors: bad bounding box or memory allocation.
 *
 */

POLYGON *bbox2Polygon(BBOX *bbox){

  POLYGON    *poly = NULL;
  GPS    *sw, *nw, *ne, *se, *swClosing;
  int    result;

  ASSERTARGS(bbox);

  if(isBbox(bbox) == FALSE){
    fprintf(stderr, "bbox2Polygon(): Error invalid bounding box in parameter bbox.\n");
    return poly;
  }

  sw = initialGps();
  if ( ! sw ){
    fprintf(stderr, "bbox2Polygon(): Error failed initialGps() function.\n");
    return poly;
  }

  /* sw and swClosing 2 different pointers with same longitude & latitude **/
  swClosing = initialGps();
  if ( ! swClosing ){
    fprintf(stderr, "bbox2Polygon(): Error failed initialGps() function.\n");
    return poly;
  }

  nw = initialGps();
  if ( ! nw ){
    fprintf(stderr, "bbox2Polygon(): Error failed initialGps() function.\n");
    return poly;
  }

  ne = initialGps();
  if ( ! ne ){
    fprintf(stderr, "bbox2Polygon(): Error failed initialGps() function.\n");
    return poly;
  }

  se = initialGps();
  if ( ! se ){
    fprintf(stderr, "bbox2Polygon(): Error failed initialGps() function.\n");
    return poly;
  }

  poly = initialPolygon();
  if ( ! poly ){
    fprintf(stderr, "bbox2Polygon(): Error failed initialPolygon() function.\n");
    return poly;
  }

  sw->longitude = bbox->sw.longitude;
  sw->latitude = bbox->sw.latitude;

  swClosing->longitude = bbox->sw.longitude;
  swClosing->latitude = bbox->sw.latitude;

  nw->longitude = bbox->sw.longitude;
  nw->latitude = bbox->ne.latitude;

  ne->longitude = bbox->ne.longitude;
  ne->latitude = bbox->ne.latitude;

  se->longitude = bbox->ne.longitude;
  se->latitude = bbox->sw.latitude;

  /* insert GPS points clockwise starting at sw **/
  result = insertNextDL(poly, DL_TAIL(poly), (void *) sw);
  if(result != ztSuccess){
    fprintf(stderr, "bbox2Polygon(): Error failed insertNextDL() function.\n");
    destroyDL(poly);
    poly = NULL;
    return poly;
  }

  result = insertNextDL(poly, DL_TAIL(poly), (void *) nw);
  if(result != ztSuccess){
    fprintf(stderr, "bbox2Polygon(): Error failed insertNextDL() function.\n");
    destroyDL(poly);
    poly = NULL;
    return poly;
  }
  result = insertNextDL(poly, DL_TAIL(poly), (void *) ne);
  if(result != ztSuccess){
    fprintf(stderr, "bbox2Polygon(): Error failed insertNextDL() function.\n");
    destroyDL(poly);
    poly = NULL;
    return poly;
  }

  result = insertNextDL(poly, DL_TAIL(poly), (void *) se);
  if(result != ztSuccess){
    fprintf(stderr, "bbox2Polygon(): Error failed insertNextDL() function.\n");
    destroyDL(poly);
    poly = NULL;
    return poly;
  }

  result = insertNextDL(poly, DL_TAIL(poly), (void *) swClosing); /* close polygon **/
  if(result != ztSuccess){
    fprintf(stderr, "bbox2Polygon(): Error failed insertNextDL() function.\n");
    destroyDL(poly);
    poly = NULL;
    return poly;
  }

  return poly;

} /* END bbox2Polygon() **/

/* isBbox() : function checks that the structure pointed to by bbox holds
 * a valid bounding box as defined by Overpass API; that is the south-west
 * GPS is really south-west relative to north-east GPS.
 * Return: function returns TRUE if structure holds a valid bounding box and
 * FALSE otherwise.
 *
 ***************************************************************************/
int isBbox(BBOX *bbox){

  ASSERTARGS (bbox);

  /* maybe a lot of noise!? - good to know reason */
  if (bbox->sw.longitude > bbox->ne.longitude)
    fprintf (stderr, "isBbox(): invalid member is: LONGITUDE.\n");

  if (bbox->sw.latitude > bbox->ne.latitude)
    fprintf (stderr, "isBbox(): invalid member is: LATITUDE.\n");

  if ( (bbox->sw.longitude < bbox->ne.longitude) &&
       (bbox->sw.latitude < bbox->ne.latitude) )

    return TRUE;

  return FALSE;

} /* END isBbox() */


LINE *getBoxLine(BBOX *box, DIRECTION which){

  LINE *line;

  ASSERTARGS(box);

  line = initialLine();
  if (! line){
    fprintf(stderr, "getBoxLine(): Error allocating memory.\n");
    return line;
  }

  switch(which){

  case EAST:

    line->gps1->longitude = box->ne.longitude;
    line->gps1->latitude = box->ne.latitude;

    line->gps2->longitude = box->ne.longitude;
    line->gps2->latitude = box->sw.latitude;

    break;

  case SOUTH:

    line->gps1->longitude = box->ne.longitude;
    line->gps1->latitude = box->sw.latitude;

    line->gps2->longitude = box->sw.longitude;
    line->gps2->latitude = box->sw.latitude;

    break;

  case WEST:

    line->gps1->longitude = box->sw.longitude;
    line->gps1->latitude = box->ne.latitude;

    line->gps2->longitude = box->sw.longitude;
    line->gps2->latitude = box->sw.latitude;

    break;

  case NORTH:

    line->gps1->longitude = box->ne.longitude;
    line->gps1->latitude = box->ne.latitude;

    line->gps2->longitude = box->sw.longitude;
    line->gps2->latitude = box->ne.latitude;

    break;

  default:
    fprintf(stderr, "getBoxLine(): Error invalid DIRECTION parameter.\n");
    zapLine((void **) &line);
    line = NULL;
    break;
  }

  return line;

} /* END getBoxLine() */



































/*
  void fprintGpsList (FILE *toFile, DLIST *gpsList){

  FILE    *dstFP;

  GPS    *gps;
  ELEM    *elem;

  ASSERTARGS(gpsList);

  if ( ! toFile)

  dstFP= stdout;

  else

  dstFP = toFile;

  if (DL_SIZE(gpsList) == 0)  return;

  fprintf(dstFP, " List size is: <%d>\n", DL_SIZE(gpsList));

  fprintf(dstFP, " [longitude, latitude]\n");

  elem = DL_HEAD(gpsList);
  while(elem){

  gps = (GPS *) DL_DATA(elem);
  fprintGps(dstFP, gps);

  elem = DL_NEXT(elem);
  }

  return;

  } **/
/* END fprintGpsList() */
/*
  void fprintSegment(FILE *toFile, SEGMENT *segment){

  FILE    *dstFP;

  ASSERTARGS(segment);

  if (DL_SIZE(segment) == 0)  return;

  if ( ! toFile)

  dstFP= stdout;

  else

  dstFP = toFile;

  fprintf(dstFP, "fprintSegment(): Segment has < %d > GPS points:\n", DL_SIZE(segment));

  return fprintGpsList(dstFP, segment);

  } **/
/* END fprintSegment() **/


/* text2StringList():
 *
 *          THIS FUNCTION IS A WORK HORSE,
 *          YOU HAVE GOT TO KNOW WHAT IT DOES
 *
 * Function places 'text' into strList, linefeed '\n' character is
 * used as delimiter, each line is placed into an element in the list.
 * Function removes white spaces from either ends before insertion.
 *
 * No empty lines are inserted.
 *
 *
 * Parameters:
 * strList: a pointer to an empty initialed STRING_LIST
 * text   : character pointer to text, must have at least one
 *          linefeed character.
 *
 ****************************************************************/

int text2StringList(STRING_LIST *strList, char *text){

  int   linefeed = '\n';
  char  *ptr;
  char  *myText;
  char  *delim = "\n";
  char  *whiteSpaceSet = "\040\t\n";
  char  *newLine;
  int   result;

  ASSERTARGS(strList && text);

  if( ! TYPE_STRING_LIST(strList) ){
    fprintf(stderr, "text2StringList(): Error parameter 'strList' is not of type STRING_LT.\n");
    return ztInvalidArg;
  }

  if (DL_SIZE(strList)){
    fprintf(stderr, "text2StringList(): Error parameter 'strList' is NOT an empty list.\n");
    return ztInvalidArg;
  }

  ptr = strchr (text, linefeed);
  if ( ! ptr ){
    fprintf(stderr, "text2StringList(): Error parameter 'text' has no linefeed characters.\n");
    return ztInvalidArg;
  }

  myText = STRDUP(text);

  ptr = strtok(myText, delim);
  if ( ! ptr ){
    fprintf(stderr, "text2StringList(): Error failed strtok() function!\n");
    return ztUnknownError;
  }

  while (ptr){

    newLine = strdup(ptr);
    if ( ! newLine ){
      fprintf(stderr, "text2StringList(): Error allocating memory for newLine.\n");
      return ztMemoryAllocate;
    }

    removeSpaces(&newLine); /* does nothing if ALL white spaces **/

    if (strspn(newLine, whiteSpaceSet) != strlen(newLine)){ /* do NOT insert blank lines **/

      result = insertNextDL (strList, DL_TAIL(strList), (void *) newLine);
      if (result != ztSuccess){
	fprintf(stderr, "text2StringList(): Error failed insertNextDL().\n");
	return result;
      }
    }

    ptr = strtok(NULL, delim);

  }

  if(myText)  free(myText);

  return ztSuccess;

} /* END text2StringList() */

