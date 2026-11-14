"""Voxel map props, batch 2 (X4 S4): the zone buildings, bridges and small props in the batch-1 look.

Uses voxprops.py's voxel grid, mesher and palette (same rules: 0.5-stud voxels, 0.75 for the mountain, 0.25 for the
tiny ground details; 2-4 shades per material, matte). build(pid) -> (Vox, extra) where extra(model) adds smooth parts
(the clothesline's line) or is None. Origin = the Kit function's cf (foot centre on the ground), front = -Y (the Kit
function's -Z), up = +Z. Blender x = -(Kit x): a Kit offset at x = +4.5 is drawn here at x = -4.5.

Facts the game needs (Blender axes; Roblox model axes = (x, z, -y) before the importer's 180-degree turn):
  House_*    walls x -9..9, y -7..7, z 0..10; ridge along X at z 17 (whole length x -10.5..10.5). Kit roof spot
             (-w/4, h + 7.6) = Blender (4.5, 0, 17.6): on the ridge.
  Shop_*     walls x -8..8, y -6..6, z 0..12; flat roof top z 13 (parapets front/back to 14). Spot (-2, 0, 13.6).
  Cabin      walls x -8..8, y -6..6, z 0..9; snowy ridge along X, top z 15.5. Spot (4, 0, 16.7).
  Pavilion   floor z 2, ridge beam top z 18 along X (x -10..10). Spot (-4, 0, 17.9).
  Bridge_*   deck top z 3.5 for |y| <= 3.5 (underside z 3.0 wood / red, 2.5 stone), 6 steps of 0.5 down to z 0.5 at
             |y| 8.5..9.5, end posts at |y| 9..10. The space under the deck is open (the cat spot at z 0.8).
  StoneLantern  glow window block centred at (0, 0, 4.5). Fountain basin water ~ z 1.6..1.9, bowl insides at z 7.0 and
             10.0 (the game's water discs sit there).
"""
import math

from voxprops import (APPLE, DARK, FLOWERS, MATS, PINK, WINDOW, Parts, Vox, box_bm, rnd)

PI = math.pi
TAU = math.tau

MATS.update({
    "white": [(222, 228, 238), (236, 240, 247), (250, 251, 255)],
    "roofb": [(44, 108, 204), (62, 132, 232), (94, 160, 248)],
    "roofp": [(116, 78, 212), (140, 104, 240), (168, 136, 255)],
    "teal": [(28, 156, 152), (44, 186, 180), (82, 212, 204)],
    "pinkr": [(230, 100, 166), (248, 132, 192), (255, 168, 212)],
    "orange": [(230, 118, 38), (250, 146, 58), (255, 176, 94)],
    "gold": [(220, 158, 28), (244, 190, 46), (255, 216, 92)],
    "navy": [(36, 42, 80), (48, 56, 102), (66, 76, 128)],
    "black": [(38, 36, 50), (54, 52, 68)],
    "lacq": [(194, 38, 42), (222, 56, 54), (242, 86, 74)],
    "brick": [(174, 72, 56), (202, 90, 68), (222, 116, 90)],
    "lstone": [(196, 200, 212), (212, 216, 226), (228, 231, 239)],
    "mosaic": [(62, 130, 188), (86, 158, 212), (116, 186, 232)],
    "bamboo": [(80, 172, 64), (104, 200, 80), (136, 222, 100)],
    "node": [(52, 128, 50), (66, 146, 58)],
    "cpink": [(226, 84, 164), (255, 124, 196), (255, 168, 220), (255, 214, 240)],
    "cblue": [(48, 164, 230), (90, 204, 255), (150, 228, 255), (208, 246, 255)],
    "cpurp": [(114, 70, 222), (148, 106, 255), (184, 150, 255), (222, 204, 255)],
    "ice": [(150, 212, 246), (178, 230, 255), (208, 242, 255)],
    "burlap": [(200, 166, 108), (220, 188, 130), (236, 206, 152)],
    "mush": [(204, 38, 46), (230, 60, 60), (246, 96, 86)],
})
GLASS_HI = (222, 244, 255)  # the glint in a window
FRUIT = {
    "apple": APPLE,
    "orange": [(240, 132, 36), (255, 164, 64)],
    "lemon": [(248, 202, 40), (255, 228, 92)],
    "grape": [(128, 72, 202), (162, 106, 236)],
}
FRUIT_LEAF = MATS["leaf"][2]
AUTUMN = [(250, 146, 54), (255, 188, 60), (204, 66, 52), (236, 120, 40), (255, 212, 80)]

IDS = ["House_1", "House_2", "House_3", "Shop_1", "Shop_2", "Shop_3", "Stall_1", "Stall_2", "Cabin", "Pavilion",
       "Torii", "Doghouse", "Fountain", "Bridge_Wood", "Bridge_Stone", "Bridge_Red",
       "StoneLantern", "Snowman", "Mountain", "Crystals_Pink", "Crystals_Blue", "Crystals_Purple", "Bamboo", "Barrel",
       "FruitCrate", "Mushroom", "Log", "Fern", "LeafPile", "Sapling", "Sack", "FlowerPot", "Pebbles", "SnowMound",
       "IcePatch", "CrystalBits", "Cobbles", "Clothesline"]
BIG = {"House_1", "House_2", "House_3", "Shop_1", "Shop_2", "Shop_3", "Cabin", "Pavilion", "Fountain", "Mountain",
       "Bridge_Wood", "Bridge_Stone", "Bridge_Red"}


# == helpers ==================================================================================================
def circle(cx, cy, r, val, r_in=-1.0):
    """fill() value: val inside the ring r_in < d <= r around (cx, cy)."""
    def f(x, y, z, i, j, k):
        d = math.hypot(x - cx, y - cy)
        if not r_in < d <= r:
            return None
        return val(x, y, z, i, j, k) if callable(val) else val
    return f


def cell(vx, x, y, z, val):
    """Set the one cell holding the point (x, y, z)."""
    if z >= 0:
        vx.cells[vx.idx(x, y, z)] = val


def disc(vx, cx, cy, r, z0, z1, val, r_in=-1.0):
    vx.fill(cx - r - 0.5, cx + r + 0.5, cy - r - 0.5, cy + r + 0.5, z0, z1, circle(cx, cy, r, val, r_in))


def face(vx, side, plane, u0, u1, z0, z1, d0, d1, val):
    """Fill on a wall face: u runs along the wall, d goes inward from the face plane (negative = out of it)."""
    if side == "-y":
        vx.fill(u0, u1, plane + d0, plane + d1, z0, z1, val)
    elif side == "+y":
        vx.fill(u0, u1, plane - d1, plane - d0, z0, z1, val)
    elif side == "-x":
        vx.fill(plane + d0, plane + d1, u0, u1, z0, z1, val)
    else:
        vx.fill(plane - d1, plane - d0, u0, u1, z0, z1, val)


def window(vx, side, plane, u0, u1, z0, z1, frame="wood", glass=WINDOW, bars=True, sill=None, shutters=None):
    """A window set into a wall: frame ring flush with the wall, glass one cell in, a cross of bars, a glint."""
    face(vx, side, plane, u0 - 0.5, u1 + 0.5, z0 - 0.5, z1 + 0.5, 0, 0.5, frame)
    face(vx, side, plane, u0, u1, z0, z1, 0, 0.5, "")
    face(vx, side, plane, u0, u1, z0, z1, 0.5, 1.0, glass)
    um, zm = (u0 + u1) / 2, (z0 + z1) / 2
    if bars:
        face(vx, side, plane, um - 0.25, um + 0.25, z0, z1, 0.5, 1.0, frame)
        face(vx, side, plane, u0, u1, zm - 0.25, zm + 0.25, 0.5, 1.0, frame)
    if glass != "glow":
        face(vx, side, plane, u0, u0 + 0.5, z1 - 0.5, z1, 0.5, 1.0, GLASS_HI)
    if sill:
        face(vx, side, plane, u0 - 0.5, u1 + 0.5, z0 - 1.0, z0 - 0.5, -0.5, 0.5, sill)
    if shutters:
        face(vx, side, plane, u0 - 1.0, u0 - 0.5, z0 - 0.5, z1 + 0.5, -0.5, 0.5, shutters)
        face(vx, side, plane, u1 + 0.5, u1 + 1.0, z0 - 0.5, z1 + 0.5, -0.5, 0.5, shutters)


