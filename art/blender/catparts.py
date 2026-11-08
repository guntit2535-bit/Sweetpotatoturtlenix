"""Parts for the block cats above Basic (round 2): hats, glasses, clothes, things they hold, wings and the effect
around Mythical / Secret cats. Every part is a simple shape that becomes a Roblox part in the game: a box (with
studs or plain), a ball, a cylinder or a wedge (obj["shape"]).

The name prefix gives the bone (art/blender/catrig.py): H_ head, B_ body, L_ leg (by position), T_ tail,
W_ wing (by side), Fx the effect (moves on its own around the cat).
"""
import math
import random
from types import SimpleNamespace

import bmesh
import bpy
from mathutils import Matrix, Vector

from blockcat import GOLD, GOLD_DARK, INK, PINK, WHITE, block, hexrgb, shade
from kit import R, T

SILVER = (205, 212, 225)
RED = (230, 60, 70)
BLUE = (60, 120, 230)
GREEN = (80, 190, 90)
BROWN = (130, 85, 50)
WOOD = (170, 115, 65)
BLACK = (40, 36, 48)


def C(c):
    if isinstance(c, str):
        return hexrgb(c, (255, 0, 255))
    return tuple(int(v) for v in c)


def mix(a, b, k=0.5):
    a, b = C(a), C(b)
    return tuple(int(x + (y - x) * k) for x, y in zip(a, b))


def G(A):
    """Handy numbers of a cat (from base()'s attach points)."""
    g = dict(A)
    g["top"] = A["head_top"]
    g["hb"] = A["hz"] - A["hh"] / 2
    g["btop"] = A["leg"] + A["bh"]
    g["bfront"] = A["by"] - A["bl"] / 2
    g["bback"] = A["by"] + A["bl"] / 2
    g["HEAD"] = ((0, A["hy"], A["hz"]), (A["hw"], A["hd"], A["hh"]))
    g["BODY"] = ((0, A["by"], A["bz"]), (A["bw"], A["bl"], A["bh"]))
    g["side"] = A["bw"] / 2  # body half width
    return SimpleNamespace(**g)


# -- shapes ----------------------------------------------------------------------------------------------------
def box(m, c, s, col, bone="B", name="Box", fr=None, studs=True, **o):
    obj = block(m, c, s, C(col), frame=fr or Matrix(), name=f"{bone}_{name}", sides="all" if studs else "none",
                bevel=0.035 if studs else 0.02, **o)
    obj["shape"] = "Block"
    return obj


def plate(m, c, s, col, bone="B", name="Plate", fr=None, **o):
    """A box with studs only on top."""
    obj = block(m, c, s, C(col), frame=fr or Matrix(), name=f"{bone}_{name}", sides="top", **o)
    obj["shape"] = "Block"
    return obj


def ball(m, c, r, col, bone="B", name="Ball", fr=None, **o):
    rr = r if isinstance(r, tuple) else (r, r, r)
    o.setdefault("rough", 0.3)
    o.setdefault("coat", 0.4)
    obj = m.blob(rr, C(col), (fr or Matrix()) @ T(*c), e1=1.0, e2=1.0, nu=20, nv=12, name=f"{bone}_{name}", **o)
    obj["shape"] = "Ball"
    return obj


def cyl(m, c, r, h, col, bone="B", name="Cyl", fr=None, axis="Z", r2=None, seg=18, **o):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=h)
    rot = {"Z": Matrix(), "X": R(math.pi / 2, "Y"), "Y": R(math.pi / 2, "X")}[axis]
    bmesh.ops.transform(bm, matrix=(fr or Matrix()) @ T(*c) @ rot, verts=bm.verts[:])
    o.setdefault("rough", 0.32)
    o.setdefault("coat", 0.35)
    obj = m.add(bm, C(col), f"{bone}_{name}", smooth=False, **o)
    obj["shape"] = "Cylinder" if r2 is None else "Cone"
    return obj


def wedge(m, c, s, col, bone="B", name="Wedge", fr=None, **o):
    """A ramp: full bottom, full +Y face, sloping down to -Y."""
    sx, sy, sz = s
    bm = bmesh.new()
    v = [bm.verts.new(p) for p in ((-sx / 2, -sy / 2, -sz / 2), (-sx / 2, sy / 2, -sz / 2), (-sx / 2, sy / 2, sz / 2),
                                    (sx / 2, -sy / 2, -sz / 2), (sx / 2, sy / 2, -sz / 2), (sx / 2, sy / 2, sz / 2))]
    for f in ((0, 1, 2), (3, 5, 4), (0, 3, 4, 1), (1, 4, 5, 2), (0, 2, 5, 3)):
        bm.faces.new([v[i] for i in f])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bmesh.ops.transform(bm, matrix=(fr or Matrix()) @ T(*c), verts=bm.verts[:])
    o.setdefault("rough", 0.32)
    o.setdefault("coat", 0.35)
    obj = m.add(bm, C(col), f"{bone}_{name}", smooth=False, **o)
    obj["shape"] = "Wedge"
    return obj


def ring(m, c, rr, n, s, col, bone="B", name="Ring", fr=None, studs=False, phase=0.0, **o):
    """n boxes round a circle (radius rr) in the XY plane of fr, at c."""
    out = []
    for k in range(n):
        a = phase + k * 2 * math.pi / n
        f = (fr or Matrix()) @ T(*c) @ R(a, "Z") @ T(rr, 0, 0)
        cols = col[k % len(col)] if isinstance(col, list) else col
        out.append(box(m, (0, 0, 0), s, cols, bone, name, fr=f, studs=studs, **o))
    return out


def stack(m, c, w0, w1, h, n, col, bone="H", name="Stack", fr=None, d0=None, d1=None, studs=True, **o):
    """n boxes stacked from width w0 at the bottom to w1 at the top (a stepped cone), base centre c."""
    d0 = w0 if d0 is None else d0
    d1 = w1 if d1 is None else d1
    hs = h / n
    for k in range(n):
        t = k / max(1, n - 1)
        w, d = w0 + (w1 - w0) * t, d0 + (d1 - d0) * t
        cols = col[k % len(col)] if isinstance(col, list) else col
        box(m, (c[0], c[1], c[2] + hs * (k + 0.5)), (w, d, hs + 0.002), cols, bone, name, fr=fr, studs=studs, **o)
    return (c[0], c[1], c[2] + h)


def about(p, rot):
    p = Vector(p)
    return Matrix.Translation(p) @ rot @ Matrix.Translation(-p)


def remove(m, names):
    for o in list(m.objects):
        if o.name.split(".")[0] in names:
            m.objects.remove(o)
            bpy.data.objects.remove(o)


