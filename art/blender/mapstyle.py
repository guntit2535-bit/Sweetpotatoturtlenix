"""Map art style concepts: one diorama corner of the map in three looks, so the developer can pick one.

The client asked for the map decoration in a "cute + pixel + LEGO pattern" style. Every look shows the same
40 x 40 stud patch: a corner of a player's pen (fence on two sides, gate arch, pen floor, cat house with cat-ear
roof), a path crossing the front with a branch to the gate, 2 trees, a bush, a flower bed, a rock, a lamp and
two voxel cats (voxcat "mix", the game's cat style) for scale.

  A  LEGO bricks       - glossy plastic, round studs on every top face, green baseplates with seams, round /
                         square brick trees, 1x1 brick fence, a brick cat house with slope roof and ear slopes
  B  Pixel voxel       - matte 0.5-stud cubes with 2-3 shade colour noise, 1-stud ground tiles with studs on top
                         (the only studs), voxel blob trees with fruit pixels, pixel arch gate, stepped roof
  C  Cute toy blocks   - chunky soft-bevelled toy blocks with big DUPLO studs, candy pastels (mint, pink,
                         butter, lilac), faces on the bush / rock / flowers / house, heart and paw fence caps

build(look) builds the diorama into the current scene. 1 unit = 1 stud, front = -Y, up = +Z, ground top z = 0.
Everything is made from boxes, cylinders, wedges and balls (Roblox parts) except the few rounded shapes in C.
"""
import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector

import kit
import voxcat
from kit import Model, R, T, mat
from crates import basis
from crates_v2 import cat_ear, paw, slab

PI = math.pi
HALF = 20.0
PATH_Y = (-15.0, -9.0)
BRANCH_X = (6.0, 10.0)
PEN = (-2.0, 20.0, 2.0, 20.0)  # x0, x1, y0, y1
BED = (-17.0, -10.0, -6.0, -1.0)
FRONT_Y, LEFT_X = 2.5, -1.5  # fence lines
GATE_X = (5.0, 11.0)  # pillar centres
HOUSE = (1.0, 9.0, 11.0, 17.0)  # x0, x1, y0, y1
DOOR = (4.0, 6.0)  # door x range (front wall)
WIN = (13.0, 15.0)  # window y range (left wall)
TREE1, TREE2 = (-13.0, 11.0), (16.0, -4.0)
BUSH = (-6.0, 6.0)
ROCK = (0.5, -5.0)
LAMP = (4.0, -7.5)
# small grass decorations (same spots in every look)
DECO = [(-17.5, -18.5), (-1.5, -17.5), (13.5, -18.0), (18.0, -7.5), (-18.5, 2.5), (-9.5, -7.5), (11.5, -6.5),
        (-16.5, 17.5), (-5.5, 16.5), (-8.5, 0.5), (-3.5, -2.5), (6.5, -18.5)]
DECO_COL = [(255, 90, 120), (255, 214, 64), (255, 255, 255), (190, 120, 255), (255, 150, 60), (90, 170, 255)]
# fence segments: start, end, post at start, post at end (the gate pillars end the front segments)
SEGS = [((LEFT_X, FRONT_Y), (4.4, FRONT_Y), True, False), ((11.6, FRONT_Y), (19.5, FRONT_Y), False, True),
        ((LEFT_X, FRONT_Y), (LEFT_X, 19.5), False, True)]
CATS = [  # position, facing angle (0 = -Y), look
    ((18.2, 6.6), -0.6, dict(shape="Loaf", fur="ffa94d", second="fff1dc", pattern="tabby", patternColor="e0762b",
                             eyes="3c96ff")),
    ((-6.5, -12.2), -0.75, dict(shape="Fluffy", fur="ffffff", second="fff4e8", pattern="patches",
                                patternColor="9aa3b5", eyes="4fb6ff")),
]


def zone(x, y):
    if PATH_Y[0] <= y < PATH_Y[1]:
        return "path"
    if BRANCH_X[0] <= x < BRANCH_X[1] and PATH_Y[1] <= y < PEN[2]:
        return "path"
    if PEN[0] <= x < PEN[1] and PEN[2] <= y < PEN[3]:
        return "pen"
    if BED[0] <= x < BED[1] and BED[2] <= y < BED[3]:
        return "bed"
    return "grass"


def rnd(*k):
    return random.Random(hash(k)).random()


def pick(pal, *k, w=(0.56, 0.26, 0.18)):
    t = rnd(*k)
    acc = 0.0
    for c, wi in zip(pal, w):
        acc += wi
        if t < acc:
            return c
    return pal[-1]


def posts_on(seg, spacing=3.0):
    (a, b, ps, pe) = seg
    a, b = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
    n = max(1, round((b - a).length / spacing))
    out = []
    for k in range(n + 1):
        if (k == 0 and not ps) or (k == n and not pe):
            continue
        out.append(a.lerp(b, k / n))
    return out


