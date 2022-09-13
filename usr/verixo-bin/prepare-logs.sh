#!/bin/bash

## initiating, defining variables
function_list=('setup' 'copy_tmp' 'system_info' 'copy_distinct' 'copy_certs' 'copy_root' 'copy_sysconfdb' 'copy_proc' 'copy_sys' 'create_zip' 'clean_up')
work_dir="/tmp/prepare-logs/"
certs_dir="/usr/local/share/ca-certificates/"
raw_stuff="/tmp/raw_stuff/"
letos_build="/sda1/data/.osbuild_LeTOS"
logfile="$work_dir/prepare-logs.log"
system_info="$work_dir/system-info"
sysconf="$raw_stuff/sysconf/"
x_version="$raw_stuff/x-version"

osbuild=`awk -F "-" '{for(i=NF;i>=1;i--) printf "%s ", $i;print ""}' /data/.osbuild | awk '{print $1}'`
osversion=`cat /data/.osversion`
upgradebuild=`cat /usr/verixo-bin/.upgradebuild | awk -F "-" '{print $1}'`
seconds=`date +%s`

zip_name="/tmp/$osbuild-$osversion-$upgradebuild-$seconds.zip"
zip_pass="$osbuild$upgradebuild"

##function to generate log of on-going activity
log(){
  if [ $1 -eq 0 ]; then
     printf "done: $2\n" >> $logfile
  elif [ $1 -eq 2 ]; then
     printf "info: $2\n" >> $logfile
  else
     printf "error: $2\n" >> $logfile
  fi
}

## prearing directories 
setup(){
  echo -n "processing ..."
  rm -rf $work_dir $raw_stuff $zip_name &>/dev/null

  mkdir -p $work_dir{"run","root","tmp","ca-certificates"} "/tmp/raw_stuff/sysconf/schemas"
  status_mkdir=$?

  cd /tmp; 
  touch $logfile
  echo "preparing logs on date [`date`]" >> $logfile
  log "$status_mkdir" "creating work directory [$work_dir]"
}

## function to backup sysconf.db and removing sensitive data
copy_sysconfdb(){
  #-# preparing data 
  cp -pa /data/sysconf.db $sysconf
  sqlite3 "$sysconf/sysconf.db" ".tables" | awk -v ORS='\n' '{ for (i = 1; i <= NF; i++) print $i }' > $sysconf/table-list

  #-# getting table schemas 
  while read table
  do
    sqlite3 $sysconf/sysconf.db "PRAGMA table_info($table)" > "$sysconf/schemas/$table"
  done < "$sysconf/table-list"
  log "0" "creating table schemas"

  #-# filtering table columns, processing only table name and password columns
  cd "$sysconf/schemas"
  grep -inR "password" | awk -F ":" '{print $1}' > "$sysconf/table-name-col"
  grep -inR "password" | awk -F "|" '{print $2}' > "$sysconf/password-col"
  cd /tmp

  #-# preparing file of field names [table-name|password]
  while read table_name
  do 
    while read password
    do 
      # setting null to password column for each row
      sqlite3 "$sysconf/sysconf.db" "update $table_name set $password = null"
      
      # deleting 1st line to manage file pointer
      sed -i -e '1d' "$sysconf/password-col"
  
      # avoiding loop more than once. resets file pointer to 1st line
      break 
    done <  "$sysconf/password-col"
  done < "$sysconf/table-name-col"

  #-# copying db to final location
  cp -pa "$sysconf/sysconf.db" $work_dir
  log "$?" "removing sensitive data and copying sysconf.db"
}

## /sys 
copy_sys(){

  size=`df -T | grep -iw tmpfs | grep -v shm | awk '{print $5}'`
  size=`echo "$size/1024" | bc`
 
  #-# copy /sys only if we got enough space, min 700MB
  if [ $size -ge 0 ]; then
    tar -cjf "$raw_stuff/sys.tbz" /sys &>/dev/null
    tar -xf "$raw_stuff/sys.tbz" -C $work_dir
    log "$?" "copying /sys"
  else
    log "1" "copying /sys due to low space"
  fi
}

## /proc 
copy_proc(){
  # listing only files under /proc
  find /proc -type f > "$raw_stuff/proc-files" 2> /dev/null

  # filtering required keywords, making a list of files to be copied, one file name on each line
  # listing environ,mountinfo and status files from each process dir and appending selective important files using echo
  cat "$raw_stuff/proc-files" | grep -iw -E "environ|mountinfo|status" >> "$raw_stuff/proc-filtered"
  echo -e "/proc/cpuinfo\n/proc/meminfo\n/proc/uptime\n/proc/stat\n/proc/filesystems" >> "$raw_stuff/proc-filtered"
  echo -e "/proc/dma\n/proc/modules\n/proc/loadavg" >> "$raw_stuff/proc-filtered"

  # copying files line by line, and also creating parent directory for the file 
  while read line
  do
    filedir="$work_dir/`dirname $line`"
    mkdir -p $filedir &> /dev/null
    cp -ap $line $filedir &> /dev/null
  done < "$raw_stuff/proc-filtered"
  
  # blindly logging as success copying /proc
  log "0" "copying /proc"
}

