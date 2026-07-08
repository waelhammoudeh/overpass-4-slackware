README.setup — Overpass SlackBuild

This file explains how to set up the Overpass API database and supporting scripts.
The following included helper scripts are discussed and explained:

```
op_initial_db.sh – initializes the database from a region OSM file.

op_ctl.sh – controls the dispatcher daemon (start/stop/status).

rc.dispatcher – integration script for Slackware system startup/shutdown.
```
Also the included Apache server configuration file is discussed here:
```
httpd-overpass.conf
```

At this stage, you should have installed required software mentioned in the introduction
[README.md](overpass-4-slackware/README.md) file and obtained your region OSM data file
from [Geofabrik.de](https://www.geofabrik.de/data/download.html)or somewhere else.


1. Create Overpass User Directories

Everything related to overpass will be run by the unprivileged overpass user.
If you have not already created the overpass home directory, run these commands as root:

```
  ~# mkdir /var/lib/overpass
  ~# chown overpass:overpass /var/lib/overpass
```
Now overpass user is situated nicely in its home.

Switch to the overpass user:

```
  ~# su overpass
```

Your shell prompt should now show $ instead of #. Move to overpass home directory:
```
  ~$ cd ~
```

Create the file system structure mentioned in the introduction:

```
  ~$ mkdir -p {database,getdiff,logs,sources,region/{extract,replication}}
```

2. Initialize the database and build the area objects

Copy your downloaded region OSM data file to `sources/` directory.

Use the provided "op_initial_db.sh" to initialize your database, its usage:
```
 op_initial_db <input.osm.pbf> <db_dir> [flush_size]
where:
 input.osm.pbf: regional OSM extract data file in any osmium supported format.
 db_dir: is your database directory, must exist and empty.
 flush_size: (optional integer) Chunk size for update_database [default: 4].
```

Run the initialization script with your region OSM data file (downloaded from
Geofabrik) assuming you placed it in your "sources" directory with nohup command
and run in the background using "&":

```
  ~$ nohup op_initial_db.sh sources/region.osm.pbf database/ 8 > nohup.out &
```

This command redirects script output to "nohup.out" file which you can view with:
```
  ~$ tail -f nohup.out.
```
By default the script uses flush_size with value 4. Here I used 8. The flush size
is how much data is read from the data file by "update_database" program. This
depends on the RAM size, larger values will speedup the process, try lower value
such as 1 if you have issues with low memory. Values I have used are below:
8 GB ram ---> 4
16 GB ram ---> 16
128 GB ram ---> 128

This step is time-consuming: depending on your CPU and region size, it may take
minutes up to two hours. You can watch the database/ directory fill-up with files
as the process runs, and view "nohup.out" file with `tail nohup.out`.

Trying to reduce initialization time, I have placed my region file for Arizona -
size 310 MB - in /tmp directory which is mounted as tmpfs (on memory) and using
flush size of 128, this reduced wall clock time from 29 minutes to 23 minutes.
You may see better time improvement with larger input files, so YMMV.

Recent extract files from Geofabrik.de have the following header file information
set: osmosis_replication_base_url, osmosis_replication_sequence_number and
osmosis_replication_timestamp among other settings.

This script writes the value for "replication_sequence_number" in "replicate_id"
file in the database. This is an id for the last change file included in your
extract data file at Geofabrik.de, this number is used when we update database.

The timestamp in the header (header.option.osmosis_replication_timestamp) is used
as the "osm_base_version" number by this script. If that is not available then
last data timestamp is used instead (data.timestamp.last) is used.

You can view all your OSM data file information using osmium with:
```
  ~$ osmium fileinfo --extended file_name.osm.pbf
```

This script copies the package "template" and "rules" directories to database/.

3. Test a Query (Manual Mode)

Once initialization is complete, you (acctually any user in the system) can query the database
directly (assuming my example `test-first.op` is in current directory):
```
  ~$ osm3s_query --db-dir=/var/lib/overpass/database < test-first.op | sort -ub
```

Find the provided "test-first.op" overpass script in the guide directory under the
package documentation: /usr/local/doc/overpass-{VERSION}/guide/
This script uses a bounding box values valid for Arizona. Replace it with values
valid for your region. (copy the example to your current directory and edit BBOX).

`osm3s_query` is part of Overpass API. Normally it runs interactively, reading
queries line by line until you press Ctrl+D. With shell redirection, you can
instead run queries in batch mode.

4. Start the Dispatcher Daemon

The `dispatcher` forwards queries to the database and must be running for normal
usage.

Start it using the control script as the overpass user:
```
  ~$ op_ctl.sh start
```

This launches both base and area dispatchers. You can now run the example query
without specifying a database directory:
```
$ osm3s_query < area-test.op | sort -ub
```

This will output a sorted list of cities and towns in your region database. Provide
full path to "area-test.op" script or move to its directory:
 $ cd /usr/local/doc/overpass-{VERSION}/guide/

5. Enable Dispatcher on System Startup

To manage `dispatcher` automatically on system boot/shutdown, set rc.dispatcher to
be executable (as root user):
```
  ~# chmod +x /etc/rc.d/rc.dispatcher
```
Then add the following lines to your /etc/rc.d/rc.local:
```
# Start Overpass dispatcher
if [ -x /etc/rc.d/rc.dispatcher ]; then
    /etc/rc.d/rc.dispatcher start
fi
```

And add this to /etc/rc.d/rc.local_shutdown (create it if it does not exist):
```
# Stop Overpass dispatcher
if [ -x /etc/rc.d/rc.dispatcher ]; then
    /etc/rc.d/rc.dispatcher stop
fi
```

The "rc.dispatcher" is a wraper script to "op_ctl.sh" which is used by "overpass"
user to start, stop or get status of the dispatcher daemon.

6. Apache Configuration (Optional)

With the dispatcher running, you can expose Overpass through Apache HTTPD.

Network configuration is beyond this README subject, simple home network with
static IPs is assumed.

a) Edit your `/etc/hosts` files:

