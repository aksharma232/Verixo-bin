#!/bin/bash

RFID="RFIDeas"
UPEK="UPEK"

cd /sys/bus/usb/drivers/usb

for i in `ls | grep ^[0-9]`
do
	#CHECK IF MANUFACTURER FILE EXISTS

	if [ -f $i/manufacturer ]
	then
		manu=`cat $i/manufacturer`
		if [ "$manu" == "$RFID" ] || [ "$manu" == "$UPEK" ]
		then
			echo "$manu found"
			echo $i > unbind
			echo $i > bind
		fi
	else
		echo "$i NOT OK"
	fi

done


# Commented below code as it was creating multiple folders 
# on quick_logout, quick_reboot, quick_shutdown

#cd /sys/bus/usb/drivers/usb-storage
#for i in `ls | grep ^[0-9]`
#do
#        echo $i > unbind
#        echo $i > bind
#done
