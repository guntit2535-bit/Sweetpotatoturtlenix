"""Cat crates v2 (concepts): three looks x seven tiers, built to read at card size (~140 px).

Looks:
  A  LEGO block crate - stacked chunky bricks, studs on the lid, pixel block ears, a pixel cat face of raised blocks
  B  Cat-head chest   - a chest with bands and a paw lock; the lid is a round cat head (ears, eyes, muzzle)
  C  Gift box         - a wrapped present: ribbon, big bow, cat ears on the lid corners, paw-print tag, raised pattern
Tiers: Paper, Wood, Iron, Gold, Ruby, Diamond, Cosmic (colour set + a corner / pattern style each).

One solid colour per part (the export bakes a palette), all detail is geometry. crate(look, tier) -> kit.Model.
1 unit = 1 stud, front = -Y, up = +Z, the crate stands on z = 0, about 2 x 2 x 2 studs.
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import kit
from kit import Model, R, T
from crates import box, basis, gem, ellipse

PI = math.pi
PINK = (255, 132, 170)
EYE = (34, 26, 48)
WHITE = (255, 255, 255)

TIERS = {
    "Paper": dict(main=(222, 170, 104), main2=(206, 152, 88), dark=(150, 102, 56), trim=(246, 228, 180),
                  ribbon=(236, 64, 72), pat="stripes", corner="tape", rough=0.8),
    "Wood": dict(main=(226, 146, 66), main2=(204, 124, 50), dark=(130, 74, 34), trim=(96, 102, 118),
                 bolt=(214, 218, 228), ribbon=(232, 44, 58), pat="planks", corner="bracket", rough=0.6),
    "Iron": dict(main=(184, 192, 208), main2=(162, 172, 190), dark=(92, 100, 120), trim=(120, 128, 148),
                 bolt=(236, 240, 248), ribbon=(40, 140, 255), pat="rivets", corner="bracket", rough=0.3, coat=0.4),
    "Gold": dict(main=(255, 200, 34), main2=(252, 180, 22), dark=(222, 128, 8), trim=(236, 140, 14),
                 gem=(232, 22, 58), ribbon=(232, 22, 58), pawc=(255, 236, 150), pat="gems", corner="gem", rough=0.22, coat=0.8),
    "Ruby": dict(main=(236, 36, 72), main2=(214, 22, 60), dark=(150, 10, 44), trim=(255, 204, 52),
                 gem=(255, 160, 196), ribbon=(255, 204, 52), pat="facets", corner="gem", rough=0.08, coat=1.0,
                 crystal=True),
    "Diamond": dict(main=(96, 194, 255), main2=(70, 170, 250), dark=(36, 112, 230), trim=(226, 246, 255),
                    gem=(236, 252, 255), ribbon=(255, 255, 255), pat="facets", corner="gem", rough=0.06, coat=1.0,
                    crystal=True),
    "Cosmic": dict(main=(92, 52, 186), main2=(70, 40, 158), dark=(30, 26, 84), trim=(255, 206, 60),
                   gem=(120, 236, 255), ribbon=(110, 232, 255), pat="stars", corner="star", rough=0.3, coat=0.6,
                   glow=1.6, eye=(30, 22, 60)),
}
LOOKS = ("A", "B", "C")


def ff(face, u, v, hx, hy, out=0.0):
    """Frame on a box face ('front' -Y, 'left' -X, 'back' +Y, 'right' +X); (u, v) = across, up; local Z = out."""
    if face == "front":
        return basis((u, -hy - out, v), (0, -1, 0))
    if face == "back":
        return basis((-u, hy + out, v), (0, 1, 0))
    if face == "left":
        return basis((-hx - out, -u, v), (-1, 0, 0))
    return basis((hx + out, u, v), (1, 0, 0))


FACES = ("front", "left", "back", "right")


def block(m, frame, u, v, w, h, d, color, bevel=0.025, seg=2, **o):
    """Raised block on a face frame: centre (u, v), half sizes w x h, `d` thick out of the face (sunk 0.03)."""
    return box(m, (u, v, d / 2 - 0.03), (w, h, d / 2 + 0.03), color, frame=frame, bevel=bevel, seg=seg, name="Px", **o)


def cyl(m, frame, r, h, color, n=16, bevel=0.03, seg=2, name="Stud", **o):
    """Cylinder standing on frame (local Z up / out); bevel 0 = plain (bolts, nails)."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=n, radius1=r, radius2=r, depth=h)
    bmesh.ops.transform(bm, matrix=frame @ T(0, 0, h / 2), verts=bm.verts[:])
    obj = m.add(bm, color, name, smooth=bevel > 0, **o)
    if bevel > 0:
        mod = obj.modifiers.new("Round", "BEVEL")
        mod.width = bevel
        mod.segments = seg
        mod.limit_method = "ANGLE"
        mod.harden_normals = True
    obj.modifiers.new("Tri", "TRIANGULATE")
    return obj


