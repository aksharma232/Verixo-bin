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


udevadm info -a -p $DEVPATH | grep -i 'ATTRS{product}' | grep TIO
STATUS=`echo $?`
grep ${DEVPATH::-1} /tmp/.tiomonitor
REMOVESTATUS=`echo $?`

if [ $STATUS -eq 0 ] || [ $REMOVESTATUS -eq 0 ]; then 
	LAST_CHAR=`echo $DEVPATH | rev | cut -c 1`

	if [ "$LAST_CHAR" == "p" ] && [ -f "/tmp/.padump" ]; then
		Sound --apply-settings --card --file "/tmp/.padump"
		(sleep 3; Sound --refresh-list) &

		if [ $ACTION == "add" ]; then
			rm -f /tmp/.padump
			echo ${DEVPATH::-1} > /tmp/.tiomonitor
		else
			cp -f /root/.padump /tmp/.padump
			rm -f /tmp/.tiomonitor
		fi
	fi
	exit 0
fi

pidof OS_Desktop
status=$?

if [ $status -eq 0 ]
then
	if [ $ACTION == "add" ]
	then
		Sound --refresh-list --set-default
	else
		Sound --refresh-list
	fi
else
	echo "OS_DESKTOP_NOT_RUNNING" > /dev/null
fi
sync
