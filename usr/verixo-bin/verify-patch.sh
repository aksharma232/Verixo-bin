#!/bin/bash

#-# variables
letos_build="/sda1/data/.osbuild_LeTOS"
os_build="/sda1/data/.osbuild"
#. /tmp/RMTDATA/min-max-verify &>/dev/null  #pulling variables from file
logfile="/var/log/minmax.log"

#-# generates log based on status
log(){
 if [ $1 -eq 0 ]; then
   echo "[Ok]: $2" > $logfile
 elif [ $1 -eq 2 ]; then
   echo "[Info]: $2" > $logfile
 else
   echo "[Error]: $2" > $logfile
 fi
}

#-# 
verify(){
  #--verify in given patch falls between passed args i.e. min/max
  if [[ "$1" -ge "$min" ]]; then
    if [[ -z $max ]]; then
      log "2" "max os version is missing, proceed carefully"
      exit 0
    elif [[ $1 -le $max ]]; then
      log "0" "valid os version"
      exit 0
    else
      log "1" "OS version mismatch, can't apply patch"
      exit 1
    fi
  else
    log "1" "OS version mismatch, can't apply patch"
    exit 1
  fi
}

setup(){
  #-# check args, we need at least one arg
  if [[ $# -eq 0 ]]; then
    log "2" "min & max version is not specified"
    exit 0
  fi

  #-# verify which os we are using to determine file and parse os version 
  if [[ -f "$letos_build" ]]; then
    letos=`cat $letos_build | sed -e "s/ /-/g" | awk -F "-" '{print $3}' | awk -F "." '{print $3}'`
    log "2" "current os version is [$letos]"
    verify $letos
  else
   gio=`cat $os_build | sed -e "s/ /-/g" | awk -F "-" '{print $5}' | awk -F "0" '{print $5}'`
   log "2" "current os version is [$gio]"
   verify $gio
  fi
}

#--# call
min=$1
max=$2
setup $min $max