## /root 
copy_root(){
  find /root -maxdepth 1 -type f > "$raw_stuff/files-in-root"
  cp -rpa `cat "$raw_stuff/files-in-root"` $work_dir/root 
  log "$?" "copying /root" 
}

## /tmp 
copy_tmp(){
  find /tmp/ | grep -iwv -E "prepare-logs|sysconf|raw_stuff" > "$raw_stuff/files-in-tmp"
  sed -i '1d' "$raw_stuff/files-in-tmp"
  cp -rpaf `cat "$raw_stuff/files-in-tmp"` "$work_dir/tmp"  
  log "$?" "copying /tmp"
}

## cpu, memory, hardware info
copy_distinct(){
  #-# store cpu, memory, hardware info	
  lscpu > $work_dir/cpu-status
  log "$?" "collecting CPU info"

  free -m > $work_dir/memory-status
  log "$?" "collecting memory info"
  
  lshw > $work_dir/hw-info 2>/dev/null
  log "$?" "copying hardware info."

  #-# copying /pkgs, /var, /run etc. directories
  cp -rpa /pkgs $work_dir &>/dev/null
  log "$?" "copying /pkgs"
  
  cp -rpa /var/ $work_dir &>/dev/null
  log "$?" "copying /var"

  cp -rpa /run/bootlog $work_dir/run/ &>/dev/null
  log "$?" "copying /run"
}

## copy ca-certificates contents
copy_certs(){
  rm -rf "$work_dir/ca-certificates/*" &>/dev/null
  printf "serial\nissuer\nstartdate\nenddate\npubkey" > "$raw_stuff/cert-data-list"

  if [ -d $certs_dir ]; then
    cd "/usr/local/share/ca-certificates" &>/dev/null
    file `find -type f` | grep -iw -E "pem|der" | awk -F ":" '{print $1}' | sed 's/^.//g; s/^\///g' > "$raw_stuff/cert-list"
    log "$?" "generating list of ca-certificates"
  
    while read cert
    do
      while read data
      do
        cert_name=`awk -F "." '{print $1}' <<< $cert`
        openssl x509 -in $cert -$data | head -n1 | sed 's/=/ = [/1; s/$/]/g' >> "$work_dir/ca-certificates/$cert_name"
      done < "$raw_stuff/cert-data-list"
    done < "$raw_stuff/cert-list"
    log "2" "collecting data from ca-certificates"
    cd /tmp
  else
    log "1" "[$certs_dir] not found, can't process ca-certificates"
  fi
}

## create file having info of image, upgrade build, kernel and x-org version
system_info(){
  #-# verify which os we are using to determine file and parse os version
  if [ -f "$letos_build" ]; then
    version=`cat $letos_build | awk -F "-" '{print $3}' | awk -F "." '{print $3}'`
    echo "Image Version = [$version]" >> $system_info
    ver_status=$?
  else
   version=`cat /sda1/data/.osbuild | awk -F "-" '{print $5}' | awk -F "0" '{print $5}'`
   echo "Image Version = [$version]" >> $system_info
   ver_status=$?
  fi
  
  ubuild=`cat /usr/verixo-bin/.upgradebuild`
  echo "Upgrade Build = [$ubuild]" >> $system_info
  ub_status=$?
  
  echo "Kernel Version = [`uname -r`]" >> $system_info
  kv_status=$?
 
  X -version 2> $x_version
  x_ver=`cat $x_version  | grep -i "x server" | awk '{print $4}'`
  echo "X Server = [$x_ver]" >> $system_info 

  si_status=$(( $ver_status || $ub_status || $kv_status ))
  log "$si_status" "generating system info"
}

## Creating zip
create_zip(){
  cd /tmp
  zip -qyrP $zip_pass $zip_name prepare-logs/ &>/dev/null
  status_zip=$?
  sleep 1
  zip_size=`du -sh $zip_name | awk '{print $1}'`
  log "2" "preparing zip [File:$zip_name; size:$zip_size]"
}

## cleaning up
clean_up(){
  cp -pa $logfile /tmp/
  rm -rf $work_dir $raw_stuff

  #-append zip name and status to local log file-#
  printf "\nZIP NAME=$zip_name\nZIP STATUS=$status_zip\n" >> "/tmp/`basename $logfile`"
  sync
}


#-# sequential calls to each function listed in array i.e. function_list[]
count=1
total=${#function_list[@]}
for funct in ${function_list[@]}
do
  ${funct}
  echo -ne "\rprocessing ... [$count/$total]"
  (( count++ ))
done

#-exiting with tar's status-#
exit $status_zip
