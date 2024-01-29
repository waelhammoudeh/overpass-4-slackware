/*
 * fileio.c
 *
 *  Created on: Dec 19, 2018
 *  Author: Wael Hammoudeh
 *
 *  functions write Well Know Text to files; they all call
 *  on functions found in "formatWkt.c" file.
 *
 ******************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

/*
  #ifndef QMASTER_H_
  #include "qmaster.h"
  #endif
**/

#include "fileio.h"

/* file2StringList(): reads file into string list.
 *
 * get to know this function and this similar function in file
 * "primitives.c":
 * int text2StringList(STRING_LIST *strList, char *text);
 *
 * caller initials 'strList'.
 **************************************************************/

int file2StringList(STRING_LIST *strList, const char *filename){

  int   result;
  FILE  *fPtr;
  char  buffer[MAX_TEXT + 1];
  char  *newString;
  char  *spaceSet = "\040\t\n";

  //ASSERTARGS(strList && filename); allow null filename
  ASSERTARGS(strList);

  if(DL_SIZE(strList) != 0){

    fprintf(stderr, "file2StringList(): Error argument 'strList' is not empty.\n");
    return ztListNotEmpty;
  }

  if(strList->listType != STRING_LT) /* just set it, keep old code working **/

    strList->listType = STRING_LT;

  if(filename == NULL){
    fPtr = stdin;
  }
  else{

    result = isFileReadable(filename);
    if(result != ztSuccess){

      fprintf(stderr, "file2StringList(): Error failed isFileReadable()"
	      " for argument 'filename'.\n");
      return result;
    }

    errno = 0;

    fPtr = fopen(filename, "r");
    if (fPtr == NULL){

      fprintf (stderr, "file2StringList(): Error failed fopen() function.\n");
      fprintf(stderr, "System error message: %s\n\n", strerror(errno));
      return ztOpenFileError;
    }
  }

  while (fgets(buffer, (MAX_TEXT + 1), fPtr)){

    /* do not allow a line longer than (MAX_TEXT) - we do not combine lines. **/
    if((strlen(buffer) == MAX_TEXT) &&
       (buffer[MAX_TEXT - 1] != '\n')){ /* did not read linefeed --> truncated **/

      fprintf(stderr, "file2StringList(): Error long line; longer than <%d> characters.\n"
	      "lines are not combined by this function.\n", MAX_TEXT);
      return ztInvalidArg;
    }

    if (strspn(buffer, spaceSet) == strlen(buffer))  continue; /* ignore empty line **/

    /* remove line feed - kept by fgets() **/
    if (buffer[strlen(buffer) - 1] == '\n')

      buffer[strlen(buffer) - 1] = '\0';

    newString = (char *)malloc((strlen(buffer) + 1) * sizeof(char));
    if(!newString){
      fprintf(stderr, "file2StringList(): Error allocating memory.\n");
      fclose(fPtr);
      return ztMemoryAllocate;
    }

    strcpy(newString, buffer);

    /* remove leading and trailing white spaces **/
    removeSpaces(&newString);

    result = insertNextDL (strList, DL_TAIL(strList), (void *)newString);
    if(result != ztSuccess){

      fprintf(stderr, "file2StringList(): Error failed insertNextDL() function.\n");
      fclose(fPtr);
      return result;
    }

  } /* end while() **/

  fclose(fPtr);

  return ztSuccess;

} /* END file2StringList() **/

/* findElemSubString():
 *
 * find element with sub-string in STRING_LIST
 *
 * return: pointer to ELEM.
 *
 ****************************************************/

ELEM* findElemSubString (STRING_LIST *list, char *subString){

  ELEM  *elem = NULL;
  ELEM  *currentElem;
  char  *string;

  ASSERTARGS(list && subString);

  if(! TYPE_STRING_LIST(list))

    return elem;

  if(DL_SIZE(list) == 0)

    return elem;

  currentElem = DL_HEAD(list);
  while(currentElem){

    string = (char *)DL_DATA(currentElem);

    if(strstr(string, subString)){

      elem = currentElem;
      break;
    }

    currentElem = DL_NEXT(currentElem);
  }

  return elem;

} /* END findElemSubString() **/

