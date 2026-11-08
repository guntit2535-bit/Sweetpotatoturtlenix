"""Walk-cycle preview of the six tier samples with their bones and effects: an animated GIF grid.
Run: blender -b --factory-startup -P art/blender/catanim_preview.py -- <pillow path> [frames]
Writes art/preview/cats_v1/walk.gif (+ walk_sheet.png, the first frame).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
FRAMES = int(args[1]) if len(args) > 1 else 16

import bpy  # noqa: E402

import blockcat  # noqa: E402
import catrig  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "cats_v1")
CELL = 300
NAMES = ["Ginger Tabby", "Cool Shades", "Pirate", "Strawberry Cat", "Dragon Cat", "Cat God"]
frames = {n: [] for n in NAMES}
for name in NAMES:
    sc = kit.new_scene()
    sc.cycles.samples = 12
    sc.render.film_transparent = True
    bpy.data.objects.remove(bpy.data.objects["Ground"])
    fn, look = blockcat.DESIGNS[name]
    m = kit.Model(name.replace(" ", ""))
    A = blockcat.base(m, look)
    fn(m, A)
    rig = catrig.rig(m, A)
    print(name, {b: len(o) for b, o in rig.bones.items()})
    for f in range(FRAMES):
        rig.pose(f / FRAMES, "walk")
        bpy.context.view_layer.update()
        path = os.path.join(OUT, f"_a_{name.replace(' ', '')}_{f:02d}.png")
        if f == 0:
            # frame the camera once (on the rest pose), keep it for every frame
            kit.frame_camera(m.objects, path, direction=(-0.95, -0.85, 0.42), res=CELL, pad=1.1)
            cam = bpy.data.cameras.new("Keep")
            co = bpy.data.objects.new("Keep", cam)
            sc.collection.objects.link(co)
        if f == 0:
            # rebuild the same camera kit.frame_camera used, to reuse it on later frames
            import math
            from mathutils import Vector

            pts = [o.matrix_world @ v.co for o in m.objects for v in o.data.vertices]
            lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
            hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
            center = (lo + hi) / 2
            radius = max((p - center).length for p in pts)
            cam.lens = 50
            dist = radius / math.sin(2 * math.atan(18 / 50) / 2) * 1.1
            d = Vector((-0.95, -0.85, 0.42)).normalized()
            co.location = center + d * dist
            co.rotation_euler = (center - co.location).normalized().to_track_quat("-Z", "Y").to_euler()
            sc.camera = co
        else:
            sc.render.filepath = path
            bpy.ops.render.render(write_still=True)
        frames[name].append(path)

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

cols, rows = 3, 2
try:
    font = ImageFont.truetype("tahomabd.ttf", 20)
except OSError:
    font = ImageFont.load_default()
gif = []
for f in range(FRAMES):
    sheet = Image.new("RGB", (cols * CELL, rows * (CELL + 30)), (236, 240, 247))
    d = ImageDraw.Draw(sheet)
    for i, name in enumerate(NAMES):
        x, y = (i % cols) * CELL, (i // cols) * (CELL + 30)
        im = Image.open(frames[name][f]).convert("RGBA")
        sheet.paste(im, (x, y), im)
        d.text((x + 10, y + CELL + 4), name, fill=(40, 44, 70), font=font)
    gif.append(sheet.convert("P", palette=Image.ADAPTIVE, colors=200))
    if f == 0:
        sheet.save(os.path.join(OUT, "walk_sheet.png"))
gif[0].save(os.path.join(OUT, "walk.gif"), save_all=True, append_images=gif[1:], duration=1000 // FRAMES * 1, loop=0)
for name in NAMES:
    for p in frames[name]:
        os.remove(p)
print("gif written")
