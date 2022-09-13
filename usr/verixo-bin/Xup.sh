#!/bin/sh
wiredval=`sqlite3 /data/sysconf.db "Select value from sysconf where Property='WiredTimeout'"`
if [ "$wiredval" == "" ]; then
        echo "wiredval is empty"
        wiredval=90
else
        echo "wiredval is not empty"
        wiredval=$(($wiredval*3))	
fi

wirelessval=`sqlite3 /data/sysconf.db "Select value from sysconf where Property='WirelessTimeout'"`
if [ "$wirelessval" == "" ]; then
        echo "wirelessval is empty"
	wirelessval=180
else
        echo "wirelessval is not empty"
	wirelessval=$(($wirelessval*3))
fi

val=$(($wiredval+$wirelessval+10))
echo $val
sleep $val

wmctrl -l > /tmp/isXup & xupid=$!
sleep 3
if [ -s /tmp/isXup ]; then 
	echo "`date +%d-%m-%y_%H:%M:%S`	X applications started successfully" >> /var/log/issue.log
else
	echo "`date +%d-%m-%y_%H:%M:%S`	Failed to start X applications" >> /var/log/issue.log
	rm -f /tmp/isXup
	echo b > /proc/sysrq-trigger
fi
