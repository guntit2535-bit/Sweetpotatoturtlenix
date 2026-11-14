"""Renders every voxel map prop (voxprops.IDS) into art/preview/mapstyle/voxprops_sheet.png, labelled with the id,
size (studs, x * y * z) and triangles.
Run:  blender -b --factory-startup -P art/blender/voxprops_sheet.py -- <pillow path> [id,id,...]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])

import kit  # noqa: E402
import voxprops  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "mapstyle")
os.makedirs(OUT, exist_ok=True)
CELL = 360
LABEL = 54
COLS = 6

ids = args[1].split(",") if len(args) > 1 and args[1] else voxprops.IDS
cells = []
for pid in ids:
    sc = kit.new_scene()
    sc.cycles.samples = 24
    model = voxprops.prop(pid)
    lo, hi = voxprops.bounds(model)
    size = hi - lo
    path = os.path.join(OUT, f"_cell_{pid}.png")
    kit.frame_camera(model.objects, path, direction=(-0.55, -1.0, 0.5), res=CELL, pad=1.1)
    cells.append((pid, path, voxprops.tri_count(model), size))
    print("rendered", pid, voxprops.tri_count(model))

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

rows = (len(cells) + COLS - 1) // COLS
sheet = Image.new("RGB", (COLS * CELL, rows * (CELL + LABEL)), (232, 236, 244))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arialbd.ttf", 22)
    small = ImageFont.truetype("arial.ttf", 17)
except OSError:
    font = small = ImageFont.load_default()
for n, (pid, path, tris, size) in enumerate(cells):
    x0, y0 = (n % COLS) * CELL, (n // COLS) * (CELL + LABEL)
    sheet.paste(Image.open(path).convert("RGB"), (x0, y0))
    d.text((x0 + 10, y0 + CELL + 4), pid, fill=(40, 44, 70), font=font)
    d.text((x0 + 10, y0 + CELL + 30), f"{size.x:.2f} x {size.y:.2f} x {size.z:.2f}   {tris} tris", fill=(110, 116, 140),
           font=small)
    os.remove(path)
name = "voxprops_sheet.png" if len(args) < 2 or not args[1] else "voxprops_sheet_part.png"
sheet.save(os.path.join(OUT, name))
print("sheet written", name)
