"""Game export of the 300 block cats (V5h): blender -b --factory-startup -P art/blender/cats_export.py

Builds every design of art/source/cat_designs.json (catalog.py), sorts its blocks into bones (catrig.py) and writes
src/shared/CatShapeData/<Tier>.luau: per design the bone pivots, a small colour palette and one line per block
that shared/CatShapes turns into a Roblox Part (box, ball, ellipsoid, cylinder, cone, wedge).

Axes: Blender x right, y back (front = -y), z up -> Roblox (-x, z, y): front = -Z, up = +Y, the picture seen from
the front stays the same (no mirror). Bones are named by their Roblox side (L = -X), like shared/CatModel.

Block line (numbers x100, rounded):  bone kind x y z sx sy sz colour flags [rx ry rz]
  bone   index into BONES
  kind   B box, S ball, E ellipsoid, C cylinder (axis = local X), K cone (axis X, from radius sy/2 to r2), W wedge
         (Roblox WedgePart), G gem (a box turned 45 degrees about Y)
  flags  letters: s studs (all sides), t studs on top only, n neon, a<k> transparency k/10, r<k> cone end radius x100
  rx ry rz  CFrame.Angles in degrees (left out when 0 0 0)
Palette entry: hex colour + role (f fur, p pattern / third colour, - other): colour variants and mutations recolour
the roles.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import blockcat  # noqa: E402
import catalog  # noqa: E402,F401  (adds every tier's designs)
import catrig  # noqa: E402
import kit  # noqa: E402

ROOT = os.path.join(HERE, "..", "..")
OUT = os.path.join(ROOT, "src", "shared", "CatShapeData")
ONLY = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []

BONES = ["Body", "Head", "Tail1", "Tail2", "LegFL", "LegFR", "LegBL", "LegBR", "WingL", "WingR", "Fx"]
SWAP = {"LegFL": "LegFR", "LegFR": "LegFL", "LegBL": "LegBR", "LegBR": "LegBL", "WingL": "WingR", "WingR": "WingL"}
P = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))  # Blender -> Roblox axes (det +1, its own inverse)
ROT_Z90 = Matrix(((0, -1, 0), (1, 0, 0), (0, 0, 1)))  # Roblox local: new X = old Y (cylinder axis)
ROT_Y45 = Matrix.Rotation(math.pi / 4, 3, "Y")


def rb(v):
    return P @ Vector(v)


def q(v):
    return str(int(round(v * 100)))


def frame_of(obj):
    f = obj.get("frame")
    return Matrix([f[0:4], f[4:8], f[8:12], f[12:16]])


def material(obj):
    emit, alpha = 0.0, 1.0
    if obj.data.materials and obj.data.materials[0] and obj.data.materials[0].node_tree:
        p = obj.data.materials[0].node_tree.nodes.get("Principled BSDF")
        if p:
            emit = p.inputs["Emission Strength"].default_value
            alpha = p.inputs["Alpha"].default_value
    return emit, alpha


fallbacks = []


def part_of(obj):
    """-> (kind, pos (Roblox), rot 3x3 (Roblox), size (Roblox), extra flags) or None to skip."""
    kind = obj.get("prim")
    if kind is None:
        # no record: the world box of its vertices
        pts = [obj.matrix_world @ v.co for v in obj.data.vertices]
        if not pts:
            return None
        lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
        hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
        fallbacks.append(obj.name)
        s = hi - lo
        return "B", rb((lo + hi) / 2), Matrix.Identity(3), Vector((s.x, s.z, s.y)), ""
    W = obj.matrix_world @ frame_of(obj)
    pos = rb(W.translation)
    rot = W.to_3x3()
    scale = Vector((rot.col[0].length, rot.col[1].length, rot.col[2].length))
    rot = rot.normalized()
    size = [obj["size"][i] * scale[i] for i in range(3)]
    R = P @ rot @ P  # local axes mapped the same way: local (x, y, z) -> part (-x, z, y)
    sz = Vector((size[0], size[2], size[1]))
    flags = ""
    if kind == "Block":
        studs = obj.get("studs", "none")
        flags = {"all": "s", "top": "t"}.get(studs, "")
        return "B", pos, R, sz, flags
    if kind == "Blob":
        e1, e2 = obj["e"]
        if e1 < 0.6 and e2 < 0.6:
            return "B", pos, R, sz, ""
        if e1 > 1.5:
            return "G", pos, R @ ROT_Y45, Vector((sz.x * 0.72, sz.y, sz.z * 0.72)), ""
        if max(sz) - min(sz) < 0.02:
            return "S", pos, R, sz, ""
        return "E", pos, R, sz, ""
    if kind == "Cyl":
        r1 = size[0] / 2
        r2 = obj.get("r2", r1) * scale[0]
        R2 = R @ ROT_Z90
        h = size[2]
        if abs(r2 - r1) < 0.01:
            return "C", pos, R2, Vector((h, 2 * r1, 2 * r1)), ""
        return "K", pos, R2, Vector((h, 2 * r1, 2 * r1)), "r" + q(r2)
    if kind == "Wedge":
        return "W", pos, R, sz, ""
    if kind == "Torus":
        # a ring of short boxes round local Z (halo, earring, the aura ring)
        big, r = obj["R"] * scale[0], obj["r"] * scale[0]
        n = max(6, min(16, int(2 * math.pi * big / (r * 3))))
        seg = 2 * math.pi * big / n * 1.08
        out = []
        for k in range(n):
            Wk = W @ Matrix.Rotation(2 * math.pi * k / n, 4, "Z") @ Matrix.Translation((obj["R"], 0, 0))
            Rk = P @ Wk.to_3x3().normalized() @ P
            # box local (x radial, y along the ring, z thickness) -> part (-x, z, y)
            out.append(("B", rb(Wk.translation), Rk, Vector((2 * r, 2 * r, seg)), ""))
        return out
    raise ValueError(kind)


def euler(R):
    """degrees (x, y, z) with R = Rx @ Ry @ Rz (Roblox CFrame.Angles)"""
    e = R.to_euler("ZYX")
    out = [int(round(math.degrees(a))) % 360 for a in (e.x, e.y, e.z)]
    return [a - 360 if a > 180 else a for a in out]


def export(d):
    name = d["en"]
    kit.new_scene()
    m = blockcat.build(name)
    A = m.A
    look = blockcat.DESIGNS[name][1]
    rig = catrig.rig(m, A)
    fur = blockcat.hexrgb(look.get("fur"), None)
    roles_p = {blockcat.hexrgb(look.get(k), None) for k in ("patternColor", "third")} - {None}
    palette, index = [], {}
    lines = []
    for bone_b, objs in rig.bones.items():
        bone = SWAP.get(bone_b, bone_b)
        for obj in objs:
            got = part_of(obj)
            if not got:
                continue
            rgb = tuple(int(v) for v in obj["rgb"])
            if rgb not in index:
                role = "f" if rgb == fur else ("p" if rgb in roles_p else "-")
                index[rgb] = len(palette)
                palette.append("%02x%02x%02x%s" % (*rgb, role))
            emit, alpha = material(obj)
            for kind, pos, R, sz, flags in (got if isinstance(got, list) else [got]):
                if emit >= 1.0:
                    flags += "n"
                if alpha < 0.99:
                    flags += "a" + str(max(1, min(9, int(round((1 - alpha) * 10)))))
                fields = [str(BONES.index(bone)), kind, q(pos.x), q(pos.y), q(pos.z),
                          q(max(0.02, sz.x)), q(max(0.02, sz.y)), q(max(0.02, sz.z)), str(index[rgb]), flags or "-"]
                e = euler(R)
                if any(e):
                    fields += [str(a) for a in e]
                lines.append(" ".join(fields))
    pivots = []
    for bone in BONES:
        src = SWAP.get(bone, bone)
        if src in rig.bones or bone == "Body":
            p = rb(rig.pivot[src])
            pivots.append(f"{bone}={q(p.x)},{q(p.y)},{q(p.z)}")
    # the model's pivot: feet, under the middle of the body
    foot = rb(Vector((0, A["by"], 0)))
    return {"name": name, "pivot": f"{q(foot.x)},{q(foot.y)},{q(foot.z)}", "bones": " ".join(pivots),
            "palette": " ".join(palette), "parts": "\n".join(lines), "count": len(lines)}


def luau_string(s):
    assert "]]" not in s
    return "[[\n" + s + "]]"


with open(os.path.join(ROOT, "art", "source", "cat_designs.json"), encoding="utf-8") as f:
    designs = json.load(f)
os.makedirs(OUT, exist_ok=True)
stats = {}
for tier in ("Basic", "Rare", "Epic", "Legendary", "Mythical", "Secret"):
    if ONLY and tier not in ONLY:
        continue
    rows = [d for d in designs if d["tier"] == tier]
    out = ["--!strict",
           "-- Generated by art/blender/cats_export.py from the Blender cats (art/blender/cats_*.py). Do not edit.",
           f"-- {tier}: {len(rows)} designs in table order. Read by shared/CatShapes (format in the exporter).",
           "", "return {"]
    counts = []
    for d in rows:
        e = export(d)
        counts.append(e["count"])
        out.append("\t{")
        out.append(f"\t\tname = {json.dumps(e['name'])},")
        out.append(f"\t\tpivot = \"{e['pivot']}\",")
        out.append(f"\t\tbones = \"{e['bones']}\",")
        out.append(f"\t\tpalette = \"{e['palette']}\",")
        out.append(f"\t\tparts = {luau_string(e['parts'])},")
        out.append("\t},")
        print("exported", tier, d["n"], d["en"], e["count"])
    out.append("}")
    with open(os.path.join(OUT, f"{tier}.luau"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(out) + "\n")
    stats[tier] = (min(counts), max(counts), sum(counts) / len(counts))
TAB, NL = chr(9), chr(10)
# the design names per tier (shared/CatDesigns: Cats.luau reads names without loading the block data)
out = ["--!strict", "-- Generated by art/blender/cats_export.py from art/source/cat_designs.json (docs/Sweetpotato_Cats.xlsx).",
       "-- Do not edit. The 300 designs (50 per tier) in table order; shared/CatShapeData/<Tier> has their blocks.", "",
       "return {"]
for tier in ("Basic", "Rare", "Epic", "Legendary", "Mythical", "Secret"):
    out.append(TAB + f"{tier} = {{")
    for d in designs:
        if d["tier"] == tier:
            out.append(TAB * 2 + json.dumps(d["en"]) + ",")
    out.append(TAB + "},")
out.append("}")
with open(os.path.join(ROOT, "src", "shared", "CatDesigns.luau"), "w", encoding="utf-8", newline=NL) as f:
    f.write(NL.join(out) + NL)
for t, s in stats.items():
    print("TIER", t, "parts min %d max %d avg %.1f" % s)
print("FALLBACKS", len(fallbacks), sorted(set(n.split(".")[0] for n in fallbacks))[:40])