def recolor(m, names, col):
    from kit import mat
    for o in m.objects:
        if o.name.split(".")[0] in names:
            o.data.materials.clear()
            o.data.materials.append(mat(C(col), rough=0.32, coat=0.35))
            o["rgb"] = list(C(col))


def ears_out(m, A, angle=0.8, push=0.45, drop=0.3):
    """Tilt the ears out to the head's top corners so a hat fits between them."""
    a = G(A)
    for o in m.objects:
        if o.name.split(".")[0] in ("Ear", "EarIn"):
            cx = sum((o.matrix_world @ v.co).x for v in o.data.vertices) / max(1, len(o.data.vertices))
            x = 1 if cx > 0 else -1
            p = (x * (a.hw / 2 - 0.55), a.hy, a.top)
            o.matrix_world = T(x * push, 0, -drop) @ about(p, R(x * angle, "Y")) @ o.matrix_world


# -- head: hats ----------------------------------------------------------------------------------------------------
def cap(m, A, col, back=True, logo=None):
    a = G(A)
    ears_out(m, A)
    w, d = a.hw * 0.74, a.hd * 0.82
    box(m, (0, a.hy, a.top + 0.32), (w, d, 0.64), col, "H", "Hat")
    s = 1 if back else -1
    plate(m, (0, a.hy + s * (d / 2 + 0.4), a.top + 0.08), (w * 0.8, 0.85, 0.14), shade(C(col), 0.85), "H", "Brim")
    box(m, (0, a.hy, a.top + 0.7), (0.3, 0.3, 0.14), shade(C(col), 0.8), "H", "Hat", studs=False)
    if logo:
        box(m, (0, a.hy - s * (d / 2 + 0.03), a.top + 0.3), (0.5, 0.06, 0.32), logo, "H", "Logo", studs=False)


def top_hat(m, A, col, band, h=1.5, w=0.6):
    a = G(A)
    plate(m, (0, a.hy, a.top + 0.08), (a.hw * 0.95, a.hd * 0.95, 0.16), col, "H", "Brim")
    box(m, (0, a.hy, a.top + 0.16 + h / 2), (a.hw * w, a.hd * w, h), col, "H", "Hat")
    box(m, (0, a.hy, a.top + 0.34), (a.hw * w + 0.06, a.hd * w + 0.06, 0.32), band, "H", "Band", studs=False)
    return a.top + 0.16 + h


def brim_hat(m, A, col, crown=None, band=None, brim=1.55, h=0.75, cw=0.68, studs=True):
    """A hat with a wide round-ish brim (sunhat, cowboy, ranger, bucket)."""
    a = G(A)
    ears_out(m, A)
    crown = crown or col
    plate(m, (0, a.hy, a.top + 0.08), (a.hw * brim, a.hd * brim, 0.14), col, "H", "Brim")
    plate(m, (0, a.hy, a.top + 0.08), (a.hw * brim * 0.8, a.hd * brim * 1.12, 0.14), col, "H", "Brim")
    box(m, (0, a.hy, a.top + 0.15 + h / 2), (a.hw * cw, a.hd * cw, h), crown, "H", "Hat", studs=studs)
    if band:
        box(m, (0, a.hy, a.top + 0.3), (a.hw * cw + 0.06, a.hd * cw + 0.06, 0.26), band, "H", "Band", studs=False)
    return a.top + 0.15 + h


def beanie(m, A, col, band=None, pom=WHITE):
    a = G(A)
    ears_out(m, A, 0.35)
    stack(m, (0, a.hy, a.top - 0.1), a.hw * 0.9, a.hw * 0.55, 1.0, 3, col, d0=a.hd * 0.92, d1=a.hd * 0.6)
    box(m, (0, a.hy, a.top + 0.02), (a.hw * 0.94, a.hd * 0.96, 0.3), band or shade(C(col), 0.85), "H", "Band", studs=False)
    if pom:
        ball(m, (0, a.hy, a.top + 1.1), 0.36, pom, "H", "Pom")


def cone_hat(m, A, cols, h=1.9, w=1.3, tilt=0.15, pom=None, n=5, brim=None):
    """Party / wizard / witch hat: a stepped cone, a bit tilted."""
    a = G(A)
    fr = about((0, a.hy, a.top), R(tilt, "Y"))
    if brim or w > a.hw * 0.6:
        ears_out(m, A)
    if brim:
        plate(m, (0, a.hy, a.top + 0.08), (a.hw * brim, a.hd * brim, 0.14), cols[0] if isinstance(cols, list) else cols, "H", "Brim", fr=fr)
    end = stack(m, (0, a.hy, a.top + (0.14 if brim else 0)), w, 0.25, h, n, cols, fr=fr)
    if pom:
        ball(m, end, 0.24, pom, "H", "Pom", fr=fr)
    return fr @ Vector(end)


def beret(m, A, col):
    a = G(A)
    fr = about((0, a.hy, a.top), R(-0.18, "Y") @ R(0.08, "X"))
    box(m, (0.15, a.hy, a.top + 0.2), (a.hw * 0.95, a.hd * 0.95, 0.36), col, "H", "Hat", fr=fr)
    box(m, (0.15, a.hy, a.top + 0.45), (0.18, 0.18, 0.2), col, "H", "Hat", fr=fr, studs=False)


def crown(m, A, col=GOLD, gems=((255, 70, 110), (80, 190, 255)), w=0.75, h=0.45, tips=5, emit=0.0):
    a = G(A)
    ears_out(m, A)
    cw, cd = a.hw * w, a.hd * w
    box(m, (0, a.hy, a.top + h / 2), (cw, cd, h), col, "H", "Crown", emit=emit)
    for k in range(tips):
        x = -cw / 2 + 0.16 + k * (cw - 0.32) / max(1, tips - 1)
        th = 0.45 if k % 2 == 0 else 0.3
        for y in (-1, 1):
            box(m, (x, a.hy + y * (cd / 2 - 0.12), a.top + h + th / 2), (0.24, 0.24, th), col, "H", "Crown", studs=False, emit=emit)
    for k, g in enumerate(gems or ()):
        x = (k - (len(gems) - 1) / 2) * 0.45
        box(m, (x, a.hy - cd / 2 - 0.05, a.top + h / 2), (0.24, 0.08, 0.24), g, "H", "Gem", studs=False, emit=0.4)
    return a.top + h


