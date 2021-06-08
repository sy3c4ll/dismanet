#The script concerned with disconnecting from a mesh.
#On disconnection, this script must be run first to notify peers of a disconnection
#before terminating the running dismanet_connect script.

#!/bin/bash
#The network must be active.
if [ ! -e ./active ];then echo 'DisMANET is not active'
#if the device is disconnecting without ever having connected, nothing needs to be done.
elif [ -e ./dht ];then
  #Scour the network for peers.
  HOSTLIST=($(nmcli device wifi list|grep dismanet|awk '{$1=$1};1'|cut -d ' ' -f 1|tr '\n' ' '))
  #For all peers
  for BSSID in $HOSTLIST;do
    #Connect.
    nmcli device wifi connect $BSSID password dismanet ifname wlan0
    #Notify them of the disconnection.
    echo 2|ncat --send-only 192.168.19.1
    #Send them the device's BSSID.
    ncat --send-only 192.168.19.1<$(iw dev wlan1 info|grep addr|awk '{$1=$1};1'|cut -d ' ' -f 2|tr a-z A-Z)
  done
  #Remove files associated with network activity.
  rm ./active ./dht
  if [ -e ./.dht ];then rm ./.dht;fi
else rm ./active
fi

