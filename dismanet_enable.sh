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
  apt-get install -y hostapd dnsmasq nmap
  #First, stop networking daemons.
  systemctl stop hostapd dnsmasq
  #Add networking interface wlan1 of type AP to physical device phy0.
  iw phy phy0 interface add wlan1 type __ap
  #Make a backup folder.
  if [ -d ./backup/ ];then mkdir ./backup/;fi
  #Replace system networking files with prewritten files in ./modified/.
  if [ -e /etc/dhcpcd.conf ];then cp /etc/dhcpcd.conf ./backup/dhcpcd.conf;fi
  cp ./modified/dhcpcd.conf /etc/dhcpcd.conf
  if [ -e /etc/dnsmasq.conf ];then cp /etc/dnsmasq.conf ./backup/dnsmasq.conf;fi
  cp ./modified/dnsmasq.conf /etc/dnsmasq.conf
  if [ -e /etc/hostapd/hostapd.conf ];then cp /etc/hostapd/hostapd.conf ./backup/hostapd.conf;fi
  cp ./modified/hostapd.conf /etc/hostapd/hostapd.conf
  if [ -e /etc/default/hostapd ];then cp /etc/default/hostapd ./backup/hostapd;fi
  cp ./modified/hostapd /etc/default/hostapd
  if [ -e /etc/sysctl.conf ];then cp /etc/sysctl.conf ./backup/sysctl.conf;fi
  cp ./modified/sysctl.conf /etc/sysctl.conf
  if [ -e /etc/iptables.ipv4.nat ];then cp /etc/iptables.ipv4.nat ./backup/iptables.ipv4.nat;fi
  if [ -e ~/.bashrc ];then cp ~/.bashrc ./backup/.bashrc;fi
  #Configure the builtin iptables firewall.
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  iptables-save>/etc/iptables.ipv4.nat
  #Restore iptables configuration on boot.
  echo 'iptables-restore</etc/iptables.ipv4.nat'>>~/.bashrc
  #Start daemons hostapd and dnsmasq.
  systemctl start hostapd dnsmasq
  #Create the file for discerning whether the interfaces have been configured.
  touch ./enabled
  #Reboot the device for the changes to take effect
  reboot now
fi

