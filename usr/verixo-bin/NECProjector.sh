# !/bin/sh 
stty -F $2 speed 38400 cs8 -cstopb -parenb -echo
if [ "$1" = "1"  ]; then
echo "True"
/bin/echo -e "\x02\x00\x00\x00\x00\x02" > $2
else
echo "False"
/bin/echo -e "\x02\x01\x00\x00\x00\x03" > $2
fi
