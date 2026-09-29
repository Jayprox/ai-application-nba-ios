import math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2048
k = S / 1024
def U(v): return v * k

yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)

# ---------- background: dark arena, navy haze ----------
cx, cy = U(512), U(360)
d = np.clip(np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (S * 0.8), 0, 1)
inner = np.array([12, 40, 100], np.float32); outer = np.array([2, 7, 24], np.float32)
bg = inner * (1 - d[..., None]) + outer * d[..., None]
img = Image.fromarray(bg.astype(np.uint8), 'RGB').convert('RGBA')

def glow(base, layer, radius, strength=1.0):
    g = layer.filter(ImageFilter.GaussianBlur(radius))
    if strength != 1.0:
        a = np.array(g).astype(np.float32); a[..., 3] = np.clip(a[..., 3] * strength, 0, 255)
        g = Image.fromarray(a.astype(np.uint8), 'RGBA')
    base.alpha_composite(g)

# arena lights (top corners): bright cores with a wide bloom
def bloom(base, centers, core_r, bloom_r, color):
    arr = np.zeros((S, S), np.float32)
    for (lx, ly) in centers:
        dd2 = ((xx - U(lx)) ** 2 + (yy - U(ly)) ** 2)
        arr += np.exp(-dd2 / (2 * (U(bloom_r) ** 2))) * 0.32
        arr += np.clip((U(core_r) - np.sqrt(dd2)) / U(1.5), 0, 1)
    arr = np.clip(arr, 0, 1)
    layer = np.zeros((S, S, 4), np.float32)
    layer[..., :3] = color; layer[..., 3] = arr * 255
    base.alpha_composite(Image.fromarray(layer.astype(np.uint8), 'RGBA'))
left = [(78, 118), (116, 108), (154, 116), (96, 150), (134, 148)]
right = [(870, 116), (908, 108), (946, 118), (890, 148), (928, 150)]
bloom(img, left + right, 8, 15, (225, 238, 255))
bloom(img, [(116, 130), (908, 130)], 0, 62, (70, 130, 255))
# light beams / haze
haze = Image.new('RGBA', (S, S), (0, 0, 0, 0)); hd = ImageDraw.Draw(haze)
hd.polygon([(U(60), U(130)), (U(160), U(130)), (U(420), U(700)), (U(150), U(700))], fill=(80, 140, 255, 40))
hd.polygon([(U(860), U(130)), (U(960), U(130)), (U(880), U(700)), (U(610), U(700))], fill=(80, 140, 255, 40))
img.alpha_composite(haze.filter(ImageFilter.GaussianBlur(U(40))))

# ---------- hoop geometry ----------
RCX, RCY = U(470), U(478)   # rim center
RX, RY = U(318), U(62)      # rim ellipse radii
NET_H = U(420)              # net depth
NET_BOTTOM_RX = U(165)

def net_point(phi, s):
    r = RX + (NET_BOTTOM_RX - RX) * s
    ry = r * (RY / RX)
    return (RCX + r * math.cos(phi), RCY + s * NET_H + ry * math.sin(phi))

def net_layer(front):
    layer = Image.new('RGBA', (S, S), (0, 0, 0, 0)); nd = ImageDraw.Draw(layer)
    N = 16; twist = 0.62
    col = (238, 242, 248, 255) if front else (150, 165, 190, 170)
    w = int(U(5.5) if front else U(4))
    for kk in range(N):
        for sign in (1, -1):
            pts = []
            for i in range(0, 61):
                s_ = i / 60
                phi = 2 * math.pi * kk / N + sign * twist * s_ * 2.2
                is_front = math.sin(phi) > 0
                if is_front == front:
                    pts.append(net_point(phi, s_))
                else:
                    if len(pts) > 1: nd.line(pts, fill=col, width=w, joint='curve')
                    pts = []
            if len(pts) > 1: nd.line(pts, fill=col, width=w, joint='curve')
    # horizontal knot rows (small shading dots where strands cross)
    return layer

# back half of the net and back of the rim go BEHIND the ball
back_net = net_layer(False)
img.alpha_composite(back_net.filter(ImageFilter.GaussianBlur(U(0.8))))

def rim_arc(front):
    layer = Image.new('RGBA', (S, S), (0, 0, 0, 0)); rd = ImageDraw.Draw(layer)
    box = [RCX - RX, RCY - RY, RCX + RX, RCY + RY]
    thick = int(U(22))
    if front:
        rd.arc(box, 0, 180, fill=(236, 84, 34, 255), width=thick)
        # highlight along the top edge of the front arc
        rd.arc([box[0] + U(4), box[1] - U(4), box[2] - U(4), box[3] - U(6)], 20, 160, fill=(255, 170, 120, 170), width=int(U(5)))
    else:
        rd.arc(box, 180, 360, fill=(186, 56, 22, 255), width=thick)
    return layer
