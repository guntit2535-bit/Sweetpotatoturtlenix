"""Game export for R5: blender -b --factory-startup -P art/blender/items_export.py -- [families] [res]

families: comma list of Treadmills, Weights, Dumbbells, Rods, Gear, Crates (default: all); res = kit.RES
(0.5 default: lighter meshes for phones).

Writes art/export/<Family>.fbx (one mesh per item, named by its id, one palette texture per family embedded in
the FBX) and art/export/manifest.json; then `python art/blender/manifest_to_luau.py` makes
src/shared/ItemModelData.luau.

Mesh names (= MeshPart names after the import):
  Treadmill1..25, Weights1..25 (rack + pair), Dumbbell1..25 (one, held), Rod1..25, Bat,
  Shoe_<key> (right shoe; the game mirrors it for the left foot), Treat_<name>,
  Crate_<key> (body) + Crate_<key>_Lid (opens around manifest.hinge).
  A part that is see-through (crystal / diamond) goes into an extra mesh <id>_Glass (the game makes it
  half transparent).
Origin of every mesh = the item's origin in Blender (floor centre for gym pieces, crates, treats and shoes;
the hand grip for rods, the bat and a dumbbell), so the manifest centre places it.
"""
import json
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

import kit  # noqa: E402

kit.RES = float(args[1]) if len(args) > 1 else 0.5

import crates  # noqa: E402
import items  # noqa: E402
import shoes  # noqa: E402
import treats  # noqa: E402

OUT = os.path.join(HERE, "..", "export")
SW, GRID = 8, 16

GRIPS = {"Rod": Vector((0, 0, 0.4)), "Bat": Vector((0, 0, 0.55)), "Dumbbell": Vector()}


def family_jobs(family):
    """[(id, builder, max_tris, grip)]"""
    if family == "Treadmills":
        return [(f"Treadmill{L}", lambda L=L: items.treadmill(L), 6000, None) for L in range(1, 26)]
    if family == "Weights":
        return [(f"Weights{L}", lambda L=L: items.weights(L), 6000, None) for L in range(1, 26)]
    if family == "Dumbbells":
        return [(f"Dumbbell{L}", lambda L=L: items.dumbbell(L), 2500, GRIPS["Dumbbell"]) for L in range(1, 26)]
    if family == "Rods":
        return [(f"Rod{L}", lambda L=L: items.rod(L), 4000, GRIPS["Rod"]) for L in range(1, 26)]
    if family == "Gear":
        jobs = [("Bat", items.bat, 3000, GRIPS["Bat"])]
        jobs += [(f"Shoe_{k}", lambda k=k: shoes.shoe(k), 3000, None) for k in shoes.KEYS]
        jobs += [(f"Treat_{n}", lambda n=n: treats.treat(n), 3000, None) for n in treats.NAMES]
        return jobs
    if family == "Crates":
        return [(f"Crate_{k}", k, 7000, None) for k in crates.LOOKS]
    raise ValueError(family)


def evaluated(objs):
    """[(mesh copy in world space with modifiers applied, rgb, glass)]"""
    dg = bpy.context.evaluated_depsgraph_get()
    out = []
    for o in objs:
        me = bpy.data.meshes.new_from_object(o.evaluated_get(dg), depsgraph=dg)
        me.transform(o.matrix_world)
        glass = False
        if o.data.materials:
            p = o.data.materials[0].node_tree.nodes["Principled BSDF"]
            glass = p.inputs["Alpha"].default_value < 0.99
        out.append((me, tuple(o["rgb"]), glass))
    return out


def merge(name, parts, palette, offset):
    verts, faces, uvs = [], [], []
    for me, rgb, _ in parts:
        if rgb not in palette:
            palette[rgb] = len(palette)
        i = palette[rgb]
        u = ((i % GRID) + 0.5) / GRID
        v = 1 - ((i // GRID) + 0.5) / GRID
        base = len(verts)
        verts += [tuple(vv.co - offset) for vv in me.vertices]
        for p in me.polygons:
            faces.append([base + k for k in p.vertices])
            uvs += [(u, v)] * len(p.vertices)
        bpy.data.meshes.remove(me)
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    uv = mesh.uv_layers.new(name="UV")
    for k, loop in enumerate(uv.data):
        loop.uv = uvs[k]
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.set_sharp_from_angle(angle=0.6)
    mesh.update()
    return mesh


def tris(mesh):
    return sum(len(p.vertices) - 2 for p in mesh.polygons)


def decimate(obj, target):
    n = tris(obj.data)
    if n <= target:
        return n
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.ratio = target / n
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), depsgraph=dg)
    obj.modifiers.remove(mod)
    old = obj.data
    obj.data = me
    bpy.data.meshes.remove(old)
    return tris(me)


