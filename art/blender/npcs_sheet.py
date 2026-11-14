"""Renders the shopkeeper NPC concepts (npcs.py):
  art/preview/npc/npc_options.png        2 rows (A chibi voxel, B blocky avatar) x 2 columns (Shop, Sell)
  art/preview/npc/npc_in_stall_<A|B>.png both girls behind stand-in counters at the real stall sizes
                                          (MapKit.shopStall / sellBooth: floor top 0.6, counter top 4.25) with a
                                          grey 5.2-stud player for scale.
Run:  blender -b --factory-startup -P art/blender/npcs_sheet.py -- <pillow path> [samples]
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])
SAMPLES = int(args[1]) if len(args) > 1 else 64

import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import kit  # noqa: E402
import npcs  # noqa: E402
from voxprops import box_bm, tri_count  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "npc")
os.makedirs(OUT, exist_ok=True)
CW, CH = 640, 760


def scene():
    sc = kit.new_scene()
    sc.cycles.samples = SAMPLES
    bg = sc.world.node_tree.nodes["Background"]
    ramp = [n for n in sc.world.node_tree.nodes if n.type == "VALTORGB"][0]
    ramp.color_ramp.elements[0].color = kit.srgb((246, 246, 250))
    ramp.color_ramp.elements[1].color = kit.srgb((214, 232, 252))
    bg.inputs[1].default_value = 1.0
    g = bpy.data.objects["Ground"]
    g.data.materials[0] = kit.mat((196, 232, 170), rough=0.95)
    return sc


def camera(target, direction, dist, lens=50, w=CW, h=CH, out=None):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = w, h
    cam = bpy.data.cameras.new("Cam")
    cam.lens = lens
    co = bpy.data.objects.new("Cam", cam)
    d = Vector(direction).normalized()
    co.location = Vector(target) + d * dist
    co.rotation_euler = (Vector(target) - co.location).to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(co)
    sc.camera = co
    sc.render.filepath = out
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(co)


def move(model, dx, dy, dz=0.0):
    for o in model.objects:
        o.location = (o.location.x + dx, o.location.y + dy, o.location.z + dz)


def blocks(name, items):
    """items: [(x0, x1, y0, y1, z0, z1, rgb)] -> one flat-shaded object per colour."""
    m = kit.Model(name)
    by = {}
    for *b, col in items:
        by.setdefault(col, []).append(b)
    for col, bs in by.items():
        bm = bmesh.new()
        for b in bs:
            box_bm(bm, *b)
        m.add(bm, col, name, smooth=False, rough=0.8)
    return m


def stall(cx, body, top, wall, step):
    """Stand-in stall (Blender axes, front -Y) centred at x = cx: floor, counter, back wall, posts, optional step."""
    it = [
        (cx - 5, cx + 5, -5.5, 4.0, 0, 0.6, (233, 211, 168)),
        (cx - 4, cx + 4, -4.8, -2.4, 0.6, 3.75, body),
        (cx - 4.3, cx + 4.3, -5.1, -2.1, 3.75, 4.25, top),
        (cx - 4.5, cx + 4.5, 3.3, 3.9, 0.6, 6.6, wall),
    ]
    for x in (cx - 4.6, cx + 4.6):
        for y in (-4.6, 3.6):
            it.append((x - 0.35, x + 0.35, y - 0.35, y + 0.35, 0.6, 7.5, (176, 118, 68)))
    if step:
        it.append((cx - 1.5, cx + 1.5, -2.2, 0.6, 0.6, 0.6 + step, (214, 154, 92)))
    return blocks("Stall", it)


def player(x, y):
    grey = (170, 176, 190)
    head = (196, 200, 212)
    return blocks("Player", [
        (x - 1, x - 0.05, y - 0.5, y + 0.5, 0, 2, grey), (x + 0.05, x + 1, y - 0.5, y + 0.5, 0, 2, grey),
        (x - 1, x + 1, y - 0.5, y + 0.5, 2, 4, grey),
        (x - 2, x - 1.05, y - 0.5, y + 0.5, 2, 4, grey), (x + 1.05, x + 2, y - 0.5, y + 0.5, 2, 4, grey),
        (x - 0.6, x + 0.6, y - 0.6, y + 0.6, 4, 5.2, head),
    ])


# -- 1: options sheet -----------------------------------------------------------------------------------------
cells = {}
tris = {}
for st in ("A", "B"):
    for who in ("Shop", "Sell"):
        scene()
        m = npcs.build(st, who)
        tris[(st, who)] = tri_count(m)
        path = os.path.join(OUT, f"_cell_{st}_{who}.png")
        camera((0, 0, 2.9), (-0.55, -1.0, 0.16), 13.0, out=path)
        cells[(st, who)] = path
        print("rendered", st, who, tris[(st, who)])

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

LW, TH = 230, 70
sheet = Image.new("RGB", (LW + 2 * CW, TH + 2 * (CH + 40)), (238, 240, 246))
d = ImageDraw.Draw(sheet)
try:
    big = ImageFont.truetype("arialbd.ttf", 34)
    mid = ImageFont.truetype("arialbd.ttf", 26)
    small = ImageFont.truetype("arial.ttf", 19)
except OSError:
    big = mid = small = ImageFont.load_default()
for c, (who, sub) in enumerate((("Shop", "pink SHOP stall"), ("Sell", "green SELL booth"))):
    d.text((LW + c * CW + 20, 14), who, fill=(40, 44, 70), font=big)
    d.text((LW + c * CW + 130, 26), sub, fill=(110, 116, 140), font=small)
for r, (st, name, note) in enumerate((("A", "A Chibi voxel", "4.5 studs + 1 for ears"),
                                      ("B", "B Blocky avatar", "5.5 studs + 1 for ears"))):
    y0 = TH + r * (CH + 40)
    d.text((16, y0 + CH // 2 - 40), name.split(" ", 1)[0], fill=(40, 44, 70), font=ImageFont.truetype("arialbd.ttf", 64)
           if big != small else big)
    d.text((16, y0 + CH // 2 + 36), name.split(" ", 1)[1], fill=(40, 44, 70), font=mid)
    d.text((16, y0 + CH // 2 + 72), note, fill=(110, 116, 140), font=small)
    for c, who in enumerate(("Shop", "Sell")):
        x0 = LW + c * CW
        sheet.paste(Image.open(cells[(st, who)]).convert("RGB"), (x0, y0))
        d.text((x0 + 12, y0 + CH + 8), f"{name} - {who}   {tris[(st, who)]} tris", fill=(90, 96, 120), font=small)
        os.remove(cells[(st, who)])
sheet.save(os.path.join(OUT, "npc_options.png"))
print("sheet written")

# -- 2: in the stalls -----------------------------------------------------------------------------------------
STEP = {"A": 2.0, "B": 1.25}  # a wooden step behind the counter (top 4.25 above the ground)
for st in ("A", "B"):
    scene()
    stall(-6, (255, 143, 184), (255, 250, 240), (255, 226, 238), STEP[st])
    stall(6, (109, 211, 109), (255, 250, 240), (228, 255, 224), STEP[st])
    for x, who in ((-6, "Shop"), (6, "Sell")):
        m = npcs.build(st, who)
        move(m, x, -0.9, 0.6 + STEP[st])
    player(-0.5, -10.5)
    camera((0, -2.5, 4.4), (-0.3, -1.0, 0.26), 36.0, lens=50, w=1400, h=820,
           out=os.path.join(OUT, f"npc_in_stall_{st}.png"))
    print("stall render", st)
