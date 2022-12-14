#!/bin/sh

set -x

# Wanted trigger timeout in milliseconds.
IDLE_TIME=$(($1*60*1000))

# Sequence to execute when timeout triggers.
trigger_cmd() {
    echo "Triggered action"
	s3.sh
}

sleep_time=$IDLE_TIME
triggered=false

# ceil() instead of floor()
while sleep $(((sleep_time+999)/1000))
do
   #Check if Pulse is in use of audio play
   #then no need of idle-time
   if [ -f /tmp/.pulserunning ]
   then	
        echo "Pulse is Running"
   else	
	 idle=$(xprintidle)
         if [ $idle -ge $IDLE_TIME ]; then
           #if ! $triggered; then
             trigger_cmd
             triggered=true
             sleep_time=$IDLE_TIME
          #fi
    	 else
        	triggered=false
       		 # Give 100 ms buffer to avoid frantic loops shortly before triggers.
        	sleep_time=$((IDLE_TIME-idle+100))
   	 fi
    fi
done
