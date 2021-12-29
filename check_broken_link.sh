#!/usr/bin/env bash

lockfile=/tmp/check_broken_link

### FUNCTIONS ###

short_hostname=$(hostname -s)
#domain="adm72.local"
UNAME=$short_hostname
#.$domain



settings_zabbix_server() {
        ZBX_IP='172.16.63.29'
        ZBX_PORT='10051'
}

find_empty_files() {
        IFS=$'\n' files=( $(timeout --signal=SIGINT 7200 find -L /opt/netris/storage-meta/ -type l 2>/dev/null) )
        l=0
        echo $(date) > /opt/scripts/broken_link_list
        for f in ${files[@]}
        do
                ((l=l+1))
                echo $f >> /opt/scripts/broken_link_list
        done
}

report_to_zabbix() {
        #echo $l
        zabbix_sender -vv  -z $ZBX_IP -p $ZBX_PORT -s $UNAME -k  broken_link_list -o $l
#	if [ "$?" -ne "0" ]
#	then
#		zabbix_sender -vv  -z $ZBX_IP -p $ZBX_PORT -s $short_hostname -k  broken_link_list -o $l
#	fi
}


### RUNNABLE CODE ###


if (set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
  then
    # set trap
    trap 'rm -f "$lockfile"; exit $?'  SIGHUP INT TERM EXIT KILL

    settings_zabbix_server
    find_empty_files
    report_to_zabbix

    rm -f "$lockfile"
    # unset trap
    trap - SIGHUP INT TERM EXIT KILL
	
  else
    echo "Failed to acquire lockfile: $lockfile."
    echo "Held by $(cat $lockfile)"
fi

