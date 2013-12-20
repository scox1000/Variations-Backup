#!/bin/bash
#
# Name: backup_content.sh
# Description: Daily Variations content backup
# Author: Steve Cox
# 11/1/2012
#
# INSTRUCTIONS FOR USE
#
# 1. Set usewest=1 to store archives on BOTH US-EAST and US-WEST Amazon Glacier endpoints. By default the script stores on US-EAST only.
#
# 2. Replace "xxx@yyy.edu" with the email addresses of people who will recieve notifications in the event of a failure
#


usewest=0

backupsize=0
nrfiles=0

backupdate=`date "+%y%m%d"`
starttime=`date "+%H:%M:%S"`
starttimeepoch=`date "+%s"`

glacier_problem=0
message_body=""


for f in `find /home/dmlserv/content -mtime -1`
do
#	echo "Processing: $f"
	if [ -f "$f" ]; then

		
#		glacier_success=`tail -1 /root/logs/glacierlog | grep "Uploaded archive"`

		java -jar /root/scripts/uploader-0.0.5-jar-with-dependencies.jar --credentials /root/scripts/aws.properties --endpoint https://glacier.us-east-1.amazonaws.com/ --vault variations --upload $f &> /root/logs/glacierlog.content
		currenttime=`date "+%y%m%d:%H:%M:%S "`
		awk -v ct=$currenttime '{ print ct " " $0 }' /root/logs/glacierlog.content >> /root/logs/glacierlog

		glacier_success=`tail -1 /root/logs/glacierlog.content | grep "Uploaded archive"`
		if [ ! "$glacier_success" ]
		then
			glacier_problem=1
			printf -v message_body "$message_body Error uploading %s to Glacier\n" $f
		fi
		

		if [ $usewest -eq 1 ]; then 

                        java -jar /root/scripts/uploader-0.0.5-jar-with-dependencies.jar --credentials /root/scripts/aws.properties --endpoint https://glacier.us-west-1.amazonaws.com/ --vault variations --upload $f &> /root/logs/glacierlog.content
			currenttime=`date "+%y%m%d:%H:%M:%S "`
			awk -v ct=$currenttime '{ print ct " " $0 }' /root/logs/glacierlog.content >> /root/logs/glacierlog

			glacier_success=`tail -1 /root/logs/glacierlog.content | grep "Uploaded archive"`
			if [ ! "$glacier_success" ]
			then
				glacier_problem=1
				printf -v message_body "$message_body Error uploading %s to Glacier\n" $f
			fi

		fi
		backupsize=$[$backupsize + `stat -c "%s" $f`]
		let nrfiles=$nrfiles+1
	fi
done

if [ $glacier_problem -eq 1 ]
then
        printf "%s %s # A problem occurred in backup_content.sh. Please consult /var/log/glacierlog for more information.\n" "$backupdate" "$starttime" >> /root/logs/backup.log
	
	echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu
        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu
        echo $message_body | mail -s "Variations Backup - Problem Occured!!!" xxx@yyy.edu


		
else

	endtime=`date "+%H:%M:%S"`
	endtimeepoch=`date "+%s"`
	elapsedtime=$[$endtimeepoch - $starttimeepoch]
	backuprate=$[$backupsize / $elapsedtime]
	printf "%s %s %s %s seconds %s bytes %s bytes/sec %s files # backup_content.sh completed successfully\n" "$backupdate" "$starttime" "$endtime" "$elapsedtime" "$backupsize" "$backuprate" "$nrfiles" >> /root/logs/backup.log

fi



