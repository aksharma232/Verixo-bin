#!/bin/bash

#$1 => Connection Name
#$2 => URL
#$3 => Domain Name
#$4 => UserName
#$5 => Password

if [ "$#" -lt 6 ]; then
	echo "Required arguments are: Domain Name, Username and Password"
	exit 1
fi

#ping -c3 $2
#if [ "$?" -gt 0 ]; then
#	ShowMessage "URL is either unreachable or unstable" "RDWeb_$1"
#	exit 1
#fi

rm -rf /tmp/.rdweb/"$1"
mkdir -p /tmp/.rdweb/"$1"
cd /tmp/.rdweb/"$1"

timeout -s SIGTERM 5s curl -c cookie.txt -d "DomainUserName=$3\\$4&UserPass=$5" ${2} -kL -o /dev/null

if [ ! -f "cookie.txt" ]; then
 	echo "Please try once again, server may slow !" > /tmp/.errorRDWeb
        rm -rf /tmp/.rdweb/"$1"
        exit
fi

file cookie.txt | /usr/verixo-bin/grep -q long

if [ "$?" -eq "1" ]; then
	echo "You entered credentials may wrong! Please enter correct credentials." > /tmp/.errorRDWeb
	rm -rf /tmp/.rdweb/"$1"
	exit
fi

curl -b cookie.txt ${2} -kL -o rdweb.xml

/usr/verixo-bin/grep Title rdweb.xml | /usr/verixo-bin/grep -o -P '(?<=").*(?=")' > title
/usr/verixo-bin/grep Type= rdweb.xml | /usr/verixo-bin/grep -o -P '(?<=").*(?=")' > type

FLAG=0
for i in `/usr/verixo-bin/grep URL rdweb.xml | /usr/verixo-bin/grep -v ico | /usr/verixo-bin/grep -o -P '(?<=").*(?=")' `
do
	j=`basename $i`
	curl -b cookie.txt -kL https://${6}/${i} -o ${j}
	if [ "${FLAG}" -eq "0" ]; then
		k=`head -n1 title`
		sed -i '1d' title
		echo -n "'$k'" >> list
		echo "$k" >> list1
		echo -ne "\t$j" >> list
		FLAG=1
	else
		echo -ne " \t $j" >> list
                m=`head -n1 type`
 		echo -e " \t $m"  >> list
		FLAG=0
	fi
done
#Changes done for the freerdweb user whom desktop or application access is not avilable in this case it will display error msg reading from /tmp/.errorRDWeb file.-Varsha	

APP_COUNT=`cat /tmp/.rdweb/"$1"/list | wc | awk {'print "$1"'}`
echo  $APP_COUNT

if [ $APP_COUNT -eq "0" ]; then
        echo "Desktops or Applications are not available."  >> /tmp/.errorRDWeb
        rm -rf /tmp/.rdweb/"$1"
        exit
fi

rm -f list1 type title rdweb.xml cookie.txt
cd -