def palette_image(palette, path):
    size = SW * GRID
    img = bpy.data.images.new(os.path.basename(path), size, size, alpha=False)
    px = [0.0] * (size * size * 4)
    for rgb, i in palette.items():
        cx, cy = (i % GRID) * SW, size - (i // GRID + 1) * SW
        for y in range(cy, cy + SW):
            for x in range(cx, cx + SW):
                k = (y * size + x) * 4
                px[k:k + 4] = [rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0]
    img.pixels = px
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    return img


def clear_scene():
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)


def rbx(v):
    """Blender (x, y, z) -> Roblox model axes (X, Y up, Z = -Y)."""
    return [round(v.x, 3), round(v.z, 3), round(-v.y, 3)]


def export_family(family, manifest):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    kit._mats.clear()
    palette = {}
    meshes = []  # (name, mesh, max_tris, entry)

    def add(name, parts, offset, max_tris, extra=None):
        solid = [p for p in parts if not p[2]]
        glass = [p for p in parts if p[2]]
        for suffix, group in (("", solid), ("_Glass", glass)):
            if group:
                meshes.append((name + suffix, merge(name + suffix, group, palette, offset), max_tris, extra or {}))

    for item_id, build, max_tris, grip in family_jobs(family):
        offset = grip if grip is not None else Vector()
        if family == "Crates":
            key = build
            closed = crates.crate(key, 0.0)
            bpy.context.view_layer.update()
            parts = evaluated(closed.objects)
            # find the lid: the parts that move when the lid opens
            probe = crates.crate(key, 0.3)
            bpy.context.view_layer.update()
            lid = []
            for a, b in zip(closed.objects, probe.objects):
                va = a.matrix_world @ a.data.vertices[0].co
                vb = b.matrix_world @ b.data.vertices[0].co
                lid.append((va - vb).length > 1e-4)
            hinge = Vector((0, crates.HY + 0.06, crates.H - 0.27))
            extra = {"hinge": rbx(hinge)}
            add(item_id, [p for p, l in zip(parts, lid) if not l], offset, max_tris, extra)
            add(item_id + "_Lid", [p for p, l in zip(parts, lid) if l], offset, max_tris // 2, extra)
        else:
            m = build()
            bpy.context.view_layer.update()
            extra = {"grip": rbx(grip)} if grip is not None else {}
            add(item_id, evaluated(m.objects), offset, max_tris, extra)
        clear_scene()

    os.makedirs(OUT, exist_ok=True)
    img = palette_image(palette, os.path.join(OUT, f"{family}_Palette.png"))
    mat = bpy.data.materials.new(f"{family}_Palette")
    mat.use_nodes = True
    nt = mat.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])

    sc = bpy.context.scene
    x = 0.0
    total = 0
    for name, mesh, max_tris, extra in meshes:
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(name, mesh)
        sc.collection.objects.link(obj)
        n = decimate(obj, max_tris)
        total += n
        co = [v.co for v in obj.data.vertices]
        lo = Vector((min(v.x for v in co), min(v.y for v in co), min(v.z for v in co)))
        hi = Vector((max(v.x for v in co), max(v.y for v in co), max(v.z for v in co)))
        obj.location = (x, 0, 0)
        x += max(hi.x - lo.x, 3) + 1
        entry = {
            "family": family,
            "triangles": n,
            "size": [round(hi.x - lo.x, 3), round(hi.z - lo.z, 3), round(hi.y - lo.y, 3)],
            "center": rbx((hi + lo) / 2),
        }
        entry.update(extra)
        manifest[name] = entry
        print(family, name, n)
    print(family, "meshes", len(meshes), "triangles", total)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT, f"{family}.fbx"),
        use_selection=False,
        object_types={"MESH"},
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_UNITS",
        axis_forward="-Z",
        axis_up="Y",
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        path_mode="COPY",
        embed_textures=True,
        add_leaf_bones=False,
        bake_anim=False,
    )


if __name__ == "__main__":
    fams = args[0].split(",") if args and args[0] else ["Treadmills", "Weights", "Dumbbells", "Rods", "Gear", "Crates"]
    manifest = {}
    for f in fams:
        export_family(f, manifest)
    path = os.path.join(OUT, "manifest.json")
    old = json.load(open(path)) if os.path.exists(path) else {}
    old.update(manifest)
    json.dump(old, open(path, "w"), indent=1, sort_keys=True)
    print("manifest", len(old))
