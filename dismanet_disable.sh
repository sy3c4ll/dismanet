#The script concerned with disabling the wlan1 AP device and
#returning the system networking file to normal.

#!/bin/bash
#Since the script deals with /etc/ files, it must be run as root.
if [ $(whoami)!=root ];then echo 'You must be root to disable DisMANET';fi
#The devices must be configured.
if [ ! -e ./enabled ];then echo 'DisMANET is already disabled'
#The network must not be active.
elif [ -e ./active ];then echo 'You must disconnect before disabling DisMANET'
else
  #Incomplete.
  #TODO
  #Delete the file for discerning whether the network has been configured.
  rm ./active
fi