def headband(m, A, col, knot=True, tails=True):
    a = G(A)
    box(m, (0, a.hy, a.hz + a.hh * 0.32), (a.hw + 0.2, a.hd + 0.2, 0.32), col, "H", "Band", studs=False)
    if knot:
        box(m, (0, a.hy + a.hd / 2 + 0.12, a.hz + a.hh * 0.32), (0.36, 0.24, 0.36), col, "H", "Knot", studs=False)
    if tails:
        for x in (-1, 1):
            box(m, (x * 0.2, a.hy + a.hd / 2 + 0.45, a.hz + a.hh * 0.1), (0.22, 0.6, 0.12), col, "H", "Knot", studs=False,
                fr=about((0, a.hy + a.hd / 2, a.hz + a.hh * 0.32), R(x * 0.4, "Z") @ R(0.5, "X")))


def bow(m, c, col, s=1.0, bone="H", knot=None, fr=None):
    """A ribbon bow (two loops and a knot) facing -Y."""
    for x in (-1, 1):
        box(m, (c[0] + x * 0.42 * s, c[1], c[2]), (0.6 * s, 0.25 * s, 0.5 * s), col, bone, "Bow", studs=False,
            fr=(fr or Matrix()) @ about(c, R(x * 0.2, "Y")))
    box(m, c, (0.26 * s, 0.32 * s, 0.3 * s), knot or shade(C(col), 0.85), bone, "Bow", studs=False, fr=fr)


def headphones(m, A, band, cup, wide=0.0):
    a = G(A)
    ears_out(m, A, 0.5)
    box(m, (0, a.hy + 0.1, a.top + 0.18), (a.hw * 0.75, 0.36, 0.22), band, "H", "Band", studs=False)
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.05), a.hy + 0.1, a.top - 0.2), (0.22, 0.36, 0.7), band, "H", "Band", studs=False)
        box(m, (x * (a.hw / 2 + 0.2 + wide), a.hy + 0.05, a.hz + 0.05), (0.42 + wide, 1.0, 1.0), cup, "H", "Cup")
        box(m, (x * (a.hw / 2 + 0.43 + wide * 2), a.hy + 0.05, a.hz + 0.05), (0.08, 0.6, 0.6), shade(C(cup), 0.7), "H", "Cup", studs=False)


def hood(m, A, col, inner=None, ears=True):
    a = G(A)
    remove(m, ("Ear", "EarIn"))
    t = 0.24
    box(m, (0, a.hy + 0.12, a.top + t / 2), (a.hw + 2 * t, a.hd + 0.1, t), col, "H", "Hood")
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + t / 2), a.hy + 0.12, a.hz + 0.15), (t, a.hd + 0.1, a.hh * 0.85), col, "H", "Hood")
    box(m, (0, a.hy + a.hd / 2 + t / 2, a.hz + 0.15), (a.hw + 2 * t, t, a.hh * 0.85 + t), col, "H", "Hood")
    if ears:
        for x in (-1, 1):
            box(m, (x * (a.hw / 2 - 0.45), a.hy + 0.15, a.top + 0.5), (0.9, 0.5, 0.6), col, "H", "Hood")
            box(m, (x * (a.hw / 2 - 0.4), a.hy + 0.15, a.top + 0.95), (0.5, 0.4, 0.4), col, "H", "Hood")
            if inner:
                box(m, (x * (a.hw / 2 - 0.45), a.hy - 0.12, a.top + 0.55), (0.45, 0.08, 0.38), inner, "H", "Hood", studs=False)


def helmet(m, A, col, visor=None, crest=None, h=0.7):
    a = G(A)
    remove(m, ("Ear", "EarIn"))
    box(m, (0, a.hy + 0.05, a.top + h / 2 - 0.25), (a.hw + 0.3, a.hd + 0.25, h), col, "H", "Helmet")
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.12), a.hy + 0.25, a.hz + 0.2), (0.24, a.hd * 0.8, a.hh * 0.7), col, "H", "Helmet")
    if visor:
        box(m, (0, a.hy - a.hd / 2 - 0.15, a.top - 0.15), (a.hw + 0.2, 0.4, 0.2), visor, "H", "Visor", studs=False)
    if crest:
        box(m, (0, a.hy + 0.1, a.top + h - 0.1), (0.3, a.hd * 0.9, 0.6), crest, "H", "Crest")


# -- head: face ----------------------------------------------------------------------------------------------------
def glasses(m, A, frame=INK, lens=(40, 44, 70), kind="square", glint=True, emit=0.0):
    a = G(A)
    f, ez = a.front, a.eyes[0].z
    y = f - 0.22
    for e in a.eyes:
        if kind == "square":
            box(m, (e.x, y, ez - 0.05), (0.9, 0.12, 0.7), frame, "H", "Glasses", studs=False)
            box(m, (e.x, y - 0.04, ez - 0.05), (0.72, 0.1, 0.52), lens, "H", "Lens", studs=False, rough=0.05, coat=1.0, emit=emit)
        elif kind == "round":
            cyl(m, (e.x, y, ez - 0.02), 0.48, 0.12, frame, "H", "Glasses", axis="Y")
            cyl(m, (e.x, y - 0.03, ez - 0.02), 0.36, 0.12, lens, "H", "Lens", axis="Y", rough=0.05, coat=1.0, alpha=0.6 if lens == WHITE else 1.0)
        elif kind == "heart":
            for dx in (-0.18, 0.18):
                box(m, (e.x + dx, y, ez + 0.1), (0.42, 0.12, 0.42), frame, "H", "Glasses", studs=False)
            box(m, (e.x, y, ez - 0.12), (0.46, 0.12, 0.46), frame, "H", "Glasses", studs=False, fr=about((e.x, y, ez - 0.12), R(0.785, "Y")))
            box(m, (e.x, y - 0.05, ez), (0.5, 0.08, 0.36), lens, "H", "Lens", studs=False, emit=emit)
        elif kind == "star":
            for ang in (0, 1.2566, 2.513, 3.77, 5.026):
                box(m, (0, 0, 0.3), (0.26, 0.12, 0.5), frame, "H", "Glasses", studs=False,
                    fr=T(e.x, y, ez) @ R(ang, "Y"))
            box(m, (e.x, y - 0.05, ez), (0.42, 0.08, 0.42), lens, "H", "Lens", studs=False, emit=emit)
        if glint and kind in ("square",):
            box(m, (e.x - 0.18, y - 0.1, ez + 0.08), (0.2, 0.05, 0.12), (190, 225, 255), "H", "Glint", studs=False, emit=0.6)
    box(m, (0, y, ez + 0.12), (abs(a.eyes[0].x - a.eyes[1].x) - 0.6, 0.1, 0.12), frame, "H", "Glasses", studs=False)
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.03), a.hy - 0.25, ez + 0.08), (0.1, a.hd * 0.7, 0.12), frame, "H", "Glasses", studs=False)