img.alpha_composite(rim_arc(False))

# ---------- ball (3D shaded, pebbled, true seams) ----------
BCX, BCY, BR = U(470), U(318), U(262)
halo = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(halo).ellipse([BCX - BR - U(6), BCY - BR - U(6), BCX + BR + U(6), BCY + BR + U(6)], fill=(40, 120, 255, 220))
glow(img, halo, U(28), 1.1)

X = (xx - BCX) / BR; Y = (yy - BCY) / BR
R2 = X * X + Y * Y; inside = R2 <= 1.0
Z = np.sqrt(np.clip(1 - R2, 0, 1))
L = np.array([-0.5, -0.65, 0.57]); L /= np.linalg.norm(L)
lam = np.clip(X * L[0] + Y * L[1] + Z * L[2], 0, 1)
light = np.array([255, 132, 44], np.float32); dark = np.array([150, 44, 8], np.float32)
shade = (0.18 + 0.82 * lam ** 0.8)[..., None]
col = dark * (1 - shade) + light * shade

rng = np.random.default_rng(7)
peb = np.zeros((S, S), np.float32)
n = 150000
peb[rng.integers(0, S, n), rng.integers(0, S, n)] = 1.0
pimg = Image.fromarray((peb * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1.5))
bump = np.array(pimg).astype(np.float32) / 255.0
gy, gx = np.gradient(bump)
bshade = -(gx * L[0] + gy * L[1]) * 6.0
col = col * (1 + np.clip(bshade, -0.35, 0.35)[..., None] * (0.35 + 0.65 * lam[..., None]))
col = col * (1 - 0.10 * bump[..., None]) + np.array([255, 170, 110], np.float32) * (0.06 * bump[..., None] * lam[..., None])
H = L + np.array([0, 0, 1.0]); H /= np.linalg.norm(H)
spec = np.clip(X * H[0] + Y * H[1] + Z * H[2], 0, 1) ** 18
col = col + (spec * 45)[..., None]
rim = np.clip(1 - Z, 0, 1) ** 2.2 * np.clip(-X * 0.5 - Y * 0.6 + 0.35, 0, 1)
col = col * (1 - rim[..., None] * 0.7) + np.array([70, 150, 255], np.float32) * rim[..., None] * 0.7

def rot(ax, ay, az):
    ax, ay, az = map(math.radians, (ax, ay, az))
    Rx = np.array([[1, 0, 0], [0, math.cos(ax), -math.sin(ax)], [0, math.sin(ax), math.cos(ax)]])
    Ry = np.array([[math.cos(ay), 0, math.sin(ay)], [0, 1, 0], [-math.sin(ay), 0, math.cos(ay)]])
    Rz = np.array([[math.cos(az), -math.sin(az), 0], [math.sin(az), math.cos(az), 0], [0, 0, 1]])
    return Rz @ Ry @ Rx
Rm = rot(-18, 28, -14)
O = np.stack([X, Y, Z], -1) @ Rm
ox, oy, oz = O[..., 0], O[..., 1], O[..., 2]
theta = np.arctan2(oz, oy)
D0, A0 = 0.66, 0.08
dist = np.minimum(np.minimum(np.abs(oy), np.abs(ox)),
                  np.minimum(np.abs(ox - (D0 + A0 * np.cos(2 * theta))), np.abs(ox + (D0 + A0 * np.cos(2 * theta)))))
w = 0.032; px_ = 1.0 / BR
seam = np.clip((w - dist) / (1.5 * px_ / np.maximum(Z, 0.15)) + 0.5, 0, 1)
groove = np.clip((w * 2.2 - dist) / (w * 1.2), 0, 1)
col = col * (1 - 0.22 * groove[..., None])
col = col * (1 - seam[..., None]) + np.array([22, 12, 8], np.float32) * seam[..., None]

ball = np.zeros((S, S, 4), np.float32); ball[..., :3] = np.clip(col, 0, 255); ball[..., 3] = inside * 255
ball_img = Image.fromarray(ball.astype(np.uint8), 'RGBA')
emask = Image.new('L', (S, S), 0); ImageDraw.Draw(emask).ellipse([BCX - BR, BCY - BR, BCX + BR, BCY + BR], fill=255)
ball_img.putalpha(emask.filter(ImageFilter.GaussianBlur(1.0)))
img.alpha_composite(ball_img)