def ear_pts(w, h, n=4):
    """Rounded cat-ear triangle: wide base, sides bulging out, soft tip."""
    pts = []
    for side in (1, -1):
        a, c, b = (side * w, 0.0), (side * w * 0.62, h * 0.62), (side * w * 0.12, h)
        seq = []
        for i in range(n + 1):
            t = i / n
            seq.append(((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0],
                        (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1]))
        pts += seq if side == 1 else seq[::-1]
    return pts


def cat_ear(m, frame, size, color, crystal=False, **o):
    """Low-poly upright cat ear on frame (local Z up, -Y towards the viewer) with a pink inside."""
    body = slab(m, ear_pts(size * 0.6, size * 0.95), size * 0.34, color, frame @ R(PI / 2, "X"), bevel=size * 0.1,
                seg=1 if crystal else 2, name="Ear", **o)
    body.modifiers["Round"].harden_normals = False
    slab(m, ear_pts(size * 0.36, size * 0.7, 3), size * 0.1, PINK, frame @ T(0, -size * 0.17, size * 0.1) @ R(PI / 2, "X"),
         bevel=size * 0.035, seg=1, name="EarIn", rough=0.5)
    return body


def star_pts(r, ri=0.46, n=5, rot=PI / 2):
    return [((r if i % 2 == 0 else r * ri) * math.cos(rot + i * PI / n), (r if i % 2 == 0 else r * ri) * math.sin(rot + i * PI / n))
            for i in range(2 * n)]


def slab(m, outline, thick, color, frame, bevel=None, seg=2, name="Slab", **o):
    obj = m.slab(outline, thick, color, frame, bevel=bevel, name=name, **o)
    obj.modifiers["Round"].segments = seg
    return obj


def star(m, frame, r, color, thick=0.08, **o):
    return slab(m, star_pts(r), thick, color, frame @ T(0, 0, thick / 2 - 0.02), bevel=thick * 0.3, seg=1, name="Star", **o)


def paw(m, frame, s, color, thick=0.07, **o):
    """Raised paw print (pad + 4 toes) on a frame, local Z = out."""
    pad = []
    for i in range(14):
        a = 2 * PI * i / 14
        pad.append((0.36 * s * math.cos(a), (0.27 * math.sin(a) * (0.8 if math.sin(a) > 0 else 1.0) - 0.12) * s))
    fr = frame @ T(0, 0, thick / 2 - 0.01)
    slab(m, pad, thick, color, fr, bevel=thick * 0.35, seg=1, name="PawPad", **o)
    for x, y, rot in ((-0.4, 0.26, 0.35), (-0.14, 0.45, 0.1), (0.14, 0.45, -0.1), (0.4, 0.26, -0.35)):
        slab(m, ellipse(0.11 * s, 0.14 * s, 8, x * s, y * s, rot), thick, color, fr, bevel=thick * 0.35, seg=1,
             name="PawToe", **o)


