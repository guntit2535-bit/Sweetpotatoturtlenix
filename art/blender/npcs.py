"""Shopkeeper NPC concepts (two girls behind the plaza's SHOP stall and SELL booth), in the map's voxel look.

build(style, who) -> kit.Model
  style "A" = chibi voxel (big head ~45 % of the height, ~5 studs), "B" = blocky avatar (block head / torso / arms /
  legs, ~5.5 studs). who "Shop" = pink girl (brown twin tails, pink apron dress, paw badge), "Sell" = mint girl
  (ginger bob, mint overalls, coin badge, notepad).

One 0.25-stud voxel grid (faces, hands, ears, badges) whose material noise comes in 2 x 2 x 2 clumps, so clothes and
hair read as the props' 0.5-stud pixels. Materials get 2-4 shades (light on top, dark underneath) like voxprops.py.
The waving arm is its own little voxel grid turned about the shoulder (like a Roblox arm). 1 unit = 1 stud,
front = -Y, up = +Z, origin at the feet (z = 0). Concept only: not exported.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from mathutils import Matrix, Vector  # noqa: E402

from kit import Model  # noqa: E402
from voxprops import MATS, Vox, tri_count  # noqa: E402
from voxprops2 import pixels  # noqa: E402

V = 0.25

MATS.update({
    "n_skin": [(242, 188, 156), (248, 200, 170), (252, 210, 182)],
    "n_brown": [(92, 54, 40), (112, 68, 48), (134, 84, 58), (154, 100, 68)],
    "n_ginger": [(212, 98, 40), (232, 122, 50), (248, 146, 66), (255, 172, 92)],
    "n_pink": [(236, 98, 156), (252, 124, 180), (255, 152, 200)],
    "n_lpink": [(255, 178, 210), (255, 198, 222), (255, 214, 232)],
    "n_white": [(232, 232, 242), (246, 244, 250), (255, 255, 255)],
    "n_mint": [(40, 172, 108), (60, 196, 128), (92, 218, 152)],
    "n_lmint": [(150, 232, 186), (176, 242, 204), (204, 250, 222)],
    "n_cream": [(244, 230, 196), (252, 240, 214), (255, 248, 230)],
    "n_shoe": [(212, 70, 128), (236, 92, 150)],
    "n_boot": [(120, 76, 50), (142, 92, 60)],
    "n_gold": [(226, 162, 28), (246, 194, 46), (255, 218, 92)],
    "n_paper": [(238, 236, 226), (250, 248, 240)],
})

INK = (44, 36, 54)
SHINE = (255, 255, 255)
BLUSH = (255, 150, 176)
MOUTH = (150, 56, 84)
TONGUE = (244, 116, 136)
PAW = (236, 84, 146)
COIN, COIN_HI = (246, 186, 40), (255, 226, 110)
LINE = (150, 170, 200)

WHO = {
    "Shop": dict(hair="n_brown", iris=(184, 70, 134), band="n_pink", inner=(255, 196, 220)),
    "Sell": dict(hair="n_ginger", iris=(30, 146, 96), band="n_mint", inner=(204, 250, 222)),
}


# == helpers ===================================================================================================
def box(vx, x0, x1, y0, y1, z0, z1, val):
    vx.fill(x0, x1, y0, y1, z0, z1, val)


def mirror(vx, x0, x1, y0, y1, z0, z1, val):
    """The same box on both sides of x = 0 (x0 < x1, both >= 0)."""
    box(vx, x0, x1, y0, y1, z0, z1, val)
    box(vx, -x1, -x0, y0, y1, z0, z1, val)


def put(vx, x, y, z, val):
    """One cell whose min corner is (x, y, z)."""
    vx.cells[vx.idx(x + V / 2, y + V / 2, z + V / 2)] = val


def face(vx, x0, z_top, y, rows, w):
    cmap = {"K": INK, "W": SHINE, "I": w["iris"], "B": BLUSH, "M": MOUTH, "T": TONGUE, "s": "n_skin"}
    pixels(vx, rows, x0, z_top, y - V, y, cmap)


def ears(vx, cx, z, y0, y1, col, inner, outer_side):
    """Cat ear on a headband: 4 cells wide, then 2, a light inner pixel in front. outer_side = +1 / -1."""
    box(vx, cx - 0.5, cx + 0.5, y0, y1, z, z + V, col)
    sx = cx if outer_side > 0 else cx - 0.5
    box(vx, sx, sx + 0.5, y0, y1, z + V, z + 2 * V, col)
    tip = cx + 0.25 if outer_side > 0 else cx - 0.5
    box(vx, tip, tip + V, y0, y1, z + 2 * V, z + 3 * V, col)
    put(vx, cx - V if outer_side > 0 else cx, y0, z, inner)
    put(vx, cx if outer_side > 0 else cx - V, y0, z, inner)
    put(vx, sx + (0 if outer_side > 0 else V), y0, z + V, inner)


def arm_part(model, seed, pivot, angle, build, odd=False):
    """A limb built upward from its shoulder (0, 0, 0) on its own grid, turned `angle` about Y, moved to `pivot`."""
    vx = Vox(seed, v=V, odd=odd)
    vx.clump = 2
    build(vx)
    n0 = len(model.objects)
    vx.mesh(model, drop_floor=False, name="Arm")
    m = Matrix.Translation(Vector(pivot)) @ Matrix.Rotation(angle, 4, "Y")
    for o in model.objects[n0:]:
        o.data.transform(m)
    return model.objects[n0:]


def tag_wave(model, parts, pivot):
    """The waving arm: exported as its own mesh (origin at the shoulder) so the game can wave it."""
    for o in parts:
        o["wave"] = 1
    model.wave_pivot = Vector(pivot)


def add_badges(model, seed, badges):
    """Raised pixel badges centred on x = 0, one cell proud of the front plane y_front. An odd width needs the
    half-cell grid: built there (y shifted half a cell too) and moved back."""
    for n, (rows, cmap, z_top, y_front) in enumerate(badges):
        w = len(rows[0])
        h = V / 2 if w % 2 else 0.0

        def build(vx, rows=rows, cmap=cmap, z_top=z_top, y_front=y_front, w=w, h=h):
            pixels(vx, rows, -w * V / 2, z_top, y_front - V + h, y_front + h, cmap)
        arm_part(model, f"{seed}{n}", (0, -h, 0), 0.0, build, odd=bool(h))


# == A: chibi voxel ============================================================================================
# feet 0 .. 0.25 shoes, legs to 0.75, skirt / shorts 0.75 .. 1.25, torso 1.25 .. 2.25, head 2.25 .. 4.25
# (2.5 wide, 2 deep), hair shell to 4.5, ears to 5.25.
def chibi(who):
    w = WHO[who]
    shop = who == "Shop"
    vx = Vox("npcA" + who, v=V)
    vx.clump = 2
    hair = w["hair"]
    badges = []

    # legs + shoes
    if shop:
        mirror(vx, 0.25, 0.75, -0.25, 0.25, 0.25, 0.75, "n_white")
        mirror(vx, 0.25, 0.75, -0.5, 0.25, 0, 0.25, "n_shoe")
    else:
        mirror(vx, 0.25, 0.75, -0.25, 0.25, 0.25, 0.75, "n_mint")
        mirror(vx, 0.25, 0.75, -0.5, 0.25, 0, 0.25, "n_white")
        mirror(vx, 0.25, 0.75, -0.5, -0.25, 0, 0.25, "n_boot")

    # lower body
    if shop:
        box(vx, -1.0, 1.0, -0.75, 0.75, 0.75, 1.25, "n_pink")           # skirt
        box(vx, -0.75, 0.75, -1.0, -0.75, 0.75, 1.25, "n_white")       # apron skirt
    else:
        box(vx, -0.75, 0.75, -0.5, 0.5, 0.75, 1.25, "n_mint")           # overall shorts
        box(vx, -0.75, 0.75, -0.5, 0.5, 1.0, 1.25, "n_mint")

    # torso
    box(vx, -0.75, 0.75, -0.5, 0.5, 1.25, 2.25, "n_pink" if shop else "n_cream")
    if shop:
        box(vx, -0.5, 0.5, -0.75, -0.5, 1.25, 2.0, "n_white")          # apron bib
        box(vx, -0.75, 0.75, -0.75, -0.5, 1.25, 1.5, "n_white")         # apron waist band
        badges.append((["P.P", "PPP", ".P."], {"P": PAW}, 2.0, -0.75))  # heart badge
        box(vx, -0.5, 0.5, -0.75, 0.5, 2.0, 2.25, "n_white")           # collar
    else:
        box(vx, -0.5, 0.5, -0.75, -0.5, 1.25, 2.0, "n_mint")            # overall bib
        box(vx, -0.75, -0.5, -0.75, 0.75, 2.0, 2.25, "n_mint")           # straps
        box(vx, 0.5, 0.75, -0.75, 0.75, 2.0, 2.25, "n_mint")
        pixels(vx, ["CG", "GG"], -0.25, 1.75, -0.75, -0.5, {"G": COIN, "C": COIN_HI})  # coin badge
    # shoulders + the hanging arm (the girl's left = viewer's right, +x); the other arm waves
    sleeve = "n_white" if shop else "n_cream"
    box(vx, 0.75, 1.25, -0.25, 0.25, 1.75, 2.25, sleeve)
    box(vx, 0.75, 1.25, -0.25, 0.25, 1.5, 1.75, "n_skin")
    box(vx, 0.75, 1.25, -0.25, 0.25, 1.25, 1.5, "n_skin")
    if shop:
        box(vx, 0.75, 1.25, -0.25, 0.25, 1.75, 2.0, "n_pink")           # cuff
    else:
        box(vx, 0.5, 1.0, -0.75, -0.25, 1.0, 1.75, "n_paper")           # notepad in her hand
        box(vx, 0.5, 1.0, -0.75, -0.5, 1.5, 1.75, (232, 96, 96))         # its red top
        put(vx, 0.5, -0.75, 1.25, LINE)
        put(vx, 0.75, -0.75, 1.0, LINE)

    # head (skin) + face on its front (y = -1)
    box(vx, -1.25, 1.25, -1.0, 1.0, 2.25, 4.25, "n_skin")
    face(vx, -1.25, 3.75, -0.75, [
        ".WK....WK.",
        ".KK....KK.",
        ".II....II.",
        "B..MMMM..B",
        "....TT....",
        "..........",
    ], w)

    # hair shell: cap, back, sides, bangs
    box(vx, -1.5, 1.5, -1.25, 1.25, 4.25, 4.5, hair)
    box(vx, -1.5, 1.5, 1.0, 1.25, 2.0, 4.25, hair)
    if shop:
        mirror(vx, 1.25, 1.5, -1.25, 1.0, 2.5, 4.25, hair)              # side locks to the cheeks
        box(vx, -1.25, 1.25, -1.25, -1.0, 3.75, 4.25, hair)              # straight bangs, centre part
        for x in (-1.25, -0.25, 1.0):
            put(vx, x, -1.25, 3.5, hair)
        # twin tails behind the ears + pink scrunchies
        for s in (-1, 1):
            x0, x1 = (1.5, 2.0) if s > 0 else (-2.0, -1.5)
            box(vx, x0, x1, 0.25, 1.0, 2.0, 3.25, hair)
            box(vx, x0 + (0.25 if s > 0 else -0.25), x1 + (0.25 if s > 0 else -0.25), 0.25, 0.75, 1.5, 2.25, hair)
            box(vx, x0, x1, 0.25, 1.0, 3.25, 3.75, "n_pink")
            box(vx, x0 - 0.25 if s < 0 else x1, x0 if s < 0 else x1 + 0.25, 0.25, 1.0, 3.25, 3.75, "n_lpink")
    else:
        mirror(vx, 1.25, 1.5, -1.25, 1.0, 2.5, 4.25, hair)              # bob
        mirror(vx, 1.5, 1.75, -1.0, 1.0, 2.5, 2.75, hair)               # flicked-out ends
        box(vx, -1.25, 1.25, -1.25, -1.0, 3.75, 4.25, hair)              # side-swept bangs
        for x in (-1.25, -0.5, -0.25):
            put(vx, x, -1.25, 3.5, hair)
        put(vx, 0.75, -1.25, 3.75, "n_skin")
        put(vx, 1.0, -1.25, 3.75, "n_skin")
        box(vx, 0.75, 1.25, -1.5, -1.25, 3.75, 4.0, "n_gold")            # hair clip
        box(vx, -0.5, 0.5, 1.25, 1.5, 3.25, 3.75, hair)                  # short tuft at the back
        box(vx, -0.25, 0.25, 1.25, 1.75, 2.75, 3.25, hair)
        box(vx, -0.25, 0.25, 1.25, 1.5, 3.25, 3.5, "n_mint")             # mint tie

    # cat-ear headband
    box(vx, -1.5, 1.5, -0.25, 0.25, 4.5, 4.75, w["band"])
    mirror(vx, 1.5, 1.75, -0.25, 0.25, 4.0, 4.75, w["band"])
    for s in (-1, 1):
        ears(vx, s * 1.0, 4.75, -0.25, 0.25, w["band"], w["inner"], s)

    m = Model("NPC_A_" + who)
    vx.mesh(m)
    add_badges(m, "npcAb" + who, badges)

    # waving arm (the girl's right = viewer's left, -x): up and out from the shoulder
    def wave(a):
        box(a, -0.25, 0.25, -0.25, 0.25, 0, 0.5, sleeve)
        if shop:
            box(a, -0.25, 0.25, -0.25, 0.25, 0.25, 0.5, "n_pink")
        box(a, -0.25, 0.25, -0.25, 0.25, 0.5, 1.25, "n_skin")
        put(a, 0.25, -0.25, 0.75, "n_skin")                                # thumb
    tag_wave(m, arm_part(m, "npcAwave" + who, (-1.0, 0, 2.0), math.radians(-45), wave), (-1.0, 0, 2.0))
    return m


# == B: blocky avatar ==========================================================================================
# shoes 0 .. 0.25, legs to 1.75, torso 1.75 .. 3.5 (2 x 1), head 3.5 .. 5.25 (2 wide, 1.5 deep), hair to 5.5,
# ears to 6.25 (head + hair ~ 5.5).
def blocky(who):
    w = WHO[who]
    shop = who == "Shop"
    vx = Vox("npcB" + who, v=V)
    vx.clump = 2
    hair = w["hair"]
    badges = []

    # legs
    if shop:
        mirror(vx, 0.25, 1.0, -0.5, 0.5, 0.25, 1.75, "n_white")
        mirror(vx, 0.25, 1.0, -0.75, 0.5, 0, 0.25, "n_shoe")
        mirror(vx, 0.25, 1.0, -0.75, 0.5, 0.25, 0.5, "n_shoe")
        box(vx, -1.25, 1.25, -0.75, 0.75, 1.0, 1.75, "n_pink")           # skirt
        box(vx, -1.0, 1.0, -1.0, -0.75, 1.0, 1.75, "n_white")            # apron
        box(vx, -1.0, 1.0, -1.0, -0.75, 1.0, 1.25, "n_lpink")            # apron frill
    else:
        mirror(vx, 0.25, 1.0, -0.5, 0.5, 0.5, 1.75, "n_mint")
        mirror(vx, 0.25, 1.0, -0.75, 0.5, 0, 0.5, "n_white")
        mirror(vx, 0.25, 1.0, -0.75, -0.5, 0, 0.25, "n_boot")
        box(vx, -1.0, 1.0, -0.5, 0.5, 1.25, 1.75, "n_mint")
        mirror(vx, 0.25, 1.0, -0.5, 0.5, 0.5, 0.75, "n_lmint")           # cuffs

    # torso
    box(vx, -1.0, 1.0, -0.5, 0.5, 1.75, 3.5, "n_pink" if shop else "n_cream")
    if shop:
        box(vx, -0.75, 0.75, -0.75, -0.5, 1.75, 3.0, "n_white")          # apron bib
        box(vx, -1.0, 1.0, -0.75, -0.5, 1.75, 2.0, "n_white")
        box(vx, -0.5, 0.5, -0.75, 0.5, 3.25, 3.5, "n_white")              # collar
        badges.append(([".P.P.", "P...P", ".PPP.", ".PPP."], {"P": PAW}, 2.75, -0.75))  # paw badge
        box(vx, -0.25, 0.25, -1.0, -0.75, 3.0, 3.25, PAW)                # bow at the collar
    else:
        box(vx, -0.75, 0.75, -0.75, -0.5, 1.75, 3.0, "n_mint")            # overall bib
        box(vx, -0.75, -0.25, -0.75, 0.75, 3.0, 3.5, "n_mint")            # straps
        box(vx, 0.25, 0.75, -0.75, 0.75, 3.0, 3.5, "n_mint")
        box(vx, -1.0, 1.0, -0.75, 0.5, 1.75, 2.0, "n_mint")               # waist
        pixels(vx, ["B....B"], -0.75, 3.0, -0.75, -0.5, {"B": COIN})                  # buttons
        badges.append(([".GGG.", "GCGGG", "GGGGG", ".GGG."], {"G": COIN, "C": COIN_HI}, 2.75, -0.75))  # coin badge

    # hanging arm (+x), 0.75 x 0.75
    sleeve = "n_white" if shop else "n_cream"
    box(vx, 1.0, 1.75, -0.5, 0.25, 2.5, 3.5, sleeve)
    box(vx, 1.0, 1.75, -0.5, 0.25, 1.75, 2.5, "n_skin")
    if shop:
        box(vx, 1.0, 1.75, -0.5, 0.25, 2.5, 2.75, "n_pink")
    else:
        box(vx, 0.75, 1.5, -0.75, -0.5, 1.5, 2.75, "n_paper")            # notepad
        box(vx, 0.75, 1.5, -0.75, -0.5, 2.5, 2.75, (232, 96, 96))
        for z in (1.75, 2.0, 2.25):
            put(vx, 1.0, -0.75, z, LINE)
            if z != 1.75:
                put(vx, 1.25, -0.75, z, LINE)

    # head + face (front y = -0.75)
    box(vx, -1.0, 1.0, -0.75, 0.75, 3.5, 5.25, "n_skin")
    face(vx, -1.0, 4.75, -0.5, [
        ".WK..WK.",
        ".KK..KK.",
        ".II..II.",
        "B.MMMM.B",
        "...TT...",
        "........",
    ], w)

    # hair
    box(vx, -1.25, 1.25, -1.0, 1.0, 5.25, 5.5, hair)
    box(vx, -1.25, 1.25, 0.75, 1.0, 3.25, 5.25, hair)
    if shop:
        mirror(vx, 1.0, 1.25, -1.0, 0.75, 3.75, 5.25, hair)
        box(vx, -1.0, 1.0, -1.0, -0.75, 4.75, 5.25, hair)
        for x in (-1.0, -0.25, 0.75):
            put(vx, x, -1.0, 4.5, hair)
        for s in (-1, 1):
            x0, x1 = (1.25, 1.75) if s > 0 else (-1.75, -1.25)
            box(vx, x0, x1, 0.25, 1.0, 2.75, 4.5, hair)
            box(vx, x0 + (0.25 if s > 0 else -0.25), x1 + (0.25 if s > 0 else -0.25), 0.25, 0.75, 2.25, 3.0, hair)
            box(vx, x0, x1, 0.25, 1.0, 4.5, 5.0, "n_pink")
            box(vx, x1 if s > 0 else x0 - 0.25, x1 + 0.25 if s > 0 else x0, 0.25, 1.0, 4.5, 5.0, "n_lpink")
    else:
        mirror(vx, 1.0, 1.25, -1.0, 0.75, 3.75, 5.25, hair)
        mirror(vx, 1.25, 1.5, -0.75, 0.75, 3.75, 4.0, hair)
        box(vx, -1.0, 1.0, -1.0, -0.75, 4.75, 5.25, hair)
        for x in (-1.0, -0.25, 0.0):
            put(vx, x, -1.0, 4.5, hair)
        put(vx, 0.5, -1.0, 4.75, "n_skin")
        put(vx, 0.75, -1.0, 4.75, "n_skin")
        box(vx, 0.5, 1.0, -1.25, -1.0, 4.75, 5.0, "n_gold")
        box(vx, -0.5, 0.5, 1.0, 1.5, 4.0, 4.75, hair)                    # little ponytail
        box(vx, -0.25, 0.25, 1.0, 1.75, 3.25, 4.25, hair)
        box(vx, -0.25, 0.25, 1.0, 1.5, 4.5, 4.75, "n_mint")

    box(vx, -1.25, 1.25, -0.25, 0.25, 5.5, 5.75, w["band"])
    mirror(vx, 1.25, 1.5, -0.25, 0.25, 5.0, 5.75, w["band"])
    for s in (-1, 1):
        ears(vx, s * 0.75, 5.75, -0.25, 0.25, w["band"], w["inner"], s)

    m = Model("NPC_B_" + who)
    vx.mesh(m)
    add_badges(m, "npcBb" + who, badges)

    def wave(a):  # 0.75 x 0.75, centred at local x 0.125 / y -0.125
        box(a, -0.25, 0.5, -0.5, 0.25, 0, 1.25, sleeve)
        if shop:
            box(a, -0.25, 0.5, -0.5, 0.25, 1.0, 1.25, "n_pink")
        box(a, -0.25, 0.5, -0.5, 0.25, 1.25, 1.75, "n_skin")
    tag_wave(m, arm_part(m, "npcBwave" + who, (-1.5, 0, 3.25), math.radians(-30), wave), (-1.5, 0, 3.25))
    return m


def build(style, who):
    return chibi(who) if style == "A" else blocky(who)


if __name__ == "__main__":  # blender -b --factory-startup -P art/blender/npcs.py : sizes + triangles
    import kit
    from voxprops import bounds
    for st in ("A", "B"):
        for who in ("Shop", "Sell"):
            kit.new_scene()
            mm = build(st, who)
            lo, hi = bounds(mm)
            print(st, who, "size", tuple(round(v, 2) for v in (hi - lo)), "z", round(lo.z, 2), "tris", tri_count(mm))