/* stringList2File(): writes string list to named file.
 *
 * if list is empty an empty file IS created - WRONG?
 *
 ***********************************************************/

int stringList2File(const char *filename, STRING_LIST *list){

  int    result;
  FILE   *fPtr;
  ELEM   *elem;
  char   *string;

  ASSERTARGS (filename && list);

  result = isGoodFilename(filename);
  if(result != ztSuccess){
    fprintf(stderr, "stringList2File() Error failed isGoodFilename() for 'filename': <%s>\n",
	    filename);
    return result;
  }

  errno = 0;
  fPtr = fopen(filename, "w");
  if(!fPtr){
    fprintf(stderr, "stringList2File(): Error failed fopen() function for 'filename': <%s>\n",
	    filename);
    fprintf(stderr, "System error message: %s\n\n", strerror(errno));
    return ztOpenFileError;
  }

  if (DL_SIZE(list) == 0){
    fclose(fPtr);
    return ztSuccess;
  }

  elem = DL_HEAD(list);

  while (elem) {

    string = (char *)DL_DATA(elem);

    if(!string){
      fprintf(stderr, "stringList2File(): Error variable 'string' is null ...\n");
      return ztFatalError;
    }

    fprintf (fPtr, "%s\n", string);

    elem = DL_NEXT(elem);

  }

  fclose(fPtr);

  return ztSuccess;

} /* END stringList2File() **/

int removeFile(const char *filename){

  int  result;

  ASSERTARGS(filename);

  /* we only keep cookie file. remove script and json settings files
   * the right way is to use temporary files.
   ***********************************************************/

  errno = 0;

  result = remove(filename);
  if (result != 0){
    fprintf(stderr, "removeFile(): Error failed remove() system call! filename: <%s>\n",
            filename);
    fprintf(stderr, "System error message: %s\n\n", strerror(errno));
    return ztFailedSysCall;
  }

  return ztSuccess;

} /* END removeFile() **/

int renameFile(const char *oldName, const char *newName){

  int   result;

  ASSERTARGS(oldName && newName);

  /* renameFile() renames files only, NOT directory
   *
   ************************************************/

  if (!isRegularFile(oldName)){
    fprintf(stderr, "renameFile(): Error - '%s' is not a regular file.\n", oldName);
    return ztNotRegFile;
  }

  /* try to use rename() first, we will be done if it is successful **/
  result = rename(oldName, newName);
  if(result == ztSuccess)

    return ztSuccess;

  /* rename() failed; try to read file into list then write list with new name **/

  STRING_LIST   *fileList;

  fileList = initialStringList();
  if(!fileList){
    fprintf(stderr, "renameFile(): Error failed initialStringList(); can not move/rename file!\n");
    return ztMemoryAllocate;
  }

  result = file2StringList(fileList, oldName);
  if(result != ztSuccess){
    fprintf(stderr, "renameFile: Error failed file2StringList(); can not move/rename file!\n");
    return result;
  }

  result = stringList2File(newName, fileList);
  if(result != ztSuccess){
    fprintf(stderr, "renameFile: Error failed stringList2File(); can not move/rename file!\n");
    zapStringList((void **) fileList);
    return result;
  }

  zapStringList((void **) fileList);

  removeFile(oldName);

  return ztSuccess;

} /* END renameFile() **/

