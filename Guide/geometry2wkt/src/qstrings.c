/*
 * strings.c
 *
 *  Created on: Sep 15, 2022
 *  Author: Wael Hammoudeh
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "qstrings.h"

#include "util.h"
#include "ztError.h"


/* csvLine2Gps(): parses ONE node string into ONE GPS structure.
 *
 * in our query4Crossing() we specify this output format in every query:
 *
 *  [out:csv( ::lon, ::lat]
 *
 * this format produces the line below between the two vertical  '|'
 * characters for each node found by 'overpass' server:
 *
 *  |-111.8908258 33.4343930|
 *
 * this function parses the above line. I call this line "csvLine", hence
 * the function name csvLine2Gps(). This line is for one NODE.
 *
 * Parameters:
 *  - line   : a character pointer to string to parse.
 *  - destGps: is a pointer to an allocated GPS structure.
 *
 * Note: caller manages memory for destination GPS.
 *
 * Return:
 * ztDisallowedChar : source string has disallowed character.
 * ztParseError
 * ztSuccess : all okay.
 *
 *****************************************************************/

int csvLine2Gps (GPS *destGps, const char *line){

  char    *myStr;
  char    *delim = "\040\t\n"; /* delimiter set: space & tab & linefeed */
  char    *token1, *token2, *token3;
  double  numLat, numLng;
  char    *endPtr;

  /* do not allow null pointers */
  ASSERTARGS (destGps && line);

  myStr = STRDUP(line); /* STRDUP() aborts program on memory failure! **/

  token1 = strtok(myStr, delim);
  token2 = strtok(NULL, delim);
  token3 = strtok(NULL, delim);

  if( ! (token1 && token2)){
    fprintf(stderr, "csvLine2Gps(): Error; could not get two required tokens.\n");
    return ztMalformedStr;
  }

  if(token3){
    fprintf(stderr, "csvLine2Gps(): Error; found third token, only two expected.\n");
    return ztMalformedStr;
  }

  if(! isDecimalStr(token1)){
    fprintf(stderr, "csvLine2Gps(): Error failed isDecimalStr() for token number 1.\n");
    return ztDisallowedChar;
  }

  if(! isDecimalStr(token2)){
    fprintf(stderr, "csvLine2Gps(): Error failed isDecimalStr() for token number 2.\n");
    return ztDisallowedChar;
  }

  numLng = (double) strtod (token1, &endPtr);
  if (*endPtr != '\0') {
    fprintf(stderr, "csvLine2Gps(): Parsing error encountered with token <%s>.\n"
	    " Verify correct numerical formatting.\n", token1);
    return ztParseError;
  }

  if (! LONGITUDE_OK (numLng)){
    fprintf(stderr, "csvLine2Gps(): Error; invalid Arizona longitude. <%f>\n", numLng);
    return ztInvalidLonValue;
  }

  numLat = (double) strtod (token2, &endPtr);
  if (*endPtr != '\0') {
    fprintf(stderr, "csvLine2Gps(): Parsing error encountered with token <%s>.\n"
	    " Verify correct numerical formatting.\n", token2);
    return ztParseError;
  }

  if (! LATITUDE_OK(numLat)){
    fprintf(stderr, "csvLine2Gps(): Error; invalid Arizona latitude. <%f>\n", numLat);
    return ztInvalidLatValue;
  }

  /* assign values */
  destGps->longitude = numLng;
  destGps->latitude = numLat;

  return ztSuccess;

} /* END csvLine2Gps() */

/* csvStrList2GpsList():
 * Parses CSV_List (placed query response as STRING_LIST) into gpsList.
 * See text2StringList() function in "primitives.c" file.
 *
 * Parameters:
 * gpsList : a pointer to an initialed empty GPS_LIST.
 * csvList : a pointer to STRING_LIST with list size > 2.
 *
 * Query response text has a HEADER as first line, and last line has 'count'
 * found; so there must be at least 2 lines, that is the size of 'csvList'.
 * input list size must be > 2 to have something to do here.
 *
 ******************************************************************************/
