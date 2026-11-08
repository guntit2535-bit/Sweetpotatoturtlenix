"""Cat crates (M10), round 2: real boxes instead of soft blobs (developer, 2026-11-08: "ดูสมจริงกว่านี้").

Each crate is a hollow box with a separate cap lid (it opens for the R8 unboxing), crisp bevelled edges and
paw-shaped holes cut through the walls. Material details are built as geometry (one colour per part, so the
export palette still works):
  Paper   - cardboard, packing tape over the lid and down the front, taped corners, printed "this way up" arrows
  Wood    - planks with grooves, darker corner posts and rims, a diagonal brace, metal corner brackets with bolts
  Gold    - gold box with raised edge bands, rivets, faceted red gems on the corners, a cat-face lock
  Diamond - see-through crystal with chamfered facets, crystal edge bars, faceted diamond corners, a glowing core
crate(key, lid_open) -> kit.Model. lid_open = radians the lid swings up around its back edge (0 = closed).
1 unit = 1 stud, front = -Y, up = +Z; the box stands on z = 0.
"""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import kit
from kit import Model, R, T

PI = math.pi
HX = HY = 1.0  # body half-size
H = 1.8  # body height
WALL = 0.13
PAW = {"Paper": (0.75, 1.1), "Wood": (0.85, 1.05), "Gold": (1.1, 0.88), "Diamond": (0.85, 1.1)}  # front hole: height, size
PINK = (255, 150, 190)
WHITE = (250, 250, 252)

LOOKS = {
    "Paper": dict(body=(206, 160, 104), lid=(214, 170, 112), inside=(70, 48, 30), ear=(214, 170, 112), rough=0.85,
                  bevel=0.035, seg=2),
    "Wood": dict(body=(204, 138, 72), lid=(210, 146, 78), inside=(64, 40, 22), ear=(210, 146, 78), rough=0.7,
                 bevel=0.05, seg=2, post=(166, 100, 44), metal=(88, 92, 104), bolt=(196, 200, 210)),
    "Gold": dict(body=(250, 192, 40), lid=(252, 200, 52), inside=(255, 214, 110), ear=(250, 192, 40), rough=0.22,
                 coat=0.7, bevel=0.06, seg=3, band=(232, 156, 18), gem=(222, 28, 52)),
    "Diamond": dict(body=(110, 180, 255), lid=(126, 190, 255), inside=(160, 230, 255), ear=(126, 190, 255), rough=0.05,
                    alpha=0.8, bevel=0.12, seg=1, band=(196, 232, 255), gem=(210, 244, 255)),
}


