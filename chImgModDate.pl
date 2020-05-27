#!/usr/bin/perl -w
#
# Script updates modification date of an image file to the
# creation date to original filename
#
use strict;

my ($usage) = "Usage: $0 [-d] imagefile | [imagefiles]\r
    -d    Perform dry run (no file updates)\n";
@ARGV > 0 or die $usage;

use Image::ExifTool 'ImageInfo';
use Time::Local;

my $exifTool = new Image::ExifTool;
my @filelist = `ls`;
my $dry = 0;                                      # dry run

############################################################
# changes modification date of passed file to creation date
# passed in 2nd argument
#
sub changeModificationDate {
  my $file = shift;
  my $crdate = shift;

  # Our data comes in the form "YEAR:MON:DAY HOUR:MIN:SEC".
  # utime() wants data in the exact opposite order, so we reverse().
  my @date = reverse(split(/[: ]/, $crdate));

  # Note that the month numbers must be shifted: Jan = 0, Feb = 1
  --$date[4];

  # Convert to epoch time format
  my $time = timelocal(@date);
#  print "\@date = @date\n";
## Test part to check how to convert date/time to epoch

#  print "CreateDate = ", $crdate, "\n";
#  $crdate =~ /(\d+):(\d+):(\d+) (\d+):(\d+):(\d+)/;
#  my $year = $1;
#  my $month = $2-1;
#  my $day = $3;
#  my $hour = $4;
#  my $min = $5;
#  my $sec = $6;
#  print "Date regexp result = ", $year, ," ", $month, " ", $day, "\n" ;
#  print "Time regexp result = ", $hour, ," ", $min, " ", $sec, "\n" ;
#  my $time = timelocal($sec,$min,$hour,$day,$month,$year);
#  my $time = timegm($sec,$min,$hour,$day,$month,$year);
#  print "timelocal = ", $time, "\n";
  if ($dry) {
    print "Dryrun: Updated: $file modification date to $crdate \n";
  } elsif (utime ($time, $time, $file))  {
    print "Updated: $file modification date to $crdate \n";
  } else {
    print "Could not update modification date of $file\n";
  }
}
################################################################
# Changes modification date of the passed file to creation date,
# if it is an image file
# returns true if file was modified else false
sub changeImageFileDate {
  my $file = shift;
  my $info = $exifTool->ImageInfo($file);

  if ( defined $$info{Error} ) {                  # if error in metadata
    print " Error file $file: $$info{Error}\n";
    return "";
  } elsif ( defined  $$info{ImageSize}) {         # check if imagefile
    print " $$info{FileType} - imagetype\n";
    if ( defined  $$info{CreateDate}) {         # check if creation date
      changeModificationDate($file, $$info{CreateDate});
    } else {
      print "$$info{FileName} does not have date metadata! Skipping ...\n";
      return 0;
    }
    return 1;
  } else {
    print "$$info{FileName} is not an image file! Skipping ...\n";
  }
return 0;
}

# ---- Object-oriented usage ----

#foreach (sort keys %$info) {
#  print "$_ => $$info{$_}\n";
#}
#print "Error\n" if defined $$info{Error};
#print "Image : $$info{FileType}\n" if defined $$info{FileType};

my $fc = 0;                                       # filescounter
my $dc = 0;                                       # dir counter
my $ec = 0;                                       # error counter
my $dt ="";                                       # file date
my $newfile = "";

if (@ARGV > 0 ) {
  if ($ARGV[0] eq "-d") {
      $dry = 1;
      shift @ARGV;
  }

  foreach my $ar (@ARGV) {                        # go through each argument
    if ( -f $ar ) {
      if (changeImageFileDate ($ar)) {
        $fc ++;                                     # count
      } else {
        $ec ++;
      }
    } elsif ( -d $ar ) {                          # if dir...
      my @fls = `ls`;
      chomp @fls;
      print "$ar is a directory, skipping! \n";
      $dc++;
#      foreach my $fl ( do_dir($ar) ) {            # list contents
#	$fc += extractJPGsIfZip($fl) if -f $fl;   # try to extract file
#	$dc += 1 if -d $fl;
    }
  }
} else {             # Not used yet, script req. > 0 arguments

  my @fls = `ls`;
  chomp @fls;
  foreach (@fls) {
    if ( -f $_ ) {                                  # if file
      if (changeImageFileDate ($_)) {
        $fc ++;                                     # count
      } else {
        $ec ++;
      }
    } elsif ( -d $_ ) {                          # if dir...
      print "$_ is a directory, skipping! \n";
      $dc++;
    }
  }
}
print "$fc image files found\n";
print "$ec unsuccessful modification attempts\n";
print "$dc directories found\n";
