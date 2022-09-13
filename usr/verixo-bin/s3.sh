#!/bin/bash
#set -x
lshw -c system | grep -i product | grep -qi "LIVA Z2V"
if [ "$?" -eq "0" ]; then
	echo s2idle > /sys/power/mem_sleep
fi

sleep 2
for dev in /sys/bus/usb/devices/*-*:*
do
  if [ -f $dev/bInterfaceClass ]
  then
    if [[ "$(cat $dev/bInterfaceClass)" == "03" && "$(cat $dev/bInterfaceProtocol)" == "01" ]]
    then
	echo "Keyboard detected: $dev"
	K=`echo $dev | cut -d ':' -f 1`
	echo $K
      	echo "enabled" > $K/power/wakeup 2> /dev/null
	cat $K/power/wakeup
    fi
    if [[ "$(cat $dev/bInterfaceClass)" == "03" && "$(cat $dev/bInterfaceProtocol)" == "02" ]]
    then
      	echo "Mouse detected: $dev"
	M=`echo $dev | cut -d ':' -f 1`
        echo $M
        echo "enabled" > $M/power/wakeup 2> /dev/null
        cat $M/power/wakeup
    fi
  fi
done
	echo "power button "
	a=`find /sys/devices/ | grep -i lnxpwrbn | grep -i wakeup$`
	echo "enabled" > $a 2> /dev/null
	cat /sys/devices/LNXSYSTM\:00/LNXPWRBN\:00/power/wakeup

	echo "XHC mode check"
	grep XHC /proc/acpi/wakeup | grep -q disabled
	if [ "$?" -eq "0" ]; then
	
	for i in `grep ^XHC /proc/acpi/wakeup  | awk '{print $1}'`; do echo $i  > /proc/acpi/wakeup; done

        fi
	grep EHC /proc/acpi/wakeup | grep -q disabled  #added for Lenovo 625
        
	if [ "$?" -eq "0" ]; then

	for i in `grep ^EHC /proc/acpi/wakeup  | awk '{print $1}'`; do echo $i  > /proc/acpi/wakeup; done	
	
    fi

RemoteSettingCheck=`sqlite3 /data/sysconf.db "select ClientStatus from ClientSettings"`

/etc/rc.d/service/x11vnc stop


for i in `grep -i pci /proc/acpi/wakeup | grep -i disabled | awk '{print $1}'`; do echo $i > /proc/acpi/wakeup ; done

echo HDAS  > /proc/acpi/wakeup #changes for sleep - Impact Notebook
echo mem > /sys/power/state

#echo "refreshing xhci bus controller for sleep issue" 
#busid=`dmesg | grep -i xhci_hcd | grep -i controller | awk '{print $4}' | cut -d: -f1,2,3 | head -1`
#echo -n "$busid" > /sys/bus/pci/drivers/xhci_hcd/unbind
#sleep 0.1
#echo -n "$busid" > /sys/bus/pci/drivers/xhci_hcd/bind
#sleep 0.1
#xset dpms force off

cd /sys/bus/pci/drivers/ohci-pci
for i in `dmesg | grep -i ohci-pci | grep controller -i | awk '{print $4}' | sort -u | cut -d: -f1,2,3`
do
        echo -n $i > unbind
        sleep 1
        echo -n $i > bind
done
cd -

xdotool mousemove 10 20

echo $RemoteSettingCheck
if [ "$RemoteSettingCheck" == "1" ]
then
        killall VMSSigHandler
     	rm -f /tmp/doNotPoll
        /usr/verixo-bin/VMSSigHandler &
fi

/etc/rc.d/service/x11vnc start &

cd /sys/devices/
for i in `find . -name wakeup`; do echo "disabled" > $i ; done 
#for laptop
grep LID /proc/acpi/wakeup | grep -q disabled
[ "$?" -eq "0" ] && echo LID > /proc/acpi/wakeup


RFID="RFIDeas"

cd /sys/bus/usb/drivers/usb

for i in `ls | grep ^[0-9]`
do
	#CHECK IF MANUFACTURER FILE EXISTS

	if [ -f $i/manufacturer ]
	then
		manu=`cat $i/manufacturer`
		if [ "$manu" == "$RFID" ]
		then
			echo $i > unbind
			echo $i > bind
		fi
	else
		echo "$i NOT OK"
	fi

done

killall -10 SignalR
(sleep 10 ;/usr/verixo-bin/SignalR) &

#/etc/rc.d/service/x11vnc stop
#/etc/rc.d/service/x11vnc start
#for Laptop L470
#cd /sys/devices/LNXSYSTM\:00/LNXSYBUS\:00/
#echo disabled > PNP0C0D\:00/power/wakeup
#echo mem > /sys/power/state
#/usr/bin/startup1.sh
#echo -n "0000:04:00.3" > xhci_hcd/unbind
#for i in `cat /proc/acpi/wakeup | awk '{print $i}'` ; do echo $i > /proc/acpi/wakeup ; done

for i in `grep -i pci /proc/acpi/wakeup | grep -i disabled | awk '{print $1}'`; do echo $i > /proc/acpi/wakeup ; done