def mo_of(P, glow=False):
    o = dict(rough=P["rough"], coat=P.get("coat", 0.0))
    if glow and P.get("glow"):
        o["emit"] = P["glow"]
    return o


def chunk(m, center, half, color, P, name="Block", bevel=0.05, **extra):
    """A tier-material box: crisp chamfer for crystal tiers, soft round for the rest."""
    crystal = P.get("crystal")
    o = mo_of(P)
    o.update(extra)
    return box(m, center, half, color, bevel=bevel * (1.8 if crystal else 1.0), seg=1 if crystal else 2, name=name, **o)


# -- corner decorations shared by the looks -------------------------------------------------------
def corners(m, P, pts, s=1.0):
    """Tier corner pieces at points (x, y, z) on the box's outer corners."""
    style = P["corner"]
    for p in pts:
        p = Vector(p)
        n = Vector((p.x, p.y, 0)).normalized()
        if style == "bracket":
            box(m, tuple(p), (0.19 * s,) * 3, P["trim"], bevel=0.04, seg=2, name="Bracket", rough=0.35, coat=0.3)
            sx, sy = math.copysign(1, p.x), math.copysign(1, p.y)
            for d in ((sx, 0, 0), (0, sy, 0)):
                cyl(m, basis(p + Vector(d) * 0.18 * s, d), 0.065 * s, 0.05, P["bolt"], n=8, bevel=0.0, name="Bolt",
                    rough=0.3)
        elif style == "gem":
            fr = basis(p, n + Vector((0, 0, 0.15)))
            m.torus(0.19 * s, 0.055 * s, P["trim"], fr, nu=14, nv=6, name="Setting", rough=0.2, coat=0.8)
            gem(m, fr @ T(0, 0, 0.03), 0.19 * s, P["gem"])
        elif style == "star":
            # glowing gold corner caps (the stars go on the faces)
            box(m, tuple(p), (0.16 * s,) * 3, P["trim"], bevel=0.05, seg=2, name="Cap", rough=0.25, coat=0.6, emit=0.5)
        elif style == "tape":
            box(m, tuple(p), (0.17 * s, 0.17 * s, 0.17 * s), P["trim"], bevel=0.02, seg=1, name="Tape", rough=0.35)