# -- small builders ------------------------------------------------------------------------------------
def box(m, center, half, color, frame=Matrix(), bevel=0.05, seg=3, name="Box", harden=True, **o):
    """Box with bevelled edges (seg 1 = a crisp chamfer, like a cut crystal)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=(half[0] * 2, half[1] * 2, half[2] * 2), verts=bm.verts[:])
    bmesh.ops.transform(bm, matrix=frame @ T(*center), verts=bm.verts[:])
    obj = m.add(bm, color, name, smooth=seg > 1, **o)
    if bevel > 0:
        mod = obj.modifiers.new("Round", "BEVEL")
        mod.width = min(bevel, min(half) * 0.9)
        mod.segments = seg
        mod.limit_method = "NONE"
        mod.harden_normals = harden and seg > 1
    return obj


def cut(target, cutters):
    """Subtract every object of the cutter model from target, then bake it to a plain mesh."""
    mod = target.modifiers.new("Cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    mod.operand_type = "COLLECTION"
    mod.collection = cutters.coll
    bake(target)


def bake(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(obj.evaluated_get(dg), depsgraph=dg)
    obj.modifiers.clear()
    obj.data = me
    # flat walls stay flat, the bevel rounds stay smooth (no streaks across the cut faces)
    smooth = any(p.use_smooth for p in me.polygons)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(32))


def drop(cutters):
    for o in list(cutters.coll.objects):
        bpy.data.objects.remove(o)
    bpy.data.collections.remove(cutters.coll)


def basis(pos, normal, up=Vector((0, 0, 1))):
    """Frame at pos with local Z along normal."""
    z = Vector(normal).normalized()
    ref = Vector(up) if abs(z.dot(Vector(up))) < 0.95 else Vector((0, 1, 0))
    x = ref.cross(z).normalized()
    y = z.cross(x)
    return Matrix.Translation(Vector(pos)) @ Matrix((x, y, z)).transposed().to_4x4()


def face_frame(face, u, v, out=0.0):
    """Frame on a body face: 'front' (-Y), 'left' (-X), 'back' (+Y), 'right' (+X); (u, v) = across, up."""
    if face == "front":
        return basis((u, -HY - out, v), (0, -1, 0))
    if face == "back":
        return basis((-u, HY + out, v), (0, 1, 0))
    if face == "left":
        return basis((-HX - out, -u, v), (-1, 0, 0))
    return basis((HX + out, u, v), (1, 0, 0))


def ellipse(rx, ry, n=20, cx=0.0, cy=0.0, rot=0.0):
    pts = []
    for i in range(n):
        a = 2 * PI * i / n
        x, y = rx * math.cos(a), ry * math.sin(a)
        c, s = math.cos(rot), math.sin(rot)
        pts.append((cx + x * c - y * s, cy + x * s + y * c))
    return pts


def paw_cutter(cm, frame, s, depth=0.6):
    """Paw-print hole: a pad and four toes, cut `depth` deep through the wall at frame (local Z = out of the wall).
    The basis frame's local Y is the face's up direction."""
    pad = []
    for i in range(24):
        a = 2 * PI * i / 24
        x = 0.36 * math.cos(a) * (1 + 0.1 * -math.sin(a))
        y = 0.27 * math.sin(a) * (0.8 if math.sin(a) > 0 else 1.0)
        pad.append((x * s, (y - 0.12) * s))
    cm.slab(pad, depth, (0, 0, 0), frame, bevel=0.025 * s / 0.6, name="CutPad")
    for x, y, rot in ((-0.37, 0.24, 0.35), (-0.13, 0.42, 0.1), (0.13, 0.42, -0.1), (0.37, 0.24, -0.35)):
        cm.slab(ellipse(0.105 * s, 0.135 * s, 16, x * s, y * s, rot), depth, (0, 0, 0), frame, bevel=0.02 * s / 0.6,
                name="CutToe")


def gem(m, frame, r, color, **o):
    """Faceted gem (table, crown, girdle, pavilion) with local Z pointing out."""
    bm = bmesh.new()
    n = 8
    table = [bm.verts.new((0.55 * r * math.cos(2 * PI * i / n + PI / n), 0.55 * r * math.sin(2 * PI * i / n + PI / n), 0.42 * r))
             for i in range(n)]
    gird = [bm.verts.new((r * math.cos(2 * PI * i / n), r * math.sin(2 * PI * i / n), 0.0)) for i in range(n)]
    culet = bm.verts.new((0, 0, -0.75 * r))
    bm.faces.new(table)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((gird[i], gird[j], table[i]))
        bm.faces.new((table[i], gird[j], table[j]))
        bm.faces.new((gird[j], gird[i], culet))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bmesh.ops.transform(bm, matrix=frame, verts=bm.verts[:])
    return m.add(bm, color, "Gem", smooth=False, rough=0.05, coat=1.0, **o)


def ear(m, frame, size, color, inner=PINK, crystal=False, **o):
    """Upright cat ear standing on frame (local Z up, -Y towards the viewer): a thick rounded triangle with a
    pink inside."""
    def tri(w, h, n=8):
        # wide base, sides bulging out (quadratic curves), a soft round tip
        pts = [(-w, 0.0)]
        for side in (1, -1):
            a, c, b = (side * w, 0.0), (side * w * 0.62, h * 0.62), (side * w * 0.12, h)
            rng = range(n + 1) if side == 1 else range(n, -1, -1)
            seq = []
            for i in range(n + 1):
                t = i / n
                seq.append(((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0],
                            (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1]))
            pts += seq if side == 1 else seq[::-1]
        return pts[1:]

    seg = 1 if crystal else 3
    outer = tri(size * 0.6, size * 0.95)
    body = m.slab(outer, size * 0.36, color, frame @ R(PI / 2, "X"), bevel=size * 0.12, name="Ear", **o)
    body.modifiers["Round"].segments = seg
    inside = tri(size * 0.36, size * 0.7)
    pk = m.slab(inside, size * 0.1, inner, frame @ T(0, -size * 0.18, size * 0.1) @ R(PI / 2, "X"), bevel=size * 0.04,
                name="EarIn")
    return body, pk


def flat(m, frame, outline, color, thick=0.02, **o):
    """Printed / stuck-on flat shape (tape, ink) on a face; frame local Z = out of the face."""
    return m.slab(outline, thick, color, frame @ T(0, 0, thick / 2), bevel=thick * 0.4, name="Flat", **o)


def rect(w, h, cx=0.0, cy=0.0):
    return [(cx - w, cy - h), (cx + w, cy - h), (cx + w, cy + h), (cx - w, cy + h)]


# -- the crate ---------------------------------------------------------------------------------------
def crate(key, lid_open=0.0):
    P = LOOKS[key]
    m = Model(f"Crate{key}")
    mo = dict(rough=P["rough"], coat=P.get("coat", 0.0), alpha=P.get("alpha", 1.0))

    # hollow body (open top) with paw holes on the front and the left side
    shell = box(m, (0, 0, H / 2), (HX, HY, H / 2), P["body"], bevel=P["bevel"], seg=P["seg"], name="Body", harden=False, **mo)
    cm = Model("Cut")
    box(cm, (0, 0, H / 2 + WALL + 0.3), (HX - WALL, HY - WALL, H / 2 + 0.3), (0, 0, 0), bevel=0.04, seg=2)
    pz, ps = PAW[key]
    paw_cutter(cm, face_frame("front", 0, pz), ps)
    paw_cutter(cm, face_frame("left", 0, 0.75), 0.75)
    if key == "Wood":
        # plank grooves around the body
        for z in (0.62, 1.18):
            for face in ("front", "left", "back", "right"):
                box(cm, (0, 0, 0), (HX * 0.98, 0.02, 0.03), (0, 0, 0), frame=face_frame(face, 0, z), bevel=0.0)
    cut(shell, cm)
    drop(cm)

    # inside: dark for paper / wood, a warm glow for gold, a glowing core for diamond
    if key in ("Paper", "Wood"):
        box(m, (0, 0, WALL + 0.02), (HX - WALL - 0.01, HY - WALL - 0.01, 0.02), P["inside"], bevel=0.0, name="Inside",
            rough=0.9)
    elif key == "Gold":
        box(m, (0, 0, WALL + 0.02), (HX - WALL - 0.01, HY - WALL - 0.01, 0.02), P["inside"], bevel=0.0, name="Inside",
            emit=2.5)
    else:
        m.ball((0, 0, H * 0.45), 0.4, P["inside"], emit=4.0, name="Core")

    def L():
        return lid_frame(lid_open)

    # lid: a cap that fits over the top, hollow underneath
    cap = box(m, (0, 0, 0), (HX + 0.06, HY + 0.06, 0.22), P["lid"], frame=L(), bevel=P["bevel"], seg=P["seg"], name="Lid", harden=False, **mo)
    cm = Model("Cut")
    box(cm, (0, 0, -0.12), (HX + 0.005, HY + 0.005, 0.22), (0, 0, 0), frame=L(), bevel=0.0)
    if key == "Wood":
        for x in (-0.36, 0.36):
            box(cm, (x, 0, 0.22), (0.022, HY + 0.2, 0.035), (0, 0, 0), frame=L(), bevel=0.0)
    cut(cap, cm)
    drop(cm)
    for x in (-1, 1):
        ear(m, L() @ T(x * 0.56, 0.3, 0.2), 0.62, P["ear"], crystal=key == "Diamond", **mo)

    globals()["_" + key.lower()](m, P, L(), mo)
    return m


def lid_frame(lid_open):
    """Lid space: origin at the lid's centre; closed, the cap covers z = H - 0.27 .. H + 0.17."""
    hinge = Vector((0, HY + 0.06, H - 0.27))
    lift = T(0, 0, 0.35 * min(1.0, lid_open / 0.6)) if lid_open > 0 else Matrix()
    return lift @ T(*hinge) @ R(-lid_open, "X") @ T(*(-hinge)) @ T(0, 0, H - 0.05)


