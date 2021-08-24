#A peer attempting to connect to a network will
#periodicaly scan for AP devices with SSID dismanet.
#If the only such device found and contacted does not have a DHT,
#the device will deem itself initiator of the network and
#send back a new DHT with itself as the only participant.
#This script creates the DHT for such scenarios.

#!/usr/bin/env python
import pandas as pd
import sys
#Create a pandas DataFrame with the device's BSSID as the only index and column
#And the ping time 0.0 (which is an alias for positive infinity)
dht=pd.DataFrame([[0.0]],index=[sys.argv[1]],columns=[sys.argv[1]])
#Save the DHT to file. The 'index=False' option must be included
#for the DHT to be saved correctly, albeit with the loss of the index.
dht.to_csv('../dht',index=False)