def goggles(m, A, strap, lens, z=None, up=True):
    """Ski / dive / pilot goggles; up=True wears them on the forehead."""
    a = G(A)
    ez = a.eyes[0].z
    gz = (a.top - 0.35) if up else ez
    box(m, (0, a.hy, gz), (a.hw + 0.2, a.hd + 0.2, 0.3), strap, "H", "Strap", studs=False)
    for e in a.eyes:
        box(m, (e.x, a.front - 0.12, gz), (0.85, 0.28, 0.62), strap, "H", "Goggle", studs=False)
        box(m, (e.x, a.front - 0.27, gz), (0.68, 0.06, 0.46), lens, "H", "Lens", studs=False, rough=0.05, coat=1.0, emit=0.15)


def mustache(m, A, col=INK, curl=True):
    a = G(A)
    for x in (-1, 1):
        box(m, (x * 0.35, a.front - 0.5, a.mz + 0.02), (0.55, 0.1, 0.14), col, "H", "Stache", studs=False,
            fr=about((x * 0.1, a.front - 0.5, a.mz), R(-x * 0.25, "Y")))
        if curl:
            box(m, (x * 0.68, a.front - 0.5, a.mz + 0.14), (0.14, 0.1, 0.22), col, "H", "Stache", studs=False)


def mask_band(m, A, col, holes=True):
    a = G(A)
    ez = a.eyes[0].z
    box(m, (0, a.front - 0.04, ez), (a.hw + 0.06, 0.1, 0.62), col, "H", "Mask", studs=False)
    box(m, (0, a.hy, ez), (a.hw + 0.2, a.hd + 0.2, 0.4), col, "H", "Mask", studs=False)


def face_cover(m, A, col):
    """Ninja style: cloth over the lower face."""
    a = G(A)
    box(m, (0, a.hy - 0.02, a.mz - 0.05), (a.hw + 0.2, a.hd + 0.2, a.hh * 0.42), col, "H", "Cover", studs=False)
    box(m, (0, a.front - 0.3, a.mz), (1.4, 0.5, 0.8), col, "H", "Cover", studs=False)


def red_nose(m, A, col=(240, 40, 50)):
    a = G(A)
    ball(m, (0, a.front - 0.55, a.mz + 0.22), 0.24, col, "H", "Nose", emit=0.3)


def beak(m, A, col, long=0.6):
    a = G(A)
    box(m, (0, a.front - long / 2, a.mz + 0.05), (0.9, long, 0.32), col, "H", "Beak", studs=False)
    box(m, (0, a.front - long / 2 + 0.05, a.mz - 0.2), (0.8, long - 0.1, 0.2), shade(C(col), 0.85), "H", "Beak", studs=False)


# -- neck and body ---------------------------------------------------------------------------------------------------
def collar(m, A, col, h=0.32, gem=None, studs=False):
    a = G(A)
    box(m, (0, a.hy, a.hb + h / 2 + 0.02), (a.hw + 0.22, a.hd + 0.22, h), col, "H", "Collar", studs=studs)
    if gem:
        box(m, (0, a.front - 0.1, a.hb + h / 2 - 0.05), (0.32, 0.12, 0.32), gem, "H", "Gem", studs=False, emit=0.5,
            fr=about((0, a.front - 0.1, a.hb + h / 2 - 0.05), R(0.785, "Y")))


def bow_tie(m, A, col, s=1.0):
    a = G(A)
    bow(m, (0, a.front - 0.1, a.hb + 0.18), col, s * 0.9)


def necktie(m, A, col, shirt=None, long=1.1):
    a = G(A)
    if shirt:
        for x in (-1, 1):
            wedge(m, (x * 0.35, a.front - 0.1, a.hb + 0.12), (0.5, 0.12, 0.4), shirt, "H", "Shirt",
                  fr=about((x * 0.35, a.front - 0.1, a.hb + 0.12), R(math.pi / 2, "X") @ R(x * 0.6, "Y")))
    box(m, (0, a.front - 0.12, a.hb + 0.12), (0.3, 0.14, 0.26), col, "H", "Tie", studs=False)
    box(m, (0, a.bfront - CLOTH - 0.06, a.hb - long / 2), (0.36, 0.1, long), col, "B", "Tie", studs=False)


def scarf(m, A, cols, tail=True):
    a = G(A)
    box(m, (0, a.hy, a.hb + 0.2), (a.hw + 0.2, a.hd + 0.2, 0.42), cols[0], "H", "Scarf", studs=False)
    for k in range(4 if tail else 0):
        box(m, (-a.hw * 0.25, a.front - 0.15, a.hb - 0.2 - k * 0.35), (0.6, 0.18, 0.35), cols[k % len(cols)], "B", "Scarf", studs=False)
    for k in range(3):
        box(m, (k * 0.5 - 0.5, a.front - 0.12, a.hb + 0.2), (0.25, 0.08, 0.44), cols[1 % len(cols)], "H", "Scarf", studs=False)


def necklace(m, A, col, n=14, r=0.12, drop=0.0, rows=1, pendant=None, emit=0.0):
    a = G(A)
    for row in range(rows):
        for k in range(n):
            t = k / (n - 1)
            x = -a.hw * 0.42 + t * a.hw * 0.84
            z = a.hb + 0.08 - drop - row * 0.25 - 0.25 * math.sin(math.pi * t)
            ball(m, (x, a.front - 0.12, z), r, col, "H", "Bead", emit=emit)
    if pendant:
        box(m, (0, a.front - 0.15, a.hb - 0.25 - drop - rows * 0.2), (0.45, 0.12, 0.45), pendant, "H", "Pendant", studs=False,
            emit=0.5, fr=about((0, a.front - 0.15, a.hb - 0.25 - drop - rows * 0.2), R(0.785, "Y")))


def lei(m, A, cols):
    a = G(A)
    for k in range(16):
        ang = k * 2 * math.pi / 16
        x, y = math.cos(ang) * (a.hw / 2 + 0.15), a.hy + math.sin(ang) * (a.hd / 2 + 0.15)
        box(m, (x, y, a.hb + 0.15), (0.38, 0.38, 0.32), cols[k % len(cols)], "H", "Flower", studs=False,
            fr=about((x, y, a.hb + 0.15), R(ang + 0.4, "Z")))


CLOTH = 0.22  # clothes stand this far off the body, over its studs and pattern patches


def shirt(m, A, col, bands=None, h=0.8, front=True, stripes=None):
    """A top round the body from h below its top (studs only on top). stripes = colours of bands from the bottom."""
    a = G(A)
    z0, z1 = a.btop - h, a.btop + 0.2
    hh = z1 - z0
    size = (a.bw + 2 * CLOTH, a.bl + 2 * CLOTH)
    if stripes:
        n = len(stripes) if bands is None else bands
        for k in range(n):
            plate(m, (0, a.by, z0 + hh * (k + 0.5) / n), size + (hh / n + 0.001,), stripes[k % len(stripes)], "B", "Shirt")
    else:
        plate(m, (0, a.by, z0 + hh / 2), size + (hh,), col, "B", "Shirt")


