#The script concerned with sending a file over an existing connection.

#!/bin/bash
#Check if the device is connected to a mesh network.
if [ ! -e ./dht ];then echo 'You must be connected to a DisMANET mesh network'
else
  #A simple iterator to count fragments.
  i=1
  #Take in input line by line from the output of multipath_route.
  #The Python script will return lines of arrays consisting of packet size then routing path.
  while ROUTE=read -r line;do
    #Save the fastest route separately. This will be the route to send the remaining packets.
    if [ i -eq 1 ];then FASTEST=$ROUTE;fi
    #Split the file by packet size.
    split -b $ROUTE[1] $2
    #Label the file by packet number by appending the packet number to the end of the file.
    echo $i>>./xaa
    #Connect to the first peer in the array.
    nmcli device wifi connect $ROUTE[2] password dismanet iwname wlan0
    #Notify the peer of an incoming file transmission.
    echo 1|ncat --send-only 192.168.19.1
    #Send the peer the route excluding the peer itself.
    echo ${ROUTE[@]:2}|ncat --send-only 192.168.19.1
    #Send the peer the packet.
    ncat --send-only 192.168.19.1<./xaa
    #Collate the rest of the files.
    rm ./xaa
    if [ -e ./xab ];then cat ./x*>$2;else touch $2;fi
    #Remove remaining splices.
    rm ./x*
    #Disconnect.
    nmcli device disconnect wlan0
    #Increment the iterator.
    ((i++))
  done<$(python multipath_route.py $(iw dev wlan1 info|grep addr|awk '$1=$1;1'|cut -d ' ' -f 2|tr a-z A-Z) $1)
  #Label the remaining fragment.
  echo $i>>$2
  #Connect to the fastest route and send the packet.
  nmcli device wifi connect $FASTEST[2] password dismanet iwname wlan0
  echo 1|ncat --send-only 192.168.19.1
  echo ${FASTEST[@]:2}|ncat --send-only 192.168.19.1
  ncat --send-only 192.168.19.1<$2
  #Complete the transmission by sending an empty file.
  ((i++))
  echo 1|ncat --send-only 192.168.19.1
  echo ${FASTEST[@]:2}|ncat --send-only 192.168.19.1
  echo $i|ncat --send-only 192.168.19.1
  #Disconenct.
  nmcli device disconnect wlan0
fi

