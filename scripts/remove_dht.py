#The Python script concerned with deleting disconnected peers from the DHT.

#!/usr/bin/env python
import pandas as pd
import sys
#Quick sanity check.
if len(sys.argv)!=2:
  raise OSError('Invalid number of arguments')
#Read the DHT from file.
dht=pd.read_csv('./dht')
#The index has been removed in the file, but it is identical to the columns.
#Use the columns as the index also.
dht.index=dht.columns
#If the BSSID does exist in the DHT
if ip in dht.index:
  #Remove all entries related to that BSSID.
  dht.drop(index=[sys.argv[1]],columns=[sys.argv[1]],inplace=True)
  #The deletion was successful, return 0.
  print(0)
#If the BSSID does not exist in the DHT
else:
  #The deletion was unsuccessful, return 127.
  print(127)
#Save the updated DHT to file.
dht.to_csv('./dht',index=False)

