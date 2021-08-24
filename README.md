# Distributed Mobile Ad-Hoc NETwork

## Introduction

*Distributed Mobile Ad-Hoc NETwork*, or in short *DisMANET*, is a project aiming to enable the direct communication via IEEE 802.11 between peers without the need for a central server or host. A decentralised internet, if you will.

## Execution

All scripts must be run as root. Due to technical issues, or more accurately me sucking at bash scripting, the following scripts will only run on Raspberry Pis (and even that's not guaranteed). Just, don't use it yet.

`dismanet_enable.sh` must first be run to set up wireless devices. This script will create a virtual wireless device wlan1 of type AP, and this device will be used to host a hotspot conneection to the device. The default device wlan0 will be used to connect to such AP devices of peers.

`dismanet_disable.sh` will revert this change, and return the system to its original state.

`dismanet_connect.sh` will connect the device to a virtual mesh network. This script is responsible for handling all interactions between peers during initialisation and connection, which means this script must not be terminated abruptly such as by C-c.

`dismanet_disconnect.sh` should be run before terminating the script above, so that all peers are notified.

`dismanet_send.sh` is the script responsible for sending a file through the mesh network. This script accepts two arguments, of which first is the BSSID of the recipient and the second is the file to send. The file will automatically be routed through the shortest path to the recipient.

All python scripts are helper scripts called within the shell scripts to aid calculation, and therefore must not be executed independently.

## Transmission Codes

A list of all transmission codes used for communication between peers.

| Code | Description |
| :-: | :--|
| 1 | Notify file transmission |
| 2 | Notify disconnection |
| 3 | Notify DHT transmission |
| 4 | Send request for DHT of host |