# == A: LEGO block crate =============================================================================
def look_a(m, P):
    hx = hy = 1.0
    lay = 0.5
    mo = mo_of(P)
    # dark core so the seams between bricks read
    box(m, (0, 0, 0.75), (0.95, 0.95, 0.74), P["dark"], bevel=0.0, name="Core", rough=0.8)
    g = 0.022
    for layer in range(3):
        z = layer * lay + lay / 2
        for side in (-1, 1):
            col = P["main"] if (layer + (side > 0)) % 2 == 0 else P["main2"]
            if layer % 2 == 0:
                c, h = (side * hx / 2, 0, z), (hx / 2 - g, hy, lay / 2 - g)
            else:
                c, h = (0, side * hy / 2, z), (hx, hy / 2 - g, lay / 2 - g)
            chunk(m, c, h, col, P, name="Brick")
    # lid plate with studs
    top = 1.5 + 0.34
    chunk(m, (0, 0, 1.5 + 0.17), (hx + 0.06, hy + 0.06, 0.17), P["main"], P, name="Lid", bevel=0.06)
    box(m, (0, 0, 1.5 + 0.03), (hx + 0.02, hy + 0.02, 0.04), P["dark"], bevel=0.0, name="LidSeam", rough=0.8)
    studc = P["trim"] if P["corner"] == "star" else P["main"]
    sp = 0.62
    for ix in (-1, 0, 1):
        for iy in (-1, 0, 1):
            if iy == 1 and ix != 0:
                continue  # ears stand there
            o = mo_of(P)
            if P["corner"] == "star":
                o = dict(rough=0.25, coat=0.6, emit=0.7)
            cyl(m, T(ix * sp, iy * sp, top - 0.02), 0.2, 0.17, studc, n=14, bevel=0.035, seg=1, **o)
    # ears: LEGO slope bricks (a crisp wedge with a flat tip leaning out), a pink wedge on the front
    for sx in (-1, 1):
        outer = [(-0.3, 0.0), (0.32, 0.0), (0.24, 0.6), (0.07, 0.6)]
        inner = [(-0.15, 0.06), (0.19, 0.06), (0.15, 0.4), (0.06, 0.4)]
        if sx < 0:
            outer = [(-x, y) for x, y in outer][::-1]
            inner = [(-x, y) for x, y in inner][::-1]
        ear_fr = T(sx * sp, sp, top - 0.02) @ R(PI / 2, "X")
        slab(m, outer, 0.38, P["main"], ear_fr, bevel=0.05, seg=1, name="Ear", **mo)
        slab(m, inner, 0.06, PINK, T(0, -0.2, 0) @ ear_fr, bevel=0.02, seg=1, name="EarIn", rough=0.5)
    # pixel face on the front, big enough to read at card size
    eye = P.get("eye", EYE)
    fr = ff("front", 0, 0, hx, hy)
    for side in (-1, 1):
        block(m, fr, side * 0.44, 0.98, 0.15, 0.2, 0.09, eye, rough=0.25)
        block(m, fr, side * 0.44 - 0.05, 1.07, 0.055, 0.055, 0.13, WHITE, bevel=0.012, seg=1, rough=0.2)
        block(m, fr, side * 0.74, 0.62, 0.14, 0.08, 0.06, PINK, bevel=0.015, rough=0.5)
    block(m, fr, 0, 0.72, 0.11, 0.07, 0.09, PINK, bevel=0.02, rough=0.4)
    for u, v in ((-0.2, 0.56), (-0.07, 0.5), (0.07, 0.5), (0.2, 0.56)):
        block(m, fr, u, v, 0.065, 0.04, 0.06, eye, bevel=0.012, seg=1, rough=0.3)
    # tier corners: bottom corners of the body and corners of the lid
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            pts.append((sx * (hx + 0.0), sy * (hy + 0.0), 0.18))
            pts.append((sx * (hx + 0.06), sy * (hy + 0.06), 1.5 + 0.17))
    corners(m, P, pts, 0.9)
    if P["corner"] == "star":
        for f, u, v, r in (("left", -0.45, 0.95, 0.24), ("left", 0.4, 0.55, 0.17), ("front", 0.0, 0.25, 0.14)):
            star(m, ff(f, u, v, hx, hy), r, P["trim"], thick=0.07, emit=1.2, rough=0.3)


