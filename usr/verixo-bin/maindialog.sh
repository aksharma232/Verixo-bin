#!/bin/sh

set +x
msg=`echo $1`

dialog --ok-label "Yes" --cancel-label "No" --pause "$msg" 12 70 20

status=$?

if [ $status -eq 1 ]
then
	touch /tmp/.pxereboot
fi
