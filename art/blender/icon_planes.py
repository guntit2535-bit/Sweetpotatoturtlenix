"""Picture upload without an API key (developer 2026-11-18): every PNG of a folder becomes a flat square named after the
file, textured with it, all in one FBX. Studio's Import 3D (Creator = the group) uploads each texture as an image of
the group; Claude then reads each MeshPart's TextureID in Studio (the image id) and deletes the imported model.

  blender -b --factory-startup -P art/blender/icon_planes.py -- <folder of PNGs> <out.fbx>

e.g. art/export/RodIcons -> art/export/RodIcons.fbx (Rod1 ... Rod50, RobuxCoin).
"""
import os
import sys

import bpy
import bmesh

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SRC, OUT = os.path.abspath(args[0]), os.path.abspath(args[1])

bpy.ops.wm.read_factory_settings(use_empty=True)
names = sorted(f[:-4] for f in os.listdir(SRC) if f.lower().endswith(".png"))
objs = []
for i, name in enumerate(names):
    bm = bmesh.new()
    s = 0.5
    v = [bm.verts.new(p) for p in ((-s, 0, -s), (s, 0, -s), (s, 0, s), (-s, 0, s))]
    bm.faces.new(v)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    uv = me.uv_layers.new(name="UV")
    for k, loop in enumerate(uv.data):
        loop.uv = ((0, 0), (1, 0), (1, 1), (0, 1))[k % 4]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.join(SRC, name + ".png"))
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    me.materials.append(mat)
    o = bpy.data.objects.new(name, me)
    o.location = ((i % 10) * 1.2, 0, -(i // 10) * 1.2)
    bpy.context.scene.collection.objects.link(o)
    objs.append(o)

bpy.ops.export_scene.fbx(
    filepath=OUT,
    use_selection=False,
    object_types={"MESH"},
    apply_scale_options="FBX_SCALE_UNITS",
    axis_forward="-Z",
    axis_up="Y",
    path_mode="COPY",
    embed_textures=True,
    add_leaf_bones=False,
    bake_anim=False,
)
print("[planes]", len(objs), "->", OUT, flush=True)
