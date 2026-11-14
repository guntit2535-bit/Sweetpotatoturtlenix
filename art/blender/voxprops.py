"""Voxel map props for the X4 map restyle (look B "pixel voxel", with look A's LEGO flowers).

prop(id) -> kit.Model for every id in IDS. 1 unit = 1 stud, origin = the prop's foot centre on the ground (z = 0),
front = -Y, up = +Z. Exported by items_export.py (family "MapProps"): one mesh per id, faces merged.

Voxels are 0.5 studs (0.75 for trees and pines, 0.4 for grass tufts) with 2-4 shades per material (pixel noise): the top
of a shape gets the light shades, its underside the dark ones. The mesher keeps only the faces next to an empty cell, drops
the bottom faces on the ground (z = 0, never seen) and merges same-colour neighbours on a plane into one quad,
so a prop stays well under 3,000 triangles. One Blender object per colour (the exporter's palette needs it).

Board / rail facts the game needs (Blender axes):
  PenGate  - posts at x = -6 / +6 (2 x 2 each), beam x -7.5..7.5, z 6.5..10.5, its front face flat at y = -1:
             the game's name board goes there (13 x 3.6 centred at x 0, z 8.5). Ears on top reach z 12.
  FenceRail - 1 stud long along Y (y -0.5..0.5), 0.4 thick (X), 0.6 tall (z 0..0.6), the same all along Y, so the
             game stretches it along its length.
  Lamp     - lantern block x/y -1..1, z 6.5..8 (centre z 7.25): the game adds the light there.
"""
import math
import os
import sys
import zlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import bmesh
from mathutils import Vector

import kit
from kit import Model

PI = math.pi
TAU = math.tau
MT = dict(rough=0.85)

# -- palette: shades dark -> light (2-4 each) ------------------------------------------------------------------
MATS = {
    "leaf": [(54, 146, 56), (70, 170, 64), (92, 192, 76), (122, 212, 92)],
    "blossom": [(236, 126, 176), (255, 160, 200), (255, 186, 216), (255, 210, 230)],
    "pine": [(30, 104, 62), (42, 126, 70), (58, 148, 80)],
    "snow": [(214, 228, 246), (236, 244, 255), (255, 255, 255)],
    "wood": [(138, 86, 46), (156, 100, 54), (176, 118, 68)],
    "dwood": [(102, 64, 40), (118, 76, 48), (134, 88, 56)],
    "plank": [(194, 132, 74), (214, 154, 92), (228, 172, 108)],
    "rock": [(112, 118, 134), (134, 140, 156), (156, 162, 178), (182, 188, 202)],
    "stone": [(128, 134, 148), (150, 156, 170), (172, 178, 192)],
    "moss": [(62, 150, 58), (84, 176, 68), (112, 200, 84)],
    "cream": [(242, 226, 198), (252, 238, 212), (255, 246, 230)],
    "roof": [(214, 70, 56), (236, 92, 70), (250, 118, 88)],
    "lamp": [(60, 60, 80), (72, 72, 94), (86, 86, 110)],
    "glow": [(255, 222, 100), (255, 236, 150)],
    "grass": [(70, 170, 64), (92, 192, 76), (122, 212, 92)],
}
APPLE = [(226, 52, 64), (244, 84, 84)]
BERRY = [(206, 34, 70), (236, 60, 96)]
BUSH_FLOWERS = [(255, 214, 64), (255, 140, 190), (255, 255, 255)]
BLOSSOM_WHITE = [(255, 255, 255)]
PINK = (255, 160, 190)
DARK = (54, 42, 64)
WINDOW = (150, 210, 255)
PAW = (255, 150, 60)
GLOW = set(MATS["glow"])
TREE_V = 0.75  # trees and pines: bigger voxels (a 0.5 grid needs ~4,000 triangles for a 13-stud canopy)

# LEGO flowers (look A)
STEM = (60, 150, 50)
LEAF = (160, 204, 30)
BASE = (98, 186, 66)
CENTRE = (250, 200, 30)
FLOWERS = {
    "Pink": (255, 140, 180), "Yellow": (250, 200, 30), "Lilac": (190, 140, 255), "Red": (214, 34, 30),
    "White": (244, 244, 242), "Orange": (255, 130, 30), "Blue": (40, 120, 214),
}