def coat(m, A, col, trim=None, open_front=True):
    """A long coat: covers the body, down to the knees."""
    a = G(A)
    h = a.bh + a.leg * 0.45 + 0.2
    z = a.btop + 0.2 - h / 2
    plate(m, (0, a.by, z), (a.bw + 2 * CLOTH, a.bl + 2 * CLOTH, h), col, "B", "Coat")
    if trim:
        for x in (-1, 1):
            box(m, (x * 0.42, a.bfront - CLOTH - 0.04, a.btop - h / 2 - 0.2), (0.22, 0.12, h - 0.4), trim, "B", "Coat", studs=False)


def overall(m, A, col, strap=None):
    a = G(A)
    plate(m, (0, a.by, a.leg + 0.4), (a.bw + 2 * CLOTH, a.bl + 2 * CLOTH, 0.8), col, "B", "Pants")
    box(m, (0, a.bfront - CLOTH, a.leg + 1.0), (a.bw * 0.6, 0.12, 0.9), col, "B", "Pants", studs=False)
    for x in (-1, 1):
        box(m, (x * a.bw * 0.25, a.by, a.btop + 0.14), (0.28, a.bl + 2 * CLOTH + 0.04, 0.12), strap or col, "B", "Strap", studs=False)
        box(m, (x * a.bw * 0.25, a.bfront - CLOTH - 0.06, a.leg + 1.3), (0.24, 0.08, 0.24), GOLD, "B", "Button", studs=False)


def skirt(m, A, col, layers=2, wide=0.55, col2=None):
    a = G(A)
    for k in range(layers):
        z = a.leg + 0.1 + k * 0.22
        cc = col if k % 2 == 0 or not col2 else col2
        plate(m, (0, a.by, z), (a.bw + wide * 2 - k * 0.3, a.bl + wide * 2 - k * 0.3, 0.2), cc, "B", "Skirt")


def cape(m, A, col, inner=None, collar_up=False, long=1.0):
    a = G(A)
    box(m, (0, a.by + 0.2, a.btop + 0.12), (a.bw + 0.5, a.bl * 0.85, 0.14), col, "B", "Cape", studs=False)
    box(m, (0, a.bback + 0.18, a.btop - a.bh * 0.55 * long + 0.1), (a.bw + 0.5, 0.14, a.bh * 1.1 * long), col, "B", "Cape", studs=False)
    for x in (-1, 1):
        box(m, (x * (a.bw / 2 + 0.25), a.by + 0.4, a.btop - a.bh * 0.35), (0.14, a.bl * 0.7, a.bh * 0.8), inner or col, "B", "Cape", studs=False)
    if collar_up:
        for x in (-1, 1):
            box(m, (x * (a.hw / 2 + 0.1), a.hy + a.hd / 2 - 0.1, a.hb + 0.5), (0.18, 0.5, 1.0), inner or col, "H", "CapeCollar", studs=False,
                fr=about((x * (a.hw / 2), a.hy + a.hd / 2, a.hb), R(x * 0.25, "Y")))


def armour(m, A, col, trim=None):
    a = G(A)
    plate(m, (0, a.by, a.bz + 0.25), (a.bw + 2 * CLOTH, a.bl + 2 * CLOTH, a.bh * 0.75 + 0.2), col, "B", "Armour", rough=0.2)
    box(m, (0, a.bfront - CLOTH - 0.06, a.bz + 0.1), (a.bw * 0.7, 0.14, a.bh * 0.6), trim or shade(C(col), 0.85), "B", "Armour", studs=False)
    for x in (-1, 1):
        box(m, (x * (a.bw / 2 + 0.2), a.bfront + 0.3, a.btop - 0.1), (0.5, 0.9, 0.35), col, "B", "Pad")


def backpack(m, A, col, flap=None):
    a = G(A)
    y = a.by + 0.45
    box(m, (0, y, a.btop + 0.55), (a.bw * 0.75, a.bl * 0.45, 1.1), col, "B", "Pack")
    box(m, (0, y - a.bl * 0.23 - 0.05, a.btop + 0.6), (a.bw * 0.5, 0.12, 0.55), flap or shade(C(col), 0.8), "B", "Pack", studs=False)
    for x in (-1, 1):
        box(m, (x * (a.bw / 2 + 0.12), a.by - 0.2, a.bz + 0.2), (0.1, 0.3, a.bh), shade(C(col), 0.8), "B", "Strap", studs=False)


def sash(m, A, col):
    a = G(A)
    box(m, (0, a.by, a.bz + 0.1), (a.bw + 2 * CLOTH + 0.1, 0.5, 0.2), col, "B", "Sash", studs=False,
        fr=about((0, a.by, a.bz), R(0.6, "Y")))


def belt(m, A, col, buckle=GOLD, z=None):
    a = G(A)
    z = a.leg + 0.35 if z is None else z
    box(m, (0, a.by, z), (a.bw + 2 * CLOTH + 0.04, a.bl + 2 * CLOTH + 0.04, 0.3), col, "B", "Belt", studs=False)
    box(m, (0, a.bfront - CLOTH - 0.06, z), (0.42, 0.1, 0.36), buckle, "B", "Buckle", studs=False)


def side_mark(m, A, col, text_blocks, x_side=-1, out=CLOTH + 0.03):
    """A simple block picture on the body's side (a number, a logo). text_blocks: list of (u, v, w, h) in the side's units."""
    a = G(A)
    for u, v, w, h in text_blocks:
        box(m, (x_side * (a.bw / 2 + out), a.by + u, a.bz + v), (0.08, w, h), col, "B", "Mark", studs=False)


# -- legs and feet ---------------------------------------------------------------------------------------------------
def boots(m, A, col, h=0.5, sole=None, which=(0, 1, 2, 3)):
    a = G(A)
    for i, p in enumerate(a.paws):
        if i not in which:
            continue
        box(m, (p.x, p.y - 0.08, h / 2 + 0.02), (1.08, 1.16, h), col, "L", "Boot")
        if sole:
            box(m, (p.x, p.y - 0.08, 0.06), (1.12, 1.2, 0.12), sole, "L", "Boot", studs=False)


def cuffs(m, A, col, z=None, which=(0, 2)):
    a = G(A)
    for i in which:
        p = a.paws[i]
        box(m, (p.x, p.y, (z if z is not None else a.leg * 0.65)), (1.1, 1.1, 0.24), col, "L", "Cuff", studs=False)