int csvStrList2GpsList(GPS_LIST *gpsList, STRING_LIST *csvList){

  ELEM  *srcElem;
  char  *line;
  int   numNodesFound, result;
  GPS   *newGps;

  ASSERTARGS (gpsList && csvList);

  if (DL_SIZE(csvList) < 2){
    fprintf(stderr, "csvStrList2GpsList(): Error source parameter 'csvList' size < 2.\n");
    return ztInvalidArg;
  }

  if (DL_SIZE(gpsList) != 0){
    fprintf(stderr, "csvStrList2GpsList(): Error destination list in parameter 'gpsList' is NOT empty.\n");
    return ztListNotEmpty;
  }

  /* with overpass output setting [out:csv( ::lon, ::lat,::count)],
   * the LAST line will have the number of nodes found ***/

  srcElem = DL_TAIL(csvList);
  line = (char *) DL_DATA(srcElem);

  result = sscanf(line, "%d", &numNodesFound);
  if (result != 1){
    fprintf(stderr, "csvStrList2GpsList(): Error failed sscanf() function; "
	    "could NOT get numNodesFound!!!\n");
    return ztFailedLibCall;
  }

  /* no blank lines are in our list - must have 2 lines exactly when numNodesFound == 0 **/
  if ((numNodesFound == 0) && (DL_SIZE(csvList) == 2)) {
    fprintf(stderr, "csvStrList2GpsList(): Error, no CSV lines to parse; zero nodes found\n");
    return ztInvalidArg;
  }
  else if (numNodesFound == 0){
    fprintf(stderr, "csvStrList2GpsList(): Zero nodes found with number of lines NOT 2. Something strange here.\n"
	    " Number of lines in 'csvList' is: <%d>\n", DL_SIZE(csvList));
    return ztUnknownError;
  }

  /* start at second line. First line has CSV HEADER
   * and do NOT try to parse LAST line; has count found only. */

  srcElem = DL_NEXT(DL_HEAD(csvList));
  while (srcElem && DL_NEXT(srcElem)){

    line = (char *) DL_DATA(srcElem);
    if ( ! line ){
      fprintf(stderr, "csvStrList2GpsList(): Error could not get line from srcElem!\n");
      return ztUnknownError;
    }

    newGps = (GPS *) malloc(sizeof(GPS));
    if ( ! newGps ){
      fprintf(stderr, "csvStrList2GpsList(): Error allocating memory for newGps.\n");
      return ztMemoryAllocate;
    }
    newGps = initialGps();
    if ( ! newGps ){
      fprintf(stderr, "csvStrList2GpsList(): Error failed 'initialGps()' function.\n");
      return ztMemoryAllocate;
    }

    result = csvLine2Gps (newGps, line);
    if ( result != ztSuccess){
      fprintf(stderr, "csvStrList2GpsList(): Error failed csvLine2Gps().\n");
      return result;
    }

    result = insertNextDL (gpsList, DL_TAIL(gpsList), (void *) newGps);
    if (result != ztSuccess){
      fprintf(stderr, "csvStrList2GpsList(): Error returned by insertNextDL().\n");
      return result;
    }

    srcElem = DL_NEXT(srcElem);
  }

  if (numNodesFound != DL_SIZE(gpsList)){
    fprintf(stderr, "csvStrList2GpsList(): Error query number of nodes found is NOT equal to gpsList size.\n"
	    " parameter 'numNodesFound' is: <%d> while 'DL_SIZE(gpsList)' is: <%d>\n",
	    numNodesFound,DL_SIZE(gpsList));
    return ztUnknownError;
  }

  return ztSuccess;

} /* END csvStrList2GpsList() */

/* int jsonLine2Gps0(GPS *destGps, char *src)
 *
 * The overpass format output setting [out:json] produces well formed JSON
 * output for geometries. A node GPS is returned in a line similar to the
 * line below; which I call "jsonLine":
 *
 *  { "lat": 33.3524579, "lon": -111.9718744 },
 *
 *  using delimiter set "{\040\t,}", line has 4 tokens:
 *   1- "lat":  --> latTag
 *   2- latitude value
 *   3- "lon":  --> lonTag
 *   4- longitude value
 *
 *
 * This function parses the above text line.
 *
 * Parametrs:
 *  - src: a character string pointer to string source.
 *  - destGps: a pointer to an allocated GPS structure.
 *
 * Note: caller manages memory for destination GPS.
 *
 * return:
 *  ztBadParam, ztUnrecognizedToken or value returned from csvNode2Gps().
 *
 *  TODO: test it. return codes?
 *
 *************************************************************/