/*
 * prepWktFile():
 * ---------------------
 * Prepares an output file for Well Known Text (WKT) writing.
 * Writes "wkt;" on first line.
 *
 * Parameters:
 *   file - Character pointer to the output file; string includes
 *   path, filename and file extension. Extension value is not checked.
 *
 * Returns:
 *   FILE pointer to the opened file for writing, or NULL on failure.
 *
 * Note:
 * This function opens the specified file for writing WKT data.
 * File extension must be included. I use ".csv" here.
 * QGIS uses ".csv" while ArcGIS uses ".txt" for WKT.
 *
 ****************************************************************/

FILE *prepWktFile(const char *file){

  FILE *filePtr = NULL;

  int   result;
  char  *wktStamp = "wkt;";

  ASSERTARGS(file);

  char *parent;

  result = isGoodFilename(file);
  if(result != ztSuccess){
    fprintf(stderr, "prepWktFile(): Error parameter 'file' not a valid filename.\n"
	    "Filename is not valid for: %s\n", ztCode2Msg(result));
    fprintf(stderr, "prepWktFile(): The problem parameter 'file' is: <%s>\n", file);
    return filePtr;
  }

  char  *noExtension;

  noExtension = dropExtension((char *)file);

  if(noExtension && strcmp(noExtension, file) == 0){ /* missing extension **/
    fprintf(stderr, "prepWktFile(): Error missing file extension in parameter 'file'\n");
    free(noExtension);
    return filePtr;
  }

  if(noExtension)
    free(noExtension);

  parent = getParentDir(file);
  if(!parent){
    fprintf(stderr, "prepWktFile(): Error failed getParentDir() function\n");
    return filePtr;
  }

  result = isDirUsable(parent); /* we must be able to write to directory **/
  if (result != ztSuccess){
    fprintf(stderr, "prepWktFiles(): Error parent directory is not usable for: %s\n", ztCode2Msg(result));
    return filePtr;
  }

  filePtr = openOutputFile((char *) file);
  if(!filePtr){
    fprintf(stderr, "prepWktFiles(): Error failed to create filename: <%s>\n", file);
    return filePtr;
  }

  fprintf(filePtr, "%s\n\n", wktStamp);

  return filePtr;

} /* END prepWktFile() **/

/* writeGpsWkt():
 *
 * Parameter 'file' is the filename for WKT file; must have an extension.
 *
 **********************************************************************/

int writeGpsWkt(char *file, GPS *gps){

  FILE  *destFP;
  char  *wktStr;
  int   result;

  ASSERTARGS(file && gps);

  destFP = prepWktFile(file);
  if(!destFP){
    fprintf(stderr, "writeGpsWkt(): Error failed prepWktFile().\n");
    return ztOpenFileError;
  }

  wktStr = gps2PointWktCh(gps);
  if(!wktStr){
    fprintf(stderr, "writeGpsWkt(): Error failed gps2PointWktCh().\n");
    return ztMemoryAllocate;
  }

  fprintf(destFP, "%s\n", wktStr);

  closeFile(destFP);

  free(wktStr);

  if(isExecutableUsable(OGR2OGR_EXEC) == ztSuccess){
    result = wkt2Shapefile(file);
    if(result != ztSuccess){
      fprintf(stderr, "writeGpsWkt(): Error failed wkt2Shapefile().\n");
      return result;
    }
  }

  return ztSuccess;

} /* END writeGpsWkt() **/

/* writeWktStrList():
 * list is one of: GPS_LIST, SEGMENT or POLYGON
 * strListFun()  : gpsList2PointWktStrList(), seg2PointWktStrList(),
 *                 seg2LinestringWktStrList(), poly2PointWktStrList()
 *                 poly2LinestringWktStrList()
 *
 *********************************************************************/