# shadow the part of the ball that is inside the hoop (below the rim plane), then front rim + front net
below = Image.new('L', (S, S), 0)
ImageDraw.Draw(below).rectangle([0, RCY, S, S], fill=120)
below = Image.fromarray((np.array(below).astype(np.float32) * (np.array(emask) / 255.0)).astype(np.uint8)).filter(ImageFilter.GaussianBlur(U(18)))
img.alpha_composite(Image.merge('RGBA', (Image.new('L', (S, S), 0),) * 3 + (below,)))

front_net = net_layer(True)
shadow = front_net.filter(ImageFilter.GaussianBlur(U(3)))
sa = np.array(shadow).astype(np.float32); sa[..., :3] = 0; sa[..., 3] *= 0.5
img.alpha_composite(Image.fromarray(sa.astype(np.uint8), 'RGBA'), (int(U(3)), int(U(4))))
img.alpha_composite(front_net.filter(ImageFilter.GaussianBlur(U(0.6))))
img.alpha_composite(rim_arc(True))

# ---------- bars + arrow (bottom right, glowing) ----------
bars = [(612, 842, 78), (706, 790, 78), (800, 724, 78), (894, 640, 78)]
base_y = U(958)
bar_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
for (x, top, w_) in bars:
    x0, y0 = int(U(x)), int(U(top)); wpx = int(U(w_)); h = int(base_y - y0)
    tt = np.linspace(0, 1, h)[:, None, None]
    ctop = np.array([40, 230, 255], np.float32); cbot = np.array([20, 80, 255], np.float32)
    g = np.zeros((h, wpx, 4), np.float32)
    g[..., :3] = ctop * (1 - tt) + cbot * tt; g[..., 3] = 255
    gi = Image.fromarray(g.astype(np.uint8), 'RGBA')
    m = Image.new('L', gi.size, 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, wpx - 1, h - 1], radius=int(U(11)), fill=255)
    gi.putalpha(m); bar_layer.alpha_composite(gi, (x0, y0))
glow(img, bar_layer, U(14), 0.9)
img.alpha_composite(bar_layer)

pts = [(588, 900), (746, 770), (806, 792), (948, 640)]
tip = (1000, 586)
def tapered(points, w0, w1):
    P = [np.array((U(x), U(y))) for x, y in points]
    lens = [np.linalg.norm(b - a) for a, b in zip(P, P[1:])]; total = sum(lens); acc = 0; left = []; right = []
    for i, p in enumerate(P):
        if i == 0: dv = P[1] - P[0]
        elif i == len(P) - 1: dv = P[-1] - P[-2]
        else: dv = (P[i + 1] - P[i]) / np.linalg.norm(P[i + 1] - P[i]) + (P[i] - P[i - 1]) / np.linalg.norm(P[i] - P[i - 1])
        dv = dv / np.linalg.norm(dv); nrm = np.array([-dv[1], dv[0]])
        ww = U(w0 + (w1 - w0) * acc / total) / 2
        left.append(tuple(p + nrm * ww)); right.append(tuple(p - nrm * ww))
        if i < len(lens): acc += lens[i]
    return left + right[::-1]
arrow = Image.new('RGBA', (S, S), (0, 0, 0, 0)); ad = ImageDraw.Draw(arrow)
red = (255, 58, 72, 255)
ad.polygon(tapered(pts, 5, 30), fill=red)
hx, hy = U(tip[0]), U(tip[1]); bx, by = U(pts[-1][0]), U(pts[-1][1])
ang = math.atan2(hy - by, hx - bx); hl = U(70); hw = U(40)
back = (hx - math.cos(ang) * hl, hy - math.sin(ang) * hl)
ad.polygon([(hx, hy), (back[0] + math.cos(ang + math.pi / 2) * hw, back[1] + math.sin(ang + math.pi / 2) * hw),
            (back[0] + math.cos(ang - math.pi / 2) * hw, back[1] + math.sin(ang - math.pi / 2) * hw)], fill=red)
glow(img, arrow, U(12), 1.0)
img.alpha_composite(arrow)

out = img.convert('RGB').resize((1024, 1024), Image.LANCZOS)
out.save('AppIcon-1024.png')
prev = Image.new('RGB', (1024 + 60 + 180 + 60 + 60 + 90, 1084), (24, 28, 34)); x = 30
for s_ in (1024, 180, 60):
    t_ = out.resize((s_, s_), Image.LANCZOS)
    m = Image.new('L', (s_, s_), 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, s_ - 1, s_ - 1], radius=int(s_ * 0.2237), fill=255)
    prev.paste(t_, (x, 30), m); x += s_ + 60
prev.save('preview.png')
