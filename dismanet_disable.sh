#The script concerned with disabling the wlan1 AP device and
#returning the system networking file to normal.

#!/bin/bash
#Since the script deals with /etc/ files, it must be run as root.
if [ $(whoami)!=root ];then echo 'You must be root to disable DisMANET';fi
#The devices must be configured.
if [ ! -e ./enabled ];then echo 'DisMANET is already disabled'
#The network must not be active.
elif [ -e ./active ];then echo 'You must disconnect before disabling DisMANET'
else
  #Stop networking daemons.
  systemctl stop hostapd dnsmasq
  #Restore system files from backup. If they did not exist before modification, remove the modified files.
  if [ -e ./backup/dhcpcd.conf ];then cp ./backup/dhcpcd.conf /etc/dhcpcd.conf;else rm /etc/dnsmasq.conf;fi
  if [ -e ./backup/dnsmasq.conf ];then cp ./backup/dnsmasq.conf /etc/dnsmasq.conf;else rm /etc/dnsmasq.conf;fi
  if [ -e ./backup/hostapd.conf ];then cp ./backup/hostapd.conf /etc/hostapd/hostapd.conf;else rm /etc/hostapd/hostapd.conf;fi
  if [ -e ./backup/hostapd ];then cp ./backup/hostapd /etc/default/hostapd;else rm /etc/default/hostapd;fi
  if [ -e ./backup/sysctl.conf ];then cp ./backup/sysctl.conf /etc/sysctl.conf;else rm /etc/sysctl.conf;fi
  if [ -e ./backup/iptables.ipv4.nat ];then cp ./backup/iptables.ipv4.nat /etc/iptables.ipv4.nat;else rm /etc/iptables.ipv4.nat;fi
  if [ -e ./backup/.bashrc ];then cp ./backup/.bashrc ~/.bashrc;else rm ~/.bashrc;fi
  #Start networking daemons.
  systemctl start hostapd dnsmasq
  #Delete the file for discerning whether the network has been configured.
  rm ./active
  #Reboot the device for the changes to take effect.
  reboot now
fi

