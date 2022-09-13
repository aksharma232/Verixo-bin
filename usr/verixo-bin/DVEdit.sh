#!/bin/bash

cd /root/
cp -apfv /sda1/data/.defaultvalues /root/
dos2unix .defaultvalues
dos2unix dv

sed -i 's/\ =\ /=/g' .defaultvalues
sed -i 's/\ =\ /=/g' dv

cat dv | while read line
do
	value=`echo -n $line | cut -f1 -d=`
	grep -i ^${value} .defaultvalues
	if [ "$?" -eq "0" ]; then
		sed -i "s/$value=.*/$line/g" .defaultvalues
	else
		echo $line >> .defaultvalues
	fi
done
mount -o remount,rw /sda1
cp -f .defaultvalues /sda1/data/.defaultvalues
sync
mount -o remount,ro /sda1