# -- per-material details ------------------------------------------------------------------------------
def _paper(m, P, L, mo):
    tape = (236, 214, 164)
    to = dict(rough=0.3)
    # tape across the lid top (front to back) and down the lid's front, then on down the body with a torn end
    flat(m, L @ T(0, 0, 0.22), rect(0.24, HY + 0.06), tape, **to)
    flat(m, L @ T(0, -HY - 0.06, 0.0) @ R(PI / 2, "X"), rect(0.24, 0.22), tape, **to)
    torn = [(-0.24, 0.0), (0.24, 0.0), (0.24, -0.12)]
    for i in range(7):
        x = 0.24 - 0.48 * (i + 1) / 7
        torn.append((x, -0.12 + (0.04 if i % 2 == 0 else -0.02)))
    torn.append((-0.24, -0.12))
    flat(m, face_frame("front", 0, H - 0.27), [(x, y) for x, y in torn], tape, **to)
    # taped bottom corners (front-left, front-right)
    for u in (-1, 1):
        flat(m, face_frame("front", u * (HX - 0.17), 0.19), rect(0.17, 0.17), tape, **to)
        flat(m, face_frame("left" if u < 0 else "right", (HY - 0.17) * -u, 0.19), rect(0.17, 0.17), tape, **to)
    # printed "this way up" arrows on the left side
    ink = (120, 80, 44)
    for u in (-0.78, -0.5):
        arrow = [(u - 0.06, 1.1), (u + 0.06, 1.1), (u + 0.06, 1.3), (u + 0.13, 1.3), (u, 1.44), (u - 0.13, 1.3), (u - 0.06, 1.3)]
        flat(m, face_frame("left", 0, 0), arrow, ink, thick=0.012, rough=0.9)


