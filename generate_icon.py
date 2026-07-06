"""
Generate a unique Arete app icon:
- Deep purple/indigo gradient background
- Gold rising bar chart (data science theme)
- Bold white 'A' letter (Arete / Greek excellence)
- Teal accent glow
"""
from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 1024
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── Background: deep purple gradient ─────────────────────────────────────────
for y in range(SIZE):
    t = y / SIZE
    r = int(10 + t * 20)
    g = int(10 + t * 5)
    b = int(40 + t * 30)
    draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# ── Rounded rectangle mask (app icon shape) ──────────────────────────────────
radius = 200
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=radius, fill=255)
img.putalpha(mask)

# ── Redraw background with rounded corners applied ───────────────────────────
bg = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
bg_draw = ImageDraw.Draw(bg)
for y in range(SIZE):
    t = y / SIZE
    r = int(15 + t * 15)
    g = int(8 + t * 8)
    b = int(45 + t * 25)
    bg_draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))
bg.putalpha(mask)
img = bg

draw = ImageDraw.Draw(img)

# ── Gold glow circle (centre halo) ───────────────────────────────────────────
for r in range(280, 0, -1):
    alpha = int(30 * (1 - r / 280))
    draw.ellipse(
        [SIZE//2 - r, SIZE//2 - r + 60, SIZE//2 + r, SIZE//2 + r + 60],
        fill=(255, 200, 0, alpha)
    )

# ── Rising bar chart (data science motif) ────────────────────────────────────
bars = [
    (0.15, 0.55, 0.28, 0.82),   # x1, y1, x2, y2  (fractions of SIZE)
    (0.31, 0.42, 0.44, 0.82),
    (0.47, 0.28, 0.60, 0.82),
    (0.63, 0.14, 0.76, 0.82),
]
gold = (255, 210, 0)
teal = (0, 212, 170)
bar_colors = [
    (255, 180, 0, 180),
    (255, 200, 0, 200),
    (255, 215, 0, 220),
    (0, 212, 170, 230),   # last bar teal accent
]
for (x1, y1, x2, y2), color in zip(bars, bar_colors):
    bx1, by1 = int(x1 * SIZE), int(y1 * SIZE)
    bx2, by2 = int(x2 * SIZE), int(y2 * SIZE)
    draw.rounded_rectangle([bx1, by1, bx2, by2], radius=18, fill=color)

# ── Trend line over bars ──────────────────────────────────────────────────────
points = []
for (x1, y1, x2, y2) in bars:
    cx = (x1 + x2) / 2 * SIZE
    cy = y1 * SIZE - 20
    points.append((cx, cy))

for i in range(len(points) - 1):
    draw.line([points[i], points[i+1]], fill=(255, 255, 255, 180), width=8)

# Dots on the trend line
for pt in points:
    r = 14
    draw.ellipse([pt[0]-r, pt[1]-r, pt[0]+r, pt[1]+r], fill=(255, 255, 255, 230))

# ── Bold 'A' lettermark (bottom centre, subtle) ──────────────────────────────
try:
    font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 180)
except:
    font = ImageFont.load_default()

text = "A"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
tx = (SIZE - tw) // 2 - bbox[0]
ty = SIZE - th - 60 - bbox[1]

# Shadow
draw.text((tx + 4, ty + 4), text, font=font, fill=(0, 0, 0, 100))
# White letter
draw.text((tx, ty), text, font=font, fill=(255, 255, 255, 200))

# ── Save ─────────────────────────────────────────────────────────────────────
img.save("assets/icon/app_icon.png")
print("Icon saved to assets/icon/app_icon.png")
