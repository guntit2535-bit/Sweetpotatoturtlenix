"""Imports exported FBX files and renders chosen meshes as the game will get them (palette texture,
decimated): blender -b --factory-startup -P art/blender/check_export.py -- <pillow> <Family:Mesh+Mesh,...> ...
Writes art/preview/models/export_check.png.
"""
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "models")
EXP = os.path.join(HERE, "..", "export")
files = []
for spec in args[1:]:
    fam, names = spec.split(":")
    group = names.split("+")
    kit.new_scene()
    sc = bpy.context.scene
    sc.cycles.samples = 16
    sc.render.film_transparent = True
    bpy.data.objects.remove(bpy.data.objects["Ground"])
    bpy.ops.import_scene.fbx(filepath=os.path.join(EXP, fam + ".fbx"))
    keep = []
    for o in list(bpy.data.objects):
        if o.type != "MESH":
            continue
        if o.name in group:
            o.location = (0, 0, 0)
            keep.append(o)
        else:
            bpy.data.objects.remove(o)
    bpy.context.view_layer.update()
    print("check", group, [(o.name, tuple(round(v, 2) for v in o.dimensions)) for o in keep])
    path = os.path.join(OUT, f"_chk_{len(files)}.png")
    kit.frame_camera(keep, path, direction=(-0.75, -0.5, 0.55), res=300, pad=1.08)
    files.append((group[0], path))

from PIL import Image, ImageDraw  # noqa: E402

sheet = Image.new("RGB", (300 * len(files), 330), (232, 236, 244))
d = ImageDraw.Draw(sheet)
for i, (label, p) in enumerate(files):
    im = Image.open(p).convert("RGBA")
    sheet.paste(im, (i * 300, 0), im)
    d.text((i * 300 + 8, 305), label, fill=(40, 44, 70))
    os.remove(p)
sheet.save(os.path.join(OUT, "export_check.png"))
print("check written")
