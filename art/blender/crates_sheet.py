"""Renders the four crates (closed) and the gold crate open into art/preview/models/crates_sheet.png.
Run:  blender -b --factory-startup -P art/blender/crates_sheet.py -- <pillow path>
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])

import bpy  # noqa: E402

import crates  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "models")
os.makedirs(OUT, exist_ok=True)
SHOTS = [("Paper", 0.0), ("Wood", 0.0), ("Gold", 0.0), ("Diamond", 0.0), ("Gold", 1.15)]
CELL = 460

files = []
for key, lid in SHOTS:
    sc = kit.new_scene()
    sc.cycles.samples = 48
    sc.render.film_transparent = True
    g = bpy.data.objects.get("Ground")
    if g:
        bpy.data.objects.remove(g)
    model = crates.crate(key, lid)
    label = f"{key} crate" + (" (open)" if lid else "")
    path = os.path.join(OUT, "crate_" + key + ("_open" if lid else "") + ".png")
    kit.frame_camera(model.objects, path, direction=(-0.8, -1.0, 0.6), res=CELL, pad=1.05)
    files.append((label, path))
    print("rendered", label, len(model.objects), "parts", model.triangles(), "tris")

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

sheet = Image.new("RGB", (len(files) * CELL, CELL + 46), (232, 236, 244))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arialbd.ttf", 26)
except OSError:
    font = ImageFont.load_default()
for i, (label, path) in enumerate(files):
    im = Image.open(path).convert("RGBA")
    sheet.paste(im, (i * CELL, 0), im)
    d.text((i * CELL + 14, CELL + 8), label, fill=(40, 44, 70), font=font)
    os.remove(path)
sheet.save(os.path.join(OUT, "crates_sheet.png"))
print("sheet written")