int jsonLine2Gps(GPS *destGps, const char *src){

  char  *allowed = "{alnot0123456789-,.:}\"\040";

  char  *mySrc; /* our own copy of source string */

  char  *latTagStr = "\"lat\":";
  char  *lonTagStr = "\"lon\":";
  char  *latStr;
  char  *lonStr;
  double  latValue, lonValue;


  ASSERTARGS (destGps && src);

  if(strspn(src, allowed) != strlen(src)){
    fprintf(stderr, "jsonNode2Gps(): Error source string has disallowed character.\n");
    return ztDisallowedChar;
  }

  mySrc = strdup(src);

  char *token;
  char *delimiter = "{\040\t,}";
  char *endP;

  int i=0;
  for (token = strtok(mySrc, delimiter); token != NULL; token = strtok(NULL, delimiter)) {

    switch(i){

    case 0:

      if(strcmp(token, latTagStr) != 0){
	fprintf(stderr, "jsonNode2Gps(): Error unmatched token for latitude tag.\n");
	return ztMalformedStr;
      }
      break;

    case 1:

      latStr = token;

      if(!isDecimalStr(latStr)){
	fprintf(stderr, "jsonNode2Gps(): Error failed isDecimalStr() for latitude string.\n");
	return ztParseError;
      }

      latValue = strtod(latStr, &endP);
      if (token == endP || *endP != '\0') {
	fprintf(stderr, "jsonNode2Gps() Error: Invalid token for double: <%s>.\n", token);
	free(mySrc);
	return ztParseError;
      }

      if(! LATITUDE_OK(latValue)){
	fprintf(stderr, "jsonNode2Gps() Error invalid latitude value in Arizona.\n");
	return ztInvalidLatValue;
      }
      break;

    case 2:

      if(strcmp(token, lonTagStr) != 0){
	fprintf(stderr, "jsonNode2Gps(): Error unmatched token for longitude tag.\n");
	return ztMalformedStr;
      }
      break;

    case 3:

      lonStr = token;

      if(!isDecimalStr(lonStr)){
	fprintf(stderr, "jsonNode2Gps(): Error failed isDecimalStr() for longitude string.\n");
	return ztParseError;
      }

      lonValue = strtod(lonStr, &endP);
      if (token == endP || *endP != '\0') {
	fprintf(stderr, "jsonNode2Gps() Error: Invalid token for double: <%s>.\n", token);
	free(mySrc);
	return ztParseError;
      }

      if(! LONGITUDE_OK(lonValue)){
	fprintf(stderr, "jsonNode2Gps() Error invalid longitude value in Arizona.\n");
	return ztInvalidLatValue;
      }
      break;

    case 4:

      fprintf(stderr, "jsonNode2Gps(): Error found extra token!\n");
      return ztStringUnknown;
      break;

    default:
      fprintf(stderr, "jsonNode2Gps(): Error in default case.\n");
      return ztUnknownError;
      break;

    }

    i++;
  }

  free(mySrc);

  if(i < 3){
    fprintf(stderr, "jsonNode2Gps(): Error missing expected token(s).\n");
    return ztMalformedStr;
  }

  destGps->longitude = lonValue;
  destGps->latitude = latValue;

  return ztSuccess;

} /* END jsonLine2Gps0() */

/*
 * parseSegment(): function parses one SEGMENT out of STRING_LIST starting
 * at this STRING_LIST 'startElem' element pointer. Function ends SEGMENT at
 * element with first character closing bracket ']' in its string.
 *
 * The data pointers in the elements are character pointers to "jsonLine"
 * string.
 *
 *
 * Caller initials destination 'seg'.
 *
 *
 * Return:
 *
 * Note to self : look at "tags": {
 * after each segment; "junction": "roundabout",
 * this means ==> closed segment or POLYGON ...
 *
 ******************************************************************/
