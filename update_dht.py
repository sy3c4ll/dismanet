#The script concerned with updating the DHT with data from peers' DHTs and ping times.
#The script will prioritise entries from the received DHT, unless
#said entry has a value of 0.0 (which is an alias for positive infinity), and thereby is unknown
#or one of the two peers in a connection is itself.

#!/usr/bin/env python
import pandas as pd
import sys
#Quick sanity check.
if len(sys.argv)!=1 and len(sys.argv)!=4:
  raise OSError('Invalid number of arguments')
#Read the DHT from file.
dht=pd.read_csv('./dht')
dht.index=dht.columns
#Read the received DHT from file.
_dht=pd.read_csv('./.dht')
_dht.index=_dht.columns
#For every entry in the original DHT
for i in dht.index:
  for j in dht.index:
    #If the ping times are not unknown in the received DHT,
    #and neither of the peers are itself
    if _dht.at[i,j]!=0.0 and i!=ip1 and j!=ip1:
      #Replace the value in the original DHT with the entry from the received DHT.
      dht.at[i,j]=_dht.at[i,j]
#For every peer in the received DHT that is unknown to this device
for i in _dht.index:
  if i not in dht.index:
    #Add the peer and its ping times to the DHT.
    dht[i]=_dht[i]
    dht=dht.append(_dht.loc[i])
#If a ping time has also been given in the command line arguments
if len(sys.argv)==4:
  #Gather the two IP addresses and the ping time from the arguments.
  ip1,ip2,t=sys.argv[1],sys.argv[2],float(sys.argv[3])
  #If the scanned peer is unknown to this device
  if ip2 not in dht.index:
    #Add the peers to the DHT.
    dht.index.append(ip2)
    dht.columns.append(ip2)
  #Update the entry for the ping time between the two peers.
  dht.at[ip1,ip2]=dht.at[ip2,ip1]=t
#Save the updated DHT to file.
dht.to_csv('dht',index=False)