int writeWktStrList(char *file, DLIST *list, int strListFun(STRING_LIST *, DLIST *)){

  FILE        *destFP;
  STRING_LIST *wktList;
  int         result;

  ASSERTARGS(file && list && strListFun);

  destFP = prepWktFile(file);
  if(!destFP){
    fprintf(stderr, "writeWktStrList(): Error failed prepWktFile().\n");
    return ztOpenFileError;
  }

  wktList = initialStringList();
  if(!wktList){
    fprintf(stderr, "writeWktStrList(): Error failed initialStringList().\n");
    return ztMemoryAllocate;
  }

  result = strListFun(wktList, list);
  if(result != ztSuccess){
    fprintf(stderr, "writeWktStrList(): Error failed to obtain WKT string list; failed strListFun().\n");
    return result;
  }

  fprintStringList(destFP, wktList);

  zapStringList((void **) &wktList);

  closeFile(destFP);

  if(isExecutableUsable(OGR2OGR_EXEC) == ztSuccess){
    result = wkt2Shapefile(file);
    if(result != ztSuccess){
      fprintf(stderr, "writeWktStrList(): Error failed wkt2Shapefile().\n");
      return result;
    }
  }

  return ztSuccess;

} /* END writeWktStrList() **/

int writeGeomWkt(char *destFile, GEOMETRY *geom, WKT_ENTITY wktEntity){

  FILE  *destFP;

  LIST_STR_LIST *lls;
  int result;

  ASSERTARGS(destFile && geom);

  if(wktEntity != WKT_POINT && wktEntity != WKT_LINESTRING){
    fprintf(stderr, "writeGeomWkt(): Error invalid 'entity' parameter.\n");
    return ztInvalidArg;
  }

  destFP = prepWktFile(destFile);
  if(!destFP){
    fprintf(stderr, "writeGeomWkt(): Error failed prepWktFile().\n");
    return ztOpenFileError;
  }

  lls = initialListStrList();
  if(!lls){
    fprintf(stderr, "writeGeomWkt(): Error failed initialListStrList().\n");
    return ztMemoryAllocate;
  }

  if(wktEntity == WKT_POINT)
    result = geom2WktListListStr(lls, geom, seg2PointWktStrList);
  else
    result = geom2WktListListStr(lls, geom, seg2LinestringWktStrList);

  if(result != ztSuccess){
    fprintf(stderr, "writeGeomWkt(): Error failed to geom2WktListListStr().\n");
    return result;
  }

  fprintListStrList(destFP, lls);

  zapListStrList((void **) &lls);

  closeFile(destFP);

  if(isExecutableUsable(OGR2OGR_EXEC) == ztSuccess){
    result = wkt2Shapefile(destFile);
    if(result != ztSuccess){
      fprintf(stderr, "writeGeomWkt(): Error failed wkt2Shapefile().\n");
      return result;
    }
  }

  return ztSuccess;

} /* END writeGeomWkt() **/

int writeBboxWktPolygon(char *toFile, BBOX *bbox){

  char  *bboxWktStr;
  int   result;
  FILE  *filePtr;

  ASSERTARGS(toFile && bbox);

  if(! isBbox(bbox)){
    fprintf(stderr, "writeBboxWktPolygon(): Error failed isBbox(); invalid bounding box.\n");
    return ztInvalidArg;
  }

  result = bbox2PolygonWkt(&bboxWktStr, bbox);
  if(result != ztSuccess){
    fprintf(stderr, "writeBboxWktPolygon(): Error failed bbox2PolygonWkt().\n");
    return result;
  }

  filePtr = prepWktFile(toFile);
  if(!filePtr){
    fprintf(stderr, "writeBboxWktPolygon(): Error failed prepWktFile().\n");
    return ztOpenFileError;
  }

  fprintf(filePtr, "%s\n", bboxWktStr);

  closeFile(filePtr);

  if(isExecutableUsable(OGR2OGR_EXEC) == ztSuccess){
    result = wkt2Shapefile(toFile);
    if(result != ztSuccess){
      fprintf(stderr, "writeBboxWktPolygon(): Error failed wkt2Shapefile().\n");
      return result;
    }
  }

  return ztSuccess;

} /* END writeBboxWktPolygon() **/

