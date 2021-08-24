#The script concerned with resetting all ping time entries involving the device.

#!/usr/bin/env python
import pandas as pd
import sys
#Quick sanity check.
if len(sys.argv)!=2:
  raise OSError('Invalid number of arguments')
#Read the DHT from file.
dht=pd.read_csv('../dht')
#The index has been removed for storing purposes,
#however it is identical to the columns.
dht.index=dht.columns
#For every known peer
for i in dht.index:
  #Reset the ping times between the peer and this device to 0 (which is an alias for positive infinity)
  dht.at[sys.argv[1],i]=dht.at[i,sys.argv[1]]=0.0
#Save the modified DHT to file.
dht.to_csv('../dht',index=False)