On all client machines in your local network, add an entry for the Overpass server:
Replace IP number "192.168.1.2" with your machine actual static IP.

127.0.0.1       localhost
::1             localhost
192.168.1.2     myoverpass.local myoverpass


This allows you to access the server at http://myoverpass.

b) Edit main Apache file: `/etc/httpd/httpd.conf`

Three things we change in this file:

1st) Change Listen setting:
```
# Listen 80
Listen 127.0.0.1:80
Listen 192.168.1.2:80
```
Note again use your own static IP above

2nd) Enable CGI execution:

uncomment commented lines in the block listed below:
```
<IfModule !mpm_prefork_module>
    LoadModule cgid_module lib64/httpd/modules/mod_cgid.so
</IfModule>
<IfModule mpm_prefork_module>
    LoadModule cgi_module lib64/httpd/modules/mod_cgi.so
</IfModule>
```

3rd) Include the provided "httpd-overpass.conf" file:

At the bottom of the file, include the Overpass configuration:
```
Include /etc/httpd/extra/httpd-overpass.conf
```

We want ALL `overpass` log files managed by `overpass`, to prevent Apache from
creating our log files, "overpass" user creates those files, 'logs/' directory
was created above:
```
  ~$ touch /var/lib/overpass/logs/op_httpd_error.log
  ~$ touch /var/lib/overpass/logs/op_httpd_access.log
```

Log files will be recreated on *logrotation* with the appropriate ownership.
See managing log files in README.update.md file.

Start or restart Apache:
```
  ~# apachectl start

Or:

  ~# apachectl restart
```

7. Test via HTTP

Make sure your "dispatcher" is running; if not start it:
```
  ~$ op_ctl status
```
if not running to start do:
```
  ~$ op_ctl start
```

Send a query using curl:
```
  ~$ curl -G http://myoverpass/api/interpreter --data-urlencode data='[out:csv(name;false)];area[admin_level=8];out;'
```

You should see a list of cities and towns in your database.

The above command should work from any machine on your local network executed by any user.

For further testing, in your browser destination bar enter:
```
  http://myoverpass/api/status
```
or:
```
  http://myoverpass/api/timestamp
```

8. Logging is written to two files in database directory; `database.log` and
`transactions.log`, the later is more insightful for you.

Next Steps are for updating database and automate strategy explained in README.update.md
file in the guide.

Wael Hammoudeh

June 10/2026
