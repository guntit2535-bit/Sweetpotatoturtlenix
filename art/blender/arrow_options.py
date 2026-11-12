"""Revision 3 item 1: the event arrow over the player's head, 3 looks for approval (Mythical pink / Secret teal).
Run: blender -b --factory-startup -P art/blender/arrow_options.py -- <pillow path> [cell px]
Writes art/preview/arrow/arrow_options.png. The picked look is exported as one mesh (arrow_export, next step).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
CELL = int(args[1]) if len(args) > 1 else 520

import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "arrow")
os.makedirs(OUT, exist_ok=True)
COLORS = [("Mythical", (255, 95, 162)), ("Secret", (24, 201, 185))]


def link(name, me, material):
    o = bpy.data.objects.new(name, me)
    o.data.materials.append(material)
    bpy.context.scene.collection.objects.link(o)
    return o


def slab(name, pts, z0, z1, material, bevel=0.0, seg=4):
    """A flat polygon (x, y) extruded from z0 to z1, rounded with a bevel."""
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, z0)) for x, y in pts]
    face = bm.faces.new(vs)
    if face.normal.z > 0:
        face.normal_flip()
    r = bmesh.ops.extrude_face_region(bm, geom=[face])
    top = [v for v in r["geom"] if isinstance(v, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, 0, z1 - z0), verts=top)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = link(name, me, material)
    if bevel > 0:
        b = o.modifiers.new("Bevel", "BEVEL")
        b.width = bevel
        b.segments = seg
        b.limit_method = "ANGLE"
        b.harden_normals = False
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def offset(pts, d):
    """Grow a counter-clockwise polygon outward by d (miter joins)."""
    out = []
    n = len(pts)
    for i in range(n):
        p0, p1, p2 = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[(i + 1) % n])
        e1, e2 = (p1 - p0).normalized(), (p2 - p1).normalized()
        n1, n2 = Vector((e1.y, -e1.x)), Vector((e2.y, -e2.x))
        k = 1 + n1.dot(n2)
        m = (n1 + n2) / k if k > 1e-3 else n1
        q = p1 + m * d
        out.append((q.x, q.y))
    return out


def box(name, size, at, material):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2])) + Vector(at)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = link(name, me, material)
    b = o.modifiers.new("Bevel", "BEVEL")
    b.width = min(size) * 0.08
    b.segments = 2
    return o


def stud(name, at, r, h, material):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=r, radius2=r, depth=h)
    for v in bm.verts:
        v.co += Vector(at) + Vector((0, 0, h / 2))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = link(name, me, material)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


# -- the 3 looks; each points +X, lies flat, centred on the origin, about 4.4 studs long --------------
ARROW = [(-2.2, -0.5), (0.3, -0.5), (0.3, -1.3), (2.2, 0.0), (0.3, 1.3), (0.3, 0.5), (-2.2, 0.5)]


def look_a(rgb):
    """A: a chunky toy arrow, glossy, with a white rim."""
    body = kit.mat(rgb, rough=0.25, coat=1.0, emit=0.35)
    rim = kit.mat((255, 255, 255), rough=0.35, emit=0.15)
    slab("ArrowRim", offset(ARROW, 0.22), -0.22, 0.22, rim, bevel=0.12)
    slab("Arrow", ARROW, -0.38, 0.38, body, bevel=0.22, seg=5)


def look_b(rgb):
    """B: a LEGO pixel arrow: 1x1 bricks with studs (like the cats)."""
    body = kit.mat(rgb, rough=0.3, coat=0.6, emit=0.3)
    cells = []
    for x in range(0, 5):
        for y in (-1, 0, 1):
            cells.append((x, y))
    for x, half in ((5, 3), (6, 2), (7, 1), (8, 0)):
        for y in range(-half, half + 1):
            cells.append((x, y))
    s = 0.5
    for x, y in cells:
        cx, cy = (x - 4) * s, y * s
        box("Brick", (s * 0.98, s * 0.98, s * 0.9), (cx, cy, 0), body)
        stud("Stud", (cx, cy, s * 0.45), s * 0.3, s * 0.22, body)


def look_c(rgb):
    """C: three chevrons, the front one brightest (points the way like a runway)."""
    v = [(-0.55, -1.25), (0.0, -1.25), (0.9, 0.0), (0.0, 1.25), (-0.55, 1.25), (0.35, 0.0)]
    for i, (x, emit, k) in enumerate(((-1.6, 0.2, 0.75), (-0.4, 0.45, 0.88), (0.8, 0.9, 1.0))):
        pts = [(x + px * k, py * k) for px, py in v]
        slab(f"Chevron{i}", pts, -0.3 * k, 0.3 * k, kit.mat(rgb, rough=0.25, coat=1.0, emit=emit), bevel=0.14)


LOOKS = [("A", look_a, "A  ลูกศรการ์ตูนขอบขาว"), ("B", look_b, "B  ลูกศรพิกเซล + ปุ่มเลโก้"), ("C", look_c, "C  ลูกศรบั้งสามชั้น")]


def player():
    """A plain blocky avatar for scale (5 studs tall), facing +X."""
    skin, shirt, pants = kit.mat((245, 205, 150)), kit.mat((70, 120, 220)), kit.mat((60, 60, 75))
    box("LegL", (1, 1, 2), (0, -0.5, 1), pants)
    box("LegR", (1, 1, 2), (0, 0.5, 1), pants)
    box("Torso", (1, 2, 2), (0, 0, 3), shirt)
    box("ArmL", (1, 1, 2), (0, -1.5, 3), skin)
    box("ArmR", (1, 1, 2), (0, 1.5, 3), skin)
    box("Head", (1.2, 1.2, 1.2), (0, 0, 4.6), skin)


files = []
for ci, (tier, rgb) in enumerate(COLORS):
    for key, fn, _ in LOOKS:
        sc = kit.new_scene()
        sc.cycles.samples = 40
        player()
        fn(rgb)
        # float over the head (Config: 6.5 studs above the root = ~4 above the head), turned toward the event
        for o in bpy.context.scene.objects:
            if o.name.startswith(("Arrow", "Brick", "Stud", "Chevron")):
                o.location.z += 8.2
                o.rotation_euler.z = math.radians(-35)
        bpy.context.view_layer.update()
        objs = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.name != "Ground"]
        p = os.path.join(OUT, f"_a{len(files):02d}.png")
        kit.frame_camera(objs, p, direction=(-1.0, 0.35, 0.75), lens=50, pad=1.1, res=CELL)
        files.append(p)
        print("rendered", tier, key)

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

HEAD = 64
sheet = Image.new("RGB", (len(LOOKS) * CELL, HEAD + len(COLORS) * (CELL + 40)), (212, 220, 234))
dr = ImageDraw.Draw(sheet)
try:
    big = ImageFont.truetype("tahomabd.ttf", 26)
    small = ImageFont.truetype("tahoma.ttf", 20)
except OSError:
    big = small = ImageFont.load_default()
for i, (_, _, label) in enumerate(LOOKS):
    dr.text((i * CELL + 18, 18), label, fill=(40, 44, 70), font=big)
for k, p in enumerate(files):
    row, col = divmod(k, len(LOOKS))
    y = HEAD + row * (CELL + 40)
    sheet.paste(Image.open(p).convert("RGB"), (col * CELL, y))
    if col == 0:
        dr.text((12, y + CELL + 8), f"อีเวนต์ {COLORS[row][0]}", fill=(40, 44, 70), font=small)
    os.remove(p)
out = os.path.join(OUT, "arrow_options.png")
sheet.save(out)
print("wrote", out)
