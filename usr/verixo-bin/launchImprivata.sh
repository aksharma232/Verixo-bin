#!/bin/bash 

export DISPLAY=:0

/usr/verixo-bin/Imprivata 1> /tmp/.implog 2> /tmp/.imperr
NSTATUS=$?

rm -rf /tmp/.noNeed

killall -9 /usr/verixo-bin/OnScreenKeyboard

if [ $NSTATUS -eq 0 ]
then
    killall -9 icewm
    killall -9 icewm*
    sqlite3 /data/sysconf.db "INSERT INTO Imprivata (Property, Value) VALUES ('CancelBtnStatus', 'true')"
    OS_Desktop --forcelogout
fi

/usr/verixo-bin/Imprivata --showosk

rm -f /tmp/.impriLogOut
