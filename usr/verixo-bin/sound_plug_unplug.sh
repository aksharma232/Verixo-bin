#!/bin/bash
export DISPLAY=:0

if [ -d "/lib64" ]; then
        export LD_LIBRARY_PATH=/usr/lib64/openssl-1.0:/usr/lib64/qt4/lib:/lib64:/usr/lib64:/lib:/usr/lib:/usr/X11R6/lib:/usr/verixo-lib:/usr/X11/lib:/usr/lib/i386-linux-gnu:/lib/i386-linux-gnu
        export QT_PLUGIN_PATH=/usr/lib64/qt4/plugins/
        export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/verixo-bin:/usr/X11/bin
else
        export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/verixo-bin:/usr/X11/bin
        export LD_LIBRARY_PATH=/lib:/usr/lib:/usr/X11R6/lib:/usr/verixo-lib:/usr/X11/lib:/usr/lib/i386-linux-gnu:/lib/i386-linux-gnu
        export QT_PLUGIN_PATH=/usr/lib/qt4/plugins/
fi

# /tmp/.padump file exists only for TIO monitor
# check /lib/udev/usb.sh script for /tmp/.padump file
if [ -f /tmp/.padump ]; then
	exit 0
fi

echo $1 | grep -iwEo 'mute|down|up|micmute'
STATUS=`echo $?`

if [ $STATUS -eq 0 ]; then
	Sound --set-volume $1
else
	if [ "$1" == "plug" ]; then
		Sound --refresh-list --set-default --analog $2
	else
		Sound --refresh-list --analog $2
	fi
fi