IDS = (["Tree_1", "Tree_2", "Tree_3", "Blossom_1", "Blossom_2", "Pine_1", "Pine_2", "PineSnow_1", "PineSnow_2",
        "Bush_1", "Bush_2", "Bush_Berry", "Bush_Snow", "Rock_1", "Rock_2", "Rock_Moss", "Rock_Snow"]
       + [f"Flower_{c}" for c in FLOWERS]
       + ["Tuft_1", "Tuft_2", "FencePost", "FenceRail", "PenGate", "CatHouse", "Lamp"])


def rnd(*k):
    """Deterministic 0..1 from a key (Python's hash() of strings changes per run)."""
    return (zlib.crc32(repr(k).encode()) & 0xFFFFFFFF) / 4294967296.0


def pick(options, weights, *k):
    t = rnd(*k)
    acc = 0.0
    for c, w in zip(options, weights):
        acc += w
        if t < acc:
            return c
    return options[-1]


# == voxel grid ===============================================================================================
class Vox:
    """Cells hold an rgb tuple or a material name (shaded later by exposure + noise)."""

    def __init__(self, seed, v=0.5, odd=False):
        self.seed = seed
        self.v = v
        self.off = v / 2 if odd else 0.0  # odd voxel counts centre on x / y = 0
        self.cells = {}
        self.dots = {}  # material -> (chance, colours): pixels sprinkled on its exposed cells
        self.clump = 1  # noise in clumps of n x n x n cells (fewer faces on big props)

    def idx(self, x, y, z):
        v = self.v
        return (math.floor((x - self.off) / v + 1e-6), math.floor((y - self.off) / v + 1e-6),
                math.floor(z / v + 1e-6))

    def centre(self, i, j, k):
        v = self.v
        return (i + 0.5) * v + self.off, (j + 0.5) * v + self.off, (k + 0.5) * v

    def fill(self, x0, x1, y0, y1, z0, z1, val):
        """val: rgb / material / "" (clear) or f(x, y, z, i, j, k) -> one of those or None (leave)."""
        i0, j0, k0 = self.idx(x0, y0, max(z0, 0.0))
        i1, j1, k1 = self.idx(x1 - 1e-4, y1 - 1e-4, z1 - 1e-4)
        for i in range(i0, i1 + 1):
            for j in range(j0, j1 + 1):
                for k in range(k0, k1 + 1):
                    c = val(*self.centre(i, j, k), i, j, k) if callable(val) else val
                    if c is None:
                        continue
                    if c == "":
                        self.cells.pop((i, j, k), None)
                    else:
                        self.cells[(i, j, k)] = c

    def blob(self, cx, cy, cz, rx, ry, rz, val, p=2.0, lumpy=0.0):
        """Superellipsoid (p = 2 round, higher = chunkier) cut at the ground; lumpy roughens the outline."""
        def f(x, y, z, i, j, k):
            d = abs((x - cx) / rx) ** p + abs((y - cy) / ry) ** p + abs((z - cz) / rz) ** p
            if d > 1.0 + lumpy * (rnd(self.seed, "lump", i // 2, j // 2, k // 2) - 0.5):
                return None
            return val(x, y, z, i, j, k) if callable(val) else val

        self.fill(cx - rx * 1.2, cx + rx * 1.2, cy - ry * 1.2, cy + ry * 1.2, cz - rz * 1.2, cz + rz * 1.2, f)

    def cone(self, cx, cy, z0, z1, r0, r1, val):
        """Round voxel cone layer: radius r0 at z0 down to r1 at z1. val(x, y, z, top) with top = on its top
        surface."""
        def r_at(z):
            return r0 + (r1 - r0) * min(max((z - z0) / (z1 - z0), 0.0), 1.0)

        def f(x, y, z, i, j, k):
            d = math.hypot(x - cx, y - cy)
            if d > r_at(z):
                return None
            top = z + self.v > z1 or d > r_at(z + self.v)
            return val(x, y, z, top, d)

        self.fill(cx - r0, cx + r0, cy - r0, cy + r0, z0, z1, f)

    def cap(self, mat, zmin, drip=0.3):
        """Cover every up-facing cell above zmin with `mat` (moss, snow), with drips one cell down the sides."""
        for (i, j, k) in list(self.cells):
            if (i, j, k + 1) in self.cells or self.centre(i, j, k)[2] < zmin:
                continue
            self.cells[(i, j, k)] = mat
            if (i, j, k - 1) in self.cells and rnd(self.seed, "drip", i, j, k) < drip:
                self.cells[(i, j, k - 1)] = mat

    # -- colours ---------------------------------------------------------------------------------------------
    def resolve(self):
        out = {}
        cells = self.cells
        for (i, j, k), c in cells.items():
            if not isinstance(c, str):
                out[(i, j, k)] = c
                continue
            sh = MATS[c]
            up = (i, j, k + 1) not in cells
            down = k > 0 and (i, j, k - 1) not in cells
            side = any((i + a, j + b, k) not in cells for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if c in self.dots and (up or side):
                chance, cols = self.dots[c]
                if rnd(self.seed, "dot", i, j, k) < chance:
                    out[(i, j, k)] = cols[int(rnd(self.seed, "dc", i, j, k) * len(cols)) % len(cols)]
                    continue
            cl = self.clump
            key = (self.seed, c, i // cl, j // cl, k // cl)
            n = len(sh)
            if up:
                opts, w = (sh[-1], sh[-2], sh[-3] if n > 2 else sh[0]), (0.55, 0.3, 0.15)
            elif down:
                opts, w = (sh[0], sh[1]), (0.7, 0.3)
            elif n >= 4:
                opts, w = (sh[1], sh[2], sh[0]), (0.55, 0.27, 0.18)
            elif n == 3:
                opts, w = (sh[1], sh[2], sh[0]), (0.56, 0.24, 0.2)
            else:
                opts, w = (sh[0], sh[1]), (0.6, 0.4)
            out[(i, j, k)] = pick(opts, w, *key)
        return out

    # -- mesh ------------------------------------------------------------------------------------------------
    def mesh(self, model, drop_floor=True, name="Vox"):
        cols = self.resolve()
        planes = {}
        for (i, j, k), c in cols.items():
            p = (i, j, k)
            for a in range(3):
                for s in (1, -1):
                    q = list(p)
                    q[a] += s
                    if tuple(q) in cols:
                        continue
                    if drop_floor and a == 2 and s < 0 and k == 0:
                        continue
                    u, w = (a + 1) % 3, (a + 2) % 3
                    planes.setdefault((a, s, p[a] + (1 if s > 0 else 0)), {})[(p[u], p[w])] = c
        bms = {}
        vmaps = {}
        v, off = self.v, (self.off, self.off, 0.0)
        for (a, s, layer), cells in planes.items():
            u, w = (a + 1) % 3, (a + 2) % 3
            done = set()
            for key in sorted(cells):
                if key in done:
                    continue
                c = cells[key]
                u0, w0 = key
                h = 1
                while (u0, w0 + h) in cells and cells[(u0, w0 + h)] == c and (u0, w0 + h) not in done:
                    h += 1
                wd = 1
                while all((u0 + wd, w0 + t) in cells and cells[(u0 + wd, w0 + t)] == c and
                          (u0 + wd, w0 + t) not in done for t in range(h)):
                    wd += 1
                for du in range(wd):
                    for dw in range(h):
                        done.add((u0 + du, w0 + dw))
                if c not in bms:
                    bms[c] = bmesh.new()
                    vmaps[c] = {}
                bm, vm = bms[c], vmaps[c]

                def vert(uu, ww):
                    co = [0, 0, 0]
                    co[a], co[u], co[w] = layer, uu, ww
                    kk = tuple(co)
                    if kk not in vm:
                        vm[kk] = bm.verts.new(tuple(co[t] * v + off[t] for t in range(3)))
                    return vm[kk]

                quad = [vert(u0, w0), vert(u0 + wd, w0), vert(u0 + wd, w0 + h), vert(u0, w0 + h)]
                if s < 0:
                    quad.reverse()
                bm.faces.new(quad)
        for c in sorted(bms):
            mo = dict(rough=0.4, emit=2.2) if c in GLOW else MT
            model.add(bms[c], c, name, smooth=False, **mo)


# == small helpers ============================================================================================
def tri_count(model):
    return sum(len(p.vertices) - 2 for o in model.objects for p in o.data.polygons)


def box_bm(bm, x0, x1, y0, y1, z0, z1):
    vs = [bm.verts.new((x, y, z)) for z in (z0, z1) for y in (y0, y1) for x in (x0, x1)]
    for f in ((0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)):
        bm.faces.new([vs[i] for i in f])


def cyl_bm(bm, cx, cy, z0, h, r, n=12, bevel=0.0):
    """Cylinder standing on z0; bevel rounds its top rim (LEGO plate / stud edge)."""
    from mathutils import Matrix
    M = Matrix.Translation((cx, cy, z0 + h / 2))
    verts = bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=n, radius1=r, radius2=r, depth=h,
                                  matrix=M)["verts"]
    if bevel > 0:
        top = [f for f in {f for vv in verts for f in vv.link_faces} if len(f.verts) == n and
               f.calc_center_median().z > z0 + h * 0.75]
        edges = list({e for f in top for e in f.edges})
        bmesh.ops.bevel(bm, geom=list({vv for e in edges for vv in e.verts}) + edges, offset=min(bevel, r * 0.5, h * 0.45),
                        segments=1, profile=0.5, affect="EDGES", clamp_overlap=True)


class Parts:
    """Smooth (non-voxel) parts grouped per colour: the LEGO flower pieces and the fence rail."""

    def __init__(self, model):
        self.model = model
        self.bms = {}

    def bm(self, col):
        if col not in self.bms:
            self.bms[col] = bmesh.new()
        return self.bms[col]

    def finish(self, smooth=True, **mo):
        for col, bm in self.bms.items():
            bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
            self.model.add(bm, col, "Part", smooth=smooth, **(mo or MT))


# == trees ====================================================================================================
def leafy(mat):
    return lambda x, y, z, i, j, k: mat


def trunk(vx, h, roots=True, n=4):
    """Square trunk n cells wide (4 x 0.75 = 3 studs), with a pixel of root flare on each side."""
    v = vx.v
    half = n * v / 2
    vx.fill(-half, half, -half, half, 0, h, "wood")
    if roots:
        for (x0, x1, y0, y1) in ((-half - v, -half, -v, v), (half, half + v, -v, 0.0),
                                 (-v, 0.0, -half - v, -half), (0.0, v, half, half + v)):
            vx.fill(x0, x1, y0, y1, 0, v, "wood")


def tree(key, mat="leaf"):
    vx = Vox(key, v=TREE_V)
    if mat == "leaf":
        vx.dots["leaf"] = (0.035, APPLE)
    else:
        vx.dots["blossom"] = (0.05, BLOSSOM_WHITE)
    L = leafy(mat)
    if key in ("Tree_1", "Blossom_1"):
        trunk(vx, 8.5)
        vx.fill(1.5, 3.0, -0.75, 0.0, 6.0, 6.75, "wood")  # a branch stub
        vx.blob(0, 0, 11.0, 6.25, 6.25, 4.5, L, lumpy=0.25)
        vx.blob(-0.8, 0.6, 15.0, 3.5, 3.5, 2.25, L, lumpy=0.2)
    elif key in ("Tree_2",):
        trunk(vx, 10.0)
        vx.blob(0, 0, 10.5, 6.0, 6.0, 4.0, L, lumpy=0.25)
        vx.blob(0.5, -0.3, 15.25, 4.5, 4.5, 3.5, L, lumpy=0.2)
    elif key in ("Tree_3", "Blossom_2"):
        trunk(vx, 7.5)
        vx.fill(-3.0, -1.5, 0.0, 0.75, 5.25, 6.0, "wood")
        vx.blob(0, 0, 10.0, 5.0, 5.0, 4.0, L, lumpy=0.25)
        vx.blob(-3.0, 1.75, 9.0, 3.25, 3.25, 2.75, L, lumpy=0.25)
        vx.blob(3.0, -1.75, 9.5, 3.25, 3.25, 2.75, L, lumpy=0.25)
        vx.blob(1.0, 2.5, 12.0, 3.25, 3.25, 2.75, L, lumpy=0.25)
        vx.blob(-0.5, -1.0, 13.5, 3.0, 3.0, 2.25, L, lumpy=0.2)
    return vx


def pine(key):
    snowy = key.startswith("PineSnow")
    vx = Vox(key, v=TREE_V)
    variant = key[-1]
    if variant == "1":
        trunk(vx, 4.0, roots=False)
        tiers = [(3.0, 7.5, 6.75, 1.5), (6.75, 10.5, 4.75, 1.0), (9.75, 13.5, 3.75, 0.75), (12.75, 15.75, 2.5, 0.5),
                 (15.0, 17.5, 1.25, 0.3)]
    else:
        trunk(vx, 3.5, roots=False)
        tiers = [(2.25, 6.0, 6.75, 2.25), (5.25, 9.0, 4.75, 1.5), (8.25, 12.0, 3.75, 1.0), (11.25, 14.25, 2.75, 0.75),
                 (13.5, 18.0, 1.5, 0.3)]
    v = vx.v
    for n, (z0, z1, r0, r1) in enumerate(tiers):
        def f(x, y, z, top, d, r0=r0, n=n, z0=z0):
            # snow on the steps (up-facing cells) of every layer, its edge jagged per direction; the rim stays green
            if snowy and top and z >= z0 + v:
                bucket = int((math.atan2(y, x) + PI) / TAU * 14) % 14
                if d <= r0 * (0.68 + 0.2 * rnd(key, "sn", n, bucket)):
                    return "snow"
            return "pine"

        vx.cone(0, 0, z0, z1, r0, r1, f)
    return vx


def bush(key):
    vx = Vox(key)
    vx.dots["leaf"] = (0.07, BERRY) if key == "Bush_Berry" else (0.045, BUSH_FLOWERS)
    if key == "Bush_Snow":
        vx.dots = {}
    if key in ("Bush_1", "Bush_Berry", "Bush_Snow"):
        vx.blob(0, 0, 1.75, 3.75, 3.25, 3.75, "leaf", lumpy=0.25)
        vx.blob(-2.0, -0.75, 2.0, 2.0, 2.0, 2.25, "leaf", lumpy=0.2)
        vx.blob(2.0, 0.75, 1.75, 2.0, 2.0, 2.0, "leaf", lumpy=0.2)
    else:
        vx.blob(-1.25, 0.25, 1.25, 2.75, 3.0, 4.0, "leaf", lumpy=0.25)
        vx.blob(1.75, -0.25, 1.0, 2.25, 2.5, 3.25, "leaf", lumpy=0.25)
        vx.blob(0.25, -0.5, 0.5, 3.75, 2.75, 3.0, "leaf", lumpy=0.2)
    if key == "Bush_Snow":
        vx.cap("snow", 3.0, drip=0.35)
    return vx


def rock(key):
    vx = Vox(key, odd=True)
    if key in ("Rock_1", "Rock_Moss", "Rock_Snow"):
        vx.blob(0, 0, 1.75, 4.25, 3.5, 4.25, "rock", p=2.6, lumpy=0.3)
        vx.blob(2.5, -1.75, 0.5, 1.75, 1.75, 2.0, "rock", p=2.4, lumpy=0.3)
    else:
        vx.blob(-1.0, 0.25, 1.5, 3.25, 3.25, 4.5, "rock", p=2.5, lumpy=0.3)
        vx.blob(2.25, -0.5, 0.75, 2.0, 2.75, 3.0, "rock", p=2.5, lumpy=0.3)
    if key == "Rock_Moss":
        vx.cap("moss", 3.0, drip=0.4)
    elif key == "Rock_Snow":
        vx.cap("snow", 3.0, drip=0.35)
    return vx


# == LEGO flower (look A) =====================================================================================
def flower(model, col):
    ps = Parts(model)
    cyl_bm(ps.bm(BASE), 0, 0, 0.0, 0.16, 0.42, n=16, bevel=0.05)  # round 1x1 plate the flower stands on
    cyl_bm(ps.bm(STEM), 0, 0, 0.12, 0.92, 0.13, n=10)  # stem
    cyl_bm(ps.bm(LEAF), 0.3, -0.06, 0.42, 0.14, 0.27, n=14, bevel=0.04)  # leaf plate on the stem
    for p in range(5):  # 5-petal flower plate
        a = TAU * p / 5 + 0.3
        cyl_bm(ps.bm(col), 0.29 * math.cos(a), 0.29 * math.sin(a), 1.0, 0.2, 0.26, n=14, bevel=0.06)
    centre = (255, 130, 30) if col == FLOWERS["Yellow"] else CENTRE
    cyl_bm(ps.bm(centre), 0, 0, 1.04, 0.28, 0.16, n=12, bevel=0.04)  # round centre stud
    ps.finish(smooth=True, rough=0.3)


# == pen pieces ===============================================================================================
def tuft(key):
    vx = Vox(key, v=0.4)
    g = MATS["grass"]
    blades = [(0, 0, 3, g[1]), (1, 0, 2, g[0]), (-1, 1, 2, g[0]), (-2, 0, 1, g[2]), (0, -1, 1, g[2])] \
        if key == "Tuft_1" else [(-1, 0, 3, g[1]), (1, 0, 3, g[0]), (0, 1, 2, g[2]), (0, -1, 1, g[0]),
                                 (-2, -1, 2, g[0]), (1, 1, 1, g[2])]
    for i, j, h, c in blades:
        for k in range(h):
            vx.cells[(i, j, k)] = c if k < h - 1 else MATS["grass"][2] if c != g[2] else g[1]
    return vx


def fence_post():
    vx = Vox("FencePost")
    vx.fill(-0.5, 0.5, -0.5, 0.5, 0, 4.0, "wood")
    vx.fill(-0.5, 0.5, -0.5, 0.5, 3.0, 3.5, "dwood")  # a dark band under the cap
    vx.fill(-0.5, 0.5, -0.5, 0.5, 4.0, 4.5, "cream")
    return vx


def fence_rail(model):
    """Plain plank, 1 long along Y, the same all along (the game stretches it)."""
    ps = Parts(model)
    box_bm(ps.bm(MATS["plank"][1]), -0.2, 0.2, -0.5, 0.5, 0.0, 0.4)
    box_bm(ps.bm(MATS["plank"][2]), -0.2, 0.2, -0.5, 0.5, 0.4, 0.6)
    ps.finish(smooth=False)


EAR_L = ["####", ".##.", ".#.."]  # bottom row first
EAR_R = ["####", ".##.", "..#."]
EAR_PINK = {(0, 1), (0, 2), (1, 1)}  # (row, col) of the inner ear (front layer)


def ears(vx, xs, zb, y0, y1, mat):
    """Two pixel cat ears standing on zb; the front layer of the inner ear is pink."""
    v = vx.v
    for ex, rows in zip(xs, (EAR_L, EAR_R)):
        for r, row in enumerate(rows):
            for c, ch in enumerate(row):
                if ch != "#":
                    continue
                x = ex + c * v
                vx.fill(x, x + v, y0, y1, zb + r * v, zb + (r + 1) * v, mat)
                inner = (r, c) in EAR_PINK if rows is EAR_L else (r, 3 - c) in EAR_PINK
                if inner:
                    vx.fill(x, x + v, y0, y0 + v, zb + r * v, zb + (r + 1) * v, PINK)


def pen_gate():
    vx = Vox("PenGate")
    for cx in (-6.0, 6.0):
        vx.fill(cx - 1.5, cx + 1.5, -1.5, 1.5, 0, 1.0, "stone")  # plinth
        vx.fill(cx - 1.0, cx + 1.0, -1.0, 1.0, 1.0, 6.5, "wood")  # post
    # brackets in the inner corners under the beam (a pixel arch)
    for sx in (-1, 1):
        vx.fill(min(sx * 4.0, sx * 5.0), max(sx * 4.0, sx * 5.0), -1.0, 1.0, 6.0, 6.5, "dwood")
        vx.fill(min(sx * 4.5, sx * 5.0), max(sx * 4.5, sx * 5.0), -1.0, 1.0, 5.5, 6.0, "dwood")
        vx.fill(min(sx * 3.5, sx * 4.0), max(sx * 3.5, sx * 4.0), -1.0, 1.0, 6.0, 6.5, "dwood")
    # beam: dark frame, a flat plank front (one colour, where the game's name board goes)
    vx.fill(-7.5, 7.5, -1.0, 1.0, 6.5, 10.5, "dwood")
    vx.fill(-7.0, 7.0, -1.0, -0.5, 7.0, 10.0, MATS["plank"][1])
    vx.fill(-7.5, 7.5, -1.0, 1.0, 10.0, 10.5, "wood")  # top course
    ears(vx, (-7.0, 5.0), 10.5, -0.5, 0.5, "roof")
    return vx


PAW_PX = ["#.#.#", ".###.", ".###."]  # top row first: three toes and the pad


def cat_house():
    vx = Vox("CatHouse")
    x0, x1, y0, y1 = -6.0, 6.0, -4.0, 4.0
    wall_top = 6.5
    vx.fill(x0, x1, y0, y1, 0, 0.5, "stone")
    vx.fill(x0, x1, y0, y1, 0.5, wall_top, "cream")
    for cx in (x0, x1 - 0.5):  # wooden corner posts
        for cy in (y0, y1 - 0.5):
            vx.fill(cx, cx + 0.5, cy, cy + 0.5, 0.5, wall_top, "wood")
    # doorway: front layer cut away (round top), the dark inside behind it, a wooden frame and lintel
    vx.fill(-2.5, 2.5, y0, y0 + 0.5, 0.5, 4.0, "wood")
    vx.fill(-2.0, 2.0, y0, y0 + 0.5, 0.5, 3.5, "")
    vx.fill(-1.5, 1.5, y0, y0 + 0.5, 3.5, 4.0, "")
    vx.fill(-2.0, 2.0, y0 + 0.5, y0 + 1.0, 0.5, 4.0, DARK)
    # paw above the door (one voxel out of the wall)
    for r, row in enumerate(PAW_PX):
        for c, ch in enumerate(row):
            if ch == "#":
                x = -1.25 + c * 0.5
                z = 4.5 + (len(PAW_PX) - 1 - r) * 0.5
                vx.fill(x, x + 0.5, y0 - 0.5, y0, z, z + 0.5, PAW)
    # side windows with a sill
    for wx, sx in ((x0, -1), (x1 - 0.5, 1)):
        vx.fill(wx, wx + 0.5, -1.0, 1.0, 2.5, 4.5, WINDOW)
        sill = wx - 0.5 if sx < 0 else wx + 0.5
        vx.fill(sill, sill + 0.5, -1.5, 1.5, 2.0, 2.5, "wood")
    # stepped pixel roof, ridge along X, overhanging 0.5; the gables are wall
    layers = int(((y1 - y0) + 1.0) / 0.5) // 2
    for L in range(layers):
        z = wall_top + L * 0.5
        ya, yb = y0 - 0.5 + L * 0.5, y1 + 0.5 - L * 0.5

        def roof(x, y, zz, i, j, k, ya=ya, yb=yb):
            if min(y - ya, yb - y) < 1.0:
                return MATS["roof"][0] if (j + k) % 4 == 0 else "roof"
            return "cream" if x0 <= x < x1 else None

        vx.fill(x0 - 0.5, x1 + 0.5, ya, yb, z, z + 0.5, roof)
    ztop = wall_top + layers * 0.5
    ears(vx, (-5.0, 3.0), ztop, -0.5, 0.5, "roof")
    return vx


def lamp():
    vx = Vox("Lamp")
    vx.fill(-1.0, 1.0, -1.0, 1.0, 0, 0.5, "lamp")
    vx.fill(-0.5, 0.5, -0.5, 0.5, 0.5, 6.0, "lamp")
    vx.fill(-1.0, 1.0, -1.0, 1.0, 6.0, 6.5, "lamp")
    vx.fill(-1.0, 1.0, -1.0, 1.0, 6.5, 8.0,
            lambda x, y, z, i, j, k: "lamp" if abs(x) > 0.5 and abs(y) > 0.5 else "glow")
    vx.fill(-1.0, 1.0, -1.0, 1.0, 8.0, 8.5, "lamp")
    vx.fill(-0.5, 0.5, -0.5, 0.5, 8.5, 9.0, "lamp")
    return vx


# == entry ====================================================================================================
# batch 2 (X4 S4): buildings, bridges and small props, built in voxprops2.py with these helpers
IDS2 = ["House_1", "House_2", "House_3", "Shop_1", "Shop_2", "Shop_3", "Stall_1", "Stall_2", "Cabin", "Pavilion",
        "Torii", "Doghouse", "Fountain", "Bridge_Wood", "Bridge_Stone", "Bridge_Red",
        "StoneLantern", "Snowman", "Mountain", "Crystals_Pink", "Crystals_Blue", "Crystals_Purple", "Bamboo", "Barrel",
        "FruitCrate", "Mushroom", "Log", "Fern", "LeafPile", "Sapling", "Sack", "FlowerPot", "Pebbles", "SnowMound",
        "IcePatch", "CrystalBits", "Cobbles", "Clothesline"]
ALL_IDS = IDS + IDS2  # the export order: batch 1 first (its meshes stay the same)
BIG = {"House_1", "House_2", "House_3", "Shop_1", "Shop_2", "Shop_3", "Cabin", "Pavilion", "Fountain", "Mountain",
       "Bridge_Wood", "Bridge_Stone", "Bridge_Red"}


def budget(pid):
    """Triangle cap for the export (the voxel meshes stay under it on their own)."""
    return 6000 if pid in BIG else 3000


def prop(pid):
    m = Model(pid)
    if pid in IDS2:
        import voxprops2
        vx, extra = voxprops2.build(pid)
        vx.mesh(m)
        if extra:
            extra(m)
        return m
    if pid.startswith("Flower_"):
        flower(m, FLOWERS[pid.split("_", 1)[1]])
        return m
    if pid == "FenceRail":
        fence_rail(m)
        return m
    if pid.startswith("Tree_"):
        vx = tree(pid)
    elif pid.startswith("Blossom_"):
        vx = tree(pid, "blossom")
    elif pid.startswith("Pine"):
        vx = pine(pid)
    elif pid.startswith("Bush_"):
        vx = bush(pid)
    elif pid.startswith("Rock_"):
        vx = rock(pid)
    elif pid.startswith("Tuft_"):
        vx = tuft(pid)
    elif pid == "FencePost":
        vx = fence_post()
    elif pid == "PenGate":
        vx = pen_gate()
    elif pid == "CatHouse":
        vx = cat_house()
    elif pid == "Lamp":
        vx = lamp()
    else:
        raise ValueError(pid)
    vx.mesh(m)
    return m


def bounds(model):
    pts = [o.matrix_world @ v.co for o in model.objects for v in o.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


if __name__ == "__main__":  # blender -b --factory-startup -P art/blender/voxprops.py : sizes + triangles
    import bpy

    bpy.ops.wm.read_factory_settings(use_empty=True)
    cols = set()
    for pid in (sys.argv[sys.argv.index("--") + 1].split(",") if "--" in sys.argv else ALL_IDS):
        m = prop(pid)
        lo, hi = bounds(m)
        cols |= {tuple(o["rgb"]) for o in m.objects}
        sz = hi - lo
        print(f"{pid:12s} tris {tri_count(m):5d}  size {sz.x:5.2f} x {sz.y:5.2f} x {sz.z:5.2f}  "
              f"x {lo.x:6.2f}..{hi.x:6.2f} y {lo.y:6.2f}..{hi.y:6.2f} z {lo.z:5.2f}..{hi.z:5.2f}")
    print("colours", len(cols))
