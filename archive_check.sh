#!/usr/bin/env bash

lockfile=/tmp/archive_check

if (set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
# set trap
trap 'rm -f "$lockfile"; exit $?'  SIGHUP INT TERM EXIT KILL


	
ZBX_IP='172.16.63.29'
ZBX_PORT='10051'	
short_hostname=$(hostname -s)
UNAME=$short_hostname



> /tmp/archive_http_check 
for i in `curl -s 'http://172.16.63.32:83/cctvApi/getCameraList?extLogin=admin' --basic -u admin:KMHfeJy2pDYSEJQ | jq -r '  .[] | .id ' `; do
   echo -n "$i;" >> /tmp/archive_http_check 
   rtsp=`curl -s "http://172.16.63.32:83/cctvApi/getUrl?extLogin=admin&id="$i --basic -u admin:KMHfeJy2pDYSEJQ | jq . | grep  \"archive\" -A 2 | grep http | cut -d \" -f2`
   echo -n "$rtsp;" >> /tmp/archive_http_check 
   ffprobe $rtsp
   if [ "$?" -ne 0 ]
   then
      echo "Nope!"  >> /tmp/archive_http_check
   else
      echo "OK!"    >> /tmp/archive_http_check
   fi   
done

cat /tmp/archive_http_check | grep http| grep Nope | awk -F";" '{print $1}'  > /tmp/camrea_withoutarchive
curl -s 'http://172.16.63.32:83/cctv/api/cameras/problem?extLogin=admin' --basic -u admin:KMHfeJy2pDYSEJQ | jq . | grep '"status": 2' -B 1 | grep id | awk '{print $2}' | tr -d \" | tr -d \, > /tmp/camrea_broken


grep -v -F -x -f /tmp/camrea_broken /tmp/camrea_withoutarchive > /tmp/cameara_withoutarchive_and_no_broken
rm -f /tmp/archive_http_check
rm -f /tmp/camrea_withoutarchive
rm -f /tmp/camrea_broken



l=0
l=`cat /tmp/cameara_withoutarchive_and_no_broken | wc -l`
zabbix_sender -vv  -z $ZBX_IP -p $ZBX_PORT -s $UNAME -k  archive_check -o $l




rm -f "$lockfile"
# unset trap
trap - SIGHUP INT TERM EXIT KILL
	
else
echo "Failed to acquire lockfile: $lockfile."
echo "Held by $(cat $lockfile)"
fi
