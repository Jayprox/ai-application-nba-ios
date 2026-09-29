from PIL import Image, ImageDraw, ImageFilter
import math
S=2048  # supersample, downscale to 1024
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
def vgrad(top,bottom):
    im=Image.new('RGB',(S,S)); d=ImageDraw.Draw(im)
    for y in range(S): d.line([(0,y),(S,y)],fill=lerp(top,bottom,y/S))
    return im
def radial_ball(size, light, dark):
    im=Image.new('RGB',(size,size),dark); px=im.load()
    cx,cy=size*0.35,size*0.3
    for y in range(size):
        for x in range(size):
            dd=math.hypot(x-cx,y-cy)/(size*0.95)
            px[x,y]=lerp(light,dark,min(1,dd))
    return im
def ball(img, cx, cy, r, light=(247,140,60), dark=(170,62,14), seam=(22,16,14), sw=None, rot=0):
    size=int(r*2)
    b=radial_ball(size//4,light,dark).resize((size,size),Image.BICUBIC)
    mask=Image.new('L',(size,size),0); ImageDraw.Draw(mask).ellipse([0,0,size-1,size-1],fill=255)
    layer=Image.new('RGBA',(size,size),(0,0,0,0)); layer.paste(b,(0,0),mask)
    d=ImageDraw.Draw(layer); sw=sw or max(6,int(r*0.055))
    # seams: vertical, horizontal, two side curves
    d.line([(r,0),(r,size)],fill=seam,width=sw)
    d.line([(0,r),(size,r)],fill=seam,width=sw)
    d.arc([-r*0.95,r*0.05,r*0.95,size-r*0.05],-62,62,fill=seam,width=sw)
    d.arc([r*1.05,r*0.05,size+r*0.95,size-r*0.05],118,242,fill=seam,width=sw)
    m2=Image.new('L',(size,size),0); ImageDraw.Draw(m2).ellipse([0,0,size-1,size-1],fill=255)
    layer.putalpha(Image.composite(layer.getchannel('A'),Image.new('L',(size,size),0),m2))
    if rot: layer=layer.rotate(rot,resample=Image.BICUBIC)
    img.paste(layer,(int(cx-r),int(cy-r)),layer)
def bars(d, x0, base, w, gap, heights, color, radius=24):
    for i,h in enumerate(heights):
        x=x0+i*(w+gap); d.rounded_rectangle([x,base-h,x+w,base],radius=radius,fill=color)
def arrow(d, pts, color, width, head=110):
    d.line(pts,fill=color,width=width,joint='curve')
    (x1,y1),(x2,y2)=pts[-2],pts[-1]; a=math.atan2(y2-y1,x2-x1)
    tip=(x2+math.cos(a)*head*0.6,y2+math.sin(a)*head*0.6)
    l=(x2+math.cos(a+2.5)*head,y2+math.sin(a+2.5)*head); rr=(x2+math.cos(a-2.5)*head,y2+math.sin(a-2.5)*head)
    d.polygon([tip,l,rr],fill=color)
def save(img,name):
    img.resize((1024,1024),Image.LANCZOS).convert('RGB').save(name)

ORANGE=(244,118,43); INK=(245,247,250); PAPER=(11,15,20); GREEN=(52,211,153); RED=(242,84,91)

# A: family match with NFL (navy gradient, ball upper-left, green bars, red arrow)
im=vgrad((16,34,66),(6,12,26)); d=ImageDraw.Draw(im)
ball(im,780,760,640,rot=-18)
bars(d,660,1990,250,70,[330,520,720,960],GREEN,34)
arrow(d,[(620,1780),(1100,1350),(1300,1470),(1900,760)],RED,70,190)
save(im,'A_family_navy_bars.png')

# B: app palette — paper bg, orange ball, white uptick through it
im=Image.new('RGB',(S,S),PAPER); d=ImageDraw.Draw(im)
ball(im,1024,1024,720)
d2=ImageDraw.Draw(im)
arrow(d2,[(330,1480),(820,1060),(1080,1250),(1700,560)],INK,110,230)
save(im,'B_paper_ball_uptick.png')

# C: chalkboard — dark slate, chalk-line ball + chalk bars
im=vgrad((30,40,38),(16,22,22)); d=ImageDraw.Draw(im)
cw=(236,238,232); r=560; cx,cy=820,860; sw=46
d.ellipse([cx-r,cy-r,cx+r,cy+r],outline=cw,width=sw)
d.line([(cx,cy-r),(cx,cy+r)],fill=cw,width=sw); d.line([(cx-r,cy),(cx+r,cy)],fill=cw,width=sw)
d.arc([cx-r-r*0.95,cy-r*0.95,cx-r+r*0.95,cy+r*0.95],-62,62,fill=cw,width=sw)
d.arc([cx+r-r*0.95,cy-r*0.95,cx+r+r*0.95,cy+r*0.95],118,242,fill=cw,width=sw)
bars(d,1180,1900,150,50,[260,420,600],ORANGE,20)
save(im,'C_chalkboard_lines.png')

# D: orange bg, dark ball, white bars
im=vgrad((250,138,70),(226,96,26)); d=ImageDraw.Draw(im)
ball(im,1024,900,650,light=(40,48,60),dark=(11,15,20),seam=ORANGE)
bars(d,380,1860,240,80,[260,420,600,800,0][:4],INK,30)
save(im,'D_orange_dark_ball.png')

# E: paper bg, ball as the top of the tallest bar
im=Image.new('RGB',(S,S),PAPER); d=ImageDraw.Draw(im)
bars(d,300,1800,300,110,[380,640,900],(40,52,64),40)
d.rounded_rectangle([300+2*410,1800-900,300+2*410+300,1800],radius=40,fill=ORANGE)
ball(im,300+2*410+150+80,560,330)
d.line([(240,1800),(1808,1800)],fill=(98,113,125),width=24)
save(im,'E_ball_on_top_bar.png')

names=['A_family_navy_bars','B_paper_ball_uptick','C_chalkboard_lines','D_orange_dark_ball','E_ball_on_top_bar']
sheet=Image.new('RGB',(5*420+60,560),(24,28,34)); sd=ImageDraw.Draw(sheet)
for i,n in enumerate(names):
    t=Image.open(n+'.png').resize((380,380),Image.LANCZOS)
    m=Image.new('L',(380,380),0); ImageDraw.Draw(m).rounded_rectangle([0,0,379,379],radius=86,fill=255)
    sheet.paste(t,(40+i*420,40),m)
    sm=Image.open(n+'.png').resize((60,60),Image.LANCZOS)
    m2=Image.new('L',(60,60),0); ImageDraw.Draw(m2).rounded_rectangle([0,0,59,59],radius=14,fill=255)
    sheet.paste(sm,(40+i*420,450),m2)
    sd.text((120+i*420,470),n.split('_')[0],fill=(245,247,250))
sheet.save('overview.png')