def _wood(m, P, L, mo):
    post, metal, bolt = P["post"], P["metal"], P["bolt"]
    wo = dict(rough=0.75)
    # corner posts and bottom rims
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(m, (sx * (HX - 0.13), sy * (HY - 0.13), H / 2 - 0.1), (0.16, 0.16, H / 2 - 0.12), post, bevel=0.04, seg=2,
                name="Post", **wo)
    for face in ("front", "left", "back", "right"):
        box(m, (0, 0, 0), (HX - 0.28, 0.11, 0.035), post, frame=face_frame(face, 0, 0.16, 0.0), bevel=0.03, seg=2,
            name="Rim", **wo)
    # diagonal brace on the left side
    fr = face_frame("left", 0, 0.98, 0.0) @ R(0.78, "Z")
    box(m, (0, 0, 0), (0.95, 0.1, 0.035), post, frame=fr, bevel=0.03, seg=2, name="Brace", **wo)
    # nails on the rims
    for face in ("front", "left"):
        for u in (-0.45, 0.0, 0.45):
            if face == "front" and u == 0.0:
                continue
            m.ball(face_frame(face, u, 0.16, 0.05) @ Vector((0, 0, 0)), 0.035, metal)
    # metal brackets: the 4 bottom corners of the body and the 4 top corners of the lid
    def bracket(fr):
        box(m, (0, 0, 0), (0.2, 0.2, 0.2), metal, frame=fr, bevel=0.04, seg=2, name="Bracket", rough=0.35)
        for d in ((0, -1, 0), (-1, 0, 0), (1, 0, 0), (0, 1, 0)):
            m.ball(fr @ (Vector(d) * 0.205 + Vector((0, 0, 0))), 0.055, bolt, rough=0.3)

    for sx in (-1, 1):
        for sy in (-1, 1):
            bracket(T(sx * (HX - 0.12), sy * (HY - 0.12), 0.12))
            bracket(L @ T(sx * (HX - 0.07), sy * (HY - 0.07), 0.08))