# == B: cat-head chest ==============================================================================
def look_b(m, P):
    hx, hy, bh = 1.0, 0.86, 1.0
    mo = mo_of(P)
    crystal = P.get("crystal")
    body = chunk(m, (0, 0, bh / 2), (hx, hy, bh / 2), P["main2"], P, name="Chest", bevel=0.07)
    # bands: two straps over the chest, a rim at the top, a foot at the bottom
    for x in (-0.58, 0.58):
        chunk(m, (x, 0, bh / 2 + 0.02), (0.13, hy + 0.035, bh / 2), P["trim"], P, name="Strap", bevel=0.04)
    chunk(m, (0, 0, 0.09), (hx + 0.05, hy + 0.055, 0.09), P["trim"], P, name="Foot", bevel=0.04)
    if P["pat"] == "planks":
        for z in (0.4, 0.7):
            for f in FACES:
                hw = (hx if f in ("front", "back") else hy) - 0.06
                box(m, (0, 0, 0), (hw, 0.022, 0.02), P["dark"], frame=ff(f, 0, z, hx, hy, -0.005), bevel=0.0, name="Groove",
                    rough=0.8)
    # head lid: a round box head, flat underneath
    hz = bh + 0.04
    head_h = 0.95

    def warp(p):
        if p.z < 0:
            p = Vector((p.x, p.y, p.z * 0.18))
        return p

    head = m.blob((hx + 0.04, hy + 0.04, head_h * 0.62), P["main"], T(0, 0, hz + head_h * 0.62 * 0.18 + 0.0),
                  e1=0.55, e2=0.42, nu=40, nv=18, warp=warp, name="Head", **mo)
    if crystal:
        for poly in head.data.polygons:
            poly.use_smooth = False
    top = hz + head_h * 0.62 * 1.18
    # collar band at the seam (where the lid opens)
    chunk(m, (0, 0, bh + 0.02), (hx + 0.07, hy + 0.07, 0.085), P["trim"], P, name="Collar", bevel=0.05)
    # ears
    for sx in (-1, 1):
        cat_ear(m, T(sx * 0.6, 0.05, top - 0.2) @ R(sx * -0.22, "Y"), 0.78, P["main"], crystal=bool(crystal), **mo)
    # face
    tree = m.bvh(head)
    out = Vector((0, -1, 0))
    fc = Vector((0, 0, hz + 0.42))
    eye = P.get("eye", EYE)
    s = 0.44
    for side in (-1, 1):
        p = fc + Vector((side * 0.42, 0, 0.1))
        if P.get("eye_ring"):
            m.stuck(tree, p, out, (s * 0.42, s * 0.54, s * 0.18), P["eye_ring"], sink=0.4, name="EyeRing")
        m.stuck(tree, p, out, (s * 0.34, s * 0.46, s * 0.2), eye, sink=0.3, rough=0.25, name="Eye")
        m.stuck(tree, p + Vector((-0.05, 0, 0.09)), out, (s * 0.13, s * 0.13, s * 0.08), WHITE, sink=-0.9, rough=0.2,
                name="Shine")
        m.stuck(tree, fc + Vector((side * 0.74, 0, -0.14)), out, (s * 0.3, s * 0.18, s * 0.06), PINK, sink=0.2,
                name="Cheek")
    muz = m.stuck(tree, fc + Vector((0, 0, -0.15)), out, (0.3, 0.19, 0.07), P.get("muzzle", (255, 246, 232)), sink=0.3,
                  name="Muzzle", rough=0.5)
    mt = m.bvh(muz)
    m.stuck(mt, fc + Vector((0, 0, -0.08)), out, (0.085, 0.06, 0.04), PINK, sink=0.2, name="Nose", rough=0.3)
    for side in (-1, 1):
        pts = []
        for k in range(7):
            a = PI * k / 6
            q = fc + Vector((side * 0.075 + 0.075 * math.cos(a) * -side * -1, 0, -0.17 - 0.06 * math.sin(a)))
            loc, nor = m.hit(mt, q, out)
            pts.append(loc + nor * 0.01)
        m.tube(pts, 0.022, eye, n=6, rough=0.3, name="Mouth")
    # paw lock plate on the chest front, hanging from the collar
    lf = ff("front", 0, 0.6, hx, hy, 0.0)
    plate = [(0.26 * math.cos(2 * PI * i / 16), 0.24 * math.sin(2 * PI * i / 16)) for i in range(16)]
    slab(m, plate, 0.1, P["trim"], lf @ T(0, 0, 0.04), bevel=0.04, name="Lock", **mo_of(P))
    paw(m, lf @ T(0, 0, 0.09), 0.36, P.get("pawc", P["dark"]), thick=0.05, rough=0.4)
    # tier corners on the chest
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            pts.append((sx * hx, sy * hy, 0.2))
    corners(m, P, pts, 0.85)
    if P["corner"] == "star":
        star(m, ff("left", 0.0, 0.5, hx, hy), 0.22, P["trim"], thick=0.07, emit=1.2, rough=0.3)
        for p, d, r in (((-0.5, 0.1, top), (-0.5, -0.3, 1), 0.17), ((-1.0, 0.25, hz + 0.45), (-1, 0, 0.25), 0.15)):
            loc, nor = m.hit(tree, p, d)
            if loc is not None:
                star(m, basis(loc, nor), r, P["trim"], thick=0.06, emit=1.2, rough=0.3)
    if P["corner"] == "gem":
        for x in (-0.58, 0.58):
            fr = ff("front", x, bh * 0.5, hx, hy, 0.04)
            gem(m, fr @ T(0, 0, 0.02), 0.12, P["gem"])
    return head