int parseSegment (SEGMENT *seg, ELEM *startElem){

  ELEM  *elem;
  char  *string;

  char  terminator = ']';

  GPS  *newGps;
  int  result;

  ASSERTARGS (seg && startElem);

  if(seg->listType != SEGMENT_LT){
    fprintf (stderr, "parseSegment(): Error, destination parameter seg does not have SEGMENT_LT.\n");
    return ztInvalidArg;
  }

  /* destination 'seg' should be empty */
  if (DL_SIZE(seg)){
    fprintf (stderr, "parseSegment(): Error, destination parameter seg is NOT empty.\n");
    return ztListNotEmpty;
  }

  elem = startElem;

  while (elem){

    string = (char *) DL_DATA(elem);


    if(string[0] == terminator)    break;

    /* we end segment at first closing bracket.
     * first character in the string because we remove surrounding
     * spaces in text2StringList().
     *
     * difference between closing bracket ONLY & closing bracket PLUS COMMA
     *                   ] vs ],
     * segments in RELATION tags are terminated by single character of
     * closing bracket, whereas segments in WAY tags are terminated by
     * two character of closing bracket plus comma
     *
     *
     ********************************************************************/

    /* we allocate memory for GPS we insert into destination list */
    newGps = (GPS *) malloc(sizeof(GPS));
    if ( ! newGps ){
      fprintf (stderr, "parseSegment(): Error allocating memory.\n");
      return ztMemoryAllocate;
    }

    //result = jsonLine2Gps(newGps, string);
    result = jsonLine2Gps(newGps, string);
    if (result != ztSuccess){
      fprintf (stderr, "parseSegment(): Error; failed jsonLine2Gps() call.\n");
      return result;
    }

    result = insertNextDL (seg, DL_TAIL(seg), (void *) newGps);
    if (result != ztSuccess){
      fprintf (stderr, "parseSegment(): Error; failed insertNextDL() call.\n");
      return result;
    }

    elem = DL_NEXT(elem);
  }

  return ztSuccess;

} /* END parseSegment() */

/* parseGeometry():
 *
 * whole 'stringList' is placed in ONE GEOMETRY.
 *
 * caller initials geometry parameter
 *
 ******************************************************************/
int parseGeometry (GEOMETRY *geometry, STRING_LIST *stringList){

  ELEM    *elem;
  int     result;
  char    *string;
  SEGMENT *newSeg;  /* each geometry tag in osmJSON is a SEGMENT **/

  ASSERTARGS (geometry && stringList);

  if(geometry->listType != GEOMETRY_LT){
    fprintf(stderr, "parseGeometry(): Error geometry parameter does not have GEOMETRY_LT.\n");
    return ztInvalidArg;
  }

  if(stringList->listType != STRING_LT){
    fprintf(stderr, "parseGeometry(): Error stringList parameter does not have STRING_LT.\n");
    return ztInvalidArg;
  }

  /* destination must be empty && source can NOT be empty */
  if (DL_SIZE(geometry)){
    fprintf(stderr, "parseGeometry(): Error destination parameter geometry is not empty.\n");
    return ztListNotEmpty;
  }

  if ( ! DL_SIZE(stringList) ){
    fprintf(stderr, "parseGeometry(): Error source list stringList is empty.\n");
    return ztListEmpty;
  }

  /* start looking for GOEM_TAG in source */

  elem = DL_HEAD(stringList);
  while (elem){

    string = (char *) DL_DATA(elem);

    if (strcmp(string, GEOM_TAG) == 0){ /* found geometry tag */

      newSeg = initialSegment();
      if ( ! newSeg){
	fprintf(stderr, "parseGeometry(): Error failed initialSegment() function.\n");
	return ztMemoryAllocate;
      }

      /* parseSegment() function starts at NEXT line (element) to opening TAG,
       * and stops at closing geometry TAG **/
      result = parseSegment(newSeg, DL_NEXT(elem));
      if (result != ztSuccess){
	fprintf(stderr, "parseGeometry(): Error returned from parseSegment() function.\n");
	return result;
      }

      /* insert new filled segment into geometry destination list */
      result = insertNextDL (geometry, DL_TAIL(geometry), (void *) newSeg);
      if (result != ztSuccess){
	fprintf(stderr, "parseGeometry(): Error returned from insertNextDL() function.\n");
	return result;
      }

    }/* end found geometry tag */

    elem = DL_NEXT(elem);

  } /* end while (elem) */

  if (DL_SIZE(geometry) == 0)

    return ztNoGeometryFound;

  return ztSuccess;

} /* END parseGeometry() */


