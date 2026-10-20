# Genera le icone Android da weight.png (manubrio nero su trasparente).
# Uso, dalla radice del progetto:
#   python3 design/icon/make_icon.py design/icon/weight.png android/app/src/main/res
import sys, os
from PIL import Image, ImageDraw
src, res = sys.argv[1], sys.argv[2]
a = Image.open(src).convert('RGBA').split()[3].crop((0,110,512,402))  # alpha = shape
def glyph(w):
    m = a.resize((w, round(w*a.height/a.width)), Image.LANCZOS)
    g = Image.new('RGBA', m.size, (255,255,255,0)); g.putalpha(m); return g
def gradient(s):
    c1, c2 = (0x8B,0x5C,0xF6), (0x63,0x66,0xF1)
    im = Image.new('RGBA', (s,s))
    px = im.load()
    for y in range(s):
        for x in range(s):
            t = (x+y)/(2*(s-1))
            px[x,y] = tuple(round(c1[i]+(c2[i]-c1[i])*t) for i in range(3))+(255,)
    return im
def place(canvas, frac):
    s = canvas.width; g = glyph(round(s*frac))
    canvas.alpha_composite(g, ((s-g.width)//2, (s-g.height)//2)); return canvas
dens = {'mdpi':1,'hdpi':1.5,'xhdpi':2,'xxhdpi':3,'xxxhdpi':4}
for d,k in dens.items():
    out = f'{res}/mipmap-{d}'
    # legacy: rounded square, 4x supersampled
    s = round(48*k); S = s*4
    bg = gradient(S); mask = Image.new('L',(S,S),0)
    ImageDraw.Draw(mask).rounded_rectangle((S*0.04,S*0.04,S*0.96,S*0.96), radius=S*0.22, fill=255)
    bg.putalpha(mask); place(bg, 0.58)
    bg.resize((s,s), Image.LANCZOS).save(f'{out}/ic_launcher.png')
    # round legacy
    S2 = S; bg = gradient(S2); mask = Image.new('L',(S2,S2),0)
    ImageDraw.Draw(mask).ellipse((S2*0.04,S2*0.04,S2*0.96,S2*0.96), fill=255)
    bg.putalpha(mask); place(bg, 0.56)
    bg.resize((s,s), Image.LANCZOS).save(f'{out}/ic_launcher_round.png')
    # adaptive layers (108dp)
    s = round(108*k)
    gradient(s).save(f'{out}/ic_launcher_background.png')
    place(Image.new('RGBA',(s,s),(0,0,0,0)), 0.50).save(f'{out}/ic_launcher_foreground.png')
