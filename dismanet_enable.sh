#The script concerned with configuring the networking devices.
#Before activating the network, two networking devices
#wlan0 of type managed and wlan1 of type AP must exist.

#!/bin/bash
#Since the script messes with networking devices and /etc/ files,
#it must be run as root.
if [ $(whoami)!=root ];then echo 'You must be root to enable DisMANET';fi
#Unexpected behaviours when run with DisMANET already configured.
if [ -e ./enabled ];then echo 'DisMANET is already enabled'
else
  #Install required packages.
  apt-get install -y hostapd dnsmasq
  #First, stop networking daemons.
  systemctl stop hostapd dnsmasq
  #Add networking interface wlan1 of type AP to physical device phy0.
  iw phy phy0 interface add wlan1 type __ap
  #Make a backup folder.
  if [ -d ./backup/ ];then mkdir ./backup/;fi
  #Replace system networking files with prewritten files in ./modified/.
  if [ -e /etc/dhcpcd.conf ];then mv /etc/dhcpcd.conf ./backup/dhcpcd.conf;fi
  mv ./modified/dhcpcd.conf /etc/dhcpcd.conf
  if [ -e /etc/dnsmasq.conf ];then mv /etc/dnsmasq.conf ./backup/dnsmasq.conf;fi
  mv ./modified/dnsmasq.conf /etc/dnsmasq.conf
  if [ -e /etc/hostapd/hostapd.conf ];then mv /etc/hostapd/hostapd.conf ./backup/hostapd.conf;fi
  mv ./modified/hostapd.conf /etc/hostapd/hostapd.conf
  if [ -e /etc/default/hostapd ];then mv /etc/default/hostapd ./backup/hostapd;fi
  mv ./modified/hostapd /etc/default/hostapd
  if [ -e /etc/sysctlconf ];then mv /etc/sysctl.conf ./backup/sysctl.conf;fi
  mv ./modified/sysctl.conf /etc/sysctl.conf
  #Configure the builtin iptables firewall.
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  sh -c 'iptables-save>/etc/iptables.ipv4.nat'
  #Restore iptables configuration on boot.
  echo 'iptables-restore</etc/iptables.ipv4.nat'>>~/.bashrc
  #Start daemons hostapd and dnsmasq.
  systemctl start hostapd dnsmasq
  #Create the file for discerning whether the interfaces have been configured.
  touch ./enabled
  #Reboot the device for the changes to take effect
  reboot
fi

