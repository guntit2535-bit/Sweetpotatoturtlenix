"""V5j game export of the effect mesh library: blender -b --factory-startup -P art/blender/fx_export.py

Every effect item kind (fxshapes.item) is built once at size 1 in pure red, then split into layers by colour role:
  main          the effect's colour        (red in the build)
  light:<k>     the colour lightened by k  (lighter(red, k) in the build: 255, 255k, 255k)
  fixed:<hex>   its own colour             (anything else: a UFO dome, a leaf's vein, a clock's hands)
and by see-through (glow halos). Plus the pieces round the cat: GlowRing, MagicCircle, RingSeg (30 degree arc),
WheelRay. Writes art/export/Effects.fbx (one mesh per layer, named Fx_<kind>_<n>) and src/shared/FxMeshData.luau;
the developer imports the FBX into ReplicatedStorage.FxMeshes (docs/DEVELOPER_TODO.md). Axes like items_export.py
(X, Y up, Z = Blender -Y; the item's front faces Blender -Y).
"""
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import cateffects  # noqa: E402
import fxshapes  # noqa: E402
import kit  # noqa: E402

ROOT = os.path.join(HERE, "..", "..")
OUT = os.path.join(ROOT, "art", "export")
RED = (255, 0, 0)
MAX_TRIS = 3000
# sizes the round pieces are built at (the game scales them by r / this)
RING_R, CIRCLE_R, SEG_R = 3.3, 3.5, 3.0


def kinds():
    out = {"twinkle"}
    for specs in cateffects.STYLE.values():
        for st in specs:
            if st["kind"]:
                out.add(fxshapes.KIND.get(st["kind"], st["kind"]))
    return sorted(out)


def material(obj):
    emit, alpha = 0.0, 1.0
    if obj.data.materials and obj.data.materials[0] and obj.data.materials[0].node_tree:
        p = obj.data.materials[0].node_tree.nodes.get("Principled BSDF")
        if p:
            emit = p.inputs["Emission Strength"].default_value
            alpha = p.inputs["Alpha"].default_value
    return emit, alpha


def tint(rgb):
    if tuple(rgb) == RED:
        return "main"
    if rgb[0] == 255 and rgb[1] == rgb[2]:
        return f"light:{rgb[1] / 255:.2f}"
    return "fixed:%02x%02x%02x" % tuple(rgb)


def rbx(v):
    return [round(v.x, 3), round(v.z, 3), round(-v.y, 3)]


def layers_of(objs):
    """{(tint, alpha, glows): [evaluated meshes in world space]}"""
    dg = bpy.context.evaluated_depsgraph_get()
    groups = {}
    for o in objs:
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg), depsgraph=dg)
        me.transform(o.matrix_world)
        emit, alpha = material(o)
        key = (tint([int(v) for v in o["rgb"]]), round(1 - alpha, 2), emit > 0.05)
        groups.setdefault(key, []).append(me)
    return groups


def merge(name, meshes):
    verts, faces = [], []
    for me in meshes:
        base = len(verts)
        verts += [tuple(v.co) for v in me.vertices]
        faces += [[base + k for k in p.vertices] for p in me.polygons]
        bpy.data.meshes.remove(me)
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.set_sharp_from_angle(angle=0.6)
    mesh.update()
    return mesh


def tris(mesh):
    return sum(len(p.vertices) - 2 for p in mesh.polygons)


bpy.ops.wm.read_factory_settings(use_empty=True)
kit._mats.clear()
sc = bpy.context.scene
plain = bpy.data.materials.new("FxPlain")
built = []  # (kind, mesh, tint, transparency, glows)


def build(kind, make):
    m = kit.Model(kind)
    make(m)
    bpy.context.view_layer.update()
    groups = layers_of(m.objects)
    for o in list(m.objects):
        bpy.data.objects.remove(o)
    for i, ((t, transp, glows), meshes) in enumerate(sorted(groups.items(), key=lambda kv: (kv[0][1], kv[0][0]))):
        built.append((kind, merge(f"Fx_{kind}_{i + 1}", meshes), t, transp, glows))


for k in kinds():
    build(k, lambda m, k=k: fxshapes.item(m, k, (0, 0, 0), 1.0, RED, (0, 1.0, 0), random.Random(7), 3.0))
build("GlowRing", lambda m: m.torus(RING_R, 0.035, RED, Matrix(), nu=96, nv=8, name="Fx_GroundRing", emit=3.0))


