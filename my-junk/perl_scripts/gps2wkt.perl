#!/usr/bin/perl

# Reads <STDIN> to format result from op query with GPS point in Well Known Text.
# Use in a pipe! to write files provide file prefix to script on invocation! Script appends
# ".csv" to file prefix for WKT and ".shp" for shapefile.
# Example input: (removed tab AND added spaces between longitude & latitude)
# Note first line is the header

# @lon    @lat    @count
# -111.8911841  33.4336286
# -111.8908560  33.4335505
# -111.8908258  33.4343930
# -111.8911520  33.4358885
# -111.8908143  33.4359186
# -111.8907748  33.4393631
# -111.8911690  33.4349055
# -111.8911136  33.4393315
# -111.8908246  33.4344738
#        9

use strict;
use warnings;

my $prefix = $ARGV[0];
my @wkt_lines;

# Ignore the first line
my $header = <STDIN>;

while (my $line = <STDIN>) {
    chomp($line);
    next if $line =~ /^\s*$/; # Skip empty lines

    my @gps = split /\s+/, $line;

    last if $gps[0] eq ""; # Exit loop if the line starts with empty space

    my $lat = $gps[0];
    my $lng = $gps[1];
    my $wkt = "\"POINT ($lat $lng)\"";

    push @wkt_lines, $wkt;
}

print "wkt\;\n";
# Write formatted WKT to STDOUT
foreach my $wkt (@wkt_lines) {
    print "$wkt\n";
}

# Write formatted WKT to file if prefix provided
if (defined $prefix) {

    my $userHome = $ENV{'HOME'};
    my $output_directory =  $userHome . "/op_scripts/";
    unless (-e $output_directory and -d $output_directory) {
        mkdir $output_directory or die "Cannot create directory $output_directory: $!";
    }

    my $sub_directory = $output_directory . $prefix . "/";
    unless (-e $sub_directory and -d $sub_directory) {
        mkdir $sub_directory or die "Cannot create directory $sub_directory: $!";
    }

    my $wktFile = $sub_directory . $prefix . "_Point.csv";
    open(my $fh_output, '>', $wktFile) or die "Cannot open $wktFile: $!";

    print $fh_output "wkt\;\n";

    foreach my $wkt (@wkt_lines) {
        print $fh_output "$wkt\n";
    }
    close($fh_output);

    print "$0: Wrote POINT WKT to file $wktFile\n";

 # Check if ogr2ogr is available
    my $ogr2ogr_executable = "/usr/bin/ogr2ogr";

   if (-e $ogr2ogr_executable) {

      my $shapeFile =  $sub_directory . $prefix . "_Point.shp";

      # ogr2ogr outputfile.shp inputfile.csv -f "ESRI Shapefile" -a_srs EPSG:4326
      system "$ogr2ogr_executable $shapeFile $wktFile -f  \"ESRI Shapefile\" -a_srs EPSG:4326";

      print "$0: Wrote POINT ESRI shapefile to file $shapeFile\n\n";
    }

}
