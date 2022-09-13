#!/bin/sh
export DISPLAY=:0.0

if [ "$1" == "setdefault" ]
then
	killall -9 /usr/verixo-bin/LayoutVariantSetting
	/usr/verixo-bin/LayoutVariantSetting --Setdefault
else
	/usr/verixo-bin/OnScreenKeyboard
fi