def held(m, A, side=-1, front=True):
    """Where a front paw holds a thing: just outside that paw, raised a little."""
    a = G(A)
    p = a.paws[0 if side < 0 else 2] if front else a.paws[1 if side < 0 else 3]
    return Vector((p.x + side * 0.75, p.y - 0.3, 0.0))


def stick(m, A, col, h=2.6, r=0.11, side=-1, tilt=0.12, top=None, top_col=None, name="Stick"):
    """A cane / wand / staff held by a front paw; returns the top point. top: "ball", "star", "hook", "gem"."""
    a = G(A)
    b = held(m, A, side)
    fr = about(b, R(-side * tilt, "Y"))
    cyl(m, (b.x, b.y, h / 2), r, h, col, "L", name, fr=fr)
    tp = fr @ Vector((b.x, b.y, h))
    if top == "ball":
        ball(m, tp, 0.28, top_col or col, "L", name, emit=0.4)
    elif top == "star":
        star(m, tp, 0.7, top_col or GOLD, "L", emit=0.8)
    elif top == "gem":
        box(m, tp, (0.4, 0.4, 0.55), top_col or (120, 220, 255), "L", "Gem", studs=False, emit=0.8,
            fr=about(tp, R(0.785, "Z")))
    elif top == "hook":
        box(m, (tp.x - side * 0.25, tp.y, tp.z + 0.05), (0.6, 0.22, 0.22), col, "L", name, studs=False)
    return tp


def star(m, c, s, col, bone="Fx", emit=0.5, name="Star", fr=None):
    """A chunky 5-point star facing -Y."""
    for k in range(5):
        ang = k * 2 * math.pi / 5
        box(m, (0, 0, s * 0.28), (s * 0.26, s * 0.18, s * 0.56), col, bone, name, studs=False, emit=emit,
            fr=(fr or Matrix()) @ T(*c) @ R(ang, "Y"))
    box(m, c, (s * 0.38, s * 0.2, s * 0.38), col, bone, name, studs=False, emit=emit, fr=fr)


def heart(m, c, s, col, bone="Fx", emit=0.6, name="Heart", fr=None):
    f = (fr or Matrix()) @ T(*c)
    for dx in (-1, 1):
        box(m, (dx * s * 0.22, 0, s * 0.12), (s * 0.48, s * 0.2, s * 0.48), col, bone, name, studs=False, emit=emit, fr=f)
    box(m, (0, 0, -s * 0.12), (s * 0.52, s * 0.2, s * 0.52), col, bone, name, studs=False, emit=emit, fr=f @ R(0.785, "Y"))


def flower(m, c, s, petal, centre=(255, 220, 80), bone="H", fr=None):
    f = (fr or Matrix()) @ T(*c)
    for k in range(5):
        box(m, (0, s * 0.3, 0), (s * 0.34, s * 0.42, s * 0.14), petal, bone, "Petal", studs=False, fr=f @ R(k * 1.2566, "Z"))
    box(m, (0, 0, 0.03), (s * 0.3, s * 0.3, s * 0.16), centre, bone, "Petal", studs=False, fr=f)


# -- back, tail, wings -----------------------------------------------------------------------------------------------
def wings(m, A, cols, kind="feather", span=1.0, up=0.5, emit=0.0, alpha=1.0):
    """Wings on the back. kind: feather (layers), bat (bones and skin), butterfly, bug (clear), stone."""
    a = G(A)
    for x in (-1, 1):
        root = T(x * (a.bw / 2 + 0.05), a.by + 0.1, a.btop + 0.1)
        if kind == "feather":
            for k in range(4):
                fr = root @ R(-x * (up - 0.15 + k * 0.28), "Y") @ T(x * 1.1 * span, 0.15 * k, 0)
                box(m, (0, 0, 0), (2.2 * span - k * 0.25, 0.22, 0.75 - k * 0.08), cols[k % len(cols)], "W", "Feather", fr=fr, emit=emit)
        elif kind == "bat":
            for k in range(3):
                fr = root @ R(-x * (up - 0.1 + k * 0.35), "Y") @ T(x * 1.2 * span, 0, 0)
                box(m, (0, 0, 0), (2.4 * span, 0.18, 0.16), cols[0], "W", "WingBone", fr=fr, studs=False)
                if k < 2:
                    fr2 = root @ R(-x * (up + 0.05 + k * 0.35), "Y") @ T(x * 1.1 * span, 0.02, 0)
                    box(m, (0, 0, 0), (2.1 * span, 0.1, 0.7), cols[1 % len(cols)], "W", "WingSkin", fr=fr2, studs=False, emit=emit)
        elif kind in ("butterfly", "bug"):
            for k, (ang, ln, h) in enumerate(((up + 0.2, 1.7, 1.2), (up - 0.5, 1.2, 0.85))):
                fr = root @ T(0, 0.3 * k, 0) @ R(-x * ang, "Y") @ T(x * ln * span / 2, 0, 0)
                box(m, (0, 0, 0), (ln * span, 0.08, h), cols[k % len(cols)], "W", "Wing", fr=fr, studs=False, emit=emit,
                    alpha=alpha, rough=0.1, coat=1.0)
        elif kind == "stone":
            for k in range(3):
                fr = root @ R(-x * (up + k * 0.32), "Y") @ T(x * 1.0 * span, 0, 0)
                box(m, (0, 0, 0), (2.0 * span - k * 0.3, 0.3, 0.6), cols[k % len(cols)], "W", "Wing", fr=fr)


def shell(m, A, col, col2=None, spiral=False):
    a = G(A)
    if spiral:
        for k in range(4):
            r = 1.2 - k * 0.25
            box(m, (0, a.by + 0.4 - k * 0.1, a.btop + 0.6 + k * 0.35), (0.9, 2 * r, 2 * r * 0.75), col if k % 2 == 0 else col2 or shade(C(col), 0.8),
                "B", "Shell", fr=about((0, a.by + 0.4, a.btop + 0.6), R(k * 0.25, "X")))
    else:
        stack(m, (0, a.by + 0.2, a.btop - 0.05), a.bw + 0.5, a.bw * 0.5, 1.2, 3, [col, col2 or shade(C(col), 0.85), col], "B", "Shell",
              d0=a.bl + 0.4, d1=a.bl * 0.5)


def tail_swap(m, A, build):
    """Replace the tail with something else: build(m, A, root) adds blocks (name them T_...)."""
    remove(m, ("Tail",))
    a = G(A)
    build(m, A, Vector((0, a.bback + 0.1, a.bz + 0.2)))


def tail_tip(m, A, s, col, name="Tip", emit=0.0):
    t = A["tail"][-1]
    return box(m, (t.x, t.y + 0.05, t.z + 0.55), s, col, "T", name, emit=emit)