def door(vx, side, plane, u0, u1, z0, z1, frame="wood", leaf="dwood", knob="gold"):
    """A planked door one cell in, a frame round its top and sides, a gold knob."""
    face(vx, side, plane, u0 - 0.5, u1 + 0.5, z0, z1 + 0.5, 0, 0.5, frame)
    face(vx, side, plane, u0, u1, z0, z1, 0, 0.5, "")
    sh = MATS[leaf]
    face(vx, side, plane, u0, u1, z0, z1, 0.5, 1.0,
         lambda x, y, z, i, j, k: sh[2] if ((i if side in ("-y", "+y") else j) % 2) else sh[1])
    ku = u1 - 1.0 if side in ("-y", "+x") else u0 + 0.5
    face(vx, side, plane, ku, ku + 0.5, (z0 + z1) / 2 - 0.5, (z0 + z1) / 2, 0, 0.5, MATS[knob][2])


def gable(vx, x0, x1, y0, y1, zb, h, ov, roof, wall=None, axis="x", ovr=None, thick=1.0):
    """Stepped pixel gable roof over the walls x0..x1 / y0..y1 from zb, h tall; ridge along `axis`, eaves `ov`
    past the walls, `ovr` past the gable ends. roof(x, y, z, i, j, k, layer) colours the shell; the gable
    triangles over the walls are `wall`. Returns the ridge top."""
    v = vx.v
    ovr = ov if ovr is None else ovr
    n = max(1, int(round(h / v)))
    a0, a1, b0, b1 = (y0, y1, x0, x1) if axis == "x" else (x0, x1, y0, y1)
    A0, A1 = a0 - ov, a1 + ov
    hd = (A1 - A0) / 2

    def snap(t):
        return math.floor(t / v + 1e-6) * v

    for L in range(n):
        ins = snap(L * hd / n)
        nxt = snap((L + 1) * hd / n) if L + 1 < n else hd
        t = max(thick, nxt - ins + v)
        lo, hi = A0 + ins, A1 - ins

        def f(x, y, z, i, j, k, lo=lo, hi=hi, t=t, L=L):
            a, b = (y, x) if axis == "x" else (x, y)
            if min(a - lo, hi - a) < t:
                return roof(x, y, z, i, j, k, L)
            if wall is not None and b0 <= b < b1:
                return wall
            return None

        z = zb + L * v
        if axis == "x":
            vx.fill(b0 - ovr, b1 + ovr, lo, hi, z, z + v, f)
        else:
            vx.fill(lo, hi, b0 - ovr, b1 + ovr, z, z + v, f)
    return zb + n * v


def tiles(mat, seed, dark=0.1):
    """Roof tiles: rows of two shades (merge along the row), a few darker tiles."""
    sh = MATS[mat]

    def f(x, y, z, i, j, k, L):
        if rnd(seed, "tile", i, j, k) < dark:
            return sh[0]
        return sh[1] if L % 2 else sh[2]
    return f


def pixels(vx, rows, x0, z_top, y0, y1, colmap):
    """Pixel art standing in the x-z plane: rows top first, one cell per char (colmap: char -> colour / mat)."""
    v = vx.v
    for r, row in enumerate(rows):
        for c, ch in enumerate(row):
            val = colmap.get(ch)
            if val is None:
                continue
            x, z = x0 + c * v, z_top - (r + 1) * v
            vx.fill(x, x + v, y0, y1, z, z + v, val)


def recolour_front(vx, x, z, col):
    """Paint the front-most cell (smallest y) of the column at (x, z)."""
    i, _, k = vx.idx(x, 0, z)
    js = [j for (a, j, c) in vx.cells if a == i and c == k]
    if js:
        vx.cells[(i, min(js), k)] = col


# == buildings ================================================================================================
HOUSE = {"House_1": ("roof", ("Pink", "Yellow", "White")), "House_2": ("roofb", ("Yellow", "White", "Red")),
         "House_3": ("roofp", ("Orange", "Pink", "Lilac"))}


