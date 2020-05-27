#!/usr/bin/perl -w
#
# Script renames image files and appends creation date to original filename
#
use strict;

my ($usage) = "Usage: $0 [-i | -d] imagefile | [imagefiles]\r
    -i    Display meta data\r
    -d    Perform dry run (no file updates)\n";
@ARGV > 0 or die $usage;

use Image::ExifTool 'ImageInfo';
use Time::Local;
use File::Basename;

my $exifTool = new Image::ExifTool;
my @filelist = `ls`;
my $dry = 0;                                      # dry run
my $only_info = 0;                                # only print meta data

##############################################################
# return file creation date (to be used if meta data is missing)
sub fileCreationDate {
  my $file = shift;
  my @sb = stat $file;                            # get file info
  #print "stat =", (localtime $sb[9])[5], "\n";
  my $date = ((localtime $sb[9])[5]+1900).":";    # start with year
  if ( (localtime $sb[9])[4] > 8 ) {              # check # of digits
    $date .= ((localtime $sb[9])[4]+1).":";       # add month
  } else {
    $date .= "0".((localtime $sb[9])[4]+1).":";   # with leading 0
  }
  if ( (localtime $sb[9])[3] >= 10 ) {            # check # digits
    $date .= (localtime $sb[9])[3];
  } else {
    $date .= "0".(localtime $sb[9])[3];
  }
#  (scalar localtime $sb[9]) =~ /.*(\d\d:\d\d:\d\d)/;
#  print "fileCreationDate: $date\n";
#  $date .= $1;
#  print "fileCreationDate: $date\n";
  return $date;
}
##############################################################
# subroutine that returns the creation date of an image file
# passed arg. should be filename
# returns the empty string if no image file

sub creationDate {
  my $file = shift;
  my $info = $exifTool->ImageInfo($file);
  if ( defined $$info{Error} ) {                  # if error in metadata
    print " Error file $file: $$info{Error}\n";
    return "";
  } elsif ( defined  $$info{ImageSize}) {
    if ( defined $$info{FileType} ) {
      print " $$info{FileType} - imagetype\n";
      if ( defined $$info{CreateDate}) {
          $$info{CreateDate} =~ /(\d+:\d+:\d+)/;
          print "Date: $1\n";
        return $1;
      }
      return fileCreationDate($file);
    }
  } else {
    print "$$info{FileName} is not an image file! Skipping ...\n";
  }
  return "";
}

############################################################
# print all meta data for an image file
sub printImageInfo {
  my $file = shift;
  my $info = $exifTool->ImageInfo($file);
  my $group = '';
  my $tag;
  foreach $tag ($exifTool->GetFoundTags('Group0')) {
    if ($group ne $exifTool->GetGroup($tag)) {
      $group = $exifTool->GetGroup($tag);
      print "---- $group ----\n";
    }
    my $val = $info->{$tag};
    if (ref $val eq 'SCALAR') {
      if ($$val =~ /^Binary data/) {
        $val = "($$val)";
      } else {
        my $len = length($$val);
        $val = "(Binary data $len bytes)";
      }
    }
    printf("%-15s : %-32s : %s\n", $tag, $exifTool->GetDescription($tag), $val);
  }
  print "###################################################################",
      "##########\n";
}
############################################################
# changes modification date of file
#
sub changeModificationDate {
  my $file = shift;
  my $info = $exifTool->ImageInfo($file);
## Test part to check how to convert date/time to epoch
  my $crdate = $$info{CreateDate};

  # Our data comes in the form "YEAR:MON:DAY HOUR:MIN:SEC".
  # utime() wants data in the exact opposite order, so we reverse().
  my @date = reverse(split(/[: ]/, $crdate));

  # Note that the month numbers must be shifted: Jan = 0, Feb = 1
  --$date[4];

  # Convert to epoch time format
  my $time = timelocal(@date);
#  print "CreateDate = ", $crdate, "\n";
#  $crdate =~ /(\d+):(\d+):(\d+) (\d+):(\d+):(\d+)/;
#  my $year = $1;
#  my $month = $2;
#  my $day = $3;
#  my $hour = $4;
#  my $min = $5;
#  my $sec = $6;
#  print "Date regexp result = ", $year, ," ", $month, " ", $day, "\n" ;
#  print "Time regexp result = ", $hour, ," ", $min, " ", $sec, "\n" ;
#  my $time = timelocal($sec,$min,$hour,$day,$month,$year);
  #  print "timelocal = ", $time, "\n";
  if ($dry) {
    print "Dryrun: Updated: $file modification date to $crdate \n";
  } elsif (utime ($time, $time, $file))  {
    print "Updated: $file modification date to $crdate \n";
  } else {
    print "Could not update modification date of $file\n";
  }
}
############################################################
# renames the passed file with date, if it an image file
# returns true if file was renamed
sub renameImageFile {
  my $file = shift;
  my $dt ="";                                       # file date
  my $newfile = "";
  my($filename, $path, $suffix) = fileparse($file);

  if ($only_info) {
      printImageInfo($file);
      return 1;
  }
  if ( $dt = creationDate($file)) {
#      printImageInfo($file);
#      print "$file Date : $dt ";                    # print date info
    $dt =~ s/:/-/g;                             # change : to _ as separator
#     print "New $dt\n";
    $newfile = $path."P".$dt."_".$filename.$suffix;
    print "New file $newfile\n";

    if ( ($file =~ /P(\d{4}-\d{2}-\d{2})/) && ($1 eq $dt) ) {
#      print "Matched : $1, $file\n";
      print "$file is allready appended with date info!\n";
      changeModificationDate($file);
    } elsif ($dry == 1)  {
      print "Dryrun: Renamed $file to $newfile\n";
      return 1;
## Proper rename
    } elsif ( rename $file, $newfile ) {
      print "Renamed $file to $newfile\n";
      changeModificationDate($newfile);
      return 1;
    } else {
      print "Rename of $file unsuccessful!\n";
    }
  } else {
    print "Could not get date for $file!\n";
  }
return 0;
}
# ---- Simple procedural usage ----

# Get hash of meta information tag names/values from an image
# my $info = $exifTool->ImageInfo('IMG_0174.JPG');
# my $info = $exifTool->ImageInfo('DSC00006.JPG');
# my $filename = 'DSC00006.txt';
#my $filename = 'erland.gif';
#my $filename = 'test1.pl';
#my $filename = 'myzip.zip';


#my $info = $exifTool->ImageInfo($filename);
#my $type = Image::ExifTool::GetFileType($filename);
#print "$info \n";
#print '$info not initialised\n' if ! $info;
#print "$filename is binary\n" if -B $filename;


#if ($type) {
#    print $type, "\n";
#} else {
#    print "No image file!\n";
#    print "Compression : ", $info->{Compression}, "\n";
#    print "Error : ", $info->{Error}, "\n";
#}

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
  if ($ARGV[0] eq "-i") {
      $only_info = 1;
      shift @ARGV;
  }

  foreach my $ar (@ARGV) {                        # go through each argument
    if ( -f $ar ) {
      if (renameImageFile ($ar)) {
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
} else {

  my @fls = `ls`;
  chomp @fls;
  foreach (@fls) {
    if ( -f $_ ) {                                  # if file
      if (renameImageFile ($_)) {
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
print "$ec unsuccessful rename attempts\n";
print "$dc directories found\n";
