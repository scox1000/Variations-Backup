#!/bin/bash
#
# Name: system_full.sh
# Description: Monthly full system backup
# Author: Steve Cox
# 11/1/2012
#
#  INSTRUCTIONS
#
#  1. Replace all "xxx@yyy.edu" with email addresses of people to receive notification failures.
#
#  NOTE: This script does NOT backup up the Variations media files, assumed to be located in /home/dmlserv/content/*
#

backupdate=`date "+%y%m%d"`
starttime=`date "+%H:%M:%S"`
starttimeepoch=`date "+%s"`


tar -cvzf /backup/variations_monthly_$(date +%m).tar.gz --exclude '/home/dmlserv/content/*' --exclude '/backup/*' --exclude-backups --exclude-caches /

java -jar /root/scripts/uploader-0.0.5-jar-with-dependencies.jar --credentials /root/scripts/aws.properties --endpoint https://glacier.us-east-1.amazonaws.com/ --vault variations --upload /backup/variations_monthly_$(date +%m).tar.gz &> /root/logs/glacierlog.full
currenttime=`date "+%y%m%d:%H:%M:%S "`
awk -v ct=$currenttime '{ print ct " " $0 }' /root/logs/glacierlog.full >> /root/logs/glacierlog
#cat /root/logs/glacierlog.full >> /root/logs/glacierlog


glacier_success=`tail -1 /root/logs/glacierlog.full | grep "Uploaded archive"`

if [ "$glacier_success" ]
then
	# Save last monthly backup and log 
	rm -f /backup/last_monthly/*.*
	mv /backup/variations_monthly_$(date +%m).tar.gz /backup/last_monthly/variations_monthly_$(date +%m).tar.gz

        endtime=`date "+%H:%M:%S"`
        endtimeepoch=`date "+%s"`
        elapsedtime=$[$endtimeepoch - $starttimeepoch]
        backupsize=`stat -c "%s" /backup/last_monthly/variations_monthly_$(date +%m).tar.gz`
        backuprate=$[$backupsize / $elapsedtime]
        printf "%s %s %s %s seconds %s bytes %s bytes/sec # system_full.sh completed successfully\n" "$backupdate" "$starttime" "$endtime" "$elapsedtime" "$backupsize" "$backuprate" >> /root/logs/backup.log


else

        # Something bad happened with Glacier. Log accordingly.
        printf "%s %s # A problem occurred in system_full.sh. Please consult /var/log/glacierlog for more information.\n" "$backupdate" "$starttime" >> /root/logs/backup.log

	message_body = "A Glacier error occurred while processing the monthly full system backup."	

        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu
        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu
        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu


fi


touch /root/scripts/lastmonthly