def flower_box(vx, x0, x1, y_wall, z0, cols):
    """A window box sticking out of a -y wall, flowers along its top."""
    vx.fill(x0, x1, y_wall - 1.0, y_wall, z0, z0 + 1.0, "dwood")
    n = int(round((x1 - x0) / 0.5))
    for c in range(n):
        x = x0 + c * 0.5
        col = FLOWERS[cols[(c // 2) % len(cols)]] if c % 2 == 0 else MATS["leaf"][2]
        vx.fill(x, x + 0.5, y_wall - 1.0, y_wall - 0.5, z0 + 1.0, z0 + 1.5, col)


def house(key):
    roofm, flw = HOUSE[key]
    vx = Vox(key)
    vx.clump = 2
    x0, x1, y0, y1, h = -9.0, 9.0, -7.0, 7.0, 10.0
    vx.fill(x0 - 0.5, x1 + 0.5, y0 - 0.5, y1 + 0.5, 0, 0.5, "stone")
    vx.fill(x0, x1, y0, y1, 0.5, h, "cream")
    for cx in (x0, x1 - 0.5):  # wooden corner posts and a beam under the eaves
        for cy in (y0, y1 - 0.5):
            vx.fill(cx, cx + 0.5, cy, cy + 0.5, 0.5, h, "wood")
    vx.fill(x0, x1, y0, y1, h - 0.5, h, lambda x, y, z, i, j, k: "wood" if (x in (x0 + 0.25, x1 - 0.25) or
                                                                             abs(abs(y) - 6.75) < 0.01) else None)
    # front: door (Kit x -2), a canopy over it in the roof colour, a lamp beside it
    door(vx, "-y", y0, 0.0, 4.0, 0.5, 7.0)
    vx.fill(-0.5, 4.5, y0 - 1.0, y0, 7.5, 8.0, roofm)
    vx.fill(5.0, 6.0, y0 - 1.0, y0, 5.5, 6.0, "lamp")
    vx.fill(5.0, 6.0, y0 - 1.0, y0, 6.0, 7.0, "glow")
    vx.fill(5.0, 6.0, y0 - 1.0, y0, 7.0, 7.5, "lamp")
    # front window (Kit x 4.5) with shutters and a flower box; side windows; a back window
    window(vx, "-y", y0, -6.5, -2.5, 4.0, 7.5, shutters=roofm)
    flower_box(vx, -7.0, -2.0, y0, 2.5, flw)
    window(vx, "+x", x1, -1.5, 1.5, 4.5, 7.5, sill="wood")
    window(vx, "-x", x0, -1.5, 1.5, 4.5, 7.5, sill="wood")
    window(vx, "+y", y1, -2.0, 2.0, 4.5, 7.5, sill="wood")
    top = gable(vx, x0, x1, y0, y1, h, 7.0, 1.5, tiles(roofm, key), wall="cream", axis="x", ovr=1.5)
    # chimney (Kit x 4.5, z 2.5 = back) with a stone cap
    vx.fill(-6.0, -3.5, 1.5, 4.0, h, 17.5, "brick")
    vx.fill(-6.5, -3.0, 1.0, 4.5, 17.5, 18.0, "stone")
    vx.fill(-5.5, -4.0, 2.0, 3.5, 17.5, 18.0, DARK)
    return vx, top


SHOP = {"Shop_1": "roof", "Shop_2": "teal", "Shop_3": "pinkr"}


def stripes(mat, x0, width, white="white"):
    """Awning colour by x: stripes `width` wide starting at x0, mat / white."""
    def f(x, y, z, i, j, k):
        return mat if int(math.floor((x - x0) / width)) % 2 == 0 else white
    return f


def shop(key):
    c = SHOP[key]
    vx = Vox(key)
    vx.clump = 2
    x0, x1, y0, y1, h = -8.0, 8.0, -6.0, 6.0, 12.0
    vx.fill(x0 - 0.5, x1 + 0.5, y0 - 0.5, y1 + 0.5, 0, 0.5, "stone")
    vx.fill(x0, x1, y0, y1, 0.5, h, "cream")
    for cx in (x0, x1 - 0.5):
        for cy in (y0, y1 - 0.5):
            vx.fill(cx, cx + 0.5, cy, cy + 0.5, 0.5, h, "wood")
    # flat roof slab, parapets (front / back taller), chimney (Kit x -4, z 2)
    vx.fill(x0 - 0.5, x1 + 0.5, y0 - 0.5, y1 + 0.5, h, h + 1.0, c)
    for ya in (y0 - 0.5, y1 - 0.5):
        vx.fill(x0 - 0.5, x1 + 0.5, ya, ya + 1.0, h + 1.0, h + 2.0, stripes(c, x0 - 0.5, 1.0))
    for xa in (x0 - 0.5, x1):
        vx.fill(xa, xa + 0.5, y0 + 0.5, y1 - 0.5, h + 1.0, h + 1.5, c)
    vx.fill(2.5, 5.5, 0.5, 3.5, h + 1.0, 17.0, "brick")
    vx.fill(2.0, 6.0, 0.0, 4.0, 17.0, 17.5, "stone")
    vx.fill(3.0, 5.0, 1.0, 3.0, 17.0, 17.5, DARK)
    # front: door (Kit x -3), shop window (Kit x 3.5), two upper windows
    door(vx, "-y", y0, 1.0, 5.0, 0.5, 7.0)
    window(vx, "-y", y0, -6.5, -1.0, 2.5, 6.5, sill="wood")
    window(vx, "-y", y0, 1.5, 4.5, 9.0, 11.0)
    window(vx, "-y", y0, -5.0, -2.0, 9.0, 11.0)
    for side, plane in (("+x", x1), ("-x", x0)):
        window(vx, side, plane, -1.5, 1.5, 8.5, 11.0)
        window(vx, side, plane, -1.5, 1.5, 3.0, 6.0, sill="wood")
    # striped awning over the front, stepping down, scalloped edge
    st = stripes(c, x0, 2.0)
    vx.fill(x0, x1, y0 - 1.0, y0, 8.0, 8.5, st)
    vx.fill(x0, x1, y0 - 2.0, y0 - 1.0, 7.5, 8.0, st)
    vx.fill(x0, x1, y0 - 3.0, y0 - 2.0, 7.0, 7.5, st)
    vx.fill(x0, x1, y0 - 3.0, y0 - 2.5, 6.5, 7.0,
            lambda x, y, z, i, j, k: st(x, y, z, i, j, k) if 0.5 <= (x - x0) % 2.0 < 1.5 else None)
    return vx, h + 1.0


STALL = {"Stall_1": ("orange", ("apple", "orange", "grape"), False),
         "Stall_2": ("roofb", ("lemon", "apple", "orange"), True)}


def fruit_crate(vx, x0, y0, z0, fruit, seed):
    """Crate 2.5 x 2 x 1.5 from its corner (x0, y0) on the grid (plank slats, dark corners), fruit heaped to
    z0 + 2.5."""
    x1, y1 = x0 + 2.5, y0 + 2.0
    plank = MATS["plank"]

    def body(x, y, z, i, j, k):
        if (x < x0 + 0.5 or x > x1 - 0.5) and (y < y0 + 0.5 or y > y1 - 0.5):
            return "dwood"
        return plank[2] if int((z - z0) / 0.5 + 1e-6) % 2 == 0 else plank[0]
    vx.fill(x0, x1, y0, y1, z0, z0 + 1.5, body)
    sh = FRUIT[fruit]

    def fr(x, y, z, i, j, k):
        return sh[1] if rnd(seed, "fr", i, j, k) < 0.6 else sh[0]
    vx.fill(x0 + 0.5, x1 - 0.5, y0 + 0.5, y1 - 0.5, z0 + 1.0, z0 + 1.5, fr)
    vx.fill(x0 + 0.5, x1 - 1.0, y0 + 0.5, y1 - 0.5, z0 + 1.5, z0 + 2.0, fr)
    vx.fill(x1 - 1.0, x1 - 0.5, y0 + 0.5, y0 + 1.0, z0 + 1.5, z0 + 2.0, fr)
    vx.fill(x0 + 1.0, x0 + 1.5, y0 + 0.5, y0 + 1.0, z0 + 2.0, z0 + 2.5, FRUIT_LEAF if fruit != "grape" else sh[1])


def stall(key):
    c, fruits, fish = STALL[key]
    vx = Vox(key)
    plank = MATS["plank"]
    # counter: vertical planks, a dark top
    vx.fill(-5.0, 5.0, -2.0, 2.0, 0, 3.0, lambda x, y, z, i, j, k: plank[1] if (i // 2) % 2 else "wood")
    vx.fill(-5.5, 5.5, -2.5, 2.5, 3.0, 3.5, "dwood")
    for px in (-5.0, 4.5):
        for py in (-2.0, 1.5):
            vx.fill(px, px + 0.5, py, py + 0.5, 3.5, 8.0 if py < 0 else 9.0, "dwood")
    # awning: back high, front low, scalloped edge; stripes 1.5 / 2 / 2 / 2 / 2 / 1.5
    edges = [-5.5, -4.0, -2.0, 0.0, 2.0, 4.0, 5.5]

    def st(x, y, z, i, j, k):
        n = sum(1 for e in edges[1:-1] if x >= e)
        return c if n % 2 == 0 else "white"
    vx.fill(-5.5, 5.5, 0.5, 2.5, 9.0, 9.5, st)
    vx.fill(-5.5, 5.5, -1.5, 0.5, 8.5, 9.0, st)
    vx.fill(-5.5, 5.5, -3.5, -1.5, 8.0, 8.5, st)
    vx.fill(-5.5, 5.5, -3.5, -3.0, 7.5, 8.0,
            lambda x, y, z, i, j, k: st(x, y, z, i, j, k) if any(a + 0.5 <= x < b - 0.5 for a, b in
                                                                 zip(edges, edges[1:])) else None)
    for n, cx in enumerate((2.0, -1.5, -4.5)):
        fruit_crate(vx, cx, -1.5, 3.5, fruits[n], (key, n))
    if fish:  # fish on ice behind the crates
        vx.fill(-2.5, 2.5, 0.5, 2.0, 3.5, 4.0, lambda x, y, z, i, j, k: MATS["ice"][2] if (i + j) % 3 else "ice")
        fishc = MATS["roofb"]
        for n, fx in enumerate((-2.0, -0.25, 1.5)):
            fy = 1.0 if n % 2 == 0 else 1.5
            vx.fill(fx, fx + 1.0, fy - 0.5, fy, 4.0, 4.5, fishc[1 + n % 2])
            vx.fill(fx + 1.0, fx + 1.5, fy - 0.5, fy, 4.0, 4.5, fishc[0])  # tail
    return vx, None


def cabin(key="Cabin"):
    vx = Vox(key)
    vx.clump = 2
    x0, x1, y0, y1, h = -8.0, 8.0, -6.0, 6.0, 9.0
    vx.fill(x0 - 0.5, x1 + 0.5, y0 - 0.5, y1 + 0.5, 0, 0.5, "stone")
    # log walls: courses of 1 stud (light top cell, dark lower cell); log ends poke out at the corners
    vx.fill(x0, x1, y0, y1, 0.5, h, lambda x, y, z, i, j, k: "wood" if k % 2 == 0 else "dwood")
    for z in [0.5 + c for c in range(0, 9)]:
        if z + 1.0 > h:
            break
        for cx in (x0 - 0.5, x1):
            for cy in (y0 - 0.5, y1):
                vx.fill(cx, cx + 0.5, cy, cy + 0.5, z, z + 0.5, MATS["plank"][2])
    door(vx, "-y", y0, 0.5, 4.5, 0.5, 7.0)
    window(vx, "-y", y0, -5.5, -2.0, 3.5, 6.5, frame="dwood", glass="glow", sill="snow")
    window(vx, "+x", x1, -1.5, 1.5, 3.5, 6.5, frame="dwood", glass="glow", sill="snow")
    window(vx, "-x", x0, -1.5, 1.5, 3.5, 6.5, frame="dwood", glass="glow", sill="snow")
    vx.fill(-0.5, 5.5, y0 - 2.0, y0 - 0.5, 0, 0.5, "stone")  # door step
    # blue roof, snow on its top, a blue edge at the eaves and the gable ends
    top = gable(vx, x0, x1, y0, y1, h, 6.0, 1.5, lambda x, y, z, i, j, k, L: "roofb", wall="wood", axis="x",
                ovr=1.5)
    for (i, j, k), cval in list(vx.cells.items()):
        if cval != "roofb" or (i, j, k + 1) in vx.cells:
            continue
        x, y, z = vx.centre(i, j, k)
        if (z > h + 0.5 or rnd(key, "drip", i, j) < 0.3) and abs(x) < x1 + 1.0:
            vx.cells[(i, j, k)] = "snow"
    vx.fill(x0 - 1.0, x1 + 1.0, -1.0, 1.0, top, top + 0.5, "snow")  # a snow ridge
    # chimney (Kit x 4, z 2.5) with a snow cap
    vx.fill(-5.5, -3.0, 1.5, 4.0, h, 17.0, "brick")
    vx.fill(-6.0, -2.5, 1.0, 4.5, 17.0, 17.5, "snow")
    vx.fill(-5.0, -3.5, 2.0, 3.5, 17.0, 17.5, DARK)
    # log pile by the side (Kit x 10, z -2): 3 + 2 + 1 logs along Y
    for row, n in enumerate((3, 2, 1)):
        for c in range(n):
            lx = -11.5 + row * 0.5 + c * 1.0
            vx.fill(lx, lx + 1.0, -4.0, 0.0, row * 1.0, row * 1.0 + 1.0, "wood")
            for ey in (-4.0, -0.5):
                vx.fill(lx, lx + 1.0, ey, ey + 0.5, row * 1.0, row * 1.0 + 1.0,
                        lambda x, y, z, i, j, k: MATS["plank"][2] if (i + k) % 2 else MATS["plank"][1])
    return vx, top + 0.5


def pavilion(key="Pavilion"):
    """Kit.pavilion(post Red, roof Navy, trim Gold, floor RedDark) as used in the Forest."""
    vx = Vox(key)
    vx.clump = 2
    w, d = 8.0, 6.5
    vx.fill(-w, w, -d, d, 0, 2.0, lambda x, y, z, i, j, k: "wood" if z >= 1.5 and abs(x) < w - 0.5 and
            abs(y) < d - 0.5 else "lacq")
    for n, (yy, zz) in enumerate(((-9.5, 0.5), (-8.5, 1.0), (-7.5, 1.5))):  # stone steps in front
        vx.fill(-3.0, 3.0, yy, -d, zz - 0.5, zz, "stone")
    for px in (-w + 0.5, w - 1.5):
        for py in (-d + 0.5, d - 1.5):
            vx.fill(px, px + 1.0, py, py + 1.0, 2.0, 11.0, "lacq")
    for sx in (-1, 1):  # side rails with balusters
        x = sx * (w - 1.0) - (0.5 if sx > 0 else 0.0)
        vx.fill(x, x + 0.5, -d + 1.5, d - 1.5, 3.5, 4.0, "lacq")
        for py in range(-4, 5, 2):
            vx.fill(x, x + 0.5, py, py + 0.5, 2.0, 3.5, "lacq")
    # gold beam ring under the roof, hanging lanterns at the front posts
    vx.fill(-w, w, -d, d, 11.0, 12.0, lambda x, y, z, i, j, k: "gold" if abs(x) > w - 1.0 or abs(y) > d - 1.0
            else None)
    for sx in (-1, 1):
        lx = sx * (w - 1.0) - 0.5
        vx.fill(lx, lx + 1.0, -d - 0.5, -d + 0.5, 8.5, 9.0, "black")
        vx.fill(lx, lx + 1.0, -d - 0.5, -d + 0.5, 9.0, 10.5, "glow")
        vx.fill(lx, lx + 1.0, -d - 0.5, -d + 0.5, 10.5, 11.0, "black")
    # navy roof (red gable faces), upturned corners, a gold ridge beam with curled ends
    top = gable(vx, -w, w, -d, d, 12.0, 5.5, 2.0, tiles("navy", key, 0.06), wall="lacq", axis="x", ovr=2.0)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cx = sx * (w + 2.0) - (0.5 if sx > 0 else 0.0)
            cy = sy * (d + 2.0) - (0.5 if sy > 0 else 0.0)
            vx.fill(cx, cx + 0.5, cy, cy + 0.5, 12.5, 13.0, "gold")
    vx.fill(-w - 2.0, w + 2.0, -0.5, 0.5, top, top + 0.5, "gold")
    for sx in (-1, 1):
        ex = sx * (w + 2.0) - (1.0 if sx > 0 else 0.0)
        vx.fill(ex, ex + 1.0, -0.5, 0.5, top, top + 1.0, "gold")
        vx.fill(ex + (0.5 if sx > 0 else 0.0), ex + (1.0 if sx > 0 else 0.5), -0.5, 0.5, top + 1.0, top + 1.5, "gold")
    return vx, top + 0.5


def torii(key="Torii"):
    vx = Vox(key, odd=True)
    for sx in (-1, 1):
        cx = sx * 5.5
        vx.fill(cx - 0.75, cx + 0.75, -0.75, 0.75, 0, 13.0, "lacq")
        vx.fill(cx - 1.25, cx + 1.25, -1.25, 1.25, 0, 1.0, "black")
    vx.fill(-7.25, 7.25, -0.75, 0.75, 10.0, 11.0, "lacq")  # nuki
    vx.fill(-8.25, 8.25, -0.75, 0.75, 12.0, 13.0, "lacq")  # shimaki
    vx.fill(-8.75, 8.75, -1.25, 1.25, 13.0, 14.0, "black")  # kasagi
    for sx in (-1, 1):  # upswept ends
        vx.fill(min(sx * 7.25, sx * 8.75), max(sx * 7.25, sx * 8.75), -1.25, 1.25, 14.0, 14.5, "black")
        vx.fill(min(sx * 8.75, sx * 9.75), max(sx * 8.75, sx * 9.75), -1.25, 1.25, 13.5, 15.0, "black")
    vx.fill(-0.75, 0.75, -0.75, 0.75, 11.0, 12.0, "black")  # plaque
    vx.fill(-0.25, 0.25, -1.25, -0.75, 11.0, 12.0, MATS["gold"][2])
    return vx, None


def doghouse(key="Doghouse"):
    vx = Vox(key)
    vx.fill(-2.5, 2.5, -2.5, 2.5, 0, 4.0, "white")
    for cx in (-2.5, 2.0):
        for cy in (-2.5, 2.0):
            vx.fill(cx, cx + 0.5, cy, cy + 0.5, 0, 4.0, MATS["roofb"][2])
    gable(vx, -2.5, 2.5, -2.5, 2.5, 4.0, 2.5, 0.5, tiles("roofb", key, 0.12), wall="white", axis="y", ovr=0.5)
    # arched doorway, dark inside
    vx.fill(-1.0, 1.0, -2.5, -2.0, 0, 2.5, "")
    vx.fill(-0.5, 0.5, -2.5, -2.0, 2.5, 3.0, "")
    vx.fill(-1.0, 1.0, -2.0, -1.5, 0, 3.0, DARK)
    vx.fill(-1.5, 1.5, -3.0, -2.5, 0, 0.5, MATS["plank"][1])  # a mat at the door
    vx.fill(-0.5, 0.5, -3.0, -2.5, 4.5, 5.0, MATS["plank"][2])  # a little name board
    # food bowl in front (Kit z -4.5)
    vx.fill(-1.0, 1.0, -5.5, -3.5, 0, 0.5, "lacq")
    vx.fill(-1.0, 1.0, -5.5, -3.5, 0.5, 1.0,
            lambda x, y, z, i, j, k: "lacq" if abs(x) > 0.5 or abs(y + 4.5) > 0.5 else None)
    vx.fill(-0.5, 0.5, -5.0, -4.0, 0.5, 1.0, MATS["dwood"][2])  # food
    return vx, None


def fountain(key="Fountain"):
    """Kit.fountain at s = 1: octagonal basin (walls, rim, corner posts), pedestal, two bowls, a ring of
    flower bushes. The water is left to the game (glassy discs): the basin floor and bowl insides are blue."""
    vx = Vox(key)
    vx.clump = 2
    s2 = math.sqrt(2)

    def octo(x, y):
        return max(abs(x), abs(y), (abs(x) + abs(y)) / s2)

    def basin(x, y, z, i, j, k):
        o = octo(x, y)
        if 2.0 <= z < 2.5:
            return "white" if 11.0 <= o <= 13.25 else None
        if 11.25 <= o <= 12.75 and z < 2.0:
            return "stone" if (o > 12.25 and 1.0 <= z < 1.5) else "lstone"
        if z < 0.5 and o < 11.25:
            return "mosaic"
        return None
    vx.fill(-14.0, 14.0, -14.0, 14.0, 0, 2.5, basin)
    for n in range(8):
        a = PI / 8 + n * PI / 4
        cx, cy = 13.0 * math.cos(a), 13.0 * math.sin(a)
        px0, py0 = round((cx - 0.75) * 2) / 2, round((cy - 0.75) * 2) / 2
        vx.fill(px0, px0 + 1.5, py0, py0 + 1.5, 0, 2.5, "stone")
        vx.fill(px0, px0 + 1.5, py0, py0 + 1.5, 2.5, 3.0, "white")
        vx.fill(px0, px0 + 1.5, py0, py0 + 1.5, 3.0, 3.5,
                lambda x, y, z, i, j, k, px0=px0, py0=py0: "white" if (abs(x - px0 - 0.75) < 0.3 or
                                                                      abs(y - py0 - 0.75) < 0.3) else None)
        vx.fill(px0 + 0.5, px0 + 1.0, py0 + 0.5, py0 + 1.0, 3.5, 4.0, "white")
    disc(vx, 0, 0, 2.6, 0.5, 1.0, "stone")
    disc(vx, 0, 0, 1.75, 1.0, 6.0, "lstone")
    disc(vx, 0, 0, 2.3, 5.5, 6.0, "stone")
    disc(vx, 0, 0, 3.5, 6.0, 6.5, "lstone")
    disc(vx, 0, 0, 4.6, 6.5, 7.0, "lstone")
    disc(vx, 0, 0, 4.1, 6.5, 7.0, "mosaic")
    disc(vx, 0, 0, 5.6, 7.0, 7.5, "white", r_in=4.1)
    disc(vx, 0, 0, 1.1, 7.0, 9.5, "lstone")
    disc(vx, 0, 0, 1.9, 9.5, 10.0, "lstone")
    disc(vx, 0, 0, 1.4, 9.5, 10.0, "mosaic")
    disc(vx, 0, 0, 2.8, 10.0, 10.5, "white", r_in=1.4)
    disc(vx, 0, 0, 0.6, 10.0, 11.0, "lstone")
    disc(vx, 0, 0, 0.8, 11.0, 12.0, "white")
    disc(vx, 0, 0, 0.4, 12.0, 12.5, "white")
    # flower bushes round it (Kit: radius 15)
    vx.dots["leaf"] = (0.22, [FLOWERS[c] for c in ("Pink", "Yellow", "Lilac", "White", "Orange")])
    for n in range(12):
        a = n * PI / 6
        vx.blob(15.0 * math.cos(a), 15.0 * math.sin(a), 0.6, 1.2, 1.2, 1.3, "leaf", p=2.4)
    return vx, None


# == bridges ==================================================================================================
def bridge(key):
    """The bridge of Kit.creek, crossing along Y: deck top 3.5 over |y| <= 3.5, 6 steps of 0.5 down to |y| 9.5,
    end posts at |y| 9..10 at both sides. Wood / red: a 1-cell deck on 2-cell side beams; stone: an arch."""
    style = key.split("_")[1].lower()
    vx = Vox(key)
    hw = 4.5 if style == "stone" else 3.5

    def top(y):
        a = abs(y)
        return 3.5 if a <= 3.5 else 3.5 - 0.5 * math.ceil(a - 3.5 - 1e-6)

    plank = MATS["plank"] if style == "wood" else MATS["dwood"]
    side = "wood" if style == "wood" else "lacq"
    cap = "white" if style != "red" else "gold"

    def f(x, y, z, i, j, k):
        t = top(y)
        if t <= 0:
            return None
        edge = abs(x) > hw - 0.5
        if style == "stone":
            a = abs(y)
            bottom = 0.0 if a >= 7.0 else max(2.5 * math.sqrt(1 - (a / 7.0) ** 2), t - 1.5)
            par = abs(x) > hw - 1.0
            if bottom <= z < t:
                if z < bottom + 0.5 and a < 7.0:
                    return "lstone" if int(a) % 2 == 0 else "rock"  # arch ring
                return "stone"
            if par and t <= z < t + 1.0:
                return "stone"
            if par and t + 1.0 <= z < t + 1.5:
                return "lstone"
            return None
        if t - 0.5 <= z < t:
            return side if edge else plank[(0, 2, 1)[j % 3]]
        if edge and t - 1.0 <= z < t:
            return side
        if edge and t <= z < t + 1.0 and int(math.floor(y)) % 2 == 0:
            return side
        if edge and t + 1.0 <= z < t + 1.5:
            return side
        return None
    vx.fill(-hw, hw, -10.0, 10.0, 0, 6.0, f)
    post = "stone" if style == "stone" else ("dwood" if style == "wood" else "lacq")
    for sx in (-1, 1):
        px = hw - 1.0 if sx > 0 else -hw
        for sy in (-1, 1):
            py = 9.0 if sy > 0 else -10.0
            vx.fill(px, px + 1.0, py, py + 1.0, 0, 4.0, post)
            vx.fill(px, px + 1.0, py, py + 1.0, 4.0, 5.0, cap)
            if style != "stone":  # deck corner posts
                qy = 3.0 if sy > 0 else -4.0
                vx.fill(px, px + 1.0, qy, qy + 1.0, 2.5, 5.5, post)
                vx.fill(px, px + 1.0, qy, qy + 1.0, 5.5, 6.0, cap)
    return vx, None


# == props ====================================================================================================
def mountain(key="Mountain"):
    """Kit.mountain: 4 stacked tiers 64 x 52 / 46 x 38 / 30 x 26 / 15 x 14 (heights 22, 18, 16, 12), rock below,
    snow above, snow ledges on every tier. 0.75 voxels."""
    vx = Vox(key, v=0.75, odd=True)
    vx.clump = 5
    tiers = [(32.0, 26.0, 22.0, "rock"), (23.0, 19.0, 18.0, "rock"), (15.0, 13.0, 16.0, "snow"),
             (7.5, 7.0, 12.0, "snow")]
    z0 = 0.0
    for n, (a, b, h, mat) in enumerate(tiers):
        def f(x, y, z, i, j, k, a=a, b=b, h=h, z0=z0, n=n, mat=mat):
            lump = 0.05 * (rnd(key, "lump", n, i // 8, j // 8, k // 8) - 0.5)
            d = max(abs(x) / a, abs(y) / b) + lump
            if abs(x) / a + abs(y) / b > 1.72 + lump:
                return None
            if z > z0 + h - 1.5 and d > 0.95:
                return None
            return mat if d <= 1.0 else None
        vx.fill(-a - 1, a + 1, -b - 1, b + 1, z0, z0 + h, f)
        z0 += h
    vx.cap("snow", 10.0, drip=0.3)
    return vx, None


def stone_lantern(key="StoneLantern"):
    vx = Vox(key, odd=True)
    vx.fill(-1.25, 1.25, -1.25, 1.25, 0, 1.0, "stone")
    vx.fill(-0.75, 0.75, -0.75, 0.75, 1.0, 3.5, "lstone")
    vx.fill(-1.25, 1.25, -1.25, 1.25, 3.5, 5.5,
            lambda x, y, z, i, j, k: "glow" if 4.0 <= z < 5.0 and (abs(x) < 0.6 or abs(y) < 0.6) else "lstone")
    vx.fill(-1.75, 1.75, -1.75, 1.75, 5.5, 6.0, "stone")
    for sx in (-1, 1):  # upturned roof corners
        for sy in (-1, 1):
            vx.fill(sx * 1.5 - 0.25, sx * 1.5 + 0.25, sy * 1.5 - 0.25, sy * 1.5 + 0.25, 6.0, 6.5, "stone")
    vx.fill(-1.25, 1.25, -1.25, 1.25, 6.0, 6.5, "stone")
    vx.fill(-0.75, 0.75, -0.75, 0.75, 6.5, 7.0, "lstone")
    vx.fill(-0.25, 0.25, -0.25, 0.25, 7.0, 7.5, "lstone")
    return vx, None


def snowman(key="Snowman"):
    vx = Vox(key, odd=True)
    vx.blob(0, 0, 2.4, 2.5, 2.5, 2.5, "snow")
    vx.blob(0, 0, 6.0, 1.95, 1.95, 1.9, "snow")
    vx.blob(0, 0, 8.7, 1.45, 1.45, 1.4, "snow")
    nb = MATS["navy"]
    vx.fill(-1.25, 1.25, -1.25, 1.25, 10.0, 10.5, nb[1])  # hat brim
    vx.fill(-0.75, 0.75, -0.75, 0.75, 10.5, 12.0, lambda x, y, z, i, j, k: "lacq" if z < 11.0 else "roofb")
    vx.fill(-0.25, 0.25, -0.25, 0.25, 12.0, 12.5, "white")
    disc(vx, 0, 0, 1.8, 7.5, 8.0, "lacq")  # scarf + its tail
    vx.fill(0.75, 1.25, -1.75, -1.25, 6.0, 7.5, "lacq")
    vx.fill(-0.25, 0.25, -2.25, -1.25, 8.5, 9.0, "orange")  # carrot nose
    for ex in (-0.5, 0.5):
        recolour_front(vx, ex, 9.25, DARK)
    for ex in (-1.0, 1.0):
        recolour_front(vx, ex, 8.25, PINK)
    for bz in (5.25, 6.25):
        recolour_front(vx, 0.0, bz, DARK)
    for sx in (-1, 1):  # stick arms with a twig
        for n in range(4):
            x = sx * (1.75 + n * 0.5)
            vx.fill(x - 0.25, x + 0.25, -0.25, 0.25, 6.5 + (n // 2) * 0.5, 7.0 + (n // 2) * 0.5, "dwood")
        x = sx * 3.25
        vx.fill(x - 0.25, x + 0.25, -0.25, 0.25, 7.5, 8.0, "dwood")
    return vx, None


CRYS = {"Crystals_Pink": "cpink", "Crystals_Blue": "cblue", "Crystals_Purple": "cpurp"}
CLUSTER = [(0.0, 0.0, 8.0, 2.0, 0.0, 0.0), (-2.25, 0.75, 5.5, 1.5, -0.22, 0.06), (2.25, -0.75, 6.5, 1.5, 0.2, -0.08),
           (0.75, 2.25, 4.5, 1.0, 0.08, 0.2), (-1.0, -2.0, 3.5, 1.0, -0.12, -0.2)]


def crystals(key):
    """Kit.crystals small (the game scales 2.2x for the big ones): 5 square crystals, tilted, pointed tips."""
    mat = CRYS[key]
    sh = MATS[mat]
    vx = Vox(key)
    for n, (cx, cy, h, w, tx, ty) in enumerate(CLUSTER):
        tip = w * 1.25

        def f(x, y, z, i, j, k, cx=cx, cy=cy, h=h, w=w, tx=tx, ty=ty, tip=tip):
            ox, oy = cx + tx * z, cy + ty * z
            hw = w / 2 if z < h - tip else max(w / 2 * (h - z) / tip, 0.26)
            if abs(x - ox) >= hw or abs(y - oy) >= hw:
                return None
            if x - ox < -hw + 0.5 and y - oy < -hw + 0.5:
                return sh[3]  # bright edge
            if z >= h - tip:
                return sh[2]
            return mat
        vx.fill(cx - 4, cx + 4, cy - 4, cy + 4, 0, h, f)
    for bx, by in ((1.5, 1.25), (-2.0, -1.0), (0.5, -1.75)):
        vx.blob(bx, by, 0.0, 0.8, 0.8, 0.7, "rock", p=2.2)
    return vx, None


STALKS = [(-2.5, -1.5, 17.0), (1.5, -2.5, 20.0), (2.5, 1.5, 15.0), (-1.5, 2.0, 21.0), (0.0, 0.0, 18.5)]


def bamboo(key="Bamboo"):
    vx = Vox(key)
    for n, (cx, cy, h) in enumerate(STALKS):
        x0, y0 = cx - 0.5, cy - 0.5
        vx.fill(x0, x0 + 1.0, y0, y0 + 1.0, 0, h,
                lambda x, y, z, i, j, k: "node" if (z % 3.0) < 0.5 and z > 1.0 else "bamboo")
        # leaf sprays from the top and from one node
        for m, ang in enumerate((0.3, 2.4, 4.4)):
            a = ang + n * 0.7
            dx, dy = math.cos(a), math.sin(a)
            for t in range(6):
                cell(vx, cx + dx * (0.75 + t * 0.5), cy + dy * (0.75 + t * 0.5), h - 0.25 - t * 0.3, "leaf")
        nz = 3.0 * int(h * 0.55 / 3.0)
        a = n * 1.3 + 0.6
        for t in range(4):
            cell(vx, cx + math.cos(a) * (0.75 + t * 0.5), cy + math.sin(a) * (0.75 + t * 0.5), nz + t * 0.3, "leaf")
        vx.blob(cx, cy, h + 0.25, 0.9, 0.9, 0.75, "leaf")
    return vx, None


def barrel(key="Barrel"):
    """Kit.barrel: d 2.6 x 3.2, two dark hoops, staves; 0.25 voxels so it reads round."""
    vx = Vox(key, v=0.25, odd=True)
    wood = MATS["wood"]

    def f(x, y, z, i, j, k):
        r = 1.15 + 0.2 * math.sin(PI * min(max(z / 3.25, 0.0), 1.0))
        if math.hypot(x, y) > r:
            return None
        if 0.5 <= z < 0.75 or 2.5 <= z < 2.75:
            return "lamp"
        b = int((math.atan2(y, x) + PI) / TAU * 14)
        return wood[1] if b % 2 else wood[2]
    vx.fill(-1.5, 1.5, -1.5, 1.5, 0, 3.25, f)
    vx.fill(-1.5, 1.5, -1.5, 1.5, 3.25, 3.5,
            lambda x, y, z, i, j, k: (MATS["plank"][1] if math.hypot(x, y) < 0.9 else "dwood")
            if math.hypot(x, y) <= 1.15 else None)
    return vx, None


def fruit_crate_prop(key="FruitCrate"):
    vx = Vox(key, odd=True)
    fruit_crate(vx, -1.25, -1.25, 0.0, "apple", key)
    return vx, None


def mushroom(key="Mushroom"):
    vx = Vox(key, v=0.25, odd=True)
    for n, (cx, cy, sw, sh_, cr, layers) in enumerate(
            [(0.0, 0.0, 0.375, 1.25, 1.15, 4), (1.0, -0.75, 0.125, 0.5, 0.55, 2), (-0.75, 1.0, 0.125, 0.75, 0.65, 3)]):
        vx.fill(cx - sw, cx + sw, cy - sw, cy + sw, 0, sh_, "cream")
        for L in range(layers):
            r = cr * (1.0, 1.0, 0.8, 0.5)[L] if layers == 4 else cr * (1.0, 0.75, 0.45)[L]
            disc(vx, cx, cy, r, sh_ + L * 0.25, sh_ + (L + 1) * 0.25,
                 lambda x, y, z, i, j, k, n=n: "white" if rnd(key, "dot", n, i, j, k) < 0.16 else "mush")
    return vx, None


def log(key="Log"):
    vx = Vox(key, v=0.25, odd=True)
    bark = MATS["dwood"]
    ring = MATS["plank"]

    def f(x, y, z, i, j, k):
        dy, dz = y, z - 0.625
        if abs(dy) + abs(dz) > 0.8:
            return None
        if abs(x) > 2.1:  # end faces: rings
            r = max(abs(dy), abs(dz))
            return ring[2] if r < 0.2 else ring[0] if r < 0.45 else ring[1]
        return bark[1] if (k + (i // 3)) % 3 else bark[2]
    vx.fill(-2.25, 2.25, -0.625, 0.625, 0, 1.25, f)
    vx.fill(0.25, 0.75, -0.75, -0.5, 0.5, 0.75, bark[2])  # branch stub
    vx.fill(0.25, 0.75, -1.0, -0.75, 0.5, 0.75, bark[1])
    for (i, j, k), c in list(vx.cells.items()):  # moss on top of the middle
        x, y, z = vx.centre(i, j, k)
        if (i, j, k + 1) not in vx.cells and -1.5 < x < 0.75 and z > 0.75:
            vx.cells[(i, j, k)] = "moss"
            if rnd(key, "m", i, j) < 0.4 and (i, j, k - 1) in vx.cells:
                vx.cells[(i, j, k - 1)] = "moss"
    return vx, None


def fern(key="Fern"):
    vx = Vox(key, v=0.25, odd=True)
    leaf = MATS["leaf"]
    for n in range(6):
        a = n / 6 * TAU + 0.25 * (rnd(key, "a", n) - 0.5)
        ln = 1.8 + 0.5 * rnd(key, "l", n)
        dx, dy = math.cos(a), math.sin(a)
        steps = int(ln / 0.25)
        for t in range(steps):
            s = t / steps
            r = 0.15 + s * ln
            x, y = dx * r, dy * r
            z = 0.25 + 1.0 * math.sin(PI * min(s * 1.1, 1.0)) * 0.9
            col = leaf[1] if n % 2 else leaf[0]
            vx.fill(x - 0.125, x + 0.125, y - 0.125, y + 0.125, z - 0.25, z, col)
            if 0.15 < s < 0.85 and t % 2 == 0:  # leaflets either side
                for side in (-1, 1):
                    px, py = x - dy * 0.25 * side, y + dx * 0.25 * side
                    vx.fill(px - 0.125, px + 0.125, py - 0.125, py + 0.125, z - 0.25, z, leaf[2] if n % 2 else leaf[1])
    return vx, None


def leaf_pile(key="LeafPile"):
    vx = Vox(key, v=0.25, odd=True)

    def f(x, y, z, i, j, k):
        d = math.hypot(x * 0.95, y * 1.1) + 0.3 * (rnd(key, "o", i // 2, j // 2) - 0.5)
        hgt = 0.6 * (1 - d / 1.4)
        if d > 1.4 or z > hgt + 0.13:
            return None
        return AUTUMN[int(rnd(key, "c", i, j, k) * len(AUTUMN)) % len(AUTUMN)]
    vx.fill(-1.5, 1.5, -1.5, 1.5, 0, 0.75, f)
    for n in range(7):  # loose leaves round it
        a = n / 7 * TAU + rnd(key, "la", n)
        r = 1.5 + 0.4 * rnd(key, "lr", n)
        x, y = r * math.cos(a), r * math.sin(a)
        vx.fill(x - 0.125, x + 0.375, y - 0.125, y + 0.125, 0, 0.25, AUTUMN[n % len(AUTUMN)])
    return vx, None


def sapling(key="Sapling"):
    """Kit.sapling: a trunk and three green tiers (2 / 1.5 / 1 wide), each with a snow layer on top."""
    vx = Vox(key, v=0.25)
    pine = MATS["pine"]
    vx.fill(-0.25, 0.25, -0.25, 0.25, 0, 0.75, "wood")
    z = 0.75
    for hw in (1.0, 0.75, 0.5):
        vx.fill(-hw, hw, -hw, hw, z, z + 0.5, lambda x, y, zz, i, j, k: pine[2] if (i + j + k) % 5 == 0 else pine[1])
        vx.fill(-hw, hw, -hw, hw, z + 0.5, z + 0.75, "snow")
        z += 0.75
    vx.fill(-0.25, 0.25, -0.25, 0.25, z, z + 0.25, "snow")
    return vx, None


def sack(key="Sack"):
    vx = Vox(key, v=0.25, odd=True)

    def f(x, y, z, i, j, k):
        r = 0.7 if z < 1.25 else 0.45
        if abs(x) / r + abs(y) / (r * 0.85) > 1.55 or max(abs(x) / r, abs(y) / (r * 0.85)) > 1.0:
            return None
        return "burlap"
    vx.fill(-0.75, 0.75, -0.75, 0.75, 0, 1.5, f)
    vx.fill(-0.375, 0.375, -0.375, 0.375, 1.5, 1.75, "dwood")
    vx.fill(-0.375, 0.375, -0.375, 0.375, 1.75, 2.0, "burlap")
    vx.fill(-0.125, 0.375, -0.125, 0.125, 2.0, 2.25, MATS["burlap"][2])
    pixels(vx, [".#.", "###", ".#."], -0.375, 1.0, -0.625, -0.375, {"#": MATS["dwood"][2]})  # a stamped mark
    return vx, None


def flower_pot(key="FlowerPot"):
    vx = Vox(key, v=0.25, odd=True)
    vx.fill(-0.625, 0.625, -0.625, 0.625, 0, 1.0, "brick")
    vx.fill(-0.875, 0.875, -0.875, 0.875, 1.0, 1.25,
            lambda x, y, z, i, j, k: "brick" if max(abs(x), abs(y)) > 0.6 else MATS["dwood"][1])
    vx.blob(0, 0, 1.4, 0.75, 0.75, 0.55, "leaf", p=2.4)
    for n, (fx, fy, col) in enumerate(((-0.25, -0.375, "Pink"), (0.375, 0.125, "Yellow"), (-0.25, 0.375, "Lilac"))):
        c = FLOWERS[col]
        z = 1.75 + 0.25 * (n % 2)
        vx.fill(fx - 0.375, fx + 0.375, fy - 0.125, fy + 0.125, z, z + 0.25, c)
        vx.fill(fx - 0.125, fx + 0.125, fy - 0.375, fy + 0.375, z, z + 0.25, c)
        vx.fill(fx - 0.125, fx + 0.125, fy - 0.125, fy + 0.125, z, z + 0.375 - 0.125, FLOWERS["Yellow"] if col !=
                "Yellow" else FLOWERS["Orange"])
    return vx, None


def pebbles(key="Pebbles"):
    vx = Vox(key, v=0.25, odd=True)
    for n, (cx, cy, s, mat) in enumerate(((-0.9, 0.3, 1.5, "rock"), (1.0, -0.6, 1.05, "stone"),
                                          (0.4, 1.3, 0.8, "rock"), (-0.3, -1.3, 0.7, "stone"))):
        vx.blob(cx, cy, 0.0, s * 0.65, s * 0.5, s * 0.42, mat, p=2.6)
    return vx, None


def snow_mound(key="SnowMound"):
    vx = Vox(key, odd=True)
    vx.blob(0, 0, -0.9, 2.2, 2.0, 2.0, "snow", p=2.2)
    vx.blob(2.0, 1.0, -0.6, 1.3, 1.2, 1.3, "snow", p=2.2)
    vx.blob(-1.75, -1.25, -0.5, 1.1, 1.1, 1.1, "snow", p=2.2)
    return vx, None


def ice_patch(key="IcePatch"):
    vx = Vox(key, v=0.25, odd=True)
    ice = MATS["ice"]

    def f(x, y, z, i, j, k):
        a = math.atan2(y, x)
        r = 2.3 + 0.35 * math.sin(3 * a + 0.7) + 0.2 * math.sin(5 * a)
        d = math.hypot(x, y)
        if d > r:
            return None
        if abs((x - y) * 0.7 - 0.6) < 0.18 and d < r - 0.6 or abs((x - y) * 0.7 + 0.5) < 0.12 and d < r - 1.0:
            return GLASS_HI  # glints
        if d > r - 0.3:
            return ice[2]
        return ice[1] if rnd(key, "n", i // 2, j // 2) < 0.7 else ice[0]
    vx.fill(-3, 3, -3, 3, 0, 0.25, f)
    return vx, None


def crystal_bits(key="CrystalBits"):
    """A few small ice crystals (snow zone). The sky zone can use Crystals_Pink / _Purple scaled down."""
    vx = Vox(key, v=0.25)
    sh = MATS["cblue"]
    for n, (cx, cy, h, tx, ty) in enumerate(((0.0, 0.0, 1.75, 0.12, -0.05), (-0.75, 0.5, 1.0, -0.25, 0.1),
                                             (0.75, -0.5, 1.25, 0.2, -0.15), (0.5, 0.75, 0.75, 0.1, 0.25))):
        w = 0.5

        def f(x, y, z, i, j, k, cx=cx, cy=cy, h=h, tx=tx, ty=ty):
            ox, oy = cx + tx * z, cy + ty * z
            hw = w / 2 if z < h - 0.5 else 0.13
            if abs(x - ox) >= hw or abs(y - oy) >= hw:
                return None
            return sh[3] if (x < ox and y < oy) else (sh[2] if z >= h - 0.5 else "cblue")
        vx.fill(cx - 1, cx + 1, cy - 1, cy + 1, 0, h, f)
    return vx, None


def cobbles(key="Cobbles"):
    vx = Vox(key, v=0.25, odd=True)
    skip = {(1, -1), (-1, 0)}
    for ix in (-1, 0, 1):
        for iy in (-1, 0, 1):
            if (ix, iy) in skip:
                continue
            s = 1.25 if rnd(key, "s", ix, iy) < 0.5 else 1.5
            sy = s if rnd(key, "t", ix, iy) < 0.5 else s - 0.25
            cx, cy = ix * 1.75, iy * 1.75
            mat = ("rock", "stone", "lstone")[int(rnd(key, "m", ix, iy) * 3)]

            def f(x, y, z, i, j, k, cx=cx, cy=cy, s=s, sy=sy, mat=mat):
                u, v = abs(x - cx) / (s / 2), abs(y - cy) / (sy / 2)
                return mat if u + v < 1.7 else None
            vx.fill(cx - s / 2, cx + s / 2, cy - sy / 2, cy + sy / 2, 0, 0.25, f)
    return vx, None


SHIRT = ["##.##", "#####", ".###.", ".###.", ".###."]
SHORTS = ["#####", "#####", "##.##", "##.##"]
TOWEL = ["####", "####", "wwww", "####", "####", "wwww"]


def clothesline(key="Clothesline"):
    vx = Vox(key, odd=True)
    for sx in (-1, 1):
        x = sx * 6.0
        vx.fill(x - 0.25, x + 0.25, -0.25, 0.25, 0, 7.0, "wood")
        vx.fill(x - 0.25, x + 0.25, -0.75, 0.75, 6.5, 7.0, "wood")
        vx.fill(x - 0.75, x + 0.75, -0.75, 0.75, 0, 0.5, "dwood")
    yel, blu, pnk = MATS["gold"][2], MATS["roofb"][2], MATS["pinkr"][2]
    pixels(vx, SHIRT, -4.75, 6.5, -0.25, 0.25, {"#": yel})          # Kit x 3.6 -> -3.6
    pixels(vx, TOWEL, -0.75, 6.5, -0.25, 0.25, {"#": pnk, "w": "white"})
    pixels(vx, SHORTS, 2.75, 6.5, -0.25, 0.25, {"#": blu})
    for px in (-4.75, -3.25, -0.75, 0.75, 2.75, 4.25):  # pegs
        vx.fill(px, px + 0.5, -0.25, 0.25, 6.5, 7.0, MATS["dwood"][2])

    def line(model):
        ps = Parts(model)
        box_bm(ps.bm(MATS["white"][2]), -6.0, 6.0, -0.08, 0.08, 6.6, 6.76)
        ps.finish(smooth=False)
    return vx, line


BUILD = {
    "House": house, "Shop": shop, "Stall": stall, "Cabin": cabin, "Pavilion": pavilion, "Torii": torii,
    "Doghouse": doghouse, "Fountain": fountain, "Bridge": bridge, "StoneLantern": stone_lantern,
    "Snowman": snowman, "Mountain": mountain, "Crystals": crystals, "Bamboo": bamboo, "Barrel": barrel,
    "FruitCrate": fruit_crate_prop, "Mushroom": mushroom, "Log": log, "Fern": fern, "LeafPile": leaf_pile,
    "Sapling": sapling, "Sack": sack, "FlowerPot": flower_pot, "Pebbles": pebbles, "SnowMound": snow_mound,
    "IcePatch": ice_patch, "CrystalBits": crystal_bits, "Cobbles": cobbles, "Clothesline": clothesline,
}
ONE_ARG = {"House", "Shop", "Stall", "Bridge", "Crystals"}


def build(pid):
    """-> (Vox, extra(model) or None). extra adds smooth parts after the voxel mesh."""
    base = pid.split("_")[0]
    fn = BUILD[base]
    out = fn(pid) if base in ONE_ARG else fn()
    vx = out[0]
    extra = out[1] if callable(out[1]) else None
    return vx, extra


assert all(p.split("_")[0] in BUILD for p in IDS)
