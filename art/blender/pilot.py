"""R5 pilot sheet: renders a few items from items.py and lays them out with labels.
Run:  blender -b --factory-startup -P art/blender/pilot.py -- <pillow path>
Writes art/preview/models/pilot_<name>.png and art/preview/models/pilot_sheet.png.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])  # Pillow (pip --target) for the sheet

import bpy  # noqa: E402

import items  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "models")
os.makedirs(OUT, exist_ok=True)

PILOT = [
    ("Treadmill Lv1", lambda: items.treadmill(1)),
    ("Treadmill Lv13", lambda: items.treadmill(13)),
    ("Treadmill Lv25", lambda: items.treadmill(25)),
    ("Weights Lv1", lambda: items.weights(1)),
    ("Weights Lv13", lambda: items.weights(13)),
    ("Weights Lv25", lambda: items.weights(25)),
    ("Wood Rod 5", lambda: items.rod(5)),
    ("Gold Rod 3", lambda: items.rod(13)),
    ("Bat", items.bat),
    ("Paper Crate", lambda: items.crate("Paper")),
    ("Gold Crate", lambda: items.crate("Gold")),
    ("Diamond Crate", lambda: items.crate("Diamond")),
]

files = []
for label, build in PILOT:
    sc = kit.new_scene()
    sc.cycles.samples = 24
    sc.render.film_transparent = True
    g = bpy.data.objects.get("Ground")
    if g:
        bpy.data.objects.remove(g)
    model = build()
    path = os.path.join(OUT, "pilot_" + label.replace(" ", "_") + ".png")
    view = (-0.7, 1.0, 0.6) if label.startswith("Treadmill") else (-1.0, -0.25, 0.3) if "Rod" in label else (-0.75, -1.0, 0.55)
    kit.frame_camera(model.objects, path, direction=view, res=420, pad=1.08)
    files.append((label, path))
    print("rendered", label, len(model.objects), "parts")

try:
    from PIL import Image, ImageDraw, ImageFont

    cols, cell = 4, 420
    rows = (len(files) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell, rows * (cell + 40)), (232, 236, 244))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arialbd.ttf", 26)
    except OSError:
        font = ImageFont.load_default()
    for i, (label, path) in enumerate(files):
        im = Image.open(path).convert("RGBA")
        x, y = (i % cols) * cell, (i // cols) * (cell + 40)
        sheet.paste(im, (x, y), im)
        d.text((x + 12, y + cell + 6), label, fill=(40, 44, 70), font=font)
    sheet.save(os.path.join(OUT, "pilot_sheet.png"))
    print("sheet written")
except ImportError as e:
    print("no Pillow, sheet skipped:", e)
