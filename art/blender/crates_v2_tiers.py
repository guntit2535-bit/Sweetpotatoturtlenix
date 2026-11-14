"""Renders the chosen crate look (B, cat-head chest) at all 7 tiers into art/preview/x3/crates_B_7.png.
Run:  blender -b --factory-startup -P art/blender/crates_v2_tiers.py -- <pillow path>
(X3, revision 4 item 9: the developer picked look B)
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])

import bpy  # noqa: E402

import crates_v2  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "x3")
os.makedirs(OUT, exist_ok=True)
TIERS = ["Paper", "Wood", "Iron", "Gold", "Ruby", "Diamond", "Cosmic"]
CELL = 340
LABEL = 40

cells = []
for tier in TIERS:
    sc = kit.new_scene()
    sc.cycles.samples = 40
    sc.render.film_transparent = True
    g = bpy.data.objects.get("Ground")
    if g:
        bpy.data.objects.remove(g)
    model = crates_v2.crate("B", tier)
    path = os.path.join(OUT, f"_tier_{tier}.png")
    kit.frame_camera(model.objects, path, direction=(-0.8, -1.0, 0.6), res=CELL, pad=1.05)
    cells.append((tier, path))
    print("rendered", tier)

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

cols = 4
rows = 2
sheet = Image.new("RGB", (cols * CELL, rows * (CELL + LABEL)), (232, 236, 244))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arialbd.ttf", 26)
except OSError:
    font = ImageFont.load_default()
for i, (tier, path) in enumerate(cells):
    x0, y0 = (i % cols) * CELL, (i // cols) * (CELL + LABEL)
    im = Image.open(path).convert("RGBA")
    sheet.paste(im, (x0, y0), im)
    d.text((x0 + 16, y0 + CELL + 4), tier, fill=(40, 44, 70), font=font)
    os.remove(path)
sheet.save(os.path.join(OUT, "crates_B_7.png"))
print("sheet written")
