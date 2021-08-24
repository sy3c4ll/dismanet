#!/usr/bin/env python
import pandas as pd
import sys
def dist(v):
  if dht.index[v]==sys.argv[1]:
    return 0
  elif spt[v]==None:
    return sys.maxsize
  else:
    s=0
    while spt[v]!=None:
      s+=dht.iloc[v,spt[v]]
      v=spt[v]
    return s
if len(sys.argv)!=3:
  raise OSError('Invalid number of arguments')
dht=pd.read_csv('../dht')
dht.index=dht.columns
spt,queue=[None]*len(dht.index),[list(dht.index).index(sys.argv[1])]
while queue:
  u=queue.pop(0)
  for v in range(len(dht.index)):
    if dht.iloc[u,v] and dist(v)>dist(u)+dht.iloc[u,v]:
      spt[v]=u
      queue.append(v)
dest,path=list(dht.index).index(sys.argv[2]),[]
while spt[dest]!=None:
  path.append(dht.index[dest])
  dest=spt[dest]
path.reverse()
for peer in path:
  print(peer,end=' ')

