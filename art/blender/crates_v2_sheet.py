"""Renders the three crate v2 looks at three tiers into art/preview/x3/crates_options.png.
Run:  blender -b --factory-startup -P art/blender/crates_v2_sheet.py -- <pillow path> [look letters, e.g. AC]
(Blender 4.5 here: its own Pillow works, pass D:/Tools/Blender/4.5/python/lib/site-packages)
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
ROWS = [("A", "A  LEGO block crate"), ("B", "B  Cat-head chest"), ("C", "C  Gift box")]
COLS = ["Wood", "Gold", "Cosmic"]
CELL = 420
LEFT = 250
LABEL = 40

only = args[1] if len(args) > 1 else "ABC"
cells = {}
for look, _ in ROWS:
    if look not in only:
        continue
    for tier in COLS:
        sc = kit.new_scene()
        sc.cycles.samples = 48
        sc.render.film_transparent = True
        g = bpy.data.objects.get("Ground")
        if g:
            bpy.data.objects.remove(g)
        model = crates_v2.crate(look, tier)
        path = os.path.join(OUT, f"_cell_{look}_{tier}.png")
        kit.frame_camera(model.objects, path, direction=(-0.8, -1.0, 0.6), res=CELL, pad=1.05)
        tris = crates_v2.triangles(model)
        cells[(look, tier)] = (path, tris)
        print("rendered", look, tier, len(model.objects), "parts", tris, "tris")

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

rows = [r for r in ROWS if r[0] in only]
sheet = Image.new("RGB", (LEFT + len(COLS) * CELL, len(rows) * (CELL + LABEL)), (232, 236, 244))
d = ImageDraw.Draw(sheet)
try:
    big = ImageFont.truetype("arialbd.ttf", 30)
    font = ImageFont.truetype("arialbd.ttf", 24)
except OSError:
    big = font = ImageFont.load_default()
for r, (look, title) in enumerate(rows):
    y0 = r * (CELL + LABEL)
    if r:
        d.line([(16, y0), (sheet.width - 16, y0)], fill=(205, 210, 224), width=2)
    letter, name = title.split("  ", 1)
    d.text((24, y0 + CELL // 2 - 40), letter, fill=(70, 90, 200), font=ImageFont.truetype("arialbd.ttf", 56) if big is not font else big)
    d.text((24, y0 + CELL // 2 + 26), name, fill=(40, 44, 70), font=big)
    for c, tier in enumerate(COLS):
        path, tris = cells[(look, tier)]
        im = Image.open(path).convert("RGBA")
        x0 = LEFT + c * CELL
        sheet.paste(im, (x0, y0), im)
        d.text((x0 + 18, y0 + CELL - 2), f"{tier}", fill=(40, 44, 70), font=font)
        d.text((x0 + CELL - 120, y0 + CELL + 2), f"{tris} tris", fill=(130, 136, 160), font=ImageFont.truetype("arial.ttf", 18) if big is not font else font)
        os.remove(path)
name = "crates_options.png" if only == "ABC" else f"crates_options_{only}.png"
sheet.save(os.path.join(OUT, name))
print("sheet written", name)
