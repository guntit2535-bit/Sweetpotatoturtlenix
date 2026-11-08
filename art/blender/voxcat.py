"""Voxel cats (revision round 2, task V1): an original chibi cat built on a voxel grid, in 3 style options.
The client's reference pictures (another game) only gave the direction: blocky pixel / brick creatures with a
dark outline. Nothing is copied.

  cat(style, look) -> kit.Model
    style: "pixel" (fine voxels, merged faces), "brick" (LEGO-like bricks with studs), "mix" (medium voxels,
           big sparkly eyes)
    look:  the game's cat data (shape Loaf / Slim / Fluffy, fur, second, pattern, patternColor, eyes)

Units: studs, front = -Y, up = +Z, feet on z = 0. Every voxel gets a colour key; faces between filled voxels
are dropped, the rest become one mesh per colour (flat shaded), so the look is crisp blocks.
"""
import math

import bmesh
from mathutils import Vector

import kit
from kit import Model

STYLES = {
    # v = voxel size; eye = eye width / height as a share of the head's half width
    "pixel": dict(v=0.125, eye=(0.34, 0.46), iris=False, bevel=0.0, studs=False),
    "brick": dict(v=0.25, eye=(0.42, 0.52), iris=True, bevel=0.03, studs=True),
    "mix": dict(v=0.16, eye=(0.5, 0.64), iris=True, bevel=0.0, studs=False),
}

SHAPES = {
    # leg height, body half sizes, head half sizes, tail radius
    "Loaf": dict(leg=0.65, body=(1.0, 1.3, 0.72), head=(1.3, 1.0, 1.05), tail=0.22, cheeks=0.0),
    "Slim": dict(leg=0.95, body=(0.82, 1.45, 0.62), head=(1.15, 0.95, 0.98), tail=0.18, cheeks=0.0),
    "Fluffy": dict(leg=0.55, body=(1.2, 1.35, 0.85), head=(1.45, 1.1, 1.12), tail=0.32, cheeks=0.22),
}

INK = (42, 36, 51)
PINK = (255, 150, 180)
WHITE = (255, 255, 255)


def rbox(p, c, h, r):
    """Inside a rounded box (centre c, half sizes h, corner radius r)."""
    q = [max(abs(p[i] - c[i]) - (h[i] - r), 0.0) for i in range(3)]
    return math.sqrt(q[0] ** 2 + q[1] ** 2 + q[2] ** 2) <= r


def seg_dist(p, a, b):
    ab = Vector(b) - Vector(a)
    t = max(0.0, min(1.0, (Vector(p) - Vector(a)).dot(ab) / ab.length_squared))
    return (Vector(p) - (Vector(a) + ab * t)).length


