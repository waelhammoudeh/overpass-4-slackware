This is the "README-WEB.md" file for Overpass Guide.

Web support setup for overpass adds network and internet access to your database;
your database can be queried from remote machines on local network or even through
the internet.

I provide simple setup for the Apache Web Server that enables you to query your overpass database through the network.
The overpass "dispatcher" daemon must be running for the Web interface to work.

**Setup Apatche Web Server:**

The Apache Web Server package is included in Slackware64 and installed with Slackware64
full installation, install it if you did not do full Slackware64 installation. This package includes
the best software documentation; you can find the documentation on your system at this path:
```
 /var/www/htdocs/manual/index.html
```

There are a lot of guides, howtos and articles available on the web to setup the
Apache Web Server on a Slackware machine. One such old document is here:
```
 https://docs.slackware.com/howtos:network_services:setup_apache
```

We are going to modify the main configuration file for Apache "/etc/httpd/httpd.conf". As you make
your changes to this file, it helps to know that you can check your edited syntax - as we all
make mistakes. Use the following command to check your configuration file syntax:
```
 # apachectl -t
```

The example configuration file "httpd.conf.example" included with this Guide will work as is providing you followed
my File System structure in this Guide. The "httpd.conf" is in sections, changes you may have
to make are only in the "Virtual hosts SECTION".  Here is that whole section:

```
    # Virtual hosts SECTION
    <VirtualHost *:80>

        Options Indexes SymLinksIfOwnerMatch
        ExtFilterDefine gzip mode=output cmd=/bin/gzip

        UseCanonicalName Off
        ServerAdmin root@localhost

        ServerName http://localhost:80
        ServerAlias myoverpass.local myoverpass

        DocumentRoot "/usr/local/html/overpass"
        ScriptAlias /api/ /usr/local/cgi-bin/

        LogLevel debug
        ErrorLog "/var/log/httpd/localhost_error_log"
        CustomLog "/var/log/httpd/localhost_access_log" common
        ScriptLog "/var/log/httpd/localhost_cgi_log"

    <Directory "/usr/local/cgi-bin/">

        Options Indexes FollowSymLinks
        Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
        AllowOverride None
        Order allow,deny
        Allow from all

        <RequireAll>
            Require all granted
        </RequireAll>

    </Directory>

    <Directory "/usr/local/html/overpass">
        <RequireAll>
            Require all granted
        </RequireAll>
    </Directory>

    </VirtualHost>
```

The server name is included in every "http" request, I simply call it "localhost" and also
give it two nick names of "myoverpass.local" and "myoverpass".

```
    ServerName http://localhost:80
    ServerAlias myoverpass.local myoverpass
```

The DocumentRoot: The directory out of which you will serve your documents.
The path used here is where my Slackware package SlackBuild script installs "html" documentation.
```
DocumentRoot "/usr/local/html/overpass"
```

The ScriptAlias line is where the Apache Web Server will look for executables, do NOT change this line.
```
ScriptAlias /api/ /usr/local/cgi-bin/
```

Apache Web Server write errors to log files; you may want to change the default settings I have.

To start the Apache Web Server in Slackware, we use "/etc/rc.d/rc.httpd" control script as follows:
```
# /etc/rc.d/rc.httpd start
```
and to stop it:
```
# /etc/rc.d/rc.httpd stop
```

The # mark above is for "root" prompt; all this is done as "root".

To test your setup and after you successfully started Apache Web Server; run this command:
```
$ curl http://localhost/api/timestamp
```
your output should look something like:
```
2023-08-03
```
this is the contents of "osm_base_version" file in your database. For us this is the last date in the last applied "change file" by our "op_update_db.sh" script.
This confirms that the "dispatcher" daemon is running and healthy, in addition it confirms that our update mechanism is working.


To make Apache Web Server start on boot, we set the control script to be executable:
```
# chmod 755 /etc/rc.d/rc.httpd
```

To further test your setup, send the "test-area.op" example query from the Guide to your overpass
server using curl as follows ($ is your prompt):
```
 $ curl -G http://localhost/api/interpreter --data-urlencode data='[out:csv(name;false)];area[admin_level=8];out;'
```
you should get a list of cities and towns in your database.

If you have your local or home network setup; you can send the above query to your overpass machine
from a different computer. If your overpass machine is accessible from the internet, you will be able to send it
queries from anywhere.

Network setup is beyond this Guide. But as a hint for local or home network, consider static IP numbers for your
machines and look into the "/etc/hosts" file.

Wael Hammoudeh

August 3/2023

Note: enable modules in main apache configure file "/etc/httpd/httpd.conf":
```
LoadModule ext_filter_module lib64/httpd/modules/mod_ext_filter.so

<IfModule !mpm_prefork_module>
	LoadModule cgid_module lib64/httpd/modules/mod_cgid.so
</IfModule>
<IfModule mpm_prefork_module>
	LoadModule cgi_module lib64/httpd/modules/mod_cgi.so
</IfModule>
```

