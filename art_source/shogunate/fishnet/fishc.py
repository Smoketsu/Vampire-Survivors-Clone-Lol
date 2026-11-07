"""color mode: fishnet on every pixel of the skin colour below a row. usage: fishc.py key skinhex minrow fillhex linehex"""
import sys, numpy as np
from PIL import Image
key,skin,minrow,fill,line=sys.argv[1:6]
root='assets/sprites/'
im=Image.open(root+key+'.png').convert('RGBA');a=np.array(im)
h=lambda s:tuple(int(s[i:i+2],16) for i in (0,2,4))
n=0
for y in range(int(minrow),a.shape[0]):
    for x in range(a.shape[1]):
        if a[y,x,3] and tuple(a[y,x,:3])==h(skin):
            a[y,x,:3]=h(line) if ((x+y)%4==0 or (x-y)%4==0) else h(fill); n+=1
print(key,n)
Image.fromarray(a).save(root+key+'.png')
