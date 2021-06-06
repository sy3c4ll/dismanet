#The script concerned with initiating and maintaining a connection.
#Through dismanet_enable, two networking devices
#wlan0 of type managed and wlan1 of type AP must already exist.
#Since this script will not only initiate the connection but
#also listen to code transmissions from new and existing devices,
#the script must keep running in background for the connection to continue.
#If one wishes to stop the transmission,
#dismanet_disconnect must first be run to notify others of the disconnection
#then the script may be terminated by Ctrl+C or kill.
#Soz I don't know the first thing about scripting

#!/bin/bash
#Unexpected behaviours if run without existing wlan0 and wlan1 devices.
#Check if dismanet_enable has been run.
if [ ! -e ./enabled ];then echo 'You must enable DisMANET before connecting'
#Unexpected behaviours if run with an existing connection, prevent.
elif [ -e ./active ];then echo 'DisMANET is already active'
else
  #The file is meant to discern whether a connection is in progress.
  touch ./active
  #A simple infinite loop, with variable i to count the number of cycles.
  for ((i=0;;i++));do
    #Periodically- adjust constant with respect to time taken during experimentation.
    if !((i%50000));then
      #Even if the connection has already been established,
      #the script will scan periodically to update the DHT.
      #If this is the case, reset all ping times from and to this device to infinity
      #in case one has moved out of range.
      if [ -e ./assigned_ip ];then python ./reset_dht.py;fi
      #This kinda complicated one-liner will save a list of the BSSIDs of all networks with the SSID 'dismanet'.
      HOSTLIST=($(nmcli device wifi list|grep dismanet|awk '{$1=$1};1'|cut -d ' ' -f 1|tr '\n' ' '))
      #For every wlan1 found
      for BSSID in $HOSTLIST;do
        #Connect.
        nmcli device wifi connect $BSSID password dismanet ifname wlan0
        #If this is the first encounter with a mesh device,
        #first generate a mesh IP address.
        if [ ! -e ./assigned_ip ];then python ./assign_ip.py;fi
        #Ask the peer for their DHT.
        echo 0|ncat --send-only 192.168.19.1
        #Listen for a reply, and save it to a temporary DHT file.
        ncat -l>./.dht
        #If this is first encounter and the contacter does not have a DHT,
        #use the peer's DHT for their own.
        if [ ! -e ./dht ];then cp ./.dht ./dht;fi
        #Ask the peer for their assigned IP address.
        echo 1|ncat --send-only 192.168.19.1
        #Try pinging the peer to gather the ping times, then
        #update the DHT with the temporary DHT and ping times for the peer.
        #See update_dht.py for specific rules.
        python ./update_dht.py $(echo ./assigned_ip) $(ncat -l) $(ping -c 3 192.168.19.1|tail -1|awk '{print $4}'|cut -d '/' -f 2)
        #Disconnect. Too many simultaneous connections have proved unstable in testing.
        nmcli device disconnect wlan0
      done
      #For every wlan1 found
      for BSSID in $HOSTLIST;do
        #Tell the peer that the contacter is trying to send their DHT.
        echo 2|ncat --send-only 192.168.19.1
        #Send the DHT.
        ncat --send-only 192.168.19.1<./dht
      done
    fi
    #When not scanning for peers, listen for codes from new and existing devices.
    CODE=$(ncat -l)
    #A simple switch statement for the code received.
    #See codes.txt for a full list of codes.
    case $CODE in
      #If the peer has requested a DHT
      0)
        #If a DHT does not already exist, the device claims itself initiator and
        #creates one with itself as the only entry.
        if [ ! -e ./dht ];then
          python ./assign_ip.py
          python ./create_dht.py
        fi
        #Send back the DHT.
        ncat --send-only 192.168.19.1<./dht
        ;;
      #If the peer has requested the device's mesh IP
      1)
        #If an IP has not already been assigned (which should not happen, but still)
        #assign one now.
        if [ ! -e ./assigned_ip ];then python ./assign_ip.py;fi
        #Send back the IP address.
        ncat --send-only 192.168.19.1<./assigned_ip
        ;;
      #If the peer has notified the device of an incoming DHT
      2)
        #Listen for the DHT, then save it to a temporary DHT file.
        ncat -l>./.dht
        #Update the DHT with the received temporary DHT file.
        python ./update_dht.py
        ;;
      #If the peer has notified the device of an incoming transmission
      3)
        #Incomplete.
        #TODO
        ;;
      #If the peer has announced a disconnection
      4)
        #Listen for the mesh IP of the disconnected device.
        TARGET_IP=$(ncat -l)
        #Attempt to delete the device's entry from the DHT.
        #If the entry did exist, and was successfully removed
        if [ $(python ./remove_dht.py TARGET_IP)='0' ];then
          #Scour the network for peers.
          HOSTLIST=($(nmcli device wifi list|grep dismanet|awk '{$1=$1};1'|cut -d ' ' -f 1|tr '\n' ' '))
          #For every peer
          for BSSID in $HOSTLIST;do
            #Connect.
            nmcli device wifi connect $BSSID password dismanet ifname dismanet0
            #Notify the peer of the disconnection.
            echo 4|ncat --send-only 192.168.19.1
            #Send them the mesh IP of the disconnected device.
            echo $TARGET_IP|ncat --send-only 192.168.19.1
          done
        fi
        #If the entry did not exist, the device has already been notified of the disconenction.
        #Stop broadcasting the disconnection info.
        ;;
    esac
  done
fi

