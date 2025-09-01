#!/usr/bin/perl

# script: bbox2template.perl
#
# This Perl script reads a bounding box input from STDIN in the format:
# minimum latitude,minimum longitude,maximum latitude,maximum longitude
# It generates Overpass query settings and Well Known Text (WKT) representations
# for its input bounding box values.

# Usage:
# Run the script and provide the bounding box coordinates as instructed.
# Optionally, provide a 'prefix' argument after the script name to generate
# op query template, WKT files and shapefile (requires ogr2ogr).
#
# Dirty little script - "Dirty as no error checking "WHATSOEVER" use at your own risk.
#
#################################################################

print "Please provide bounding box decimal values in the following format:\n";
print "minimum latitude,minimum longitude,maximum latitude,maximum longitude\n\n";
print "Hint: paste copied bounding box bounds from JSOM here\n\n";

my $line = <STDIN>;
chomp($line);

# Construct Overpass and WKT representations
my ($minLat, $minLon, $maxLat, $maxLon) = split /,/, $line;
my $bboxSetting = "[bbox: $line]";
my $bboxWkt = "\"POLYGON(($minLon $minLat, $minLon $maxLat, $maxLon $maxLat, $maxLon $minLat, $minLon $minLat))\"";

print "Overpass query bounding box setting:\n $bboxSetting\n\n";

print "Well Known Text for bounding box as POLYGON:\n  $bboxWkt\n\n";

# Check if a prefix is provided as an argument
# Yes ARGV[0] is first argument in perl scripts; $0 has script name
my $prefix = $ARGV[0];

if (not defined $prefix) {
    print "No 'prefix' argument provided, not generating any files.\n";
    print "To generate files for op query template and bbox files";
    print "please provide prefix for filename after script as:.\n";
    print "$0 prefix\n\n";
}
else {

    # Define the directory path for saving Overpass scripts
    my $userHome = $ENV{'HOME'};
    my $output_directory =  $userHome . "/op_scripts/";
    unless (-e $output_directory and -d $output_directory) {
        mkdir $output_directory or die "Cannot create directory $output_directory: $!";
    }

  my $sub_directory = $output_directory . $prefix . "/";
    unless (-e $sub_directory and -d $sub_directory) {
        mkdir $sub_directory or die "Cannot create directory $sub_directory: $!";
    }

    # Create the full path for the Overpass script
    my $templateFile = $sub_directory . $prefix . ".op";

    open(my $templateHandle, '>', $templateFile) or die "Could not create template file '$templateFile': $!"; #$i is perror() in c

    # uncomment lines below to get 2 templates for the price of one  -:)
    print $templateHandle "[out:csv(::lon, ::lat,::count)]\n";
 #   print $templateHandle "\/\/[out:json]\n";
    print $templateHandle "[bbox: $line];\n";
    print $templateHandle "\n\n";
    print $templateHandle "out; out count;\n";
 #   print $templateHandle "\/\/out geom;\n";

    close $templateHandle;

   # Create bbox wkt file, append "_Bbox.csv" to file prefix
    my $bboxWktFile = $sub_directory . $prefix . "_Bbox.csv";
    open(my $bboxWktHandle, '>', $bboxWktFile) or die "Could not create bbox file '$bboxWktFile': $!";

    print $bboxWktHandle "wkt;\n$bboxWkt\n";

    close $bboxWktHandle;

     print "Wrote the files below:\n $templateFile\n $bboxWktFile\n\n";

    # Check if ogr2ogr is available
    my $ogr2ogr_executable = "/usr/bin/ogr2ogr";

    if (-e $ogr2ogr_executable) {

      # Create bbox shapefile file, append "_Bbox.shp" to file prefix
      my $shapeFile =  $sub_directory . $prefix . "_Bbox.shp";

      # ogr2ogr command:
      # ogr2ogr outputfile.shp inputfile.csv -f "ESRI Shapefile" -a_srs EPSG:4326
      system "$ogr2ogr_executable $shapeFile $bboxWktFile -f  \"ESRI Shapefile\" -a_srs EPSG:4326";

      print "Wrote shapefile to: $shapeFile\n\n"
    }
    else {
        print "Program ogr2ogr executable was not found. Could not make shapefile.\n";
        print "Please install GDAL/OGR or provide the correct path to ogr2ogr.\n\n";
    }

}
