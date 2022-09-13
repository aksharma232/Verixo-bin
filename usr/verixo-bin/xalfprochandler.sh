#!/bin/sh
 
#while [ 1 ];
#do
#           sleep 1

	if [  "$1" = "LaunchCommand" ]; 
        then
		PID=`sqlite3 /data/sysconf.db "select Pid from ConnectionTable where ConnectionName ='$2' and ConnectionType='$3'" | sed 's/,/ /g'`
	        str=$2
		if [[ $str != *[:]* ]]
		then
 			rm /tmp/.kioskreconnect
	 		rm /tmp/.reconnect
			echo "It contains one of those"
		fi  
	 fi

        if [ "$1" = "LaunchApplication" ];
        then
		PID=`sqlite3 /data/sysconf.db "select PID from appinfo where AppName ='$2'" | sed 's/,/ /g'`
	fi


	if [ "$3" = "Browser" ] || [ "$3" = "RDP" ] || [ "$3" = "VNC" ] || [ "$3" = "ICA" ] || [ "$3" = "X11" ];
        then
		kill -9 $PID
	elif  [ "$3" = "PNAgent" ]
        then
		killall -9 storebrowse AuthManagerDaemon ServiceRecord
	else
		pkill -9 -P $PID
        fi
	status=$?
	if [ $status != 0 ]
	then
		kill -9 $PID
        elif [ $status -eq 0 ]
	then   
		exit 0  
	fi
 
#done
