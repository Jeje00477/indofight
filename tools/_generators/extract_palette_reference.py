import sys, os
from PIL import Image, ImageDraw
import numpy as np
from collections import deque
src, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)
im = Image.open(src).convert('RGB')
boxes = {
 'mahasiswa':(90,10,455,205),
 'jenderal-gemoy':(650,10,870,205),
 'gatot-kaca':(25,205,470,410),
 'emak-emak':(475,205,640,410),
 'intel-bakso':(25,410,495,610),
 'kuli-jawa':(515,410,790,610),
 'abang-ojol':(20,610,400,815),
 'dukun-santet':(565,610,965,815),
 'pocong-brawler':(60,815,455,1024),
 'bocah-warnet':(530,815,950,1024),
}
K = 64
MAXC = 20
TH = 13
results = {}
for name,b in boxes.items():
    a = np.array(im.crop(b)).astype(int)
    h,w,_ = a.shape
    nearwhite = (a.min(axis=2) > 238)
    bg = np.zeros((h,w),bool)
    q = deque()
    for x in range(w):
        for y in (0,h-1):
            if nearwhite[y,x] and not bg[y,x]: bg[y,x]=True; q.append((y,x))
    for y in range(h):
        for x in (0,w-1):
            if nearwhite[y,x] and not bg[y,x]: bg[y,x]=True; q.append((y,x))
    while q:
        y,x = q.popleft()
        for dy,dx in ((1,0),(-1,0),(0,1),(0,-1)):
            ny,nx=y+dy,x+dx
            if 0<=ny<h and 0<=nx<w and nearwhite[ny,nx] and not bg[ny,nx]:
                bg[ny,nx]=True; q.append((ny,nx))
    px = a[~bg].astype(np.uint8)
    pim = Image.fromarray(px.reshape(-1,1,3))
    qim = pim.quantize(colors=K, method=Image.Quantize.MEDIANCUT)
    pal = qim.getpalette()[:K*3]
    counts = sorted(qim.getcolors(), reverse=True)
    cols = []
    for c,i in counts:
        rgb = tuple(pal[i*3:i*3+3])
        cols.append((rgb,c))
    def dist(c1,c2):
        rm=(c1[0]+c2[0])/2
        dr,dg,db=c1[0]-c2[0],c1[1]-c2[1],c1[2]-c2[2]
        return ((2+rm/256)*dr*dr+4*dg*dg+(2+(255-rm)/256)*db*db)**0.5/3
    kept=[]
    for rgb,c in cols:
        if all(dist(rgb,k[0])>=TH for k in kept): kept.append((rgb,c))
        if len(kept)>=MAXC: break
    cols=kept
    cols.sort(key=lambda t: 0.299*t[0][0]+0.587*t[0][1]+0.114*t[0][2])
    ACC={'mahasiswa':['e23b3b'],'intel-bakso':['ff2a2a'],'pocong-brawler':['ff5a3c','ffd23f'],'bocah-warnet':['ff2bd6','2bf0ff','7dff3a'],'gatot-kaca':['ffe066'],'jenderal-gemoy':['d8dde3']}
    for hx in ACC.get(name,[]):
        cols.append((tuple(int(hx[j:j+2],16) for j in (0,2,4)),0))
    hexes = ['%02x%02x%02x'%c for c,_ in cols]
    results[name]=hexes
    with open(f'{outdir}/{name}.hex','w') as f: f.write('\n'.join(hexes)+'\n')
    with open(f'{outdir}/{name}.gpl','w') as f:
        f.write(f'GIMP Palette\nName: IndoFight {name}\nColumns: 10\n#\n')
        for (r,g,bb),_ in cols: f.write(f'{r:3d} {g:3d} {bb:3d}\t{"%02x%02x%02x"%(r,g,bb)}\n')
# preview
sw=28; rows=len(results)
prev = Image.new('RGB',(170+sw*(MAXC+3), rows*sw+10),(255,255,255))
d=ImageDraw.Draw(prev)
for r,(name,hexes) in enumerate(results.items()):
    d.text((6,r*sw+12),name,fill=(0,0,0))
    for i,hx in enumerate(hexes):
        c=tuple(int(hx[j:j+2],16) for j in (0,2,4))
        d.rectangle((160+i*sw, r*sw+5, 160+i*sw+sw-2, r*sw+5+sw-2), fill=c)
prev.save(f'{outdir}/_preview_palettes.png')
print('ok', {k:len(v) for k,v in results.items()})
