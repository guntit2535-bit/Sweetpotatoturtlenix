"""Hotbar icons for the 400 cats (developer 2026-11-15), step 2 of 3.

Reads art/export/CatIcons/parts.json (tools/icons/cat_parts.luau: the game's own blocks and colours per cat) and
renders art/export/CatIcons/<id>.png: 256 x 256, transparent, the cat seen from the front left, a dark outline
(so it reads on the grey Roblox hotbar). Also art/preview/cat_icons_sheet.png (a few of every tier).

  blender -b --factory-startup -P art/blender/cat_icons.py -- <pylib dir with Pillow> [first] [last]

Roblox space (Y up, front -Z) -> Blender (Z up, front -Y): (x, y, z) -> (-x, z, y), a proper rotation.
Block kinds as in shared/CatModel: B box, S ball (diameter = the smallest side), E ellipsoid, C cylinder (axis X),
K cone (stepped cylinders along X, radius size.Y / 2 -> r2), W wedge (Roblox WedgePart), G gem (a turned box).
"""
import bpy
import bmesh
import json
import math
import os
import sys
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "art", "export", "CatIcons")
SHEET = os.path.join(ROOT, "art", "preview", "cat_icons_sheet.png")
RES = 256
CONE_STEPS = 4
OUTLINE = (47, 53, 82)  # the UI's dark edge colour
OUTLINE_PX = 5

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])
FIRST = int(args[1]) if len(args) > 1 else 1
LAST = int(args[2]) if len(args) > 2 else 10 ** 6

M = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def lin(v):
    v /= 255.0
    return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4


_mats = {}


def material(hexc, neon, alpha):
    key = (hexc, neon, round(alpha, 2))
    if key in _mats:
        return _mats[key]
    r, g, b = int(hexc[0:2], 16), int(hexc[2:4], 16), int(hexc[4:6], 16)
    rgb = (lin(r), lin(g), lin(b), 1.0)
    m = bpy.data.materials.new(f"m_{hexc}_{int(neon)}_{alpha:.2f}")
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = rgb
    bsdf.inputs["Roughness"].default_value = 0.55
    if neon:
        bsdf.inputs["Emission Color"].default_value = rgb
        bsdf.inputs["Emission Strength"].default_value = 1.5
    if alpha < 1:
        bsdf.inputs["Alpha"].default_value = alpha
        for attr, value in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            try:
                setattr(m, attr, value)
            except Exception:
                pass
    _mats[key] = m
    return m


def box_verts(hx, hy, hz):
    return [Vector((x, y, z)) for x in (-hx, hx) for y in (-hy, hy) for z in (-hz, hz)]


def mesh_box(bm, hx, hy, hz, frame):
    vs = [bm.verts.new(frame @ v) for v in box_verts(hx, hy, hz)]
    idx = lambda x, y, z: vs[x * 4 + y * 2 + z]
    faces = [
        (idx(0, 0, 0), idx(0, 0, 1), idx(0, 1, 1), idx(0, 1, 0)),
        (idx(1, 0, 0), idx(1, 1, 0), idx(1, 1, 1), idx(1, 0, 1)),
        (idx(0, 0, 0), idx(1, 0, 0), idx(1, 0, 1), idx(0, 0, 1)),
        (idx(0, 1, 0), idx(0, 1, 1), idx(1, 1, 1), idx(1, 1, 0)),
        (idx(0, 0, 0), idx(0, 1, 0), idx(1, 1, 0), idx(1, 0, 0)),
        (idx(0, 0, 1), idx(1, 0, 1), idx(1, 1, 1), idx(0, 1, 1)),
    ]
    for f in faces:
        bm.faces.new(f)


def mesh_wedge(bm, hx, hy, hz, frame):
    # Roblox WedgePart: full bottom and back (+Z), the slope from the top back edge down to the bottom front edge
    p = [Vector(v) for v in ((-hx, -hy, -hz), (hx, -hy, -hz), (hx, -hy, hz), (-hx, -hy, hz), (-hx, hy, hz), (hx, hy, hz))]
    v = [bm.verts.new(frame @ q) for q in p]
    for f in ((v[0], v[1], v[2], v[3]), (v[3], v[2], v[5], v[4]), (v[0], v[4], v[5], v[1]), (v[0], v[3], v[4]), (v[1], v[5], v[2])):
        bm.faces.new(f)


def mesh_cyl(bm, length, radius, frame, segs=20):
    # axis X
    turn = frame @ Matrix.Rotation(math.radians(90), 4, "Y")
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segs, radius1=radius, radius2=radius, depth=length, matrix=turn)


def mesh_sphere(bm, sx, sy, sz, frame):
    m = frame @ Matrix.Diagonal((sx / 2, sy / 2, sz / 2, 1))
    bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=12, radius=1.0, matrix=m)


