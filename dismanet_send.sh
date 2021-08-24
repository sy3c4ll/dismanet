#The script concerned with sending a file over an existing connection.
#파일전송의 스크립트.

#!/bin/bash
#Check if the device is connected to a mesh network.
if [ ! -e ./dht ];then echo 'You must be connected to a DisMANET mesh network'
else
  #Append the name of the file to the end of the file.
  print "\n$2">>$2
  #route will return a list of peers through the shortest path to the target.
  ROUTE=$(python ./scripts/route.py $(iw dev wlan1 info|grep addr|awk '$1=$1;1'|cut -d ' ' -f 2|tr a-z A-Z) $1)
  #Connect to the first peer in the array.
  nmcli device wifi connect $ROUTE[1] password dismanet iwname wlan0
  #Notify the peer of an incoming file transmission.
  echo 1|ncat 192.168.19.1
  #Send the peer the route excluding the peer itself.
  echo ${ROUTE[@]:1}|ncat 192.168.19.1
  #Send the peer the packet.
  ncat 192.168.19.1<$2
  #Disconenct.
  nmcli device disconnect wlan0
fi

