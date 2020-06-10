# misc-scripts

This repo contains some miscellaneous scripts

## Perl scripts:

`renImg2CreDate.pl - Rename image file with creation date as prefix:`

    Usage: ./renImg2CreDate.pl [-i | -d] imagefile | [imagefiles]
        -i    Display meta data
        -d    Perform dry run (no file updates)

This script reads image files meta data information and renames the file with the
creation date appended to the file name. The script also updates the modification
time stamp of the file.
The -d option stands for dry-run and executes without making any filechanges.
The -i option stands for information printout and displays available meta data of
files.

Requires Image-ExifTool (https://exiftool.org/)


`chImgModDate.pl - Change image file modification date to creation date`

    Usage: ./chImgModDate.pl [-d] imagefile | [imagefiles]
        -d    Perform dry run (no file updates)

This script reads the image files meta data information and updates the
modification time stamp of the file to the image creation date.

This script requires Image-ExifTool (https://exiftool.org/)
