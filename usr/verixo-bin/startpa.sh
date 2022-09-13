#!/bin/bash

mkdir /dev/shm 
mount -t tmpfs shm /dev/shm
/etc/rc.d/init.d/dbus restart > /tmp/dbus.log 2> /tmp/dbus.log

sync

pamixer  --get-volume >/tmp/sound_debug
/etc/rc.d/service/PulseAudio start

sync
