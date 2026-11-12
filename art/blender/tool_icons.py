"""Revision 3 item 3: hotbar icons for the two tools (the words "Rod" / "Bat" become pictures).
Run: blender -b --factory-startup -P art/blender/tool_icons.py -- <pillow path>
Writes art/export/ui_icons/P13_rod.png and P14_bat.png (512 x 512, transparent, the item lying diagonally with a
thick dark outline like the other UI icons). The developer uploads both under the group (Config.UIIcons.Rod / Bat).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])

import bpy  # noqa: E402
from mathutils import Matrix  # noqa: E402

import items  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "export", "ui_icons")
SIZE = 512
# name, builder, turn axis, degrees, camera direction: the rod bends toward -Y, so it is seen from the side
JOBS = [
    ("P13_rod", lambda: items.rod(1), "X", -42, (-1.0, -0.12, 0.16)),
    ("P14_bat", lambda: items.bat(), "Y", -40, (0.12, -1.0, 0.18)),
]

from PIL import Image, ImageFilter  # noqa: E402

for name, build, axis, tilt, view in JOBS:
    sc = kit.new_scene()
    sc.cycles.samples = 48
    sc.render.film_transparent = True
    g = bpy.data.objects.get("Ground")
    if g:
        bpy.data.objects.remove(g)
    model = build()
    # lie the item across the picture: bottom-left (handle) to top-right (tip)
    turn = Matrix.Rotation(math.radians(tilt), 4, axis)
    for o in model.objects:
        o.matrix_world = turn @ o.matrix_world
    bpy.context.view_layer.update()
    raw = os.path.join(OUT, f"_{name}_raw.png")
    kit.frame_camera(model.objects, raw, direction=view, lens=70, res=SIZE, pad=1.18)
    im = Image.open(raw).convert("RGBA")
    # handle at the bottom left, tip at the top right (the usual way a tool icon lies)
    im = im.transpose(Image.FLIP_LEFT_RIGHT)
    os.remove(raw)
    # a thick dark outline around the shape (the other UI icons have one), then a soft shadow-free edge
    a = im.split()[3]
    ring = a.filter(ImageFilter.MaxFilter(19)).filter(ImageFilter.GaussianBlur(1.2))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ink = Image.new("RGBA", im.size, (40, 37, 80, 255))
    out.paste(ink, (0, 0), ring)
    out.alpha_composite(im)
    out.save(os.path.join(OUT, f"{name}.png"))
    print("wrote", name)