def build_part(p):
    kind = p["k"]
    s = p["s"]
    pos = Vector(p["p"])
    r = p["r"]
    rot = Matrix(((r[0], r[1], r[2], 0), (r[3], r[4], r[5], 0), (r[6], r[7], r[8], 0), (0, 0, 0, 1)))
    frame = Matrix.Translation(pos) @ rot  # part space -> Roblox world
    bm = bmesh.new()
    if kind == "W":
        mesh_wedge(bm, s[0] / 2, s[1] / 2, s[2] / 2, frame)
    elif kind == "K":
        h, r1, r2 = s[0], s[1] / 2, p.get("r2", 0) or 0
        for k in range(CONE_STEPS):
            t = (k + 0.5) / CONE_STEPS
            rr = max(0.03, r1 + (r2 - r1) * t)
            mesh_cyl(bm, h / CONE_STEPS + 0.01, rr, frame @ Matrix.Translation((-h / 2 + h * t, 0, 0)))
    elif kind == "C":
        mesh_cyl(bm, s[0], min(s[1], s[2]) / 2, frame)
    elif kind == "S":
        d = min(s)
        mesh_sphere(bm, d, d, d, frame)
    elif kind == "E":
        mesh_sphere(bm, s[0], s[1], s[2], frame)
    else:  # B, G
        mesh_box(bm, s[0] / 2, s[1] / 2, s[2] / 2, frame)
    me = bpy.data.meshes.new("part")
    bm.to_mesh(me)
    bm.free()
    alpha = 1.0 - float(p.get("t", 0) or 0)
    me.materials.append(material(p["c"][:6].lower(), bool(p.get("n")), alpha))
    o = bpy.data.objects.new("part", me)
    o.matrix_world = M
    bpy.context.scene.collection.objects.link(o)
    return o


def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            sc.render.engine = engine
            break
        except Exception:
            pass
    sc.view_settings.view_transform = "Standard"
    sc.render.film_transparent = True
    sc.render.resolution_x = sc.render.resolution_y = RES
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    try:
        sc.eevee.taa_render_samples = 16
    except Exception:
        pass
    world = bpy.data.worlds.new("W")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.78, 0.85, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
    sc.world = world
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.0
    so = bpy.data.objects.new("Sun", sun)
    so.rotation_euler = (math.radians(45), math.radians(-20), math.radians(-35))
    sc.collection.objects.link(so)
    cam = bpy.data.cameras.new("Cam")
    cam.type = "ORTHO"
    co = bpy.data.objects.new("Cam", cam)
    sc.collection.objects.link(co)
    sc.camera = co
    return sc, co


def frame(co, objs, direction=Vector((-0.55, -1.0, 0.45))):
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (lo + hi) / 2
    d = direction.normalized()
    co.location = center + d * 50
    co.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    inv = co.matrix_world.inverted()
    loc = [inv @ p for p in pts]
    x0, x1 = min(p.x for p in loc), max(p.x for p in loc)
    y0, y1 = min(p.y for p in loc), max(p.y for p in loc)
    # centre the picture on the projected box
    right = co.matrix_world.to_3x3() @ Vector((1, 0, 0))
    up = co.matrix_world.to_3x3() @ Vector((0, 1, 0))
    co.location = co.location + right * ((x0 + x1) / 2) + up * ((y0 + y1) / 2)
    co.data.ortho_scale = max(x1 - x0, y1 - y0) * 1.12 + 0.05
    co.data.clip_end = 200


def clear(objs):
    for o in objs:
        me = o.data
        bpy.data.objects.remove(o)
        bpy.data.meshes.remove(me)


def outline(path):
    from PIL import Image, ImageFilter
    im = Image.open(path).convert("RGBA")
    a = im.split()[3]
    grown = a.point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.MaxFilter(OUTLINE_PX * 2 + 1))
    base = Image.new("RGBA", im.size, OUTLINE + (0,))
    base.putalpha(grown)
    base.alpha_composite(im)
    base.save(path)


def sheet(ids):
    from PIL import Image, ImageDraw
    cols, cell = 10, 128
    rows = (len(ids) + cols - 1) // cols
    img = Image.new("RGBA", (cols * cell, rows * cell), (110, 116, 128, 255))
    d = ImageDraw.Draw(img)
    for i, cid in enumerate(ids):
        x, y = (i % cols) * cell, (i // cols) * cell
        d.rectangle((x + 4, y + 4, x + cell - 4, y + cell - 4), fill=(90, 96, 108, 255))
        icon = Image.open(os.path.join(OUT, f"{cid}.png")).resize((cell - 16, cell - 16), Image.LANCZOS)
        img.alpha_composite(icon, (x + 8, y + 8))
    img.save(SHEET)


def main():
    with open(os.path.join(OUT, "parts.json"), encoding="utf-8") as f:
        cats = json.load(f)
    sc, co = setup_scene()
    done = []
    for n, cat in enumerate(cats, start=1):
        if n < FIRST or n > LAST:
            continue
        objs = [build_part(p) for p in cat["parts"]]
        frame(co, objs)
        path = os.path.join(OUT, f"{cat['id']}.png")
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        clear(objs)
        outline(path)
        done.append(cat["id"])
        print(f"[icons] {n}/{len(cats)} {cat['id']} {cat['name']}", flush=True)
    # a few of every tier for the developer
    by_tier = {}
    for cat in cats:
        if cat["id"] in done:
            by_tier.setdefault(cat["tier"], []).append(cat["id"])
    pick = []
    for tier in sorted(by_tier):
        pick += by_tier[tier][:10]
    if pick:
        sheet(pick)
    print(f"[icons] done {len(done)}", flush=True)


main()