# == C: gift box =====================================================================================
def look_c(m, P):
    hx = hy = 1.0
    bh = 1.42
    mo = mo_of(P)
    ribbon = P["ribbon"]
    ro = dict(rough=0.35, coat=0.5)
    if P.get("glow"):
        ro["emit"] = 0.8
    chunk(m, (0, 0, bh / 2), (hx, hy, bh / 2), P["main"], P, name="Box", bevel=0.05)
    lz0, lh = bh - 0.1, 0.42
    chunk(m, (0, 0, lz0 + lh / 2), (hx + 0.08, hy + 0.08, lh / 2), P["main2"], P, name="Lid", bevel=0.06)
    top = lz0 + lh
    rw = 0.19
    # ribbon: around the body, over the lid
    box(m, (0, 0, bh / 2), (rw, hy + 0.03, bh / 2 - 0.02), ribbon, bevel=0.02, seg=2, name="Ribbon", **ro)
    box(m, (0, 0, bh / 2), (hx + 0.03, rw, bh / 2 - 0.02), ribbon, bevel=0.02, seg=2, name="Ribbon", **ro)
    box(m, (0, 0, lz0 + lh / 2), (rw, hy + 0.11, lh / 2 + 0.03), ribbon, bevel=0.025, seg=2, name="Ribbon", **ro)
    box(m, (0, 0, lz0 + lh / 2), (hx + 0.11, rw, lh / 2 + 0.03), ribbon, bevel=0.025, seg=2, name="Ribbon", **ro)
    # bow: two loops, a knot, two tails
    for sx in (-1, 1):
        fr = T(sx * 0.33, -0.08, top + 0.24) @ R(sx * -0.5, "Y") @ R(PI / 2, "X") @ Matrix.Diagonal((1.25, 1.0, 1.0, 1.0))
        m.torus(0.22, 0.11, ribbon, fr, nu=24, nv=10, name="Loop", **ro)
        m.leaf((sx * 0.06, -0.14, top + 0.06), (sx * 0.5, -1.0, -0.3), 0.7, 0.32, ribbon, thick=0.08,
               up=(0, 0, 1), fat=0.45, name="Tail", **ro)
    m.blob((0.17, 0.15, 0.15), ribbon, T(0, -0.08, top + 0.13), e1=0.7, e2=0.7, nu=16, nv=10, name="Knot", **ro)
    if P["corner"] == "gem":
        gem(m, basis((0, -0.22, top + 0.17), (0, -1, 0.5)), 0.12, P["gem"] if P["gem"] != ribbon else (255, 236, 120))
    # cat ears on the two back corners of the lid
    for sx in (-1, 1):
        cat_ear(m, T(sx * 0.72, 0.62, top - 0.06) @ R(sx * -0.2, "Y"), 0.86, P["main2"], crystal=bool(P.get("crystal")),
                **mo)
    # paw-print tag hanging on the front ribbon
    tf = ff("front", 0.0, 0.66, hx, hy, 0.03) @ R(0.12, "Z")
    tag = [(0.31 * math.cos(2 * PI * i / 16), 0.31 * math.sin(2 * PI * i / 16)) for i in range(16)]
    slab(m, tag, 0.06, (255, 248, 226), tf @ T(0, 0, 0.03), bevel=0.025, name="Tag", rough=0.5)
    paw(m, tf @ T(0, 0, 0.055), 0.42, P["dark"] if P["pat"] != "stars" else P["main"], thick=0.05, rough=0.4)
    cyl(m, ff("front", 0.0, bh - 0.02, hx, hy, 0.03), 0.06, 0.05, P["trim"], n=10, bevel=0.0, name="Pin", rough=0.3)
    # raised pattern on the four body faces (away from the ribbon)
    pat = P["pat"]
    for f in FACES:
        for su in (-1, 1):
            if pat == "gems":
                fr = ff(f, su * 0.6, 0.72, hx, hy, 0.0)
                m.torus(0.16, 0.045, P["dark"], fr, nu=14, nv=6, name="Setting", rough=0.2, coat=0.8)
                gem(m, fr @ T(0, 0, 0.03), 0.16, P["gem"])
                for v in (0.32, 1.12):
                    m.blob((0.06, 0.06, 0.04), P["dark"], ff(f, su * 0.6, v, hx, hy, -0.005), nu=8, nv=4, name="Dot", **mo)
            elif pat == "dots":
                for u, v in ((0.62, 0.36), (0.62, 1.02), (0.4, 0.69), (0.84, 0.69)):
                    m.blob((0.1, 0.1, 0.06), P["dark"], ff(f, su * u, v, hx, hy, -0.01), e1=0.8, e2=1.0, nu=8, nv=4,
                           name="Dot", **mo)
            elif pat == "stars":
                star(m, ff(f, su * 0.6, 0.86, hx, hy), 0.2, P["trim"], thick=0.07, emit=1.3, rough=0.3)
                m.blob((0.06, 0.06, 0.04), P["ribbon"], ff(f, su * 0.42, 0.36, hx, hy, -0.005), nu=8, nv=4, name="Dot",
                       emit=1.5, rough=0.3)
                m.blob((0.045, 0.045, 0.04), P["trim"], ff(f, su * 0.8, 0.3, hx, hy, -0.005), nu=8, nv=4, name="Dot",
                       emit=1.5, rough=0.3)
            elif pat == "planks":
                for v in (0.47, 0.95):
                    box(m, (su * 0.6, v, 0.0), (0.37, 0.028, 0.025), P["dark"], frame=ff(f, 0, 0, hx, hy), bevel=0.0,
                        name="Groove", rough=0.8)
                for v in (0.24, 0.71, 1.18):
                    cyl(m, ff(f, su * 0.86, v, hx, hy, -0.01), 0.045, 0.04, P["dark"], n=6, bevel=0.0, name="Nail",
                        rough=0.5)
            elif pat == "stripes":
                for u in (0.42, 0.78):
                    box(m, (su * u, bh / 2, 0.0), (0.07, bh / 2 - 0.06, 0.025), P["trim"], frame=ff(f, 0, 0, hx, hy),
                        bevel=0.01, seg=1, name="Stripe", rough=0.6)
            elif pat == "rivets":
                for u, v in ((0.36, 0.25), (0.86, 0.25), (0.36, 1.2), (0.86, 1.2)):
                    m.blob((0.06, 0.06, 0.05), P["bolt"], ff(f, su * u, v, hx, hy, -0.01), nu=10, nv=6, name="Rivet",
                           rough=0.3)
            elif pat == "facets":
                d = [(0, -0.26), (0.18, 0), (0, 0.26), (-0.18, 0)]
                slab(m, d, 0.08, P["trim"], ff(f, su * 0.6, 0.7, hx, hy) @ T(0, 0, 0.02), bevel=0.03, seg=1,
                     name="Facet", **mo)


# == entry =========================================================================================
def crate(look, tier):
    P = TIERS[tier]
    m = Model(f"Crate{look}{tier}")
    old, kit.RES = kit.RES, 0.6  # game resolution for the round shapes (blobs, tori, tubes)
    try:
        {"A": look_a, "B": look_b, "C": look_c}[look](m, P)
    finally:
        kit.RES = old
    return m


def triangles(model):
    dg = bpy.context.evaluated_depsgraph_get()
    n = 0
    for o in model.objects:
        e = o.evaluated_get(dg)
        me = e.to_mesh()
        me.calc_loop_triangles()
        n += len(me.loop_triangles)
        e.to_mesh_clear()
    return n
