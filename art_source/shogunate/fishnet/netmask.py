import sys, numpy as np
from PIL import Image
from PIL import ImageFilter
class ndi:
    @staticmethod
    def uniform_filter(x,n):
        r=n//2; p=np.pad(x,r,mode='edge'); c=np.cumsum(np.cumsum(np.pad(p,((1,0),(1,0))),0),1)
        h,w=x.shape; return (c[n:n+h,n:n+w]-c[0:h,n:n+w]-c[n:n+h,0:w]+c[0:h,0:w])/(n*n)
    @staticmethod
    def _f(m,size,mode):
        im=Image.fromarray((m*255).astype(np.uint8)).filter(mode(size))
        return np.array(im)>127
    @staticmethod
    def binary_opening(m,iterations=1):
        return ndi._f(ndi._f(m,2*iterations+1,ImageFilter.MinFilter),2*iterations+1,ImageFilter.MaxFilter)
    @staticmethod
    def binary_closing(m,iterations=1):
        return ndi._f(ndi._f(m,2*iterations+1,ImageFilter.MaxFilter),2*iterations+1,ImageFilter.MinFilter)
def netmask(src, k):
    """hi-res mask of fishnet: dense high-contrast fine texture, opaque."""
    im=Image.open(src).convert('RGBA'); a=np.array(im).astype(float)
    alpha=a[...,3]>128
    L=a[...,:3].mean(2)/255
    # fine dark lines: pixels darker than local 9x9 mean by margin
    loc=ndi.uniform_filter(L,9)
    dark=((loc-L)>0.12)&alpha
    dens=ndi.uniform_filter(dark.astype(float),15)
    m=(dens>0.14)&alpha
    m=ndi.binary_opening(m,iterations=2); m=ndi.binary_closing(m,iterations=4)
    return m,alpha
if __name__=='__main__':
    m,al=netmask(sys.argv[1],0)
    im=Image.open(sys.argv[1]).convert('RGBA'); a=np.array(im)
    a[m]=(a[m]*0.4+np.array([255,0,255,255])*0.6).astype(np.uint8)
    Image.fromarray(a).resize((512,512)).save(sys.argv[2])
