"""V1 sheet: the same original cat in the 3 style options.
Run: blender -b --factory-startup -P art/blender/voxcat_sheet.py -- <pillow path> [styles|shapes]
Writes art/preview/cats_v1/<name>.png.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
MODE = args[1] if len(args) > 1 else "styles"

import bpy  # noqa: E402

import kit  # noqa: E402
import voxcat  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "cats_v1")
os.makedirs(OUT, exist_ok=True)

GINGER = dict(shape="Loaf", fur="ffa94d", second="fff1dc", pattern="tabby", patternColor="e0762b", eyes="3c96ff")
if MODE == "styles":
    JOBS = [("A Pixel", "pixel", GINGER), ("B Brick", "brick", GINGER), ("C Mix", "mix", GINGER)]
else:
    style = MODE
    JOBS = [
        ("Loaf tabby", style, GINGER),
        ("Slim tuxedo", style, dict(shape="Slim", fur="3b3f4f", second="ffffff", pattern="tuxedo", eyes="7ad957")),
        ("Fluffy patches", style, dict(shape="Fluffy", fur="ffffff", second="fff4e8", pattern="patches",
                                       patternColor="f2a24a", eyes="4fb6ff")),
        ("Loaf socks", style, dict(shape="Loaf", fur="9aa3b5", second="ffffff", pattern="socks", eyes="f5c542")),
    ]

files = []
for label, style, look in JOBS:
    sc = kit.new_scene()
    sc.cycles.samples = 32
    sc.render.film_transparent = True
    bpy.data.objects.remove(bpy.data.objects["Ground"])
    voxcat.outline(sc, 2.4)
    m = voxcat.cat(style, look)
    path = os.path.join(OUT, f"_tmp{len(files)}.png")
    kit.frame_camera(m.objects, path, direction=(-0.6, -1.0, 0.35), res=520, pad=1.05)
    files.append((label, path))
    print("rendered", label, sum(len(o.data.polygons) for o in m.objects), "faces")

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

cell = 520
sheet = Image.new("RGB", (cell * len(files), cell + 50), (236, 240, 247))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arialbd.ttf", 30)
except OSError:
    font = ImageFont.load_default()
for i, (label, p) in enumerate(files):
    im = Image.open(p).convert("RGBA")
    sheet.paste(im, (i * cell, 0), im)
    d.text((i * cell + 16, cell + 8), label, fill=(40, 44, 70), font=font)
    os.remove(p)
name = "styles" if MODE == "styles" else f"shapes_{MODE}"
sheet.save(os.path.join(OUT, f"{name}.png"))
print("sheet", name)