def _gold(m, P, L, mo):
    band, gemc = P["band"], P["gem"]
    go = dict(rough=0.2, coat=0.8)
    # raised bands on the vertical edges and along the bottom
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(m, (sx * (HX - 0.1), sy * (HY - 0.1), H / 2 - 0.12), (0.14, 0.14, H / 2 - 0.12), band, bevel=0.05, seg=3,
                name="Band", **go)
    for face in ("front", "left", "back", "right"):
        box(m, (0, 0, 0), (HX - 0.2, 0.1, 0.04), band, frame=face_frame(face, 0, 0.14, 0.0), bevel=0.035, seg=3, name="Band", **go)
    # lid rim band
    box(m, (0, 0, -0.14), (HX + 0.09, HY + 0.09, 0.07), band, frame=L, bevel=0.05, seg=3, name="LidBand", **go)
    # gems on the corners (body bottom + lid top), each in a gold setting
    corners = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            corners.append(T(sx * (HX + 0.02), sy * (HY + 0.02), 0.2) @ Matrix())
            corners.append(L @ T(sx * (HX + 0.08), sy * (HY + 0.08), 0.06))
    for c in corners:
        pos = c.to_translation()
        centre = Vector((0, 0, pos.z))
        n = (pos - centre).normalized()
        fr = basis(pos, n)
        m.torus(0.17, 0.045, band, fr, nu=24, nv=8, name="Setting", **go)
        gem(m, fr @ T(0, 0, 0.02), 0.17, gemc)
    # cat-face lock with a keyhole, under the paw hole
    lock = face_frame("front", 0, 0.3, 0.0) @ kit.S(0.85)
    head = []
    for i in range(28):
        a = -PI / 2 + 2 * PI * i / 28
        x, y = 0.3 * math.cos(a), 0.26 * math.sin(a)
        if y < 0.12:
            head.append((x, y))
    right = sorted([p for p in head if p[0] >= 0], key=lambda p: p[1])
    left = sorted([p for p in head if p[0] < 0], key=lambda p: -p[1])
    ears = [(0.26, 0.12), (0.24, 0.36), (0.08, 0.2), (-0.08, 0.2), (-0.24, 0.36), (-0.26, 0.12)]
    m.slab(right + ears + left, 0.12, (255, 214, 70), lock @ T(0, 0, 0.06), bevel=0.04, name="Lock", **go)
    hole = ellipse(0.055, 0.055, 14, 0, 0.04) [:]
    flat(m, lock @ T(0, 0, 0.12), hole, (90, 50, 10), thick=0.02)
    flat(m, lock @ T(0, 0, 0.12), [(-0.025, 0.02), (0.025, 0.02), (0.045, -0.12), (-0.045, -0.12)], (90, 50, 10), thick=0.02)
    # rivets along the front bottom band
    for u in (-0.55, -0.28, 0.28, 0.55):
        m.ball(face_frame("front", u, 0.14, 0.05).to_translation(), 0.04, (255, 226, 120), rough=0.2)


def _diamond(m, P, L, mo):
    band, gemc = P["band"], P["gem"]
    co = dict(rough=0.04, alpha=0.8)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(m, (sx * (HX - 0.08), sy * (HY - 0.08), H / 2 - 0.12), (0.12, 0.12, H / 2 - 0.14), band, bevel=0.06, seg=1,
                name="Bar", **co)
    for face in ("front", "left", "back", "right"):
        box(m, (0, 0, 0), (HX - 0.2, 0.08, 0.05), band, frame=face_frame(face, 0, 0.12, 0.0), bevel=0.04, seg=1, name="Bar", **co)
    box(m, (0, 0, -0.14), (HX + 0.09, HY + 0.09, 0.07), band, frame=L, bevel=0.04, seg=1, name="LidBar", **co)
    for sx in (-1, 1):
        for sy in (-1, 1):
            for c in (T(sx * (HX + 0.02), sy * (HY + 0.02), 0.16), L @ T(sx * (HX + 0.08), sy * (HY + 0.08), 0.06)):
                pos = c.to_translation()
                n = (pos - Vector((0, 0, pos.z))).normalized() + Vector((0, 0, 0.2))
                gem(m, basis(pos, n), 0.2, gemc, emit=0.15)
    # sparkles
    for p, r in (((-1.5, -0.4, 2.35), 0.18), ((1.3, -1.35, 1.75), 0.13), ((-1.45, 0.6, 0.6), 0.1)):
        pts = []
        for i in range(8):
            a = PI / 2 + i * PI / 4
            rr = r if i % 2 == 0 else r * 0.28
            pts.append((rr * math.cos(a), rr * math.sin(a)))
        m.slab(pts, 0.03, (255, 255, 255), basis(p, (-0.4, -1, 0.2)), bevel=0.01, name="Sparkle", emit=3.0)