def hexrgb(h, default):
    if not h:
        return default
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def design(look):
    """Returns the body plan: a function (x, y, z) -> (part, colour key) or None, plus face anchors."""
    S = SHAPES.get(look.get("shape", "Loaf"), SHAPES["Loaf"])
    leg = S["leg"]
    bw, bd, bh = S["body"]
    hw, hd, hh = S["head"]
    body_c = (0.0, 0.5, leg + bh)
    head_c = (0.0, -0.85, leg + 2 * bh + hh * 0.55)
    head_front = head_c[1] - hd
    ear_z = head_c[2] + hh
    tail_pts = [(0, body_c[1] + bd - 0.1, body_c[2] + 0.1), (0, body_c[1] + bd + 0.45, body_c[2] + 0.55),
                (0, body_c[1] + bd + 0.55, body_c[2] + 1.25), (0, body_c[1] + bd + 0.3, body_c[2] + 1.8)]
    pattern = look.get("pattern", "solid")

    def at(x, y, z):
        # head (with cheeks for Fluffy) and muzzle
        if rbox((x, y, z), head_c, (hw + (S["cheeks"] if z < head_c[2] - 0.2 else 0), hd, hh), 0.35):
            return "head"
        # ears: pyramids on the head's top corners
        for ex in (-hw * 0.58, hw * 0.58):
            dz = z - (ear_z - 0.2)
            if 0 <= dz <= 1.1:
                k = 1 - dz / 1.1
                ey = head_c[1] - hd * 0.35
                if abs(x - ex) <= 0.55 * k + 0.05 and abs(y - ey) <= 0.22 * k + 0.08:
                    inner = abs(x - ex) <= 0.3 * k and y < ey and 0.12 < dz < 0.85
                    return "earin" if inner else "ear"
        if rbox((x, y, z), body_c, (bw, bd, bh), 0.4):
            return "body"
        for lx in (-bw * 0.55, bw * 0.55):
            for ly in (body_c[1] - bd * 0.7, body_c[1] + bd * 0.7):
                if abs(x - lx) <= 0.3 and abs(y - ly) <= 0.3 and 0 <= z <= leg + 0.3:
                    return "paw" if z < 0.28 else "leg"
        for a, b in zip(tail_pts, tail_pts[1:]):
            if seg_dist((x, y, z), a, b) <= S["tail"]:
                return "tailtip" if z > tail_pts[-2][2] + 0.25 else "tail"
        return None

    def colour(part, x, y, z):
        fur = "fur"
        if part == "tailtip":
            return "second"
        if part == "earin":
            return "pink"
        if part == "body" and y < body_c[1] - bd * 0.25 and z < body_c[2] + 0.1 and abs(x) < bw * 0.6:
            return "second"  # chest
        if part == "paw":
            return "second" if pattern in ("socks", "tuxedo") else fur
        if pattern == "tabby":
            if part == "body" and z > body_c[2] + bh * 0.3 and int(math.floor((y + 4) / 0.42)) % 2 == 0:
                return "pattern"
            if part == "head" and z > head_c[2] + hh * 0.55 and abs(x) < 0.55 and int(math.floor((x + 4) / 0.3)) % 2 == 0:
                return "pattern"
            # two stripes on each cheek
            if part == "head" and abs(x) > hw - 0.25 and y > head_c[1] - hd * 0.6 and int(math.floor((z + 4) / 0.32)) % 2 == 0 and abs(z - head_c[2]) < hh * 0.5:
                return "pattern"
            if part == "tail" and int(math.floor((z + 4) / 0.4)) % 2 == 0:
                return "pattern"
        if pattern == "patches":
            if (x - 0.6) ** 2 + (y - 0.9) ** 2 < 0.55 or (x + 0.7) ** 2 + (z - head_c[2] - 0.5) ** 2 < 0.35:
                return "pattern"
        if pattern == "spots":
            if part == "body" and (int(math.floor(x / 0.45)) + int(math.floor(y / 0.45))) % 3 == 0 and z > body_c[2]:
                return "pattern"
        if pattern == "tuxedo" and part == "body" and y < body_c[1]:
            return "second"
        return fur

    return at, colour, dict(head_c=head_c, head_front=head_front, hw=hw, hh=hh, body_c=body_c, bh=bh, bd=bd)


def face_pixel(style, fx, fz, a, look):
    """Colour key of the face at (fx, fz) on the front surface, or None (keep the fur). Sizes follow the head."""
    hc = a["head_c"]
    hw = a["hw"]
    ew, eh = STYLES[style]["eye"][0] * hw, STYLES[style]["eye"][1] * hw
    ez = hc[2] + a["hh"] * 0.08
    for sx in (-1, 1):
        ex = sx * hw * 0.5
        dx, dz = fx - ex, fz - ez
        if abs(dx) <= ew / 2 and abs(dz) <= eh / 2:
            # two shines (a big one up left, a small one down right), an iris in the lower part
            if -ew * 0.45 <= dx <= -ew * 0.02 and eh * 0.08 <= dz <= eh * 0.45:
                return "white"
            if ew * 0.12 <= dx <= ew * 0.4 and -eh * 0.42 <= dz <= -eh * 0.2:
                return "white"
            if STYLES[style]["iris"] and dz < -eh * 0.02:
                return "iris"
            return "ink"
    nz = ez - eh * 0.5 - hw * 0.22
    if abs(fx) <= hw * 0.1 and nz - hw * 0.05 <= fz <= nz + hw * 0.06:
        return "pink"  # nose
    # a small "w" mouth under the nose
    mz = nz - hw * 0.12
    if abs(fz - mz) <= hw * 0.045 and (hw * 0.04 <= abs(fx) <= hw * 0.2) and abs(abs(fx) - hw * 0.12) > hw * 0.035:
        return "ink"
    if abs(fz - (mz + hw * 0.06)) <= hw * 0.04 and abs(fx) <= hw * 0.04:
        return "ink"
    # muzzle patch (second colour), blush
    if abs(fx) <= hw * 0.42 and nz - hw * 0.32 <= fz <= nz + hw * 0.12:
        return "second"
    for sx in (-1, 1):
        if abs(fx - sx * hw * 0.74) <= hw * 0.14 and abs(fz - (ez - eh * 0.62)) <= hw * 0.06:
            return "blush"
    return None


