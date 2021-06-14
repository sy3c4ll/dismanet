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
#연결을 생성하고 유지하는 스크립트.
#연결 수용기기 wlan0과 연결 제공기기 wlan1이 존재해야 함.
#다른 기기들에서 코드를 접수하기도 하므로 dismanet_disconnect로 연결을 끊기 전까지는 종료하면 안됨.

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
    #주기적으로, 숫자는 조절 가능함.
    if !((i%50000));then
      #Even if the connection has already been established,
      #the script will scan periodically to update the DHT.
      #If this is the case, reset all ping times from and to this device to positive infinity
      #in case one has moved out of range.
      #이미 연결되었으면 토폴로지 업데이트로 간주하고 재측정 항목 삭제.
      if [ -e ./dht ];then python ./reset_dht.py $(iw dev wlan1 info|grep addr|awk '{$1=$1};1'|cut -d ' ' -f 2|tr a-z A-Z);fi
      #This kinda complicated one-liner will save a list of the BSSIDs of all networks with the SSID 'dismanet'.
      HOSTLIST=($(nmcli device wifi list|grep dismanet|awk '{$1=$1};1'|cut -d ' ' -f 1|tr '\n' ' '))
      #For every wlan1 found
      #dismanet의 이름을 가진 모든 핫스팟에 대해
      for BSSID in $HOSTLIST;do
        #Connect.
        nmcli device wifi connect $BSSID password dismanet ifname wlan0
        #Ask the peer for their DHT.
        echo 4|ncat --send-only 192.168.19.1
        #Listen for a reply, and save it to a temporary DHT file.
        ncat -l>./.dht
        #If this is first encounter and the contacter does not have a DHT,
        #use the peer's DHT for their own.
        if [ ! -e ./dht ];then cp ./.dht ./dht;fi
        #Try pinging the peer to gather the ping times, then
        #update the DHT with the temporary DHT and ping times for the peer.
        #See update_dht.py for specific rules.
        #연결한 상대로부터 DHT를 받고, 상대까지의 연결시간을 측정해 토폴로지 업데이트.
        python ./update_dht.py $(iw dev wlan1 info|grep addr|awk '{$1=$1};1'|cut -d ' ' -f 2|tr a-z A-Z) $BSSID $(ping -c 3 192.168.19.1|tail -1|awk '{print $4}'|cut -d '/' -f 2)
        #Disconnect. Too many simultaneous connections have proved unstable in testing.
        nmcli device disconnect wlan0
      done
      #For every wlan1 found
      for BSSID in $HOSTLIST;do
        #Tell the peer that the contacter is trying to send their DHT.
        echo 3|ncat 192.168.19.1
        #Send the DHT.
        #수집한 토폴로지 역전송하기.
        ncat 192.168.19.1<./dht
      done
    fi
    #When not scanning for peers, listen for codes from new and existing devices.
    #다른 기기로부터 연결코드 접수.
    CODE=$(ncat -l)
    #A simple switch statement for the code received.
    #See CODES for a full list of codes.
    case $CODE in
      #If the peer has notified the device of an incoming transmission
      #파일전송을 공지하면
      1)
        #Receive route from peer.
        #전송경로 접수.
        ROUTE=$(ncat -l)
        #If the next peer is itself
        #자신이 목적지이면
        if [ $ROUTE[1]=$(iw dev wlan1 info|grep addr|awk '{$1=$1};1'|cut -d ' ' -f 2|tr a-z A-Z) ];then
          #Receive the fragment.
          ncat -l>./unidentified.part
          #Save the annotation marking the fragment's order.
          i=$(tail -n 1 ./unidentified.part)
          #Rename the file to show its order.
          mv ./unidentified.part ./fragment$i.part
          #Remove the annotation.
          #파일 순서 숙지.
          sed -i '$ d' ./fragment$i.part
          #Concatenate received files in order.
          #파일을 순서대로 붙이기.
          #TODO
        else
          #Connect to the next peer.
          nmcli device wifi connect $ROUTE[1] password dismanet ifname wlan0
          #Relay transmission to the next peer.
          echo 1|ncat 192.168.19.1
          #Send the peer the route inforation.
          echo ${ROUTE[@]:1}|ncat 192.168.19.1
          #Relay file to the next peer.
          #다음 기기로 정보 릴레이.
          ncat -l|ncat 192.168.19.1
          #Disconnect.
          nmcli device disconnect wlan0
        fi
        ;;
      #If the peer has announced a disconnection
      #연결해제를 공지하면
      2)
        #Listen for the BSSID of the disconnected device.
        TARGET_BSSID=$(ncat -l)
        #Attempt to delete the device's entry from the DHT.
        #If the entry did exist, and was successfully removed
        #DHT에서 해당 기기 제거.
        if [ $(python ./remove_dht.py TARGET_BSSID)='0' ];then
          #Scour the network for peers.
          HOSTLIST=($(nmcli device wifi list|grep dismanet|awk '{$1=$1};1'|cut -d ' ' -f 1|tr '\n' ' '))
          #For every peer
          for BSSID in $HOSTLIST;do
            #Connect.
            nmcli device wifi connect $BSSID password dismanet ifname wlan0
            #Notify the peer of the disconnection.
            echo 2|ncat 192.168.19.1
            #Send them the BSSID of the disconnected device.
            echo $TARGET_BSSID|ncat 192.168.19.1
          done
        fi
        #If the entry did not exist, the device has already been notified of the disconenction.
        #Stop broadcasting the disconnection info.
        #처음 듣는 공지이면 주변 기기들로 전송.
        ;;
      #If the peer has notified the device of an incoming DHT
      #DHT전송을 공지하면
      3)
        #Listen for the DHT, then save it to a temporary DHT file.
        ncat -l>./.dht
        #Update the DHT with the received temporary DHT file.
        #DHT 업데이트.
        python ./update_dht.py
        ;;
      #If the peer has requested a DHT
      #기기의 DHT를 요청하면
      4)
        #If a DHT does not already exist, the device claims itself initiator and
        #creates one with itself as the only entry.
        #없으면 자신만 존재하는 DHT 생성.
        if [ ! -e ./dht ];then python ./create_dht.py $(iw dev wlan1 info|grep addr|awk '{$1=$1};1'|cut -d ' ' -f 2|tr a-z A-Z);fi
        #Send back the DHT.
        #DHT 전송.
        ncat 192.168.19.1<./dht
        ;;
    esac
  done
fi

