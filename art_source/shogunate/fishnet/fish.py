"""fish.py: paint a clean fishnet lattice on the leg skin of a converted sprite.
usage: fish.py <src hi-res png> <sprite key> <hip_row_frac> <skin hex> <line hex> [dens]"""
import sys, numpy as np
from PIL import Image
from netmask import netmask
src,key,hipf,skin,line=sys.argv[1:6]
dens=float(sys.argv[6]) if len(sys.argv)>6 else 0.14
root='assets/sprites/'
spr=Image.open(root+key+'.png').convert('RGBA'); sa=np.array(spr); W,H=spr.size
m,alpha=netmask(src,0)
ys,xs=np.where(alpha); x0,x1,y0,y1=xs.min(),xs.max()+1,ys.min(),ys.max()+1
sc=(H-2)/(y1-y0)
cw=max(1,round((x1-x0)*sc)); ch=H-2
def small(arr):
    im=Image.fromarray((arr[y0:y1,x0:x1]*255).astype(np.uint8)).resize((cw,ch),Image.BOX)
    return np.array(im)/255.
sm=small(m); sal=small(alpha)>0.5
body=sa[...,3]>0
best=None
for dx in range(0,W-cw+1):
    for dy in (0,1,2):
        sub=np.zeros((H,W),bool); sub[dy:dy+ch,dx:dx+cw]=sal[:min(ch,H-dy)]
        sc2=(sub&body).sum()/ (sub|body).sum()
        if best is None or sc2>best[0]: best=(sc2,dx,dy)
print('align',best)
_,dx,dy=best
full=np.zeros((H,W)); full[dy:dy+ch,dx:dx+cw]=sm[:min(ch,H-dy)]
hexc=lambda h:tuple(int(h[i:i+2],16) for i in (0,2,4))
S=hexc(skin);L=hexc(line)
hip=int(H*float(hipf))
cnt=0
for y in range(hip,H-3):
    for x in range(W):
        if body[y,x] and full[y,x]>0.5:
            if (x+y)%4==0 or (x-y)%4==0: sa[y,x,:3]=L
            else: sa[y,x,:3]=S
            cnt+=1
print('painted',cnt)
Image.fromarray(sa).save(root+key+'.png')