# -- held things -------------------------------------------------------------------------------------------------------
def sword(m, A, blade=(225, 230, 240), hilt=BROWN, guard=GOLD, side=-1, ln=1.8, emit=0.0):
    b = held(m, A, side)
    fr = T(b.x, b.y, 0.3) @ R(-side * 0.25, "Y")
    box(m, (0, 0, 0.25), (0.24, 0.24, 0.5), hilt, "L", "Hilt", fr=fr, studs=False)
    box(m, (0, 0, 0.55), (0.75, 0.28, 0.14), guard, "L", "Guard", fr=fr, studs=False)
    box(m, (0, 0, 0.62 + ln / 2), (0.22, 0.36, ln), blade, "L", "Blade", fr=fr, studs=False, rough=0.15, emit=emit)


def shield(m, A, col, rim=SILVER, emblem=None, side=1, round_=False):
    a = G(A)
    x = side * (a.bw / 2 + 0.25)
    if round_:
        cyl(m, (x, a.by - 0.2, a.bz), 1.0, 0.2, col, "B", "Shield", axis="X")
        cyl(m, (x + side * 0.04, a.by - 0.2, a.bz), 1.08, 0.12, rim, "B", "Shield", axis="X")
        cyl(m, (x + side * 0.14, a.by - 0.2, a.bz), 0.25, 0.12, rim, "B", "Shield", axis="X")
    else:
        box(m, (x, a.by - 0.2, a.bz + 0.1), (0.2, 1.5, 1.7), rim, "B", "Shield", studs=False)
        box(m, (x + side * 0.08, a.by - 0.2, a.bz + 0.1), (0.14, 1.3, 1.5), col, "B", "Shield")
        if emblem:
            box(m, (x + side * 0.17, a.by - 0.2, a.bz + 0.15), (0.06, 0.4, 0.8), emblem, "B", "Shield", studs=False)
            box(m, (x + side * 0.17, a.by - 0.2, a.bz + 0.3), (0.06, 0.8, 0.3), emblem, "B", "Shield", studs=False)


# -- effects (preview of the in-game effect) ----------------------------------------------------------------------------
def fx_item(m, kind, c, s, col, emit, rnd):
    col = C(col)
    rot = R(rnd.uniform(0, 6.28), "Z")
    f = T(*c) @ rot
    if kind == "ball":
        ball(m, (0, 0, 0), s * 0.5, col, "Fx", "Orb", fr=f, emit=emit)
    elif kind == "bubble":
        ball(m, (0, 0, 0), s * 0.5, col, "Fx", "Bubble", fr=f, emit=emit, alpha=0.45, rough=0.05, coat=1.0)
    elif kind == "cube":
        box(m, (0, 0, 0), (s, s, s), col, "Fx", "Cube", fr=f @ R(0.6, "X"), studs=False, emit=emit)
    elif kind == "pixel":
        box(m, (0, 0, 0), (s, s * 0.3, s), col, "Fx", "Pixel", fr=f, studs=False, emit=emit)
    elif kind == "star":
        star(m, (0, 0, 0), s, col, "Fx", emit=emit, fr=f)
    elif kind == "spark":
        for ax in ("X", "Y", "Z"):
            box(m, (0, 0, 0), (s * 0.18, s * 0.18, s), col, "Fx", "Spark", fr=f @ R(0.785, ax), studs=False, emit=emit)
    elif kind == "heart":
        heart(m, (0, 0, 0), s, col, "Fx", emit=emit, fr=f)
    elif kind == "note":
        box(m, (0, 0, 0), (s * 0.45, s * 0.2, s * 0.35), col, "Fx", "Note", fr=f, studs=False, emit=emit)
        box(m, (s * 0.18, 0, s * 0.45), (s * 0.1, s * 0.14, s * 0.85), col, "Fx", "Note", fr=f, studs=False, emit=emit)
        box(m, (s * 0.35, 0, s * 0.78), (s * 0.35, s * 0.12, s * 0.16), col, "Fx", "Note", fr=f, studs=False, emit=emit)
    elif kind == "flame":
        m.blob((s * 0.35, s * 0.35, s * 0.75), col, f, e1=0.8, e2=1.0, nu=8, nv=6, name="Fx_Flame", emit=emit, alpha=0.9)
        m.blob((s * 0.18, s * 0.18, s * 0.4), (255, 235, 140), f @ T(0, 0, -s * 0.12), e1=0.8, e2=1.0, nu=8, nv=6, name="Fx_Flame",
               emit=emit * 1.3)
    elif kind in ("leaf", "petal", "feather"):
        sz = {"leaf": (s * 0.5, s * 0.1, s), "petal": (s * 0.6, s * 0.1, s * 0.45), "feather": (s * 0.32, s * 0.08, s * 1.2)}[kind]
        box(m, (0, 0, 0), sz, col, "Fx", kind.title(), fr=f @ R(rnd.uniform(-0.8, 0.8), "Y") @ R(0.4, "X"), studs=False, emit=emit)
    elif kind == "flake":
        for k in range(3):
            box(m, (0, 0, 0), (s * 0.14, s * 0.1, s), col, "Fx", "Flake", fr=f @ R(k * 1.047, "Y"), studs=False, emit=emit)
    elif kind == "gem":
        box(m, (0, 0, 0), (s * 0.6, s * 0.6, s * 0.8), col, "Fx", "Gem", fr=f @ R(0.785, "Z") @ R(0.3, "X"), studs=False, emit=emit,
            rough=0.05, coat=1.0)
    elif kind == "coin":
        cyl(m, (0, 0, 0), s * 0.45, s * 0.14, col, "Fx", "Coin", fr=f, axis="Y", emit=emit, rough=0.2)
    elif kind == "ufo":
        cyl(m, (0, 0, 0), s * 0.6, s * 0.16, (200, 210, 225), "Fx", "Ufo", fr=f, rough=0.2)
        ball(m, (0, 0, s * 0.12), (s * 0.3, s * 0.3, s * 0.22), (150, 255, 170), "Fx", "Ufo", fr=f, emit=1.0, alpha=0.8)
        for k in range(4):
            ball(m, (math.cos(k * 1.57) * s * 0.45, math.sin(k * 1.57) * s * 0.45, -s * 0.05), s * 0.07, col, "Fx", "Ufo", fr=f, emit=2.0)
    elif kind == "bat":
        ball(m, (0, 0, 0), s * 0.22, col, "Fx", "Bat", fr=f)
        for x in (-1, 1):
            box(m, (x * s * 0.38, 0, s * 0.05), (s * 0.55, s * 0.08, s * 0.3), col, "Fx", "Bat", fr=f @ R(x * 0.3, "Y"), studs=False)
    elif kind == "gear":
        cyl(m, (0, 0, 0), s * 0.38, s * 0.16, col, "Fx", "Gear", fr=f, axis="Y", rough=0.25)
        for k in range(8):
            box(m, (0, 0, s * 0.42), (s * 0.14, s * 0.16, s * 0.16), col, "Fx", "Gear", fr=f @ R(k * 0.785, "Y"), studs=False)
    elif kind == "candy":
        ball(m, (0, 0, 0), s * 0.3, col, "Fx", "Candy", fr=f, emit=emit)
        for x in (-1, 1):
            box(m, (x * s * 0.38, 0, 0), (s * 0.25, s * 0.3, s * 0.3), shade(col, 1.15), "Fx", "Candy", fr=f, studs=False)
    elif kind == "moon":
        for k in range(5):
            ang = -1.1 + k * 0.55
            box(m, (math.cos(ang) * s * 0.4, 0, math.sin(ang) * s * 0.4), (s * 0.25, s * 0.15, s * 0.28), col, "Fx", "Moon", fr=f,
                studs=False, emit=emit)
    elif kind == "cloud":
        for dx, r in ((-0.3, 0.3), (0.0, 0.4), (0.32, 0.28)):
            ball(m, (dx * s, 0, 0), r * s, col, "Fx", "Cloud", fr=f, emit=emit)
    elif kind == "rock":
        box(m, (0, 0, 0), (s * 0.7, s * 0.6, s * 0.55), col, "Fx", "Rock", fr=f @ R(0.5, "X"), studs=True)
    elif kind == "drop":
        m.blob((s * 0.3, s * 0.3, s * 0.45), col, f, e1=0.9, e2=1.0, nu=10, nv=8, name="Fx_Drop", emit=emit, alpha=0.8, rough=0.05, coat=1.0)
    elif kind == "lantern":
        box(m, (0, 0, 0), (s * 0.6, s * 0.6, s * 0.55), col, "Fx", "Lantern", fr=f, emit=emit)
        box(m, (0, -s * 0.31, 0), (s * 0.35, s * 0.04, s * 0.15), (90, 40, 10), "Fx", "Lantern", fr=f, studs=False)
    elif kind == "z":
        for dz, w, ang in ((0.35, 0.6, 0), (0, 0.75, 0.8), (-0.35, 0.6, 0)):
            box(m, (0, 0, dz * s), (w * s, s * 0.12, s * 0.14), col, "Fx", "Zzz", fr=f @ R(ang, "Y"), studs=False, emit=emit)
    elif kind == "bolt":
        for k, (dx, dz) in enumerate(((0.1, 0.4), (-0.05, 0.0), (0.1, -0.4))):
            box(m, (dx * s, 0, dz * s), (s * 0.18, s * 0.12, s * 0.5), col, "Fx", "Bolt", fr=f @ R(0.5 if k % 2 == 0 else -0.5, "Y"),
                studs=False, emit=emit)
    elif kind == "clock":
        cyl(m, (0, 0, 0), s * 0.5, s * 0.12, col, "Fx", "Clock", fr=f, axis="Y", emit=emit)
        box(m, (0, -s * 0.08, s * 0.15), (s * 0.06, s * 0.04, s * 0.3), INK, "Fx", "Clock", fr=f, studs=False)
        box(m, (s * 0.12, -s * 0.08, 0), (s * 0.25, s * 0.04, s * 0.06), INK, "Fx", "Clock", fr=f, studs=False)
    elif kind == "portal":
        ring(m, (0, 0, 0), s * 0.5, 10, (s * 0.2, s * 0.12, s * 0.2), col, "Fx", "Portal", fr=f @ R(math.pi / 2, "X"), emit=emit)
    elif kind == "sweetpotato":
        m.blob((s * 0.3, s * 0.3, s * 0.55), (170, 90, 190), f @ R(1.2, "Y"), e1=1.0, e2=1.0, nu=12, nv=8, name="Fx_Potato", emit=emit * 0.3)
    elif kind == "fish":
        box(m, (0, 0, 0), (s * 0.6, s * 0.18, s * 0.35), col, "Fx", "Fish", fr=f, studs=False, emit=emit)
        wedge(m, (-s * 0.42, 0, 0), (s * 0.18, s * 0.3, s * 0.35), col, "Fx", "Fish", fr=f @ R(math.pi / 2, "Z"))
    else:
        raise ValueError(kind)


