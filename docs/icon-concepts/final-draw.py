import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 2048
k = S / 1024  # layout in 1024 units

def U(v): return v * k

# ---------- background: radial navy ----------
yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
cx, cy = U(470), U(420)
d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (S * 0.85)
d = np.clip(d, 0, 1)
inner = np.array([8, 36, 104], np.float32)
outer = np.array([1, 7, 28], np.float32)
bg = inner[None, None, :] * (1 - d[..., None]) + outer[None, None, :] * d[..., None]
img = Image.fromarray(bg.astype(np.uint8), 'RGB').convert('RGBA')

def add_glow(base, layer, radius, strength=1.0):
    g = layer.filter(ImageFilter.GaussianBlur(radius))
    if strength != 1.0:
        a = np.array(g).astype(np.float32); a[..., 3] *= strength
        g = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), 'RGBA')
    base.alpha_composite(g)

# ---------- ball (3D shaded, with physically placed seams) ----------
BCX, BCY, BR = U(452), U(440), U(330)

# ball halo (blue rim glow, as in the source art)
halo = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ImageDraw.Draw(halo).ellipse([BCX - BR - U(6), BCY - BR - U(6), BCX + BR + U(6), BCY + BR + U(6)], fill=(40, 120, 255, 230))
add_glow(img, halo, U(30), 1.2)

# sphere normals
X = (xx - BCX) / BR
Y = (yy - BCY) / BR
R2 = X * X + Y * Y
inside = R2 <= 1.0
Z = np.sqrt(np.clip(1 - R2, 0, 1))

# light from upper-left-front
L = np.array([-0.55, -0.62, 0.56]); L /= np.linalg.norm(L)
lam = np.clip(X * L[0] + Y * L[1] + Z * L[2], 0, 1)
base_light = np.array([255, 132, 44], np.float32)
base_dark = np.array([150, 44, 8], np.float32)
shade = (0.18 + 0.82 * lam ** 0.8)[..., None]
col = base_dark * (1 - shade) + base_light * shade

# pebbled leather: a field of small bumps, bump-mapped against the light
rng = np.random.default_rng(7)
peb = np.zeros((S, S), np.float32)
pts_n = 150000
px_ = rng.integers(0, S, pts_n); py_ = rng.integers(0, S, pts_n)
peb[py_, px_] = 1.0
pimg = Image.fromarray((peb * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1.5))
bump = np.array(pimg).astype(np.float32) / 255.0
gy, gx = np.gradient(bump)
bshade = -(gx * L[0] + gy * L[1]) * 6.0
col = col * (1 + np.clip(bshade, -0.35, 0.35)[..., None] * (0.35 + 0.65 * lam[..., None]))
col = col * (1 - 0.10 * bump[..., None]) + np.array([255, 170, 110], np.float32) * (0.06 * bump[..., None] * lam[..., None])
# specular highlight
H = L + np.array([0, 0, 1.0]); H /= np.linalg.norm(H)
spec = np.clip(X * H[0] + Y * H[1] + Z * H[2], 0, 1) ** 18
col = col + (spec * 45)[..., None]

# rim light (blue, left side) like the source
rim = np.clip(1 - Z, 0, 1) ** 2.2 * np.clip(-X * 0.8 - Y * 0.3 + 0.35, 0, 1)
col = col * (1 - rim[..., None] * 0.75) + np.array([70, 150, 255], np.float32) * rim[..., None] * 0.75

ball = np.zeros((S, S, 4), np.float32)
ball[..., :3] = np.clip(col, 0, 255)
ball[..., 3] = inside * 255.0
# antialias edge
ball_img = Image.fromarray(ball.astype(np.uint8), 'RGBA')
edge_mask = Image.new('L', (S, S), 0)
ImageDraw.Draw(edge_mask).ellipse([BCX - BR, BCY - BR, BCX + BR, BCY + BR], fill=255)
ball_img.putalpha(edge_mask.filter(ImageFilter.GaussianBlur(1.0)))

# seams: signed distance per pixel in the ball's own coordinates (clean, foreshortened lines)
def rot(ax, ay, az):
    ax, ay, az = map(math.radians, (ax, ay, az))
    Rx = np.array([[1, 0, 0], [0, math.cos(ax), -math.sin(ax)], [0, math.sin(ax), math.cos(ax)]])
    Ry = np.array([[math.cos(ay), 0, math.sin(ay)], [0, 1, 0], [-math.sin(ay), 0, math.cos(ay)]])
    Rz = np.array([[math.cos(az), -math.sin(az), 0], [math.sin(az), math.cos(az), 0], [0, 0, 1]])
    return Rz @ Ry @ Rx