# == batched geometry: one mesh per material, so thousands of bricks stay cheap ==============================
class Geo:
    def __init__(self, name):
        self.name = name
        self.bms = {}
        self.coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(self.coll)

    def _bm(self, color, mo):
        key = (tuple(int(c) for c in color), tuple(sorted(mo.items())))
        if key not in self.bms:
            self.bms[key] = bmesh.new()
        return self.bms[key]

    @staticmethod
    def _bevel(bm, edges, offset, seg):
        verts = list({v for e in edges for v in e.verts})
        r = bmesh.ops.bevel(bm, geom=verts + edges, offset=offset, segments=seg, profile=0.5, affect="EDGES",
                            clamp_overlap=True)
        if seg > 1:
            for f in r["faces"]:
                f.smooth = True

    def box(self, c, h, color, bevel=0.0, seg=2, frame=None, **mo):
        bm = self._bm(color, mo)
        M = (frame if frame is not None else Matrix()) @ T(*c) @ Matrix.Diagonal((2 * h[0], 2 * h[1], 2 * h[2], 1.0))
        verts = bmesh.ops.create_cube(bm, size=1.0, matrix=M)["verts"]
        if bevel > 0:
            edges = list({e for v in verts for e in v.link_edges})
            self._bevel(bm, edges, min(bevel, 0.95 * min(h)), seg)

    def span(self, x0, x1, y0, y1, z0, z1, color, **o):
        self.box(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), ((x1 - x0) / 2, (y1 - y0) / 2, (z1 - z0) / 2),
                 color, **o)

    def cyl(self, c, r, h, color, n=16, bevel=0.0, seg=2, frame=None, r2=None, both=False, **mo):
        """Cylinder standing on c (local Z up); bevel rounds the top rim (and the bottom with both=True)."""
        bm = self._bm(color, mo)
        M = (frame if frame is not None else Matrix()) @ T(c[0], c[1], c[2] + h / 2)
        verts = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=n, radius1=r,
                                      radius2=r if r2 is None else r2, depth=h, matrix=M)["verts"]
        faces = list({f for v in verts for f in v.link_faces})
        caps = [f for f in faces if len(f.verts) == n]
        for f in faces:
            if f not in caps:
                f.smooth = True
        Mi = M.inverted()
        caps.sort(key=lambda f: (Mi @ f.calc_center_median()).z)
        rim = caps if both else caps[-1:]
        for f in caps:
            if bevel <= 0 or f not in rim:
                for e in f.edges:
                    e.smooth = False
        if bevel > 0:
            edges = list({e for f in rim for e in f.edges})
            self._bevel(bm, edges, min(bevel, r * 0.6, h * 0.45), seg)

    def ball(self, c, rad, color, n=18, frame=None, scale=(1, 1, 1), **mo):
        bm = self._bm(color, mo)
        M = (frame if frame is not None else Matrix()) @ T(*c) @ Matrix.Diagonal(
            (rad * scale[0], rad * scale[1], rad * scale[2], 1.0))
        verts = bmesh.ops.create_uvsphere(bm, u_segments=n, v_segments=max(6, n // 2), radius=1.0, matrix=M)["verts"]
        for f in {f for v in verts for f in v.link_faces}:
            f.smooth = True

    def prism(self, outline, thick, color, frame, bevel=0.0, seg=1, **mo):
        """2D outline in local XY, extruded thick along local Z."""
        bm = self._bm(color, mo)
        vs = [bm.verts.new(frame @ Vector((x, y, 0.0))) for x, y in outline]
        f = bm.faces.new(vs)
        ext = bmesh.ops.extrude_face_region(bm, geom=[f])
        nv = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
        bmesh.ops.translate(bm, verts=nv, vec=frame.to_3x3() @ Vector((0, 0, thick)))
        faces = list({f for v in vs + nv for f in v.link_faces})
        bmesh.ops.recalc_face_normals(bm, faces=faces)
        if bevel > 0:
            edges = list({e for f in faces for e in f.edges})
            self._bevel(bm, edges, bevel, seg)

    def finish(self):
        objs = []
        for (col, mo), bm in self.bms.items():
            me = bpy.data.meshes.new(self.name)
            bm.to_mesh(me)
            bm.free()
            obj = bpy.data.objects.new(self.name, me)
            obj.data.materials.append(mat(col, **dict(mo)))
            self.coll.objects.link(obj)
            objs.append(obj)
        self.bms = {}
        return objs


XZ = R(PI / 2, "X")  # local XY -> world XZ, local Z -> world -Y (a flat shape facing the viewer)


def yz_frame(x0):
    """local (a, b, c) -> world (c + x0, a, b): an outline in world YZ extruded along +X."""
    return T(x0, 0, 0) @ Matrix(((0, 0, 1, 0), (1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


def place_cats(floor_z):
    """The game's voxel cats (voxcat 'mix') for scale; floor_z(x, y) = height of the floor under them."""
    for (x, y), ang, look in CATS:
        m = voxcat.cat("mix", look, name="Cat")
        M = T(x, y, floor_z(x, y)) @ R(ang, "Z") @ Matrix.Scale(0.95, 4)
        for o in m.objects:
            o.matrix_world = M @ o.matrix_world


# =============================================================================================================
# A  LEGO bricks
# =============================================================================================================
GL = dict(rough=0.2, coat=0.55)  # glossy ABS
A = dict(
    g1=(66, 160, 58), g2=(98, 186, 66), seam=(56, 52, 46), base1=(168, 98, 58), base2=(140, 80, 48),
    path1=(236, 214, 164), path2=(250, 244, 226), pathbed=(150, 154, 160),
    deck=((204, 142, 105), (176, 112, 74), (222, 166, 118)), deckbed=(92, 58, 38),
    post=(124, 80, 58), rail=(222, 166, 118), red=(214, 34, 30), yellow=(250, 200, 30), blue=(20, 110, 200),
    white=(244, 244, 242), lblue=(120, 196, 240), roof=(214, 34, 30), pink=(255, 140, 180), dark=(40, 36, 52),
    trunk=(124, 80, 58), leaf1=(30, 130, 64), leaf2=(66, 170, 58), leaf3=(160, 204, 30), black=(34, 36, 44),
    dgrey=(100, 104, 112), lgrey=(166, 172, 180),
)
A_PLATE = 0.4
A_BRICK = 1.2


def a_stud(g, x, y, z, col):
    g.cyl((x, y, z - 0.02), 0.3, 0.2, col, n=16, bevel=0.05, seg=2, **GL)


def a_studs(g, x0, x1, y0, y1, z, col, skip=None):
    """Studs on every whole stud cell of the top face [x0, x1] x [y0, y1] at height z."""
    for i in range(int(math.floor(x0 + 0.01)), int(math.ceil(x1 - 0.01))):
        for j in range(int(math.floor(y0 + 0.01)), int(math.ceil(y1 - 0.01))):
            cx, cy = i + 0.5, j + 0.5
            if cx - 0.45 < x0 or cx + 0.45 > x1 or cy - 0.45 < y0 or cy + 0.45 > y1:
                continue
            if skip and skip(cx, cy):
                continue
            a_stud(g, cx, cy, z, col)


def a_brick(g, x0, x1, y0, y1, z0, h, col, studs=True, gap=0.03, skip=None):
    g.span(x0 + gap, x1 - gap, y0 + gap, y1 - gap, z0, z0 + h - 0.02, col, bevel=0.05, seg=2, **GL)
    if studs:
        a_studs(g, x0, x1, y0, y1, z0 + h - 0.02, col, skip)


def a_round(g, x, y, z0, r, h, col, studs=True):
    """Round brick / plate (radius r) with studs on its top."""
    g.cyl((x, y, z0), r - 0.03, h - 0.02, col, n=max(16, int(r * 18)), bevel=0.06, seg=2, **GL)
    if studs:
        for i in range(int(math.floor(x - r)), int(math.ceil(x + r))):
            for j in range(int(math.floor(y - r)), int(math.ceil(y + r))):
                if math.hypot(i + 0.5 - x, j + 0.5 - y) <= r - 0.45:
                    a_stud(g, i + 0.5, j + 0.5, z0 + h - 0.02, col)


def a_ground(g):
    # 4 x 4 baseplates of 10 x 10, checkered, with seams; studs only on the grass
    for px in range(4):
        for py in range(4):
            x0, y0 = -HALF + px * 10, -HALF + py * 10
            col = A["g1"] if (px + py) % 2 == 0 else A["g2"]
            g.span(x0 + 0.04, x0 + 9.96, y0 + 0.04, y0 + 9.96, -A_PLATE, 0, col, bevel=0.04, seg=2, **GL)
            for i in range(10):
                for j in range(10):
                    cx, cy = x0 + i + 0.5, y0 + j + 0.5
                    if zone(cx, cy) == "grass":
                        a_stud(g, cx, cy, 0, col)
    # the diorama base: two courses of 1x4 bricks on the two sides the camera sees, a filler behind
    g.span(-HALF + 0.9, HALF, -HALF + 0.9, HALF, -2 * A_BRICK - A_PLATE, -A_PLATE, A["seam"])
    for c in range(2):
        z0 = -A_PLATE - (c + 1) * A_BRICK
        for k in range(-1, 11):
            x0 = -HALF + k * 4 + (2 if c else 0)
            col = A["base1"] if (k + c) % 2 == 0 else A["base2"]
            lo, hi = max(x0, -HALF), min(x0 + 4, HALF)
            if hi - lo > 0.5:
                g.span(lo + 0.03, hi - 0.03, -HALF + 0.03, -HALF + 0.97, z0 + 0.02, z0 + A_BRICK - 0.02, col,
                       bevel=0.05, seg=2, **GL)
            lo, hi = max(x0, -HALF + 1), min(x0 + 4, HALF)
            if hi - lo > 0.5:
                g.span(-HALF + 0.03, -HALF + 0.97, lo + 0.03, hi - 0.03, z0 + 0.02, z0 + A_BRICK - 0.02,
                       A["base2"] if (k + c) % 2 == 0 else A["base1"], bevel=0.05, seg=2, **GL)
    # path: smooth 2x2 tiles on a grey plate (tiles have no studs)
    for (x0, x1, y0, y1) in ((-HALF, HALF, PATH_Y[0], PATH_Y[1]), (BRANCH_X[0], BRANCH_X[1], PATH_Y[1], PEN[2])):
        g.span(x0, x1, y0, y1, 0, 0.2, A["pathbed"])
        for i in range(int(x0), int(x1), 2):
            for j in range(int(y0), int(y1), 2):
                col = A["path1"] if ((i - int(x0)) // 2 + (j - int(y0)) // 2) % 2 == 0 else A["path2"]
                g.span(i + 0.04, i + 1.96, j + 0.04, min(j + 2, y1) - 0.04, 0.18, A_PLATE, col, bevel=0.04, seg=2,
                       **GL)
    # pen floor: plank tiles (1 x 3..6) in three wood colours on a dark plate
    x0, x1, y0, y1 = PEN
    g.span(x0, x1, y0, y1, 0, 0.2, A["deckbed"])
    for j in range(int(y0), int(y1)):
        x = x0 - (j % 3)
        k = 0
        while x < x1:
            ln = 3 + int(rnd("plank", j, k) * 4)
            lo, hi = max(x, x0), min(x + ln, x1)
            if hi - lo > 0.4:
                col = A["deck"][int(rnd("pc", j, k) * 3)]
                g.span(lo + 0.03, hi - 0.03, j + 0.04, j + 0.96, 0.18, A_PLATE, col, bevel=0.04, seg=2, **GL)
            x += ln
            k += 1


def a_fence(g):
    for seg in SEGS:
        a, b = Vector(seg[0] + (0,)), Vector(seg[1] + (0,))
        d = (b - a).normalized()
        n = Vector((-d.y, d.x, 0))
        L = (b - a).length
        mid = (a + b) / 2
        # rails: 1-wide plates at two heights, studs on top
        posts = posts_on(seg)
        avoid = posts + [Vector((GATE_X[0], FRONT_Y, 0)), Vector((GATE_X[1], FRONT_Y, 0))]
        for z0 in (0.8, 2.0):
            hx = L / 2 if abs(d.x) > 0.5 else 0.3
            hy = 0.3 if abs(d.x) > 0.5 else L / 2
            g.box((mid.x, mid.y, z0 + A_PLATE / 2), (hx, hy, A_PLATE / 2 - 0.01), A["rail"], bevel=0.04, seg=2, **GL)
            for k in range(int(L) + 1):
                p = a + d * (k + 0.5)
                if (p - a).length > L - 0.3 or min((p - q).length for q in avoid) < 1.1:
                    continue
                a_stud(g, p.x, p.y, z0 + A_PLATE - 0.02, A["rail"])
        for p in posts:
            for c in range(2):
                g.span(p.x - 0.48, p.x + 0.48, p.y - 0.48, p.y + 0.48, c * A_BRICK + 0.01, (c + 1) * A_BRICK - 0.02,
                       A["post"], bevel=0.05, seg=2, **GL)
            a_stud(g, p.x, p.y, 2 * A_BRICK - 0.02, A["post"])
        _ = n


def a_gate(g, m):
    y0, y1 = FRONT_Y - 1, FRONT_Y + 1
    for cx in GATE_X:
        for c in range(4):
            a_brick(g, cx - 1, cx + 1, y0, y1, c * A_BRICK + 0.01, A_BRICK, A["red"] if c % 2 == 0 else A["yellow"],
                    studs=False)
    top = 4 * A_BRICK
    # arch brick between the pillars (an elliptic opening)
    out = [(6.0, top)]
    for k in range(17):
        a = PI - PI * k / 16
        out.append((8 + 2.0 * math.cos(a), top - 2.0 + 1.5 * math.sin(a)))
    out.append((10.0, top))
    g.prism(out, 1.6, A["blue"], T(0, FRONT_Y + 0.8, 0) @ XZ, bevel=0.04, seg=1, **GL)
    # beam on top with studs, ear slopes at the ends, a white sign with a paw
    a_brick(g, 3.5, 12.5, y0, y1, top, A_BRICK, A["blue"],
            skip=lambda x, y: x < 5 or x > 11)
    for sx in (-1, 1):
        cx = 8 + sx * 3.5
        ear = [(-0.95, 0), (0.95, 0), (0.25, 1.5), (-0.25, 1.5)]
        g.prism(ear, 1.6, A["red"], T(cx, FRONT_Y + 0.8, top + A_BRICK - 0.02) @ XZ, bevel=0.05, seg=1, **GL)
        inner = [(-0.55, 0.15), (0.55, 0.15), (0.15, 1.05), (-0.15, 1.05)]
        g.prism(inner, 0.12, A["pink"], T(cx, FRONT_Y - 0.78, top + A_BRICK - 0.02) @ XZ, bevel=0.03, seg=1, **GL)
    g.span(6.3, 9.7, y0 - 0.16, y0 + 0.02, top + 0.12, top + A_BRICK - 0.12, A["white"], bevel=0.04, seg=2, **GL)
    paw(m, basis((8, y0 - 0.16, top + A_BRICK / 2 - 0.02), (0, -1, 0)), 0.95, A["black"], thick=0.08, **GL)


def a_house(g):
    x0, x1, y0, y1 = HOUSE
    z0 = A_PLATE
    door = DOOR
    wall_c = 3
    blues = {(0, 1), (1, 5), (2, 2), (0, 9), (2, 7), (1, 11)}
    # interior so the door / window show dark
    g.span(x0 + 1, x1 - 1, y0 + 1, y1 - 1, z0, z0 + wall_c * A_BRICK, A["dark"])
    for c in range(wall_c):
        zc = z0 + c * A_BRICK
        k = 0
        # front / back rows run along X
        for (ya, yb, front) in ((y0, y0 + 1, True), (y1 - 1, y1, False)):
            x = x0 - (c % 2)
            while x < x1:
                lo, hi = max(x, x0), min(x + 2, x1)
                pieces = [(lo, hi)]
                if front and c < 2:
                    pieces = [(a, min(b, door[0])) for a, b in pieces if a < door[0]] + \
                             [(max(a, door[1]), b) for a, b in pieces if b > door[1]]
                for a, b in pieces:
                    if b - a > 0.4:
                        col = A["lblue"] if (c, k) in blues else A["white"]
                        a_brick(g, a, b, ya, yb, zc, A_BRICK, col, studs=False)
                    k += 1
                x += 2
        # side walls run along Y (window on the left wall, middle course)
        for (xa, xb, left) in ((x0, x0 + 1, True), (x1 - 1, x1, False)):
            y = y0 + 1 - ((c + 1) % 2)
            while y < y1 - 1:
                lo, hi = max(y, y0 + 1), min(y + 2, y1 - 1)
                pieces = [(lo, hi)]
                if left and c == 1:
                    pieces = [(a, min(b, WIN[0])) for a, b in pieces if a < WIN[0]] + \
                             [(max(a, WIN[1]), b) for a, b in pieces if b > WIN[1]]
                for a, b in pieces:
                    if b - a > 0.4:
                        col = A["lblue"] if (c, k) in blues else A["white"]
                        a_brick(g, xa, xb, a, b, zc, A_BRICK, col, studs=False)
                    k += 1
                y += 2
    # window pane and a door frame (1x1 bricks either side would be too busy: a yellow lintel tile)
    g.span(x0 + 0.42, x0 + 0.58, WIN[0], WIN[1], z0 + A_BRICK, z0 + 2 * A_BRICK, (170, 220, 255), rough=0.05, coat=1.0)
    g.span(door[0] - 0.3, door[1] + 0.3, y0 - 0.12, y0 + 0.2, z0 + 2 * A_BRICK - 0.02, z0 + 2 * A_BRICK + 0.38,
           A["yellow"], bevel=0.04, seg=2, **GL)
    # stepped slope roof, ridge along X; white gable fill under it
    zt = z0 + wall_c * A_BRICK
    for i in range(3):
        zb = zt + i * A_BRICK
        slope = [(0.0, 0.0), (1.0, 0.0), (1.0, A_BRICK - 0.02), (0.0, 0.4)]
        g.prism([(y0 - 0.5 + i + u, v) for u, v in slope], (x1 - x0) + 1.0, A["roof"],
                T(0, 0, zb) @ yz_frame(x0 - 0.5), bevel=0.04, seg=1, **GL)
        g.prism([(y1 + 0.5 - i - u, v) for u, v in slope], (x1 - x0) + 1.0, A["roof"],
                T(0, 0, zb) @ yz_frame(x0 - 0.5), bevel=0.04, seg=1, **GL)
        g.span(x0 + 0.03, x1 - 0.03, y0 + 0.5 + i, y1 - 0.5 - i, zb, zb + A_BRICK - 0.02, A["white"], bevel=0.04,
               seg=2, **GL)
    zr = zt + 3 * A_BRICK
    ym = (y0 + y1) / 2
    ears = (x0 + 1.0, x1 - 1.0)
    a_brick(g, x0 - 0.5, x1 + 0.5, ym - 0.5, ym + 0.5, zr, A_BRICK, A["roof"],
            skip=lambda x, y: min(abs(x - e) for e in ears) < 1.0)
    for ex in ears:
        ear = [(-1.0, 0), (1.0, 0), (0.25, 1.7), (-0.25, 1.7)]
        g.prism(ear, 1.0, A["roof"], T(ex, ym + 0.5, zr + A_BRICK - 0.02) @ XZ, bevel=0.05, seg=1, **GL)
        inner = [(-0.6, 0.12), (0.6, 0.12), (0.15, 1.2), (-0.15, 1.2)]
        g.prism(inner, 0.12, A["pink"], T(ex, ym - 0.48, zr + A_BRICK - 0.02) @ XZ, bevel=0.03, seg=1, **GL)


def a_trees(g):
    # round tree: stacked round bricks, red 1x1 round "apples" on the ledges
    x, y = TREE1
    for c in range(3):
        a_round(g, x, y, c * A_BRICK, 1.0, A_BRICK, A["trunk"], studs=False)
    tiers = [(3.6, A["leaf1"]), (3.0, A["leaf2"]), (2.2, A["leaf3"]), (1.2, A["leaf3"])]
    for k, (r, col) in enumerate(tiers):
        a_round(g, x, y, 3 * A_BRICK + k * A_BRICK, r, A_BRICK, col)
    for ang in (3.5, 4.1, 4.7, 5.4, 2.6):
        ax, ay = x + 3.25 * math.cos(ang), y + 3.25 * math.sin(ang)
        g.cyl((ax, ay, 4 * A_BRICK - 0.02), 0.44, 0.3, A["red"], n=20, **GL)
        g.ball((ax, ay, 4 * A_BRICK + 0.26), 0.44, A["red"], n=20, scale=(1, 1, 0.8), **GL)
        g.cyl((ax, ay, 4 * A_BRICK + 0.55), 0.07, 0.25, (60, 150, 50), n=8, **GL)
    # square tree: 6x6, 6x6, 4x4, 2x2 bricks, pink 1x1 flower plates on the steps
    x, y = TREE2
    for c in range(3):
        a_brick(g, x - 1, x + 1, y - 1, y + 1, c * A_BRICK, A_BRICK, A["trunk"], studs=False)
    for k, (h, col) in enumerate(((3, A["leaf1"]), (3, A["leaf2"]), (2, A["leaf2"]), (1, A["leaf3"]))):
        a_brick(g, x - h, x + h, y - h, y + h, (3 + k) * A_BRICK, A_BRICK, col)
    for dx, dy in ((-2.5, -2.5), (2.5, -2.5), (-2.5, 0.5), (0.5, -2.5), (-1.5, -1.5), (1.5, -1.5)):
        g.cyl((x + dx, y + dy, (5 if abs(dx) > 2 or abs(dy) > 2 else 6) * A_BRICK - 0.02), 0.45, A_PLATE,
              A["pink"], n=20, bevel=0.06, **GL)


def a_props(g):
    # bush: offset bricks in two greens with yellow flower studs
    x, y = BUSH
    a_brick(g, x - 2, x + 2, y - 1.5, y + 1.5, 0, A_BRICK, A["leaf2"])
    a_brick(g, x - 2, x, y - 1, y + 1, A_BRICK, A_BRICK, A["leaf3"])
    a_brick(g, x, x + 1.5, y - 1.5, y + 0.5, A_BRICK, A_BRICK, A["leaf1"])
    for dx, dy in ((-1.5, -0.5), (0.75, -1.0)):
        g.cyl((x + dx, y + dy, 2 * A_BRICK - 0.02), 0.42, A_PLATE, A["yellow"], n=20, bevel=0.06, **GL)
    # flower bed: tan border bricks, brown soil plate with studs, 1x1 stems with 5-petal flower plates
    x0, x1, y0, y1 = BED
    g.span(x0 + 1, x1 - 1, y0 + 1, y1 - 1, 0, 0.8, (110, 66, 40), bevel=0.04, seg=2, **GL)
    a_studs(g, x0 + 1, x1 - 1, y0 + 1, y1 - 1, 0.8, (110, 66, 40))
    for xa in range(int(x0), int(x1), 2):
        for (ya, yb) in ((y0, y0 + 1), (y1 - 1, y1)):
            a_brick(g, xa, min(xa + 2, x1), ya, yb, 0, A_BRICK, (228, 205, 158))
    for ya in range(int(y0) + 1, int(y1) - 1, 2):
        for (xa, xb) in ((x0, x0 + 1), (x1 - 1, x1)):
            a_brick(g, xa, xb, ya, min(ya + 2, y1 - 1), 0, A_BRICK, (228, 205, 158))
    cols = [A["red"], A["yellow"], A["pink"], A["white"], (255, 130, 30), A["blue"], A["red"], A["pink"]]
    spots = [(-15.5, -4.5), (-13.5, -4.5), (-11.5, -4.5), (-14.5, -2.5), (-12.5, -2.5), (-15.5, -2.5),
             (-11.5, -2.5)]
    for k, (fx, fy) in enumerate(spots):
        hgt = 1.6 + 0.6 * (k % 2)
        g.cyl((fx, fy, 0.78), 0.14, hgt, (60, 150, 50), n=10, **GL)
        g.cyl((fx + 0.25, fy - 0.1, 0.78), 0.3, 0.2, A["leaf3"], n=14, bevel=0.04, **GL)
        z = 0.78 + hgt
        for p in range(5):
            a = 2 * PI * p / 5 + k
            g.cyl((fx + 0.3 * math.cos(a), fy + 0.3 * math.sin(a), z), 0.28, 0.22, cols[k], n=14, bevel=0.06, **GL)
        g.cyl((fx, fy, z + 0.05), 0.17, 0.3, A["yellow"], n=12, bevel=0.04, **GL)
    # rock: grey bricks and a slope
    x, y = ROCK
    a_brick(g, x - 1.5, x + 1.5, y - 1, y + 1, 0, A_BRICK, A["dgrey"])
    a_brick(g, x - 0.5, x + 1.5, y - 1, y + 1, A_BRICK, A_BRICK, A["lgrey"])
    g.prism([(-1.47, 0), (-0.53, 0), (-0.53, A_BRICK - 0.02), (-1.47, 0.4)], 1.94, A["lgrey"],
            T(x, y + 0.97, A_BRICK) @ XZ, bevel=0.04, **GL)
    # lamp: round plate, bar, black round brick, glowing dome
    x, y = LAMP
    a_round(g, x, y, 0, 1.0, A_PLATE, A["black"])
    g.cyl((x, y, A_PLATE - 0.02), 0.24, 4.0, A["dgrey"], n=14, **GL)
    a_round(g, x, y, 4.3, 0.8, 0.6, A["black"], studs=False)
    g.ball((x, y, 5.15), 0.78, (255, 222, 90), n=24, scale=(1, 1, 0.85), rough=0.1, coat=1.0, emit=2.5)
    a_round(g, x, y, 5.75, 0.6, A_PLATE, A["black"])


def a_deco(g):
    for n, (x, y) in enumerate(DECO):
        g.cyl((x, y, -0.02), 0.45, 0.4, A["leaf3"] if n % 2 else A["leaf2"], n=20, bevel=0.06, **GL)
        if n % 3 != 2:
            for p in range(5):
                a = 2 * PI * p / 5 + n
                g.cyl((x + 0.26 * math.cos(a), y + 0.26 * math.sin(a), 0.36), 0.25, 0.2, DECO_COL[n % 6], n=12,
                      bevel=0.05, **GL)
            g.cyl((x, y, 0.4), 0.15, 0.25, A["yellow"], n=10, bevel=0.03, **GL)
        else:
            for k, (dx, dy) in enumerate(((-0.2, 0), (0.2, 0.1), (0, -0.2))):
                g.cyl((x + dx, y + dy, 0.36), 0.1, 0.7 + 0.25 * k, A["leaf1"], n=8, **GL)


def build_a():
    g = Geo("LookA")
    a_deco(g)
    m = Model("LookAExtra")
    a_ground(g)
    a_fence(g)
    a_gate(g, m)
    a_house(g)
    a_trees(g)
    a_props(g)
    g.finish()
    place_cats(lambda x, y: A_PLATE)


# =============================================================================================================
# B  Pixel voxel
# =============================================================================================================
MT = dict(rough=0.85)
V = 0.5  # prop voxel size
B = dict(
    grass=((104, 196, 72), (126, 214, 86), (84, 174, 60)),
    dirt=((156, 104, 62), (138, 90, 52), (172, 118, 72)),
    sand=((242, 222, 170), (230, 206, 150), (250, 236, 196)),
    plank=((214, 154, 92), (194, 132, 74), (228, 172, 108)),
    wood=((168, 108, 60), (150, 94, 50), (184, 124, 72)),
    leaf=((70, 170, 64), (92, 192, 76), (54, 146, 56)),
    blossom=((255, 160, 200), (255, 188, 218), (238, 128, 178)),
    stone=((150, 156, 170), (172, 178, 192), (128, 134, 148)),
    cream=((252, 238, 212), (242, 226, 198), (255, 246, 230)),
    roof=((240, 98, 72), (222, 78, 60), (252, 122, 90)),
    red=((236, 70, 70), (214, 54, 58), (248, 98, 92)),
)


class Vox:
    """A 0.5-stud voxel grid in world space: put colours in, cubes with at least one open side come out."""

    def __init__(self):
        self.cells = {}

    @staticmethod
    def idx(x, y, z):
        return (int(math.floor(x / V + 1e-6)), int(math.floor(y / V + 1e-6)), int(math.floor(z / V + 1e-6)))

    def fill(self, x0, x1, y0, y1, z0, z1, col):
        """col: colour or f(i, j, k) -> colour / None."""
        i0, j0, k0 = self.idx(x0, y0, z0)
        i1, j1, k1 = self.idx(x1 - 1e-4, y1 - 1e-4, z1 - 1e-4)
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                for k in range(k0, k1 + 1):
                    c = col(i, j, k) if callable(col) else col
                    if c:
                        self.cells[(i, j, k)] = c

    def blob(self, cx, cy, cz, rx, ry, rz, col):
        def f(i, j, k):
            x, y, z = (i + 0.5) * V - cx, (j + 0.5) * V - cy, (k + 0.5) * V - cz
            if (x / rx) ** 2 + (y / ry) ** 2 + (z / rz) ** 2 > 1.0:
                return None
            return col(i, j, k) if callable(col) else col

        self.fill(cx - rx, cx + rx, cy - ry, cy + ry, max(0.0, cz - rz), cz + rz, f)

    def emit(self, g):
        nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
        for (i, j, k), col in self.cells.items():
            if all((i + a, j + b, k + c) in self.cells for a, b, c in nb):
                continue
            g.box(((i + 0.5) * V, (j + 0.5) * V, (k + 0.5) * V), (V / 2,) * 3, col, **col_mo(col))


def col_mo(col):
    return dict(rough=0.4, emit=2.2) if col == (255, 226, 110) else MT


def b_ground(g):
    for i in range(-20, 20):
        for j in range(-20, 20):
            cx, cy = i + 0.5, j + 0.5
            zn = zone(cx, cy)
            if zn == "path":
                col = pick(B["sand"], "s", i, j)
            elif zn == "pen":
                k = (i + 2 * (j % 2) + 7) // 4
                col = pick(B["plank"], "p", k, j)
            elif zn == "bed":
                col = pick(((96, 60, 40), (84, 52, 34), (108, 70, 46)), "b", i, j)
            else:
                col = pick(B["grass"], "g", i, j)
            g.box((cx, cy, -0.5), (0.5, 0.5, 0.5), col, **MT)
            if zn == "grass":
                g.cyl((cx, cy, -0.01), 0.3, 0.15, col, n=12, **MT)
    # dirt sides on the two sides the camera sees (a few grass pixels hang over the edge, a few stones)
    for k in range(-3, -1):
        for t in range(-20, 20):
            for (cx, cy) in ((t + 0.5, -19.5), (-19.5, t + 0.5))[:2 if t > -20 else 1]:
                if k == -2 and rnd("hang", cx, cy) < 0.3:
                    col = B["grass"][2]
                elif rnd("ore", cx, cy, k) < 0.06:
                    col = B["stone"][0]
                else:
                    col = pick(B["dirt"], "d", cx, cy, k)
                g.box((cx, cy, k + 0.5), (0.5, 0.5, 0.5), col, **MT)
    g.span(-19, 20, -19, 20, -3, -1, B["dirt"][1], **MT)


def b_fence(vx):
    for seg in SEGS:
        a, b = Vector(seg[0] + (0,)), Vector(seg[1] + (0,))
        along_x = abs(b.x - a.x) > 0.5
        for z0 in (1.0, 2.0):
            if along_x:
                vx.fill(min(a.x, b.x), max(a.x, b.x), a.y, a.y + V, z0, z0 + V,
                        lambda i, j, k: pick(B["plank"], "r", i, k))
            else:
                vx.fill(a.x, a.x + V, min(a.y, b.y), max(a.y, b.y), z0, z0 + V,
                        lambda i, j, k: pick(B["plank"], "r", j, k))
        for p in posts_on(seg):
            px, py = math.floor(p.x * 2) / 2, math.floor(p.y * 2) / 2
            vx.fill(px - V, px + 2 * V, py - V, py + 2 * V, 0, 2.5, lambda i, j, k: pick(B["wood"], "w", i, j, k))
            vx.fill(px - V, px + 2 * V, py - V, py + 2 * V, 2.5, 3.0, B["wood"][2])


PAW_PX = [".##.##.", ".##.##.", "#.....#", "#.###.#", ".#####.", ".#####.", "..###.."]


def b_gate(vx):
    for cx in GATE_X:
        vx.fill(cx - 1, cx + 1, FRONT_Y - 1, FRONT_Y + 1, 0, 3.5, lambda i, j, k: pick(B["wood"], "gp", i, j, k))
    # pixel arch: a half ring of voxels between the pillars
    def arch(i, j, k):
        x, z = (i + 0.5) * V - 8.0, (k + 0.5) * V - 3.5
        d = math.hypot(x, z)
        if 2.0 <= d <= 4.0:
            return B["red"][0] if int(d * 2) % 2 == 0 else (255, 246, 236)
        return None

    vx.fill(4.0, 12.0, FRONT_Y - 0.75, FRONT_Y + 0.75, 3.5, 7.5, arch)
    # pixel sign with a paw above the arch
    w, h = len(PAW_PX[0]), len(PAW_PX)
    x0, z0 = 5.5, 7.5
    vx.fill(x0, x0 + (w + 2) * V, FRONT_Y - 0.25, FRONT_Y + 0.25, z0, z0 + (h + 2) * V,
            lambda i, j, k: pick(B["cream"], "sg", i, k))
    for r, row in enumerate(PAW_PX):
        for c, ch in enumerate(row):
            if ch == "#":
                vx.fill(x0 + (c + 1) * V, x0 + (c + 2) * V, FRONT_Y - 0.75, FRONT_Y - 0.25,
                        z0 + (h - r) * V, z0 + (h - r + 1) * V, (60, 44, 70))
    vx.fill(x0 - V, x0, FRONT_Y - 0.25, FRONT_Y + 0.25, z0, z0 + (h + 2) * V, B["wood"][1])
    vx.fill(x0 + (w + 2) * V, x0 + (w + 3) * V, FRONT_Y - 0.25, FRONT_Y + 0.25, z0, z0 + (h + 2) * V, B["wood"][1])


def b_house(vx):
    x0, x1, y0, y1 = HOUSE
    wall = lambda i, j, k: pick(B["cream"], "hw", i, j, k)  # noqa: E731
    found = lambda i, j, k: pick(B["stone"], "hf", i, j, k)  # noqa: E731
    vx.fill(x0, x1, y0, y1, 0, 0.5, found)
    vx.fill(x0, x1, y0, y1, 0.5, 4.0, wall)
    vx.fill(x0 + 0.5, x1 - 0.5, y0 + 0.5, y1 - 0.5, 0.5, 4.0, (54, 42, 64))  # dark inside
    # door (pixel round top) and window
    for (i, j, k) in list(vx.cells):
        x, y, z = (i + 0.5) * V, (j + 0.5) * V, (k + 0.5) * V
        if y0 <= y < y0 + 0.5 and DOOR[0] <= x < DOOR[1] and 0.5 <= z < 3.0:
            if not (z > 2.5 and (x < DOOR[0] + 0.5 or x > DOOR[1] - 0.5)):
                del vx.cells[(i, j, k)]
        if x0 <= x < x0 + 0.5 and WIN[0] <= y < WIN[1] and 1.5 <= z < 3.0:
            vx.cells[(i, j, k)] = (150, 210, 255)
    vx.fill(x0 - 0.5, x0, WIN[0] - 0.5, WIN[1] + 0.5, 1.0, 1.5, B["wood"][0])  # window sill
    vx.fill(DOOR[0] - 0.5, DOOR[1] + 0.5, y0 - 0.5, y0, 3.0, 3.5, B["wood"][0])  # door lintel
    # stepped pixel roof, ridge along X, gable filled with wall pixels
    n_rows = int((y1 - y0) / V) + 2
    for L in range(n_rows // 2):
        z = 4.0 + L * V
        ya, yb = y0 - V + L * V, y1 + V - L * V
        def roof(i, j, k, ya=ya, yb=yb):
            y = (j + 0.5) * V
            x = (i + 0.5) * V
            edge = min(y - ya, yb - y) < 2 * V
            if edge:
                return pick(B["roof"], "rf", i, j, k) if (j + k) % 4 else B["roof"][1]
            return wall(i, j, k) if x0 <= x < x1 else None
        vx.fill(x0 - V, x1 + V, ya, yb, z, z + V, roof)
    ztop = 4.0 + (n_rows // 2) * V
    # pixel ears on the ridge (stepped triangles, pink inside)
    ym = (y0 + y1) / 2
    for ex in (x0 + 0.5, x1 - 2.5):
        rows = ["####", "####", ".##.", ".#.."] if ex < (x0 + x1) / 2 else ["####", "####", ".##.", "..#."]
        for r, row in enumerate(rows):
            for c, ch in enumerate(row):
                if ch == "#":
                    vx.fill(ex + c * V, ex + (c + 1) * V, ym - V, ym + V, ztop + r * V, ztop + (r + 1) * V,
                            B["roof"][0])
        vx.fill(ex + V, ex + 3 * V, ym - 1.5 * V, ym - V, ztop, ztop + 2 * V, (255, 160, 190))


def b_trees(vx):
    x, y = TREE1
    vx.fill(x - 0.75, x + 0.75, y - 0.75, y + 0.75, 0, 4.5, lambda i, j, k: pick(B["wood"], "t", i, j, k))
    vx.blob(x, y, 7.0, 3.8, 3.8, 3.1,
            lambda i, j, k: (232, 58, 70) if rnd("ap", i, j, k) < 0.05 else pick(B["leaf"], "l", i, j, k))
    vx.blob(x - 1.2, y - 1.0, 9.4, 2.2, 2.2, 1.6, lambda i, j, k: pick(B["leaf"], "l2", i, j, k))
    x, y = TREE2
    vx.fill(x - 0.5, x + 0.5, y - 0.5, y + 0.5, 0, 4.0, lambda i, j, k: pick(B["wood"], "t2", i, j, k))
    vx.blob(x, y, 6.0, 3.0, 3.0, 2.4,
            lambda i, j, k: (255, 255, 255) if rnd("bw", i, j, k) < 0.06 else pick(B["blossom"], "bl", i, j, k))
    vx.blob(x + 0.6, y + 0.4, 7.9, 1.9, 1.9, 1.5, lambda i, j, k: pick(B["blossom"], "bl2", i, j, k))


def b_props(vx):
    x, y = BUSH
    vx.blob(x, y, 0.0, 3.0, 2.4, 2.6,
            lambda i, j, k: ((255, 214, 64) if rnd("bf", i, j, k) < 0.5 else (255, 140, 190))
            if rnd("bfl", i, j, k) < 0.08 else pick(B["leaf"], "bu", i, j, k))
    vx.blob(*ROCK, 0.0, 1.7, 1.3, 1.5,
            lambda i, j, k: B["leaf"][0] if k >= 2 and rnd("moss", i, j) < 0.35 else pick(B["stone"], "st", i, j, k))
    # flower bed: stone border, soil, pixel flowers (stem + a plus of petals with a yellow middle)
    x0, x1, y0, y1 = BED
    vx.fill(x0, x1, y0, y1, 0, 0.5, lambda i, j, k: pick(B["stone"], "fb", i, j))
    vx.fill(x0 + 0.5, x1 - 0.5, y0 + 0.5, y1 - 0.5, 0, 0.5, lambda i, j, k: pick(((96, 60, 40), (84, 52, 34),
                                                                                    (108, 70, 46)), "so", i, j))
    cols = [(255, 90, 120), (255, 214, 64), (190, 120, 255), (255, 255, 255), (255, 150, 60), (90, 170, 255)]
    spots = [(-15.5, -4.5), (-13.5, -4.0), (-11.5, -4.5), (-14.5, -2.5), (-12.5, -2.0), (-11.0, -3.0),
             (-16.0, -2.0)]
    for n, (fx, fy) in enumerate(spots):
        h = 1.0 + 0.5 * (n % 2)
        vx.fill(fx, fx + V, fy, fy + V, 0.5, 0.5 + h, (70, 160, 60))
        vx.fill(fx + V, fx + 2 * V, fy, fy + V, 0.5, 1.0, (100, 190, 70))
        zc = 0.5 + h
        c = cols[n % len(cols)]
        for dx, dy, dz in ((0, 0, 0), (1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1)):
            col = (255, 220, 60) if (dx, dy, dz) == (0, 0, 0) else c
            if (dx, dy, dz) == (0, 0, 0) and c == (255, 214, 64):
                col = (240, 120, 40)
            vx.fill(fx + dx * V, fx + (dx + 1) * V, fy + dy * V, fy + (dy + 1) * V, zc + dz * V, zc + (dz + 1) * V,
                    col)
    # lamp: dark voxel post, glowing lantern cube with a cap
    x, y = LAMP
    vx.fill(x - 1.0, x + 1.0, y - 1.0, y + 1.0, 0, 0.5, (70, 70, 90))
    vx.fill(x - 0.5, x + 0.5, y - 0.5, y + 0.5, 0.5, 4.5, (70, 70, 90))
    vx.fill(x - 1.0, x + 1.0, y - 1.0, y + 1.0, 4.5, 5.5, (255, 226, 110))
    vx.fill(x - 1.0, x + 1.0, y - 1.0, y + 1.0, 5.5, 6.0, (70, 70, 90))
    vx.fill(x - 0.5, x + 0.5, y - 0.5, y + 0.5, 6.0, 6.5, (70, 70, 90))


def b_deco(vx):
    for n, (x, y) in enumerate(DECO):
        x, y = math.floor(x * 2) / 2, math.floor(y * 2) / 2
        g1, g2 = B["leaf"][1], B["leaf"][0]
        if n % 3 == 2:  # tall grass tuft
            vx.fill(x, x + V, y, y + V, 0, 1.0, g1)
            vx.fill(x + V, x + 2 * V, y, y + V, 0, 0.5, g2)
            vx.fill(x - V, x, y + V, y + 2 * V, 0, 1.5, g2)
        else:  # pixel flower
            vx.fill(x, x + V, y, y + V, 0, 0.5, g2)
            vx.fill(x + V, x + 2 * V, y, y + V, 0, 0.5, g1)
            vx.fill(x, x + V, y, y + V, 0.5, 1.0, DECO_COL[n % 6])


def build_b():
    g = Geo("LookB")
    b_ground(g)
    vx = Vox()
    b_deco(vx)
    b_fence(vx)
    b_gate(vx)
    b_house(vx)
    b_trees(vx)
    b_props(vx)
    vx.emit(g)
    g.finish()
    place_cats(lambda x, y: 0.0)


# =============================================================================================================
# C  Cute toy blocks
# =============================================================================================================
SO = dict(rough=0.38, coat=0.25)  # soft toy plastic
C = dict(
    mint1=(150, 228, 190), mint2=(178, 240, 210), butter=(255, 226, 140), cream=(255, 246, 220),
    pink=(255, 170, 200), pink2=(255, 196, 216), lilac=(196, 172, 248), lilac2=(220, 204, 255),
    white=(255, 252, 246), choco=(150, 100, 82), green=(110, 206, 120), green2=(150, 226, 140),
    trunk=(214, 160, 118), plum=(120, 84, 160), rose=(255, 140, 180), sky=(150, 214, 255),
)
C_TOP = 0.45  # path / pen floor height


def c_stud(g, x, y, z, col):
    g.cyl((x, y, z - 0.06), 0.62, 0.46, col, n=28, bevel=0.16, seg=3, **SO)


def c_ground(g):
    for px in range(10):
        for py in range(10):
            x0, y0 = -HALF + px * 4, -HALF + py * 4
            col = C["mint1"] if (px + py) % 2 == 0 else C["mint2"]
            g.span(x0 + 0.06, x0 + 3.94, y0 + 0.06, y0 + 3.94, -1.0, 0, col, bevel=0.3, seg=3, **SO)
            for sx in (1, 3):
                for sy in (1, 3):
                    cx, cy = x0 + sx, y0 + sy
                    if all(zone(cx + a, cy + b) == "grass" for a in (-0.9, 0.9) for b in (-0.9, 0.9)):
                        c_stud(g, cx, cy, 0, col)
    # cake base: butter layer, pink layer
    g.span(-HALF + 0.15, HALF - 0.15, -HALF + 0.15, HALF - 0.15, -2.3, -0.9, C["butter"], bevel=0.5, seg=4, **SO)
    g.span(-HALF + 0.35, HALF - 0.35, -HALF + 0.35, HALF - 0.35, -3.6, -2.2, C["pink"], bevel=0.5, seg=4, **SO)
    # path: rounded pavers in running bond (main path along X, branch along Y)
    y0, y1 = PATH_Y
    for r, yy in enumerate((y0, y0 + 2, y0 + 4)):
        x = -HALF - (1.5 if r % 2 else 0)
        k = 0
        while x < HALF:
            lo, hi = max(x, -HALF), min(x + 3, HALF)
            if hi - lo > 0.8:
                col = C["butter"] if rnd("pv", r, k) < 0.5 else C["cream"]
                g.span(lo + 0.07, hi - 0.07, yy + 0.07, yy + 1.93, -0.1, C_TOP, col, bevel=0.22, seg=3, **SO)
            x += 3
            k += 1
    for r, yy in enumerate(range(int(PATH_Y[1]), int(PEN[2]), 2)):
        for xx in (6.0, 8.0):
            col = C["butter"] if (r + int(xx)) % 2 == 0 else C["cream"]
            g.span(xx + 0.07, xx + 1.93, yy + 0.07, min(yy + 2, PEN[2]) - 0.07, -0.1, C_TOP, col, bevel=0.22, seg=3,
                   **SO)
    # pen floor: lilac 2x2 rounded tiles
    x0, x1, y0, y1 = PEN
    for i in range(int(x0), int(x1), 2):
        for j in range(int(y0), int(y1), 2):
            col = C["lilac2"] if ((i + j) // 2) % 2 == 0 else (232, 220, 255)
            g.span(i + 0.06, i + 1.94, j + 0.06, j + 1.94, -0.1, C_TOP, col, bevel=0.22, seg=3, **SO)


def heart_pts(s, n=32):
    pts = []
    for i in range(n):
        t = 2 * PI * i / n
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((x * s / 16, (y + 4) * s / 16))
    return pts


def c_fence(g, m):
    k = 0
    for si, seg in enumerate(SEGS):
        a, b = Vector(seg[0] + (0,)), Vector(seg[1] + (0,))
        along_x = abs(b.x - a.x) > 0.5
        mid = (a + b) / 2
        L = (b - a).length
        for z in (0.95, 1.95):
            h = (L / 2, 0.24, 0.24) if along_x else (0.24, L / 2, 0.24)
            g.box((mid.x, mid.y, z), h, C["pink"], bevel=0.2, seg=3, **SO)
        face = R(0.0 if along_x else -PI / 2, "Z")
        for p in posts_on(seg):
            m.blob((0.45, 0.45, 1.35), C["white"], T(p.x, p.y, 1.35), e1=0.35, e2=1.0, nu=24, nv=14, name="Post",
                   **SO)
            fr = T(p.x, p.y, 2.62) @ face @ XZ
            if k % 2 == 0:
                slab(m, heart_pts(0.62), 0.32, C["rose"], fr, bevel=0.1, seg=2, name="Heart", **SO)
            else:
                m.blob((0.36, 0.36, 0.12), C["lilac"], T(p.x, p.y, 2.75), e1=0.5, e2=1.0, nu=20, nv=10, **SO)
                paw(m, fr @ T(0, 0.45, -0.14), 0.9, C["lilac"], thick=0.28, **SO)
            k += 1


def c_gate(g, m):
    for cx in GATE_X:
        m.blob((0.9, 0.9, 2.0), C["lilac"], T(cx, FRONT_Y, 2.0), e1=0.3, e2=1.0, nu=28, nv=14, name="Pillar", **SO)
        m.blob((0.75, 0.75, 0.5), C["pink"], T(cx, FRONT_Y, 4.1), e1=0.6, e2=1.0, nu=24, nv=12, **SO)
    pts = [(8 + 3.0 * math.cos(PI * k / 24), FRONT_Y, 4.3 + 3.0 * math.sin(PI * k / 24)) for k in range(25)]
    m.tube(pts, 0.5, C["pink"], n=18, caps=False, name="Arch", **SO)
    # round sign with cat ears and a paw
    sc = Vector((8.0, FRONT_Y - 0.2, 8.1))
    m.blob((1.35, 0.3, 1.2), C["butter"], T(*sc), e1=1.0, e2=0.8, nu=32, nv=14, name="Sign", **SO)
    for sx in (-1, 1):
        cat_ear(m, T(sc.x + sx * 0.8, sc.y + 0.05, sc.z + 0.75) @ R(sx * -0.35, "Y"), 0.85,
                C["butter"], **SO)
    paw(m, basis(sc + Vector((0, -0.28, -0.05)), (0, -1, 0)), 1.25, C["rose"], thick=0.1, **SO)


def c_house(g, m):
    x0, x1, y0, y1 = HOUSE
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    hx, hy, hz = (x1 - x0) / 2 - 0.4, (y1 - y0) / 2 - 0.4, 2.6
    body = m.blob((hx, hy, hz), C["butter"], T(cx, cy, C_TOP + hz), e1=0.22, e2=0.22, nu=48, nv=24, name="House",
                  **SO)
    top = C_TOP + 2 * hz
    roof = m.blob((hx + 0.6, hy + 0.6, 1.0), C["lilac"], T(cx, cy, top + 0.55), e1=0.45, e2=0.25, nu=48, nv=20,
                  name="Roof", **SO)
    for sx in (-1, 1):
        cat_ear(m, T(cx + sx * (hx - 0.9), cy - 0.3, top + 1.2) @ R(sx * -0.28, "Y"), 2.4, C["lilac"], **SO)
    # round-top door, face over it, round window on the left wall, studs on the roof top
    door = [(-1.0, 0.0), (1.0, 0.0)] + [(math.cos(PI * k / 12), 2.2 + math.sin(PI * k / 12)) for k in range(13)]
    slab(m, door, 0.3, C["plum"], T(cx, y0 + 0.42, C_TOP) @ XZ, bevel=0.1, seg=2, name="Door", **SO)
    m.blob((0.18, 0.08, 0.18), C["butter"], T(cx + 0.55, y0 + 0.2, C_TOP + 1.5), nu=12, nv=8, **SO)
    tree = m.bvh(body)
    m.face(tree, Vector((cx, cy, C_TOP + 3.95)), (0, -1, 0), 0.62, gap=5.4, cheeks=True, smile=False)
    m.blob((0.12, 0.85, 0.85), C["sky"], T(x0 + 0.38, cy - 0.3, C_TOP + 2.4), nu=24, nv=12, rough=0.1, coat=1.0)
    m.torus(0.85, 0.16, C["white"], T(x0 + 0.42, cy - 0.3, C_TOP + 2.4) @ R(PI / 2, "Y"), nu=32, nv=10, **SO)
    rt = m.bvh(roof)
    for dx in (-1.6, 0.0, 1.6):
        loc, _ = m.hit(rt, (cx + dx, cy - 0.6, top + 4), (0, 0, 1))
        if loc is not None:
            c_stud(g, loc.x, loc.y, loc.z, C["lilac"])


def c_trees(g, m):
    # pink blossom tree: rounded cube tiers with DUPLO studs
    x, y = TREE1
    m.blob((0.8, 0.8, 2.3), C["trunk"], T(x, y, 2.3), e1=0.35, e2=1.0, nu=24, nv=12, name="Trunk", **SO)
    t1 = m.blob((3.2, 3.2, 1.5), C["pink"], T(x, y, 5.6), e1=0.35, e2=0.35, nu=40, nv=18, name="Canopy", **SO)
    t2 = m.blob((2.1, 2.1, 1.2), C["pink2"], T(x, y, 8.1), e1=0.35, e2=0.35, nu=40, nv=18, name="Canopy", **SO)
    for tree, pts in ((m.bvh(t1), [(-2.4, -2.4), (0, -2.5), (-2.5, 0), (2.4, -2.4), (-2.4, 2.4)]),
                      (m.bvh(t2), [(-0.9, -0.9), (0.9, -0.9), (-0.9, 0.9), (0.9, 0.9)])):
        for dx, dy in pts:
            loc, _ = m.hit(tree, (x + dx, y + dy, 12), (0, 0, 1))
            if loc is not None:
                c_stud(g, loc.x, loc.y, loc.z, C["pink"] if max(abs(dx), abs(dy)) > 2 else C["pink2"])
    # mint-green round tree: rounded cylinder tiers, butter fruit
    x, y = TREE2
    m.blob((0.7, 0.7, 2.0), C["trunk"], T(x, y, 2.0), e1=0.35, e2=1.0, nu=24, nv=12, name="Trunk", **SO)
    t1 = m.blob((3.0, 3.0, 1.4), C["green"], T(x, y, 4.9), e1=0.4, e2=1.0, nu=40, nv=18, name="Canopy", **SO)
    t2 = m.blob((2.0, 2.0, 1.1), C["green2"], T(x, y, 7.2), e1=0.4, e2=1.0, nu=40, nv=18, name="Canopy", **SO)
    for tree, pts, col in ((m.bvh(t1), [(-2.5, 0), (0, -2.5), (-1.8, -1.8), (1.8, -1.8), (-1.8, 1.8)], C["green"]),
                           (m.bvh(t2), [(0, 0)], C["green2"])):
        for dx, dy in pts:
            loc, _ = m.hit(tree, (x + dx, y + dy, 12), (0, 0, 1))
            if loc is not None:
                c_stud(g, loc.x, loc.y, loc.z, col)
    for a in (3.3, 3.9, 4.5, 5.1):
        m.ball((x + 3.0 * math.cos(a), y + 3.0 * math.sin(a), 4.6), 0.42, C["rose"], **SO)


def c_flower(g, m, base, col, h, out):
    x, y, z = base
    head = Vector((x, y, z + h))
    m.tube([(x, y, z), (x, y, z + h * 0.5), (x, y, z + h)], 0.14, (100, 190, 100), n=10, caps=False, **SO)
    m.leaf((x, y, z + h * 0.35), (1, -0.3, 0.5), 0.8, 0.4, (110, 206, 120), up=(0, 0, 1), **SO)
    fr = basis(head, out)
    for p in range(6):
        a = 2 * PI * p / 6
        m.blob((0.42, 0.42, 0.14), col, fr @ T(0.62 * math.cos(a), 0.62 * math.sin(a), -0.06), nu=16, nv=8,
               name="Petal", **SO)
    c = m.blob((0.5, 0.5, 0.22), (255, 222, 90), fr, nu=20, nv=10, name="FlowerMid", **SO)
    m.face(m.bvh(c), head, out, 0.26, gap=1.7, cheeks=True, smile=True)


def c_props(g, m):
    out = Vector((-0.5, -1.0, 0.45)).normalized()
    # smiling bush
    x, y = BUSH
    b = m.blob((2.5, 2.0, 1.8), C["green"], T(x, y, 1.3), e1=0.8, e2=0.75, nu=40, nv=20, name="Bush", **SO)
    m.face(m.bvh(b), Vector((x, y, 1.6)), out, 0.58, gap=2.2)
    for dx, dy in ((-1.2, 0.6), (1.0, 0.2)):
        loc, _ = m.hit(m.bvh(b), (x + dx, y + dy, 6), (0, 0, 1))
        m.ball(loc + Vector((0, 0, 0.1)), 0.32, C["rose"], **SO)
    # rock with eyes
    x, y = ROCK
    r = m.blob((1.7, 1.35, 1.15), (186, 182, 214), T(x, y, 0.95), e1=0.7, e2=0.75, nu=32, nv=16, name="Rock", **SO)
    m.face(m.bvh(r), Vector((x, y, 1.0)), out, 0.4, gap=2.3, cheeks=True, smile=True)
    # planter with face flowers
    x0, x1, y0, y1 = BED
    bx, by = (x0 + x1) / 2, (y0 + y1) / 2
    m.blob(((x1 - x0) / 2, (y1 - y0) / 2, 0.65), C["pink"], T(bx, by, 0.6), e1=0.3, e2=0.25, nu=40, nv=16,
           name="Planter", **SO)
    m.blob(((x1 - x0) / 2 - 0.5, (y1 - y0) / 2 - 0.5, 0.2), C["choco"], T(bx, by, 1.2), e1=0.4, e2=0.25, nu=40,
           nv=12, name="Soil", rough=0.8)
    for (fx, fy), col, h in (((-15.3, -4.3), C["pink"], 1.6), ((-12.0, -4.6), C["lilac"], 1.3),
                             ((-13.6, -2.4), (255, 255, 255), 2.0), ((-11.6, -2.4), C["rose"], 1.9)):
        c_flower(g, m, (fx, fy, 1.3), col, h, out)
    # lamp: candy post, glowing ball with little ears
    x, y = LAMP
    m.blob((0.8, 0.8, 0.3), C["lilac"], T(x, y, 0.3), e1=0.5, e2=1.0, nu=28, nv=10, **SO)
    m.blob((0.28, 0.28, 2.2), C["white"], T(x, y, 2.6), e1=0.2, e2=1.0, nu=20, nv=12, **SO)
    for z in (1.4, 2.4, 3.4):
        m.torus(0.3, 0.1, C["pink"], T(x, y, z), nu=24, nv=8, **SO)
    m.blob((0.5, 0.5, 0.2), C["lilac"], T(x, y, 4.75), e1=0.5, e2=1.0, nu=24, nv=10, **SO)
    m.ball((x, y, 5.55), 0.8, (255, 226, 110), rough=0.2, emit=2.4)
    for sx in (-1, 1):
        cat_ear(m, T(x + sx * 0.45, y, 6.05) @ R(sx * -0.4, "Y"), 0.5, C["lilac"], **SO)


def c_deco(g, m):
    for n, (x, y) in enumerate(DECO):
        if n % 3 == 2:  # little mushroom
            m.blob((0.22, 0.22, 0.4), C["cream"], T(x, y, 0.35), e1=0.6, e2=1.0, nu=14, nv=8, **SO)
            m.blob((0.6, 0.6, 0.38), C["rose"], T(x, y, 0.8), e1=0.9, e2=1.0, nu=20, nv=10, **SO)
            for a in (0.5, 2.6, 4.4):
                m.ball((x + 0.42 * math.cos(a), y + 0.42 * math.sin(a), 0.98), 0.1, C["white"], nu=10, nv=6, **SO)
        else:  # tiny flower
            col = (C["pink"], C["butter"], C["white"], C["lilac"], (255, 180, 120), C["sky"])[n % 6]
            m.tube([(x, y, 0.2), (x, y, 0.9)], 0.07, (100, 190, 100), n=8, caps=False, **SO)
            fr = basis((x, y, 1.0), (-0.3, -0.6, 1.0))
            for p in range(5):
                a = 2 * PI * p / 5
                m.blob((0.2, 0.2, 0.08), col, fr @ T(0.24 * math.cos(a), 0.24 * math.sin(a), 0), nu=10, nv=6, **SO)
            m.blob((0.15, 0.15, 0.1), (255, 222, 90), fr @ T(0, 0, 0.04), nu=10, nv=6, **SO)


def build_c():
    g = Geo("LookC")
    m = Model("LookCRound")
    c_deco(g, m)
    c_ground(g)
    c_fence(g, m)
    c_gate(g, m)
    c_house(g, m)
    c_trees(g, m)
    c_props(g, m)
    g.finish()
    place_cats(lambda x, y: C_TOP)


def build(look):
    {"A": build_a, "B": build_b, "C": build_c}[look]()


# == scene, camera =============================================================================================
def setup(samples=64, w=1400, h=900):
    sc = kit.new_scene()
    g = bpy.data.objects.get("Ground")
    if g:
        bpy.data.objects.remove(g)
    sc.render.resolution_x, sc.render.resolution_y = w, h
    sc.cycles.samples = samples
    sc.render.film_transparent = True
    sun = bpy.data.objects["Sun"]
    sun.data.energy = 3.6
    sun.data.angle = math.radians(5)
    sun.rotation_euler = Vector((0.62, 0.5, -0.85)).to_track_quat("-Z", "Y").to_euler()
    sc.world.node_tree.nodes["Background"].inputs[1].default_value = 1.1
    return sc


def camera(direction=(-0.8, -1.0, 0.7), lens=40, margin=0.95):
    sc = bpy.context.scene
    W, H = sc.render.resolution_x, sc.render.resolution_y
    pts = []
    for o in sc.objects:
        if o.type == "MESH":
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (lo + hi) / 2
    d = Vector(direction).normalized()
    f = -d
    r = f.cross(Vector((0, 0, 1))).normalized()
    u = r.cross(f)
    k = lens / 36.0

    def fit(dist):
        eye = center + d * dist
        xs, ys = [], []
        for p in pts:
            v = p - eye
            z = v.dot(f)
            xs.append(v.dot(r) / z * k)
            ys.append(v.dot(u) / z * k)
        return min(xs), max(xs), min(ys), max(ys)

    a, b = 5.0, 1000.0
    for _ in range(60):
        mid = (a + b) / 2
        x0, x1, y0, y1 = fit(mid)
        if x1 - x0 <= margin and y1 - y0 <= margin * H / W:
            b = mid
        else:
            a = mid
    x0, x1, y0, y1 = fit(b)
    cam = bpy.data.cameras.new("Cam")
    cam.lens = lens
    cam.sensor_fit = "HORIZONTAL"
    cam.shift_x, cam.shift_y = (x0 + x1) / 2, (y0 + y1) / 2
    co = bpy.data.objects.new("Cam", cam)
    co.location = center + d * b
    co.rotation_euler = f.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(co)
    sc.camera = co
    return co
