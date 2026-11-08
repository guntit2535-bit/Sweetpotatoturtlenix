"""V1 second try: block cats with LEGO studs, one per tier look. Run:
blender -b --factory-startup -P art/blender/blockcat_sheet.py -- <pillow path>
Writes art/preview/cats_v1/blockcats.png.
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
    ("Basic: ginger tabby", 1, dict(shape="Loaf", fur="ffa04a", second="fff0d8", pattern="tabby", patternColor="d9681f", eyes="3c96ff")),
    ("Rare: tuxedo", 2, dict(shape="Slim", fur="3a3f52", second="ffffff", pattern="tuxedo", eyes="7ad957")),
    ("Epic: lavender fluff", 3, dict(shape="Fluffy", fur="b9a2ff", second="f6f0ff", pattern="patches", patternColor="8a6ae8", eyes="ffd23f")),
    ("Legendary: golden", 5, dict(shape="Loaf", fur="ffd36b", second="fff6dc", pattern="spots", patternColor="f0a830", eyes="ff8a3c")),
]
files = []
for label, tier, look in JOBS:
    sc = kit.new_scene()
    sc.cycles.samples = 40
    sc.render.film_transparent = True
    bpy.data.objects.remove(bpy.data.objects["Ground"])
    m = blockcat.cat(look, tier)
    p = os.path.join(OUT, f"_b{len(files)}.png")
    kit.frame_camera(m.objects, p, direction=(-1.0, -0.75, 0.45), res=520, pad=1.04)
    files.append((label, p))
    print("rendered", label)

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

cell = 520
sheet = Image.new("RGB", (cell * len(files), cell + 50), (236, 240, 247))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arialbd.ttf", 28)
except OSError:
    font = ImageFont.load_default()
for i, (label, p) in enumerate(files):
    im = Image.open(p).convert("RGBA")
    sheet.paste(im, (i * cell, 0), im)
    d.text((i * cell + 14, cell + 9), label, fill=(40, 44, 70), font=font)
    os.remove(p)
sheet.save(os.path.join(OUT, "blockcats.png"))
print("sheet written")
