#!/usr/bin/bash

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Roland Olbricht et al.
#
# This file is part of Overpass_API.
#
# Overpass_API is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Overpass_API is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Overpass_API. If not, see <https://www.gnu.org/licenses/>.

# this script is a rewrite of overpass script "rules_loop.sh" with new name: op_area_update.sh

DB_DIR=/path/to/overpass/database
EXEC_DIR=/usr/local/bin
RULES_DIR=/usr/local/rules
LOG_FILE=$DB_DIR/logs/op_area_update.log


while [[ true ]]; do
{
  echo "`date '+%F %T'`: update started" >>$LOG_FILE
  #  ./osm3s_query --progress --rules <$DB_DIR/rules/areas.osm3s
  ionice -c 2 -n 7 nice -n 19 $EXEC_DIR/osm3s_query --progress --rules <$RULES_DIR/areas.osm3s
  echo "`date '+%F %T'`: update finished" >>$LOG_FILE
  sleep 3
}; done
