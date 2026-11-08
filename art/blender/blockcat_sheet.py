"""One block cat per tier from the approved design table. Run:
blender -b --factory-startup -P art/blender/blockcat_sheet.py -- <pillow path>
Writes art/preview/cats_v1/tier_sample.png.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])

import bpy  # noqa: E402

import blockcat  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "cats_v1")
os.makedirs(OUT, exist_ok=True)
JOBS = [
    ("Basic", "แมวส้มลายเสือ", "Ginger Tabby"),
    ("Rare", "แมวแว่นดำ", "Cool Shades"),
    ("Epic", "แมวโจรสลัด", "Pirate"),
    ("Legendary", "แมวสตรอว์เบอร์รี", "Strawberry Cat"),
    ("Mythical", "แมวมังกร", "Dragon Cat"),
    ("Secret", "แมวเทพเจ้า", "Cat God"),
]
TIER_COLOURS = {"Basic": (154, 167, 189), "Rare": (61, 165, 255), "Epic": (164, 107, 255), "Legendary": (255, 176, 32),
                "Mythical": (255, 95, 162), "Secret": (24, 201, 185)}
files = []
for tier, th, name in JOBS:
    sc = kit.new_scene()
    sc.cycles.samples = 40
    sc.render.film_transparent = True
    bpy.data.objects.remove(bpy.data.objects["Ground"])
    m = blockcat.build(name)
    p = os.path.join(OUT, f"_t{len(files)}.png")
    kit.frame_camera(m.objects, p, direction=(-0.95, -0.85, 0.42), res=520, pad=1.04)
    files.append((tier, th, name, p))
    print("rendered", name, len(m.objects), "parts")

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

cell, cols = 520, 3
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cell * cols, rows * (cell + 70)), (236, 240, 247))
d = ImageDraw.Draw(sheet)
try:
    big = ImageFont.truetype("tahomabd.ttf", 28)
    small = ImageFont.truetype("tahoma.ttf", 24)
except OSError:
    big = small = ImageFont.load_default()
for i, (tier, th, name, p) in enumerate(files):
    x, y = (i % cols) * cell, (i // cols) * (cell + 70)
    im = Image.open(p).convert("RGBA")
    sheet.paste(im, (x, y), im)
    d.rounded_rectangle((x + 12, y + cell + 6, x + 12 + 150, y + cell + 42), 14, fill=TIER_COLOURS[tier])
    d.text((x + 24, y + cell + 9), tier, fill=(255, 255, 255), font=big)
    d.text((x + 175, y + cell + 10), f"{name} · {th}", fill=(40, 44, 70), font=small)
    os.remove(p)
sheet.save(os.path.join(OUT, "tier_sample.png"))
print("sheet written")
