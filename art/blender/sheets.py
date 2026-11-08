"""Labelled preview sheet of one item family.
Run:  blender -b --factory-startup -P art/blender/sheets.py -- <pillow path> <family> [cols] [cell]
family: treadmill | weights | dumbbell | rod | shoes | treats
Writes art/preview/models/sheet_<family>.png.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
FAMILY = args[1]
COLS = int(args[2]) if len(args) > 2 else 5
CELL = int(args[3]) if len(args) > 3 else 300

import bpy  # noqa: E402

import items  # noqa: E402
import kit  # noqa: E402
import shoes  # noqa: E402
import treats  # noqa: E402

FAM = ["Basic", "Sport", "Neon", "Gold", "Cosmic"]
WTS = ["Rubber", "Chrome", "Gold", "Crystal", "Cosmic"]
RODS = ["Wood", "Iron", "Gold", "Crystal", "Cosmic"]


def lv(names, level):
    return f"{level}. {names[(level - 1) // 5]} {(level - 1) % 5 + 1}"


JOBS = {
    "treadmill": ([(lv(FAM, L), (lambda L=L: items.treadmill(L))) for L in range(1, 26)], (-0.7, 1.0, 0.6)),
    "weights": ([(lv(WTS, L), (lambda L=L: items.weights(L))) for L in range(1, 26)], (-0.75, -1.0, 0.55)),
    "dumbbell": ([(lv(WTS, L), (lambda L=L: items.dumbbell(L))) for L in range(1, 26)], (-0.6, -1.0, 0.5)),
    "rod": ([(lv(RODS, L), (lambda L=L: items.rod(L))) for L in range(1, 26)], (-1.0, -0.25, 0.3)),
    "shoes": ([(f"{i + 1}. {k}", (lambda k=k: shoes.shoe(k))) for i, k in enumerate(shoes.KEYS)], (1.0, -0.75, 0.55)),
    "treats": ([(n, (lambda n=n: treats.treat(n))) for n in treats.NAMES], (-0.45, -1.0, 0.4)),
}

jobs, view = JOBS[FAMILY]
OUT = os.path.join(HERE, "..", "preview", "models")
os.makedirs(OUT, exist_ok=True)
files = []
for label, build in jobs:
    sc = kit.new_scene()
    sc.cycles.samples = 20
    sc.render.film_transparent = True
    g = bpy.data.objects.get("Ground")
    if g:
        bpy.data.objects.remove(g)
    model = build()
    path = os.path.join(OUT, f"_tmp_{len(files)}.png")
    kit.frame_camera(model.objects, path, direction=view, res=CELL, pad=1.06)
    files.append((label, path))
    print("rendered", label, model.triangles(), "tris")

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

rows = (len(files) + COLS - 1) // COLS
LAB = 34
sheet = Image.new("RGB", (COLS * CELL, rows * (CELL + LAB)), (232, 236, 244))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arialbd.ttf", max(16, CELL // 14))
except OSError:
    font = ImageFont.load_default()
for i, (label, path) in enumerate(files):
    im = Image.open(path).convert("RGBA")
    x, y = (i % COLS) * CELL, (i // COLS) * (CELL + LAB)
    sheet.paste(im, (x, y), im)
    d.text((x + 10, y + CELL + 4), label, fill=(40, 44, 70), font=font)
    os.remove(path)
sheet.save(os.path.join(OUT, f"sheet_{FAMILY}.png"))
print("sheet written", FAMILY)
