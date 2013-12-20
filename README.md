Variations-Backup
=================

A comphrehensive backup solution for the Variations Digital Music Library System ( http://variations.sourceforge.net ) built on the Amazon Glacier service.

The solution is implemented as a set of bash scripts that have been tested on RHEL v6 using the root account. There are 3 primary scripts as follows:

1. system_incremental.sh - A daily system incremental backup which includes files that have been updated since the last successful monthly backup, with the exception of the Variations media files. It creates a tar file and uploads a single Glacier repository each time it runs.
2. system_full.sh - A monthly full backup that includes all files with the exception of the Variations media files. It creates a tar file and uploads a single Glacier repository each time it runs.
3. backup_content.sh - A daily incremental media content backup which includes all Variations media files that have been updated in the last 24 hours. It create a separate Glacier repository for each media file every time it runs.

The scripts notify selected individuals via email in the event of failures. They generate logs to the root/logs directory that include a general job log and a detailed Amazon glacier log that can be used for troubleshooting purposes and contains detailed statistics and archive ids.

Specific configuration instructions for each script are located in the script headers.


DEPENDENCIES: These scripts use the Java Glacier uploader written by Carsten MoriTanosuke, which should be installed and tested before installing these scripts. It is located here: https://github.com/MoriTanosuke/glacieruploader