/* writeSegmentWktByNum():
 * writes POINT & LINESTRING files for the numbered segment in geometry.
 *
 * we append to fPrefix the following quoted strings:
 * "_segN_M_Linestring.csv" --> for LINESTRING
 * "_segN_M_Point.csv" --> for POINT
 *
 * where N is segNum and M is geometry size.
 *
 * parameter fPrefix (file prefix) is expected to be short; not longer
 * than 24 characters.
 *
 *********************************************************************/

int writeSegmentWktByNum(GEOMETRY *geometry, int segNum, char *toDir, char *fPrefix){

  ASSERTARGS(geometry && toDir && fPrefix);

  if(! TYPE_GEOMETRY(geometry) ){
    fprintf(stderr, "writeSegmentWktByNum(): Error parameter 'geometry' is not of type GEOMETRY_LT.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(geometry) == 0){
    fprintf(stderr, "writeSegmentWktByNum(): Error parameter 'geometry' is empty.\n");
    return ztListEmpty;
  }

  if(segNum < 1 || segNum > DL_SIZE(geometry)){
    fprintf(stderr, "writeSegmentWktByNum(): Error 'segNum' parameter is not within geometry size range.\n");
    return ztInvalidArg;
  }

  if(strlen(fPrefix) > 24){
    fprintf(stderr, "writeSegmentWktByNum(): Error parameter 'fPrefix' is longer than 24 characters.\n");
    return ztInvalidArg;
  }

  /* using the function below:
   *
   * int writeWktStrList(char *file, DLIST *list, int strListFun(STRING_LIST *, DLIST *))
   *
   * parameter 'file' is full filename: we stich that below.
   * parameter 'list' is segment with segNum: we find this below.
   * parameter 'strListFun' is seg2LinestringWktStrList() or seg2PointWktStrList()
   *
   ***************************************************************************/

  //find the segment
  ELEM *elem;
  SEGMENT *seg;
  int num = 0;

  elem = DL_HEAD(geometry);
  while(num < segNum){

    seg = (SEGMENT *) DL_DATA(elem);

    num++;

    elem = DL_NEXT(elem);

  }

  // make file names
  char *lsTemplate = "_seg%d_%d_Linestring.csv";
  char *ptTemplate = "_seg%d_%d_Point.csv";
  char mySuffix[64] = {0};
  char filename[128] = {0};
  char filefull[PATH_MAX] = {0};
  int  result;

  /* write WKT file for LINESTRING **/
  snprintf(mySuffix, 64, lsTemplate, segNum, DL_SIZE(geometry));
  snprintf(filename, 128, "%s%s", fPrefix, mySuffix);
  if(SLASH_ENDING(toDir))
    snprintf(filefull, PATH_MAX, "%s%s", toDir, filename);
  else
    snprintf(filefull, PATH_MAX, "%s/%s", toDir, filename);

  result = writeWktStrList(filefull, seg, seg2LinestringWktStrList);
  if(result != ztSuccess){
    fprintf(stderr, "writeSegmentWktByNum(): Error failed writeWktStrList() function for LINESTRING.\n");
    return result;
  }

  /* convert WKT to shapefile **/
  result = wkt2Shapefile(filefull);
  if(result != ztSuccess){
    fprintf(stderr, "writeSegmentWktByNum(): Error failed wkt2Shapefile() function for LINESTRING.\n");
    return result;
  }

  /* write WKT file for POINT **/
  snprintf(mySuffix, 64, ptTemplate, segNum, DL_SIZE(geometry));
  snprintf(filename, 128, "%s%s", fPrefix, mySuffix);
  if(SLASH_ENDING(toDir))
    snprintf(filefull, PATH_MAX, "%s%s", toDir, filename);
  else
    snprintf(filefull, PATH_MAX, "%s/%s", toDir, filename);

  result = writeWktStrList(filefull, seg, seg2PointWktStrList);
  if(result != ztSuccess){
    fprintf(stderr, "writeSegmentWktByNum(): Error failed writeWktStrList() function for POINT.\n");
    return result;
  }

  /* convert WKT to shapefile **/
  if(isExecutableUsable(OGR2OGR_EXEC) == ztSuccess){
    result = wkt2Shapefile(filefull);
    if(result != ztSuccess){
      fprintf(stderr, "writeSegmentWktByNum(): Error failed wkt2Shapefile() function for POINT.\n");
      return result;
    }
  }

  return ztSuccess;

} /* END writeSegmentWktByNum() **/

/* wkt2Shapefile(): calls ogr2ogr program to convert Well Known Text file
 * infile to "ESRI Shapefile" file.
 *
 * TODO FIXME: infile is expected to have Well Known Text. TEST FOR THIS.
 *
 * infile is expected to have .csv extension and have correctly formated Well
 * Known Text.
 * Others : .dbf .prj .shx are still needed by QGIS. Do not remove.
 ***********************************************************************/
int wkt2Shapefile (char *infile){

  char    outfile[PATH_MAX] = {0};
  char    *program = OGR2OGR_EXEC;
  char    *myArgs[9];

  int    result;

  ASSERTARGS(infile);

  if(! isGoodExecutable(OGR2OGR_EXEC)){
    fprintf(stderr, "Wkt2Shapefile(): Did NOT find ogr2ogr executable in path: [%s]\n"
	    "Could not convert WKT file to shapefile.\n\n"
	    "The ogr2ogr program comes with GDAL package, you may want to install GDAL.\n"
	    "if you have ogr2ogr installed in different location, adjust defined path in 'fileio.h'\n",
	    OGR2OGR_EXEC);
    return ztFileNotFound;
  }

  /* we do not test input file except that it exist.
   * file name extension should be checked
   * should check text in file for WKT format
   ********************************************/

  result = isFileReadable(infile);
  if (result != ztSuccess){
    fprintf(stderr, "wkt2Shapefile(): Error input file <%s> is not readable file.\n", infile);
    return result;
  }

  /* output file is placed into the SAME SOURCE directory using source file
   * name and replacing the "csv" extension with "shp" extension.
   *
   * TODO : FIXME
   * client should be able to specify output destination directory and name.
   * one way might be a function in between! that is; set destination directory,
   * combine that with file name then call this function with the one combined
   * string.
   *
   * make output shape file name: use .shp extension in place of .csv
   * **********************************************************************/
  sprintf(outfile, "%s.shp", dropExtension(infile));

  /* to convert wkt file "inputfile.csv" to shape file in "outputfile.shp"
   * invoke ogr2ogr program with the following command line:
   *
   * ~$ ogr2ogr outputfile.shp inputfile.csv -f "ESRI Shapefile" -a_srs EPSG:4326
   *
   * our spawnWait() function takes an argument list, we fill the list below:
   ***************************************************************************/

  myArgs[0] = program;
  myArgs[1] = outfile;
  myArgs[2] = infile;
  myArgs[3] = "-f";
  myArgs[4] ="ESRI Shapefile";
  myArgs[5] = "-a_srs";
  myArgs[6] = "EPSG:4326";
  myArgs[7] = NULL;

  result = spawnWait (program, myArgs);
  if (result != ztSuccess){
    fprintf(stderr, "wkt2Shapefile(): Error returned from spawnWait() function call. Failed to convert to shape file!\n");
    return result;
  }
/*  else{
    fprintf(stdout, "wkt2Shapefile(): WKT file converted successfully; new shapefile:\n"
    		"  %s\n", outfile);
  }
**/
  /* Do not remove .dbf, .prj or .shx files **/

  return ztSuccess;

} /* END wkt2Shapefile() */

/* getHeadStrList():
 * get head from geometry string list,
 * to verify it is geometry result from overpass
 *
 ****************************************************/

int getHeadStrList(STRING_LIST *hdStrList, STRING_LIST *srcStrList){

  ASSERTARGS(hdStrList && srcStrList);

  if(DL_SIZE(hdStrList) != 0){

    fprintf(stderr, "getHeadStrList(): Error argument 'hdStrList' is not empty.\n");
    return ztListNotEmpty;
  }

  if(hdStrList->listType != STRING_LT){
    fprintf(stderr, "getHeadStrList(): Error argument 'hdStrList' is not STRLIG_LT.\n");
    return ztInvalidArg;
  }

  if(DL_SIZE(srcStrList) < 10){

    fprintf(stderr, "getHeadStrList(): Error argument 'srcStrList' size is too small.\n");
    return ztInvalidArg;
  }

  if(srcStrList->listType != STRING_LT){
    fprintf(stderr, "getHeadStrList(): Error argument 'srcStrList' is not STRLIG_LT.\n");
    return ztInvalidArg;
  }

  ELEM  *elem;
  char  *str;
  char  *strCpy;
  int   result;

  elem = DL_HEAD(srcStrList);

  for(int i = 0; i < 10; i++){
    str = (char *) DL_DATA(elem);
    strCpy = STRDUP(str);

    result = insertNextDL(hdStrList, DL_TAIL(hdStrList), (void *) strCpy);
    if(result != ztSuccess){
      fprintf(stderr, "getHeadStrList(): Error failed insertNextDL() function.\n");
      return result;
    }

    elem = DL_NEXT(elem);
  }

  return ztSuccess;

} /* END getHeadStrList() **/

/* the head WITH & WITHOUT area filter:
 * {
  "version": 0.6,
  "generator": "Overpass API 0.7.61.8 b1080abd",
  "osm3s": {
    "timestamp_osm_base": "2024-01-25T21:20:40Z",
    "timestamp_areas_base": "2024-01-25T21:20:40Z",
    "copyright": "The data included in this document is from www.openstreetmap.org. The data is made available under ODbL."
  },
  "elements": [

  {
  "version": 0.6,
  "generator": "Overpass API 0.7.61.8 b1080abd",
  "osm3s": {
    "timestamp_osm_base": "2024-01-21T21:21:06Z",
    "copyright": "The data included in this document is from www.openstreetmap.org. The data is made available under ODbL."
  },
  "elements": [

 *
 *
 */

int isGeometryStrList(STRING_LIST *srcStrList){

  int  result;

  ASSERTARGS(srcStrList);

  if(DL_SIZE(srcStrList) < 10){
    fprintf(stderr, "isGeometryStrList(): Error argument 'srcStrList' size is too small.\n");
    return FALSE;
  }

  if(srcStrList->listType != STRING_LT){
    fprintf(stderr, "isGeometryStrList(): Error argument 'srcStrList' is not STRLIG_LT.\n");
    return FALSE;
  }

  STRING_LIST  *myHdStrList;

  myHdStrList = initialStringList();
  if(! myHdStrList){
    fprintf(stderr, "isGeometryStrList(): Error failed initialStringList().\n");
    return FALSE;
  }

  result = getHeadStrList(myHdStrList, srcStrList);
  if(result != ztSuccess){
    fprintf(stderr, "isGeometryStrList(): Error failed getHeadStrList().\n");
    return FALSE;
  }

  char *hdStrings[6] = {"\"version\": 0.6,",
                        "\"generator\": \"Overpass API",
			"\"osm3s\": {",
			"\"timestamp_osm_base\":",
			"\"elements\": [",
			NULL};

  char  **mover;
  ELEM  *elem;

  for(mover = hdStrings; *mover; mover++){

    elem = findElemSubString(myHdStrList, *mover);
    if( ! elem)
      return FALSE;
  }

  zapStringList((void **) &myHdStrList);

  return TRUE;

} /* END isGeometryStrList() **/


