import math
inv=lambda a: math.tan(a)-a
def invinv(v):
    a=0.5
    for _ in range(60): a-= (inv(a)-v)/(math.tan(a)**2)
    return a
al=math.radians(20)
def geo(z,m,x,b,ha=1.0,j=0.0):
    r=m*z/2; rb=r*math.cos(al)
    # working pressure angle for zero-backlash mesh of two equal gears with shift x
    aw=invinv(2*x*math.tan(al)/z+inv(al))  # 2*(x1+x2)/(z1+z2) tan = 2*2x/(2z)
    a=2*r*math.cos(al)/math.cos(aw)
    ra=r+m*(ha+x); rf=r-m*(1.25-x)
    c=a-ra-rf
    pb=math.pi*m*math.cos(al)
    rw=a/2
    eps=(2*math.sqrt(ra**2-rb**2)-2*rw*math.sin(aw))/pb
    V=2*math.pi*b*(ra**2-rw**2-pb**2/12)
    # tip thickness
    s=m*(math.pi/2+2*x*math.tan(al))
    aa=math.acos(rb/ra)
    sa=2*ra*(s/(2*r)+inv(al)-inv(aa))
    zmin=2/math.sin(al)**2
    xmin=(zmin-z)/zmin
    dq=math.pi**2*rb**2/ (4*(ra**2-rw**2)) if 0 else None
    # flow ripple (Ivantysyn): delta = (pb^2/4)/(ra^2-rw^2 - pb^2/12)  peak-to-peak/mean
    rip=(pb**2/4)/(ra**2-rw**2-pb**2/12)
    return dict(a=a,aw=math.degrees(aw),ra=ra,rf=rf,c=c,eps=eps,V=V,sa=sa,xmin=xmin,rip=rip,rw=rw,rb=rb)
if __name__=="__main__":
 for z in (10,11,12,13,14):
  for m in (1.5,1.75,2.0,2.25,2.5):
    for x in (0.2,0.3,0.4,0.5):
      for ha in (1.0,0.95,0.9):
        g=geo(z,m,x,1,ha)
        b=8000/g['V']
        if g['c']<0.2*m*0.5 or g['eps']<1.1 or g['sa']<0.3*m or x<g['xmin']: continue
        print(z,m,x,ha,'b=%.2f a=%.3f ra=%.3f rf=%.3f c=%.3f eps=%.3f sa/m=%.2f rip=%.3f'%(b,g['a'],g['ra'],g['rf'],g['c'],g['eps'],g['sa']/m,g['rip']))
