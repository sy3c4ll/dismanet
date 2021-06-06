#Acts as a DHCP in the wireless mesh network.
#Should assign IP addresses automatically however
#for the sake of simplicity, this has been skipped and
#it is necessary to modify the file such that
#Raspberry Pi number n is assigned 10.32.254.n and so on.

#!/usr/bin/env python
#Open the save file for the IP within the network and
#write the IP address of 10.32.254.n
#where n is the Raspberry Pi number.
open('./assigned_ip','x').write('10.32.254.1')

