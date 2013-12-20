#!/bin/bash
# 
# Name: system_incremental.sh 
# Description: Daily cumulative incremental system backup
# Author: Steve Cox
# 11/1/2012
# 
#  INSTRUCTIONS
#
#  1. Replace all "xxx@yyy.edu" with email address of people to receive notifications of failure
#
#  2. Replace "zzz@yyy.edu" with email address of person to receive the daily disk use report
#


backupdate=`date "+%y%m%d"`
starttime=`date "+%H:%M:%S"`
starttimeepoch=`date "+%s"`


find / -newer /root/scripts/lastmonthly -type f -print > /root/scripts/filelist
tar -cvzf /backup/variations_backup_$(date +%d).tar.gz --exclude '/home/dmlserv/content/*' --exclude '/backup/*' --exclude-backups --exclude-caches --files-from /root/scripts/filelist

java -jar /root/scripts/uploader-0.0.5-jar-with-dependencies.jar --credentials /root/scripts/aws.properties --endpoint https://glacier.us-east-1.amazonaws.com/ --vault variations --upload /backup/variations_backup_$(date +%d).tar.gz &> /root/logs/glacierlog.incr
currenttime=`date "+%y%m%d:%H:%M:%S "`
awk -v ct=$currenttime '{ print ct " " $0 }' /root/logs/glacierlog.incr >> /root/logs/glacierlog

glacier_success=`tail -1 /root/logs/glacierlog.incr | grep "Uploaded archive"`


if [ "$glacier_success" ]
then
        # Save last monthly backup and log
        rm -f /backup/last_daily/*.*
        mv /backup/variations_backup_$(date +%d).tar.gz /backup/last_daily/variations_backup_$(date +%d).tar.gz


	endtime=`date "+%H:%M:%S"`
	endtimeepoch=`date "+%s"`
	elapsedtime=$[$endtimeepoch - $starttimeepoch]
	backupsize=`stat -c "%s" /backup/last_daily/variations_backup_$(date +%d).tar.gz`
	backuprate=$[$backupsize / $elapsedtime]
	printf "%s %s %s %s seconds %s bytes %s bytes/sec # system_incremental.sh completed successfully\n" "$backupdate" "$starttime" "$endtime" "$elapsedtime" "$backupsize" "$backuprate" >> /root/logs/backup.log
	


else
        # Something bad happened with Glacier. Log accordingly.
	printf "%s %s # A problem occurred in system_incremental.sh. Please consult /var/log/glacierlog for more information.\n" "$backupdate" "$starttime" >> /root/logs/backup.log

	message_body="A Glacier error occurred occurred while processing the daily incremental system backup."	

        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu
        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu
        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu


fi



df | mail -s "Variations Storage Monitor" zzz@yyy.edu
date >> /root/logs/dflog
df >> /root/logs/dflog
 
