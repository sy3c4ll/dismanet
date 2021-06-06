#The Python script concerned with deleting disconnected peers from the DHT.

#!/usr/bin/env python
import pandas as pd
import sys
#Quick sanity check.
if len(sys.argv)!=2:
  raise OSError('Please specify one and only one IP address')
#Read the DHT from file.
dht=pd.read_csv('./dht')
#The index has been removed in the file, but it is identical to the columns.
#Use the columns as the index also.
dht.index=dht.columns
#Read the disconnected peer's mesh IP from the command line arguments.
ip=sys.argv[1]
#If the IP address does exist in the DHT
if ip in dht.index:
  #Remove all entries related to that IP.
  dht.drop(index=[ip],columns=[ip],inplace=True)
  #The deletion was successful, return 0.
  print(0)
#If the IP address does not exist in the DHT
else:
  #The deletion was unsuccessful, return 127.
  print(127)
#Save the update DHT to file.
dht.to_csv('./dht',index=False)

