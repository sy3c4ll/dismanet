#The script concerned with resetting all ping time entries involving the device.

#!/usr/bin/env python
import pandas as pd
#Read the DHT from file.
dht=pd.read_csv('./dht')
#The index has been removed for storing purposes,
#however it is identical to the columns.
dht.index=dht.columns
#Read the mesh IP from file.
ip=open('./assigned_ip','r').read()
#For every known peer
for i in dht.index:
  #Reset the ping times between the peer and this device to 0 (which is an alias for positive infinity)
  dht.at[ip,i]=dht.at[i,ip]=0.0
#Save the modified DHT to file.
dht.to_csv('./dht',index=False)

