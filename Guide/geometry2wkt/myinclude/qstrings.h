/*
 * qstrings.h
 *
 *  Created on: Mar 31, 2021
 *      Author: wael
 */

#ifndef QSTRINGS_H_
#define QSTRINGS_H_

#ifndef PRIMITIVES_H_
#include "primitives.h"
#endif


/* LINE_SIZE buffer size **/
#define LINE_SIZE 1024

#define GEOM_TAG "\"geometry\": ["
#define GEOM_TAG_END "]"


/* functions prototypes **/

int csvLine2Gps (GPS *destGps, const char *line);

int csvStrList2GpsList(GPS_LIST *gpsList, STRING_LIST *csvList);

int jsonLine2Gps(GPS *destGps, const char *src);

int parseSegment (SEGMENT *seg, ELEM *startElem);

int parseGeometry (GEOMETRY *geometry, STRING_LIST *stringList);

int parseBbox(BBOX *bbox, const char *str);

int isDecimalStr(const char *token);

int numChrStr(char letter, const char *str);



#endif /* OPSTRING_H_ */