/* parseBbox():
 *
 * parses string pointed to by parameter 'str' assumed to be in
 * the following format:
 *
 * [bbox: south-line latitude, west-line longitude, north-line latitude, east-line longitude]
 *
 * Specifications:
 *  - starts with opening bracket character '[' and
 *    ends with closing bracket character ']'
 *  - bounding box tag follows opening bracket;
 *    tag consist of 'bbox:' colon included (lower case, no space) -
 *    op allows space between bbox and colon; not here!
 *  - four decimal numbers follow the tag;
 *    (2 corners; south-west and north-east)
 *    south-most latitude, west-most longitude,
 *    north-most latitude, east-most longitude
 *
 * Parameters:
 *  - bbox: pointer to client initialed empty BBOX structure.
 *  - 'str' character pointer to string to parse.
 *
 *  Return:
 *   - ztSuccess
 *   - ztDisallowedChar
 *   - ztParseError
 *   - ztMalformedStr
 *   - ztInvalidLatValue: invalid latitude value
 *   - ztInvalidLonValue: invalid longitude value
 *   - ztInvalidBbox: incorrect order for values
 *
 * Example accepted input string: ALL ACCEPTED
 *
 * [bbox: 33.53097, -112.07400, 33.56055, -112.0567345]
 * [ bbox: 33.53097, -112.07400, 33.56055, -112.0567345]
 * [bbox: 33.53097, -112.07400, 33.56055, -112.0567345  ]
 * [bbox: 33.53097  , -112.07400, 33.56055, -112.0567345]
 * [bbox: 33.53097  , -112.07400,33.56055  , -112.0567345  ]
 *
 * Failed tested:
 * [bbox:33.53097,, -112.07400, 33.56055, -112.0567345]
 * [bbox:33.53097 -1,12.07400, 33.56055, -112.0567345]
 * [Bbox: 33.53097, -112.07400, 33.56055, -112.0567345]
 * [bbox : 33.53097, -112.07400, 33.56055, -112.0567345]
 * [bbox:33.53097, -112.07400 33.56055, -112.0567345, -112.777777]
 * [bbox:33.5365299,  -112.0505905, 33.615477, ]
 *
 * allow sloppy typing, not incorrect values!
 ***************************************************************************/