def fx(m, A, layout="orbit", kind="star", cols=((255, 230, 120),), n=8, r=None, z=(0.6, 3.6), s=0.4, emit=2.0, seed=3):
    """A preview of an effect round the cat. layout: orbit (round the body), above (over the head), ground (round the
    feet), ring (a flat glowing ring of blocks), back (a big disc / wheel behind the cat), rise (round and up)."""
    a = G(A)
    rnd = random.Random(seed)
    cols = [C(c) for c in cols]
    r = r or max(a.bw, a.bl) / 2 + 1.4
    cy = a.by - 0.3
    if layout in ("orbit", "rise"):
        for k in range(n):
            ang = k * 2 * math.pi / n + rnd.uniform(-0.25, 0.25)
            rr = r * rnd.uniform(0.9, 1.1)
            zz = rnd.uniform(*z) if layout == "orbit" else z[0] + (z[1] - z[0]) * (k / max(1, n - 1))
            fx_item(m, kind, (math.cos(ang) * rr, cy + math.sin(ang) * rr, zz), s * rnd.uniform(0.8, 1.2), cols[k % len(cols)], emit, rnd)
    elif layout == "above":
        for k in range(n):
            fx_item(m, kind, (rnd.uniform(-1.8, 1.8), a.hy + rnd.uniform(-1.2, 1.5), a.top + 1.0 + rnd.uniform(0, 1.6)), s,
                    cols[k % len(cols)], emit, rnd)
    elif layout == "ground":
        for k in range(n):
            ang = k * 2 * math.pi / n + rnd.uniform(-0.2, 0.2)
            fx_item(m, kind, (math.cos(ang) * r, cy + math.sin(ang) * r, s * 0.5 + rnd.uniform(0, 0.3)), s, cols[k % len(cols)], emit, rnd)
    elif layout == "ring":
        zz = z[0] if isinstance(z, tuple) else z
        ring(m, (0, cy, zz), r, n, (s, s * 0.6, s * 0.4), cols, "Fx", "Ring", emit=emit)
    elif layout == "back":
        c = z if isinstance(z, Vector) else (0, a.bback + 0.6, a.btop + 1.0)
        ring(m, (0, 0, 0), r, n, (s, s * 0.5, s * 0.3), cols, "Fx", "Wheel", fr=T(*c) @ R(math.pi / 2, "X"), emit=emit)
    return a
