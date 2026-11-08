"""Every design of one tier on one sheet, all at the same scale (so a kitten looks small next to a Maine Coon).
Run: blender -b --factory-startup -P art/blender/blockcat_tier.py -- <pillow path> <Tier> [cell px]
Reads art/source/cat_designs.json, writes art/preview/cats_v1/tier_<tier>.png.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
TIER = args[1]
CELL = int(args[2]) if len(args) > 2 else 300

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import blockcat  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "cats_v1")
RADIUS = {"Basic": 4.3, "Rare": 4.6, "Epic": 5.0, "Legendary": 5.4, "Mythical": 6.2, "Secret": 6.6}[TIER]
DIRECTION = Vector((-0.95, -0.85, 0.42)).normalized()

with open(os.path.join(HERE, "..", "source", "cat_designs.json"), encoding="utf-8") as f:
    designs = [d for d in json.load(f) if d["tier"] == TIER]
LIMIT = int(os.environ.get("CAT_LIMIT", "0"))
if LIMIT:
    designs = designs[:LIMIT]
files = []
for d in designs:
    sc = kit.new_scene()
    sc.cycles.samples = 24
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = CELL
    bpy.data.objects.remove(bpy.data.objects["Ground"])
    if d["en"] not in blockcat.DESIGNS:
        print("not built yet:", d["en"])
        continue
    m = blockcat.build(d["en"])
    pts = [o.matrix_world @ v.co for o in m.objects for v in o.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), 0))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, 2.75))
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 50
    co = bpy.data.objects.new("Cam", cam)
    co.location = center + DIRECTION * (RADIUS / math.sin(math.atan(18 / 50)))
    co.rotation_euler = (center - co.location).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(co)
    sc.camera = co
    p = os.path.join(OUT, f"_tier_{len(files):02d}.png")
    sc.render.filepath = p
    bpy.ops.render.render(write_still=True)
    files.append((d, p))
    print("rendered", d["n"], d["en"], len(m.objects), "parts")

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

COLOURS = {"Basic": (154, 167, 189), "Rare": (61, 165, 255), "Epic": (164, 107, 255), "Legendary": (255, 176, 32),
           "Mythical": (255, 95, 162), "Secret": (24, 201, 185)}
cols = 10
rows = (len(files) + cols - 1) // cols
LAB = 52
HEAD = 70
sheet = Image.new("RGB", (cols * CELL, HEAD + rows * (CELL + LAB)), (236, 240, 247))
dr = ImageDraw.Draw(sheet)
try:
    title = ImageFont.truetype("tahomabd.ttf", 34)
    big = ImageFont.truetype("tahomabd.ttf", 19)
    small = ImageFont.truetype("tahoma.ttf", 18)
except OSError:
    title = big = small = ImageFont.load_default()
dr.rounded_rectangle((16, 14, 16 + 190, 14 + 44), 18, fill=COLOURS[TIER])
dr.text((34, 18), TIER, fill=(255, 255, 255), font=title)
dr.text((226, 22), f"{len(files)} แบบ (ขนาดจริงเทียบกัน)", fill=(40, 44, 70), font=big)
for i, (d, p) in enumerate(files):
    x, y = (i % cols) * CELL, HEAD + (i // cols) * (CELL + LAB)
    im = Image.open(p).convert("RGBA")
    sheet.paste(im, (x, y), im)
    dr.text((x + 10, y + CELL - 2), f"{d['n']}. {d['en']}", fill=(40, 44, 70), font=big)
    dr.text((x + 10, y + CELL + 22), d["th"], fill=(90, 96, 120), font=small)
    os.remove(p)
name = os.path.join(OUT, f"tier_{TIER.lower()}.png")
sheet.save(name)
print("sheet written", name)