def voxels(style, look):
    v = STYLES[style]["v"]
    at, colour, a = design(look)
    grid = {}
    nx, ny, nz = int(2.4 / v) + 2, int(3.6 / v) + 2, int(5.2 / v) + 2
    for i in range(-nx, nx + 1):
        x = (i + 0.5) * v
        for j in range(-ny, ny + 1):
            y = (j + 0.5) * v
            for k in range(0, nz + 1):
                z = (k + 0.5) * v
                part = at(x, y, z)
                if part:
                    grid[(i, j, k)] = (part, colour(part, x, y, z))
    # the face: paint the frontmost voxel of every column on the head / muzzle
    front = {}
    for (i, j, k), (part, _) in grid.items():
        if part == "head" and ((i, k) not in front or j < front[(i, k)]):
            front[(i, k)] = j
    for (i, k), j in front.items():
        f = face_pixel(style, (i + 0.5) * v, (k + 0.5) * v, a, look)
        if f:
            grid[(i, j, k)] = (grid[(i, j, k)][0], f)
    return grid, v


def palette(look):
    return {
        "fur": hexrgb(look.get("fur"), (255, 179, 71)),
        "second": hexrgb(look.get("second"), (255, 240, 214)),
        "pattern": hexrgb(look.get("patternColor"), (214, 112, 40)),
        "pink": PINK,
        "blush": (255, 170, 190),
        "ink": INK,
        "white": WHITE,
        "iris": hexrgb(look.get("eyes"), (60, 150, 255)),
    }


NB = [((1, 0, 0), 0), ((-1, 0, 0), 0), ((0, 1, 0), 1), ((0, -1, 0), 1), ((0, 0, 1), 2), ((0, 0, -1), 2)]


def cat(style, look, name="VoxCat"):
    grid, v = voxels(style, look)
    pal = palette(look)
    m = Model(name)
    S = STYLES[style]
    by_colour = {}
    for (i, j, k), (_, key) in grid.items():
        by_colour.setdefault(key, []).append((i, j, k))
    for key, cells in by_colour.items():
        bm = bmesh.new()
        if True:
            vmap = {}

            def vert(p):
                if p not in vmap:
                    vmap[p] = bm.verts.new((p[0] * v, p[1] * v, p[2] * v))
                return vmap[p]

            for (i, j, k) in cells:
                for d, axis in NB:
                    if (i + d[0], j + d[1], k + d[2]) in grid:
                        continue
                    # the quad on that side of the voxel
                    base = [i, j, k]
                    if d[axis] > 0:
                        base[axis] += 1
                    o = [a for a in range(3) if a != axis]
                    q = []
                    for du, dv in ((0, 0), (1, 0), (1, 1), (0, 1)):
                        p = list(base)
                        p[o[0]] += du
                        p[o[1]] += dv
                        q.append(vert(tuple(p)))
                    if d[axis] < 0:
                        q.reverse()
                    try:
                        bm.faces.new(q if axis != 1 else list(reversed(q)))
                    except ValueError:
                        pass
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
            if S["studs"]:
                for (i, j, k) in cells:
                    if (i, j, k + 1) not in grid and (i + j) % 2 == 0 and grid[(i, j, k)][0] in ("head", "body", "ear"):
                        c = Vector(((i + 0.5) * v, (j + 0.5) * v, (k + 1) * v))
                        cy = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=v * 0.32, radius2=v * 0.32,
                                                   depth=v * 0.3)
                        bmesh.ops.translate(bm, verts=cy["verts"], vec=c + Vector((0, 0, v * 0.15)))
        obj = m.add(bm, pal.get(key, (255, 0, 255)), key, smooth=False, rough=0.35 if style == "brick" else 0.55,
                    coat=0.6 if style == "brick" else 0.0)
        if S["bevel"]:
            mod = obj.modifiers.new("Bevel", "BEVEL")
            mod.width = S["bevel"]
            mod.segments = 2
    return m


def outline(scene, px=2.2):
    """Dark outline round the silhouette (Freestyle), like the reference direction."""
    import bpy

    scene.render.use_freestyle = True
    scene.render.line_thickness_mode = "ABSOLUTE"
    scene.render.line_thickness = px
    vl = scene.view_layers[0]
    vl.use_freestyle = True
    fs = vl.freestyle_settings
    ls = fs.linesets[0] if fs.linesets else fs.linesets.new("Lines")
    ls.select_by_visibility = True
    ls.select_by_edge_types = True
    ls.select_silhouette = True
    ls.select_border = False  # (True drew a box round every colour patch)
    ls.select_crease = False
    ls.select_external_contour = True
    if ls.linestyle is None:
        ls.linestyle = bpy.data.linestyles.new("Outline")
    ls.linestyle.color = (0.10, 0.08, 0.13)
    ls.linestyle.thickness = px
    _ = bpy
