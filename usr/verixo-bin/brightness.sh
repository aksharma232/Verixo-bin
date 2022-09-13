#!/bin/bash

cd /sys/class/backlight
value=`echo \`cat */max_brightness\` / 10 | bc`
if [ "$1" == "up" ]; then
	curr_value=`cat */brightness`
	new_value=`echo $curr_value + ${value} |bc`
	echo $new_value > */brightness
	[ "$?" -eq "0" ] && echo $new_value > /root/.current_brightness_value
fi

if [ "$1" == "down" ]; then
	curr_value=`cat */brightness`
	new_value=`echo $curr_value - ${value} |bc`
	echo $new_value > */brightness
	[ "$?" -eq "0" ] && echo $new_value > /root/.current_brightness_value
fi

if [ "$1" == "restore" ]; then
	[ -f /root/.current_brightness_value ] && cat /root/.current_brightness_value > /sys/class/backlight/*/brightness
fi

