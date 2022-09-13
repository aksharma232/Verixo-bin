#!/bin/sh
##SHELL SCRIPT TO CHECK LTM SERVER VALIDATION BEFORE APPLYING TASK
. /tmp/fudmconfig.txt 
TIMEOUT=10
clear
#create a file to upload on server fot testing purpose
touch /tmp/"${IMAGEFILENAME}".txt
#Remove /tmp/upload.log
rm -rf /tmp/upload.log
#Code to download certificate
if [ ! -z "${CERTNAME}" ]; then
	/bin/wget --user="${FTUSERNAME}" --password="${FTPASSWORD}" ${PROTOCOL}://${IPADDRESS}/${CERTNAME} -O /tmp/${CERTNAME} 2>/dev/null
fi
TELNET=`echo "quit" | telnet ${IPADDRESS} ${ALTPORT} | grep "Escape character is"`
	if [ "$?" -eq "0" ]; then
  
	case ${PROTOCOL} in
	FTP)
		if [ -z "${FTUSERNAME}" ]; then
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" "ftp://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" 1>/dev/null 2>/dev/nul
			status=$?
		else
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" -u "${FTUSERNAME}":"${FTPASSWORD}" "ftp://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" 1>/dev/null 2>/dev/null
			status=$?
        fi
        if [ "$status" -ne "0" ]; then
             echo "FTP:Failed to upload ${IMAGEFILENAME}.txt file " > /tmp/upload.log
        fi
		break;
		;;
	FTPS)
		if [ -z "${CERTNAME}" ]; then
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" -u "${FTUSERNAME}":"${FTPASSWORD}" "ftps://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" 1>/dev/null 2>/dev/null
			status=$?
        else
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" -u "${FTUSERNAME}":"${FTPASSWORD}" "ftps://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" --cacert "/tmp/${CERTNAME}" --ftp-ssl 1>/dev/null 2>/dev/null
			status=$?
        fi
        if [ "$status" -ne "0" ]; then
             echo "FTPS:Failed to upload ${IMAGEFILENAME}.txt file" > /tmp/upload.log
        fi
		break;
		;;
	HTTP)
		if [ -z "${FTUSERNAME}" ]; then
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" "http://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" 1>/dev/null 2>/dev/null
			status=$?
        else
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" -u "${FTUSERNAME}":"${FTPASSWORD}" "http://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" 1>/dev/null 2>/dev/null
			status=$?
        fi
        if [ "$status" -ne "0" ]; then
             echo "HTTP:Failed to upload ${IMAGEFILENAME}.txt file" > /tmp/upload.log
        fi
		break
		;;
	HTTPS)
		if [ -z "${CERTNAME}" ]; then
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" -u "${FTUSERNAME}":"${FTPASSWORD}" "https://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" 1>/dev/null 2>/dev/null
			status=$?
        else
			curl -Ss -T "/tmp/${IMAGEFILENAME}.txt" -u "${FTUSERNAME}":"${FTPASSWORD}" "https://${IPADDRESS}/${FOLDER}/${IMAGEFILENAME}.txt" --connect-timeout "${TIMEOUT}" --cacert "/tmp/${CERTNAME}" 1>/dev/null 2>/dev/null
			status=$?
        fi
        if [ "$status" -ne "0" ]; then
             echo "HTTPS:Failed to upload ${IMAGEFILENAME}.txt file" > /tmp/upload.log
	fi
	     break
		;;
	CIFS)
		mkdir -p /mnt/samba &> /dev/null
	if [ ! -z "${DOMAIN}" ]; then
        	mount -t cifs //${IPADDRESS}/${FOLDER} /mnt/samba -o username="${FTUSERNAME}",password="${FTPASSWORD}",domain="${DOMAIN}",vers=1.0,sec=ntlm &> /dev/null
                if [ "$?" -ne "0" ]; then
            		mount -t cifs //${IPADDRESS}/${FOLDER} /mnt/samba -o user="${FTUSERNAME}",pass="${FTPASSWORD}",dom="${DOMAIN}",vers=2.0 &> /dev/null
		fi
                if [ "$?" -ne "0" ]; then
                    mount -t cifs //${IPADDRESS}/${FOLDER} /mnt/samba -o user="${FTUSERNAME}",pass="${FTPASSWORD}",dom="${DOMAIN}",vers=3.0 &> /dev/null
                fi
	else
        	mount -t cifs //${IPADDRESS}/${FOLDER} /mnt/samba -o username="${FTUSERNAME}",password="${FTPASSWORD}",vers=1.0,sec=ntlm &> /dev/null
                if [ "$?" -ne "0" ]; then
        		    mount -t cifs //${IPADDRESS}/${FOLDER} /mnt/samba -o user="${FTUSERNAME}",pass="${FTPASSWORD}",vers=2.0 &> /dev/null
                fi
                if [ "$?" -ne "0" ]; then
                    mount -t cifs //${IPADDRESS}/${FOLDER} /mnt/samba -o user="${FTUSERNAME}",pass="${FTPASSWORD}",vers=3.0 &> /dev/null
                fi
       fi
       		status=$?
		if [ "$status" -eq "0" ]; then
			cp "/tmp/${IMAGEFILENAME}.txt" "/mnt/samba/${IMAGEFILENAME}.txt" 1>/dev/null 2>/dev/null
		else
			echo "SAMBA:Unable to copy ${IMAGEFILENAME}.txt file" >> /tmp/upload.log
		fi
		break
		;;
	esac
else
	echo "TELNET: Connection to ${IPADDRESS} with ${ALTPORT} Failed..Please check the firewall" > /tmp/upload.log
	exit 1
fi
