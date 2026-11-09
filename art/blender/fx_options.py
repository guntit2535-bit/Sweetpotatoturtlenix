"""V5j effect style options for approval: each sample cat now (block effect) and with styles A / B / C (fxshapes.py).
Run: blender -b --factory-startup -P art/blender/fx_options.py -- <pillow path> [cell px]
Writes art/preview/cats_v1/fx_options.png.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
CELL = int(args[1]) if len(args) > 1 else 560

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import blockcat  # noqa: E402
import catalog  # noqa: E402,F401
import catparts  # noqa: E402
import fxshapes  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "cats_v1")
FIRE = [(255, 100, 25), (255, 160, 30)]
ICE = [(60, 150, 255), (120, 210, 255)]
GOLD = [(255, 195, 40), (255, 150, 30)]
SAMPLES = [
    ("Dragon Cat", "Mythical", "flame", FIRE, 8, 0.65),
    ("Ice Dragon Cat", "Mythical", "crystal", ICE, 7, 0.6),
    ("Star Emperor Cat", "Secret", "star", GOLD, 7, 0.75),
]
STYLES = [None, "charms", "magic", "aura"]
LABELS = ["ตอนนี้ (บล็อก)", "A  ประกายนุ่ม", "B  วงเวทย์ + เกลียวแสง", "C  ออร่าเปลวพลัง"]
DIRECTION = Vector((-0.95, -0.85, 0.42)).normalized()

files = []
for name, tier, kind, cols, n, s in SAMPLES:
    for style in STYLES:
        sc = kit.new_scene()
        sc.cycles.samples = 40
        sc.render.resolution_x = sc.render.resolution_y = CELL
        m = blockcat.build(name)
        a = catparts.G(m.A)
        if style:
            for o in list(m.objects):
                base = o.name.split(".")[0]
                if base.startswith("Fx") or base in ("Sparkle", "FxFlame", "Aura"):
                    m.objects.remove(o)
                    bpy.data.objects.remove(o)
            fxshapes.effect(m, a, style, kind, cols, n=n, s=s)
        r = max(a.bw, a.bl) / 2 + 1.5
        center = Vector((0, a.by - 0.3, (a.top + 1.4) / 2))
        radius = math.hypot(r * 1.1, (a.top + 1.6) / 2) * 1.02
        cam = bpy.data.cameras.new("Cam")
        cam.lens = 50
        co = bpy.data.objects.new("Cam", cam)
        co.location = center + DIRECTION * (radius / math.sin(math.atan(18 / 50)))
        co.rotation_euler = (center - co.location).normalized().to_track_quat("-Z", "Y").to_euler()
        sc.collection.objects.link(co)
        sc.camera = co
        p = os.path.join(OUT, f"_fx_{len(files):02d}.png")
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        files.append(p)
        print("rendered", name, style, len(m.objects))

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

HEAD, SIDE = 64, 0
cols_n = len(STYLES)
sheet = Image.new("RGB", (cols_n * CELL, HEAD + len(SAMPLES) * (CELL + 40)), (212, 220, 234))
dr = ImageDraw.Draw(sheet)
try:
    big = ImageFont.truetype("tahomabd.ttf", 26)
    small = ImageFont.truetype("tahoma.ttf", 20)
except OSError:
    big = small = ImageFont.load_default()
for i, lab in enumerate(LABELS):
    dr.text((i * CELL + 18, 18), lab, fill=(40, 44, 70), font=big)
for k, p in enumerate(files):
    row, col = divmod(k, cols_n)
    y = HEAD + row * (CELL + 40)
    sheet.paste(Image.open(p).convert("RGB"), (col * CELL, y))
    if col == 0:
        nm, tier = SAMPLES[row][0], SAMPLES[row][1]
        dr.text((12, y + CELL + 8), f"{nm} ({tier})", fill=(40, 44, 70), font=small)
    os.remove(p)
out = os.path.join(OUT, "fx_options.png")
sheet.save(out)
print("wrote", out)
