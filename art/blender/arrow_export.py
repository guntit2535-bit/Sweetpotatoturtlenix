"""Revision 3 item 1, look A (picked 2026-11-13): the event arrow for the game.
Run: blender -b --factory-startup -P art/blender/arrow_export.py
Writes art/export/EventArrow.fbx with two meshes: ArrowBody (tinted by the game: Mythical pink / Secret teal) and
ArrowRim (white). The tip points along Blender -Y (an item's front, like items_export.py), so after the 3D
Importer (Config.ItemModels.Flip) it points along the model's LookVector. The developer imports it into
ReplicatedStorage as the model "EventArrow" (docs/DEVELOPER_TODO.md).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import bpy  # noqa: E402

import arrow_options  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "export")
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
arrow_options.look_a((255, 255, 255))
for o in list(bpy.context.scene.objects):
    if o.name == "Arrow":
        o.name = "ArrowBody"
        o.data.name = "ArrowBody"
    elif o.name == "ArrowRim":
        o.data.name = "ArrowRim"
    # point the tip from +X to -Y
    o.rotation_euler.z = math.radians(-90)
bpy.context.view_layer.update()
for o in bpy.context.scene.objects:
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
tris = 0
for o in bpy.context.scene.objects:
    ev = o.evaluated_get(bpy.context.evaluated_depsgraph_get())
    me = ev.to_mesh()
    tris += sum(len(p.vertices) - 2 for p in me.polygons)
    ev.to_mesh_clear()
print("tris", tris, [o.name for o in bpy.context.scene.objects])

bpy.ops.export_scene.fbx(
    filepath=os.path.join(OUT, "EventArrow.fbx"), use_selection=False, object_types={"MESH"}, apply_unit_scale=True,
    apply_scale_options="FBX_SCALE_UNITS", axis_forward="-Z", axis_up="Y", use_mesh_modifiers=True,
    mesh_smooth_type="FACE", add_leaf_bones=False, bake_anim=False)
print("wrote", os.path.join(OUT, "EventArrow.fbx"))
_ = kit
