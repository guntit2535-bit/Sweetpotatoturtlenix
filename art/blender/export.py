"""Game export: python export.py [res] [max_tris]

For each world writes export/World<N>.fbx (one mesh per item, named by the item id) and its
palette texture (export/World<N>_Palette.png, also embedded in the FBX), plus export/manifest.json
(size in studs of every item, grip point of every club, triangle counts).

Every item is one mesh with one texture: each part's color is a swatch in the palette and the
part's UVs point at it. Clubs: the grip center is the origin (where the hand holds it). Balls: the
center of the item is the origin.
"""
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kit  # noqa: E402

kit.RES = float(sys.argv[1]) if len(sys.argv) > 1 else 0.5
MAX_TRIS = int(sys.argv[2]) if len(sys.argv) > 2 else 8000

import balls  # noqa: E402
import clubs  # noqa: E402

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "export")
SW = 8  # swatch size (px)
GRID = 16  # swatches per row (256 colors max)


def evaluated_parts(model):
    """(mesh data copy with modifiers applied, rgb) for each part, in world space."""
    dg = bpy.context.evaluated_depsgraph_get()
    out = []
    for o in model.objects:
        ev = o.evaluated_get(dg)
        me = bpy.data.meshes.new_from_object(ev, depsgraph=dg)
        me.transform(o.matrix_world)
        out.append((me, tuple(o["rgb"])))
    return out


def merge(name, parts, palette, offset):
    """One mesh from all parts; UVs at each part's palette swatch; moved by -offset."""
    verts, faces, uvs = [], [], []
    for me, rgb in parts:
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


def export_world(world, manifest):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    kit._mats.clear()
    palette = {}
    meshes = []
    for name, w, head, style in clubs.CLUBS:
        if w != world:
            continue
        m = clubs.build(name, head, style)
        bpy.context.view_layer.update()
        grip = Vector((0, 0, (3.2 + clubs.GRIP_TOP) / 2))
        meshes.append(("club", name, merge(name, evaluated_parts(m), palette, grip)))
        for o in m.objects:
            bpy.data.objects.remove(o)
    for name, w, fn in balls.BALLS:
        if w != world:
            continue
        m = balls.build(name, fn)
        bpy.context.view_layer.update()
        meshes.append(("ball", name, merge(name, evaluated_parts(m), palette, Vector())))
        for o in m.objects:
            bpy.data.objects.remove(o)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)

    os.makedirs(OUT, exist_ok=True)
    img_path = os.path.join(OUT, "World%d_Palette.png" % world)
    img = palette_image(palette, img_path)
    mat = bpy.data.materials.new("World%d_Palette" % world)
    mat.use_nodes = True
    nt = mat.node_tree
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
    nt.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.5

    sc = bpy.context.scene
    x = 0.0
    for kind, name, mesh in meshes:
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(name, mesh)
        sc.collection.objects.link(obj)
        n = decimate(obj, MAX_TRIS)
        co = [v.co for v in obj.data.vertices]
        lo = Vector((min(v.x for v in co), min(v.y for v in co), min(v.z for v in co)))
        hi = Vector((max(v.x for v in co), max(v.y for v in co), max(v.z for v in co)))
        # Roblox: Y up, -Z forward. Blender's FBX exporter converts axes (forward -Z, up Y).
        obj.location = (x, 0, 0)
        x += max(hi.x - lo.x, 3) + 1
        manifest[name] = {
            "kind": kind,
            "world": world,
            "triangles": n,
            "size": [round(hi.x - lo.x, 3), round(hi.z - lo.z, 3), round(hi.y - lo.y, 3)],  # Roblox X, Y(up), Z
            "center": [round((hi.x + lo.x) / 2, 3), round((hi.z + lo.z) / 2, 3), round(-(hi.y + lo.y) / 2, 3)],
        }
        print(world, name, n)
    bpy.ops.export_scene.fbx(
        filepath=os.path.join(OUT, "World%d.fbx" % world),
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
    manifest = {}
    worlds = [int(a) for a in sys.argv[3].split(",")] if len(sys.argv) > 3 else range(1, 7)
    for w in worlds:
        export_world(w, manifest)
    path = os.path.join(OUT, "manifest.json")
    old = json.load(open(path)) if os.path.exists(path) else {}
    old.update(manifest)
    json.dump(old, open(path, "w"), indent=1, sort_keys=True)