def circle(m):
    fxshapes.magic_circle(m, 0, 0, CIRCLE_R, RED, 2.5)
    for o in list(m.objects):
        if o.name.split(".")[0] == "Fx_GroundGlow":  # the soft disc is a plain Roblox cylinder in the game
            m.objects.remove(o)
            bpy.data.objects.remove(o)


build("MagicCircle", circle)


def seg(m):
    pts = [Vector((math.cos(a) * SEG_R, math.sin(a) * SEG_R, 0)) for a in [math.radians(-15 + 30 * i / 8) for i in range(9)]]
    m.tube(pts, 0.07, RED, n=8, caps=False, name="Fx_Ring", emit=3.0)
    m.tube(pts, 0.2, RED, n=8, caps=False, name="Fx_RingGlow", emit=1.5, alpha=0.82)


build("RingSeg", seg)
build("WheelRay", lambda m: m.tube([Vector((0, 0, 0)), Vector((1, 0, 0))], lambda t: 0.16 * (1 - t) + 0.02, RED, n=8,
                                   name="Fx_WheelRay", emit=3.0))

# one scene with every layer side by side, then the FBX
entries = {}
x = 0.0
total = 0
for kind, mesh, t, transp, glows in built:
    mesh.materials.append(plain)
    obj = bpy.data.objects.new(mesh.name, mesh)
    sc.collection.objects.link(obj)
    n = tris(mesh)
    if n > MAX_TRIS:
        mod = obj.modifiers.new("Decimate", "DECIMATE")
        mod.ratio = MAX_TRIS / n
        dg = bpy.context.evaluated_depsgraph_get()
        me = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), depsgraph=dg)
        obj.modifiers.remove(mod)
        obj.data = me
        n = tris(me)
    total += n
    co = [v.co for v in obj.data.vertices]
    lo = Vector((min(v.x for v in co), min(v.y for v in co), min(v.z for v in co)))
    hi = Vector((max(v.x for v in co), max(v.y for v in co), max(v.z for v in co)))
    obj.location = (x, 0, 0)
    x += max(hi.x - lo.x, 1) + 1
    entries.setdefault(kind, []).append({
        "mesh": mesh.name, "size": [round(hi.x - lo.x, 3), round(hi.z - lo.z, 3), round(hi.y - lo.y, 3)],
        "center": rbx((hi + lo) / 2), "tint": t, "transparency": transp, "glows": glows, "tris": n,
    })
    print("mesh", mesh.name, t, transp, n)

os.makedirs(OUT, exist_ok=True)
bpy.ops.export_scene.fbx(
    filepath=os.path.join(OUT, "Effects.fbx"), use_selection=False, object_types={"MESH"}, apply_unit_scale=True,
    apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y", use_mesh_modifiers=True,
    mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False)


def v3(a):
    return f"Vector3.new({a[0]}, {a[1]}, {a[2]})"


lines = [
    "--!strict",
    "-- Generated by art/blender/fx_export.py (V5j effect mesh library). Do not edit.",
    "-- kind -> its layers: mesh (a MeshPart in ReplicatedStorage.FxMeshes), size and center at size 1 (studs; X, Y up,",
    "-- Z = Blender -Y, the item's front faces -Z after the import turn, Config.ItemModels.Flip), tint (\"main\" = the",
    "-- effect's colour, \"light:k\" = lightened by k, \"fixed:rrggbb\"), transparency, glows (Neon when the effect glows).",
    f"-- Round pieces are built at radius GlowRing {RING_R}, MagicCircle {CIRCLE_R}, RingSeg {SEG_R}; WheelRay is 1 long (+X).",
    "",
    "export type Layer = { mesh: string, size: Vector3, center: Vector3, tint: string, transparency: number, glows: boolean }",
    "",
    "return {",
    f"\tBuiltRadius = {{ GlowRing = {RING_R}, MagicCircle = {CIRCLE_R}, RingSeg = {SEG_R} }},",
    "\tKinds = {",
]
for kind in sorted(entries):
    lines.append(f"\t\t{kind} = {{")
    for e in entries[kind]:
        lines.append(f"\t\t\t{{ mesh = \"{e['mesh']}\", size = {v3(e['size'])}, center = {v3(e['center'])}, "
                     f"tint = \"{e['tint']}\", transparency = {e['transparency']}, glows = {str(e['glows']).lower()} }},")
    lines.append("\t\t},")
lines += ["\t} :: { [string]: { Layer } },", "}"]
with open(os.path.join(ROOT, "src", "shared", "FxMeshData.luau"), "w", encoding="utf-8", newline=chr(10)) as f:
    f.write(chr(10).join(lines) + chr(10))
print("EXPORTED", len(built), "meshes,", total, "triangles,", len(entries), "kinds")