int parseBbox(BBOX *bbox, const char *str){

  ASSERTARGS(bbox && str);

  char *allowed = "[box:0123456789.,-+]\040\t";

  char *myStr, *myStrPP;
  char comma = ',';
  char openCh = '[';
  char closeCh = ']';
  char *bboxTag = "bbox:";
  int  numCommaAll, numCommaRemain;

  /*  allowed characters set only **/
  if(strspn(str, allowed) != strlen(str)){
    fprintf(stderr, "parseBbox(): parse error; disallowed character detected.\n"
	    "Only digits, commas, periods, and '[bbox:]' (letters lower case) plus\n"
	    "space and tab characters are allowed.\n"
	    "Parameter in: <%s>\n", str);
    return ztDisallowedChar;
  }

  myStr = STRDUP(str);

  myStrPP = myStr;  /* myStrPP : Preserve Pointer; so we can call free() **/

  /* remove leading and trailing spaces **/
  removeSpaces(&myStr);

  /* check opening and closing characters **/
  if(myStr[0] != openCh || myStr[strlen(myStr) - 1] != closeCh){
    fprintf(stderr, "parseBbox(): Error missing / misplaced opening or closing bracket;"
	    " string must start with '[' and end with ']'\n 'str': <%s>\n", str);
    return ztMalformedStr;
  }

  /* check bbox: tag; move myStr pointer past '[' character and skip spaces **/

  myStr++;
  while(isspace(myStr[0])) myStr++;


  if(strncmp(myStr, bboxTag, strlen(bboxTag)) != 0){
    fprintf(stderr, "parseBbox(): Error unmatched 'bbox:' tag; ensure 'bbox:' follows opening bracket.\n"
	    "Colon included, no space and all lower case characters.\n");
    return ztMalformedStr;
  }

  /* move myStr pointer past 'bbox:'; strtok() takes care of leading spaces **/
  myStr = myStr + strlen(bboxTag);

  numCommaAll = numChrStr(comma, myStr);

  if(numCommaAll != 3){
    fprintf(stderr, "parseBbox(): Error string must include exactly 3 commas.\n "
	    "'str': <%s>\n", str);
    return ztMalformedStr;
  }

  /* keep track of commas with consumed tokens **/
  numCommaRemain = numCommaAll;


  char *delimiter = ",\040\t]"; /* includes closing bracket **/
  char *token;

  double south, west, north, east;

  int numTokens = 4;
  int numCoord = 0;

  int i = 0;
  for (token = strtok(myStr, delimiter); token != NULL; token = strtok(NULL, delimiter)) {

    if(!isDecimalStr(token)){
      fprintf(stderr, "parseBbox(): parse error encountered; invalid string for decimal number: <%s>\n", token);
      return ztParseError;
    }

    numCommaRemain--;

    char* endPtr;
    double num = strtod(token, &endPtr);

    if (token == endPtr || *endPtr != '\0') {
      fprintf(stderr, "parseBbox() Error: Invalid token for double: <%s>.\n", token);
      free(myStrPP);
      return ztParseError;
    }

    switch (i) {
    case 0:
      south = num;
      break;
    case 1:
      west = num;
      break;
    case 2:
      north = num;
      break;
    case 3:
      east = num;
      break;
    case 4:
      fprintf(stderr, "parseBbox(): Error found EXTRA token: token: <%s>\n", token);
      return ztParseError;
      break;
    default:
      break;
    }

    numCoord++; /* count assigned sides **/

    if(i < 3){

      /* track them for first three tokens only,
       * consume one comma if there was space between token
       * and comma as: "33.5800885 ,-112.1722126 , ..."
       *
       *********************************************/

      myStr = token + strlen(token) + 1;

      while(isspace(myStr[0])) myStr++;

      if(myStr[0] == comma) myStr++; /* eat it up **/

      numCommaAll = numChrStr(comma, myStr);

      if(numCommaAll != numCommaRemain){
        fprintf(stderr, "parseBbox(): parse error encountered; misplaced comma.\n");
        return ztParseError;
      }
    } /* end if(i < 3) **/

    i++;
  }

  free(myStrPP); /* free original preserved pointer **/

  if(numCoord < numTokens){
    fprintf(stderr, "parseBbox(): Error missing token(s), four coordinates are required.\n");
    return ztMalformedStr;
  }

  /* validate longitude & latitude values for Arizona **/
  if(! (LATITUDE_OK(south) && LATITUDE_OK(north)) ){
    fprintf(stderr, "parseBbox(): Error detected invalid latitude value for Arizona.\n");
    return ztInvalidLatValue;
  }

  if(! (LONGITUDE_OK(west) &&  LONGITUDE_OK(east)) ){
    fprintf(stderr, "parseBbox(): Error detected invalid longitude value for Arizona.\n");
    return ztInvalidLonValue;
  }

  /* check numbers placement in the string **/
  if( (south > north) || (west > east) ){
    fprintf(stderr, "parseBbox(): Error, inconsistent longitudes or latitudes;\n"
	    "ensure that south latitude is less than north latitude and\n"
	    "that west longitude is less than east longitude.\n");
    return ztInvalidBbox;
  }

  /* ALL okay, assign BBOX members: **/
  bbox->sw.latitude = south;
  bbox->sw.longitude = west;

  bbox->ne.latitude = north;
  bbox->ne.longitude = east;

  return ztSuccess;

} /* END parseBbox() **/

/* isDecimalStr():
 * is parameter 'token' good as coordinate decimal number?
 *
 * isCoordDecimalStr(): name is too long!
 *
 * 3 digits max before period? digits after period?
 *
 * Returns TRUE or FALSE
 *
 *************************************************/
int isDecimalStr(const char *token){

  ASSERTARGS(token);

  char  *allowed = "-+.0123456789";
  char  peroid = '.';

  if(strspn(token, allowed) != strlen(token))

    return FALSE;

  if(!strchr(token, peroid))

    return FALSE;

  return TRUE;

} /* END isDecimalStr() **/

int numChrStr(char letter, const char *str){

  int count = 0;
  char *start;
  char *location;

  ASSERTARGS(str);

  start = STRDUP(str);

  location = strchr(start,(int) letter);

  while(location){

    count++;

    start = location + 1;
    location = strchr(start, letter);
  }

  return count;

} /* END numChrStr() **/