Rm = rot(-22, 32, -24)
P = np.stack([X, Y, Z], -1)
O = P @ Rm            # view -> object coords (Rm is orthonormal, so P @ Rm == Rm^T P)
ox, oy, oz = O[..., 0], O[..., 1], O[..., 2]
theta = np.arctan2(oz, oy)
d_eq = np.abs(oy)                                  # great circle 1
d_mer = np.abs(ox)                                 # great circle 2
D0, A0 = 0.66, 0.08
d_c1 = np.abs(ox - (D0 + A0 * np.cos(2 * theta)))  # curved seams around (+-1, 0, 0)
d_c2 = np.abs(ox + (D0 + A0 * np.cos(2 * theta)))
dist = np.minimum(np.minimum(d_eq, d_mer), np.minimum(d_c1, d_c2))
w = 0.030                                          # seam half-width on the unit sphere
px_ = 1.0 / BR                                     # one pixel in sphere units (for antialiasing)
seam = np.clip((w - dist) / (1.5 * px_ / np.maximum(Z, 0.15)) + 0.5, 0, 1)
groove = np.clip((w * 2.2 - dist) / (w * 1.2), 0, 1)   # soft channel darkening beside each seam
arr = np.array(ball_img).astype(np.float32)
arr[..., :3] *= (1 - 0.22 * groove[..., None])
seam_col = np.array([22, 12, 8], np.float32)
arr[..., :3] = arr[..., :3] * (1 - seam[..., None]) + seam_col * seam[..., None]
ball_img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), 'RGBA')
ball_img.putalpha(edge_mask.filter(ImageFilter.GaussianBlur(1.0)))
img.alpha_composite(ball_img)

# ---------- bars (cyan -> blue, glowing) ----------
bars = [(372, 800, 160), (562, 728, 125), (716, 632, 120), (862, 505, 106)]
base_y = U(952)
bar_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
for (x, top, w) in bars:
    x0, x1, y0 = U(x), U(x + w), U(top)
    h = int(base_y - y0)
    grad = np.zeros((h, int(x1 - x0), 4), np.float32)
    tt = np.linspace(0, 1, h)[:, None]
    ctop = np.array([40, 230, 255], np.float32); cbot = np.array([20, 80, 255], np.float32)
    grad[..., :3] = (ctop * (1 - tt) + cbot * tt)[:, None, :].repeat(int(x1 - x0), 1).reshape(h, int(x1 - x0), 3)
    grad[..., 3] = 255
    g = Image.fromarray(grad.astype(np.uint8), 'RGBA')
    m = Image.new('L', g.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, g.size[0] - 1, g.size[1] - 1], radius=int(U(14)), fill=255)
    g.putalpha(m)
    bar_layer.alpha_composite(g, (int(x0), int(y0)))
add_glow(img, bar_layer, U(14), 0.9)
img.alpha_composite(bar_layer)

# ---------- arrow (tapered red, glowing) ----------
pts = [(330, 865), (612, 648), (690, 672), (948, 392)]
tip = (1012, 326)
def tapered(points, w0, w1):
    P = [np.array((U(x), U(y))) for x, y in points]
    lens = [np.linalg.norm(b - a) for a, b in zip(P, P[1:])]
    total = sum(lens); acc = 0; left = []; right = []
    for i, p in enumerate(P):
        if i == 0: dvec = P[1] - P[0]
        elif i == len(P) - 1: dvec = P[-1] - P[-2]
        else: dvec = (P[i + 1] - P[i]) / np.linalg.norm(P[i + 1] - P[i]) + (P[i] - P[i - 1]) / np.linalg.norm(P[i] - P[i - 1])
        dvec = dvec / np.linalg.norm(dvec); nrm = np.array([-dvec[1], dvec[0]])
        f = acc / total; w = U(w0 + (w1 - w0) * f) / 2
        left.append(tuple(p + nrm * w)); right.append(tuple(p - nrm * w))
        if i < len(lens): acc += lens[i]
    return left + right[::-1]
arrow_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
ad = ImageDraw.Draw(arrow_layer)
red = (255, 58, 72, 255)
ad.polygon(tapered(pts, 6, 44), fill=red)
# head
hx, hy = U(tip[0]), U(tip[1]); bx, by = U(pts[-1][0]), U(pts[-1][1])
ang = math.atan2(hy - by, hx - bx); hl = U(92); hw = U(52)
back = (hx - math.cos(ang) * hl, hy - math.sin(ang) * hl)
ad.polygon([(hx, hy),
            (back[0] + math.cos(ang + math.pi / 2) * hw, back[1] + math.sin(ang + math.pi / 2) * hw),
            (back[0] + math.cos(ang - math.pi / 2) * hw, back[1] + math.sin(ang - math.pi / 2) * hw)], fill=red)
add_glow(img, arrow_layer, U(12), 1.0)
img.alpha_composite(arrow_layer)
out = img.convert('RGB').resize((1024, 1024), Image.LANCZOS)
out.save('AppIcon-1024.png')

# preview with the iOS mask at 3 sizes
prev = Image.new('RGB', (1024 + 60 + 180 + 60 + 60 + 90, 1084), (24, 28, 34))
x = 30
for s in (1024, 180, 60):
    t_ = out.resize((s, s), Image.LANCZOS)
    m = Image.new('L', (s, s), 0); ImageDraw.Draw(m).rounded_rectangle([0, 0, s - 1, s - 1], radius=int(s * 0.2237), fill=255)
    prev.paste(t_, (x, 30), m); x += s + 60
prev.save('preview.png')
