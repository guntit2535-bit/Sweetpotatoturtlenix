"""Epic tier (round 2): costumes, each a whole character (hat + clothes + a thing to hold). Pirate is in blockcat.py."""
import math

import blockcat
from blockcat import GOLD, GOLD_DARK, INK, PINK, WHITE, shade
from catparts import (BLACK, BLUE, BROWN, CLOTH, GREEN, RED, SILVER, WOOD, C, G, about, armour, backpack, ball, beanie,
                      belt, beret, boots, bow, brim_hat, cap, cape, coat, collar, cone_hat, crown, cuffs, cyl, ears_out,
                      face_cover, fx, glasses, goggles, headband, headphones, held, helmet, hood, lei, mask_band, mix,
                      mustache, necklace, necktie, overall, plate, remove, ring, sash, scarf, shield, shirt, skirt,
                      stack, star, stick, sword, top_hat, wedge, box, side_mark, flower)
from kit import R, T

DESIGNS = {}


def cat(name, **look):
    def deco(fn):
        DESIGNS[name] = (fn, look)
        return fn
    return deco


def arc(m, c, r, a0, a1, n, s, col, bone="L", name="Arc", fr=None, axis="Y"):
    """n boxes along an arc (angles a0..a1) in the XZ plane (axis Y) or XY plane (axis Z) round c."""
    from mathutils import Matrix
    for k in range(n):
        ang = a0 + (a1 - a0) * k / max(1, n - 1)
        if axis == "Y":
            f = (fr or Matrix()) @ T(*c) @ R(-ang, "Y") @ T(r, 0, 0)
        else:
            f = (fr or Matrix()) @ T(*c) @ R(ang, "Z") @ T(r, 0, 0)
        box(m, (0, 0, 0), s, col, bone, name, fr=f, studs=False)


def under_board(m, A, col, length=None, wheels=None, tip=True, z=0.0):
    """A board under the paws (skateboard, surfboard, skis)."""
    a = G(A)
    ln = length or a.bl + 1.6
    plate(m, (0, a.by, z + 0.1), (a.bw + 0.4, ln, 0.2), col, "B", "Board")
    if tip:
        for s in (-1, 1):
            wedge(m, (0, a.by + s * (ln / 2 + 0.25), z + 0.2), (a.bw + 0.4, 0.5, 0.2), col, "B", "Board",
                  fr=about((0, a.by + s * (ln / 2 + 0.25), z + 0.2), R(0 if s > 0 else math.pi, "Z")))
    if wheels:
        for x in (-1, 1):
            for y in (-1, 1):
                cyl(m, (x * (a.bw / 2), a.by + y * (ln / 2 - 0.5), z - 0.1), 0.2, 0.25, wheels, "B", "Wheel", axis="X")


def lift(m, dz):
    """Raise the whole cat (to stand on a board)."""
    for o in m.objects:
        o.location.z += dz


# --------------------------------------------------------------------------------------------------------------------
@cat("Ninja", shape="Slim", fur="2b2733", second="3d3846", eyes="ffd23c", eyeStyle="big")
def _ninja(m, A):
    a = G(A)
    black = (36, 32, 44)
    face_cover(m, A, black)
    headband(m, A, (220, 40, 50))
    shirt(m, A, black, h=a.bh)
    belt(m, A, (220, 40, 50), buckle=(220, 40, 50))
    b = held(m, A, -1)
    for k in range(4):
        box(m, (0, 0.22, 0), (0.18, 0.5, 0.06), (190, 195, 210), "L", "Shuriken", studs=False,
            fr=T(b.x, b.y, 0.9) @ R(math.pi / 2, "X") @ R(k * math.pi / 2, "Z"))
    fx(m, A, "ground", "cloud", [(200, 200, 215), (170, 170, 185)], n=6, s=0.8, emit=0.0)


@cat("Wizard", shape="Fluffy", fur="ffe6bc", second="fffaf0", eyes="5ab0ff")
def _wizard(m, A):
    a = G(A)
    purple, star_c = (110, 70, 210), (255, 220, 70)
    tip = cone_hat(m, A, purple, h=2.4, w=a.hw * 0.75, tilt=-0.2, brim=1.3, n=6)
    for c in ((-0.5, a.hy - a.hd * 0.32, a.top + 0.8), (0.3, a.hy - a.hd * 0.27, a.top + 1.4)):
        star(m, (0, 0, 0), 0.4, star_c, "H", emit=0.4, fr=T(*c))
    coat(m, A, purple, trim=star_c)
    stick(m, A, WOOD, h=2.8, top="star", top_col=star_c)
    box(m, (0, a.front - 0.3, a.hb - 0.2), (1.2, 0.3, 1.0), (245, 245, 250), "H", "Beard")
    fx(m, A, "orbit", "star", [star_c, (180, 140, 255)], n=7, s=0.4, emit=2.0)


@cat("Knight", shape="Loaf", fur="ffb066", second="fff0d8", eyes="3c96ff")
def _knight(m, A):
    a = G(A)
    steel = (195, 202, 215)
    helmet(m, A, steel, visor=(150, 158, 175), crest=(60, 120, 230))
    armour(m, A, steel, trim=(60, 120, 230))
    boots(m, A, steel, h=0.4)
    sword(m, A)
    shield(m, A, (60, 120, 230), rim=steel, emblem=GOLD, side=1)


@cat("Astronaut", shape="Loaf", fur="a8adb8", second="eef0f4", eyes="3c96ff")
def _astronaut(m, A):
    a = G(A)
    suit = (245, 246, 250)
    coat(m, A, suit)
    boots(m, A, (200, 205, 215), h=0.6)
    box(m, (0, a.bfront - CLOTH - 0.06, a.bz + 0.2), (0.9, 0.12, 0.5), (60, 120, 230), "B", "Panel", studs=False)
    box(m, (0.25, a.bfront - CLOTH - 0.1, a.bz + 0.2), (0.15, 0.06, 0.15), (240, 60, 60), "B", "Panel", studs=False, emit=0.8)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + CLOTH + 0.03), a.by, a.bz), (0.06, a.bl * 0.9, 0.2), (255, 140, 40), "B", "Stripe", studs=False)
    ball(m, (0, a.hy, a.hz + 0.15), (a.hw * 0.72, a.hd * 0.75, a.hh * 0.68), (200, 230, 255), "H", "Glass", alpha=0.25,
         rough=0.02, coat=1.0)
    box(m, (0, a.hy, a.hb + 0.1), (a.hw + 0.4, a.hd + 0.4, 0.3), (220, 225, 235), "H", "Ring", studs=False)
    backpack(m, A, (225, 230, 240), flap=(255, 140, 40))
    fx(m, A, "orbit", "star", [(255, 240, 160), WHITE], n=6, s=0.35, emit=2.5)


@cat("Cowboy", shape="Slim", fur="b07a4a", second="f6e2c8", eyes="52d273", pattern="socks")
def _cowboy(m, A):
    a = G(A)
    hat = (150, 95, 50)
    brim_hat(m, A, hat, band=(90, 55, 30), brim=1.45, h=0.8, cw=0.6)
    for x in (-1, 1):
        box(m, (x * a.hw * 0.68, a.hy, a.top + 0.3), (0.3, a.hd * 1.3, 0.4), hat, "H", "Brim", studs=False)
    scarf(m, A, [(220, 40, 50), WHITE], tail=False)
    belt(m, A, (110, 70, 40))
    b = held(m, A, -1)
    for k in range(12):
        ang = k * math.pi / 6
        box(m, (0, 0, 0), (0.18, 0.4, 0.18), (220, 190, 120), "L", "Rope", studs=False,
            fr=T(b.x - 0.3, b.y, 0.9) @ R(math.pi / 2, "Y") @ R(ang, "X") @ T(0, 0, 0.6))
    boots(m, A, (120, 75, 40), h=0.5, which=(0, 2))


@cat("Firefighter", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="tabby", patternColor="d9681f")
def _firefighter(m, A):
    a = G(A)
    red, yel = (215, 40, 40), (255, 210, 50)
    ears_out(m, A)
    stack(m, (0, a.hy, a.top), a.hw * 0.95, a.hw * 0.6, 0.8, 3, red, d0=a.hd * 0.95, d1=a.hd * 0.6)
    plate(m, (0, a.hy + 0.3, a.top + 0.05), (a.hw * 1.1, a.hd * 1.35, 0.12), red, "H", "Brim")
    box(m, (0, a.hy - a.hd * 0.45, a.top + 0.6), (0.6, 0.12, 0.6), GOLD, "H", "Badge", studs=False)
    coat(m, A, (60, 55, 50))
    for z in (-0.3, 0.3):
        for s in (-1, 1):
            box(m, (s * (a.bw / 2 + CLOTH + 0.03), a.by, a.bz + z), (0.06, a.bl + 0.3, 0.2), yel, "B", "Stripe", studs=False, emit=0.3)
    boots(m, A, BLACK, h=0.5)
    b = held(m, A, -1)
    for k in range(5):
        cyl(m, (b.x, b.y - 0.4 + k * 0.35, 0.3 + k * 0.15), 0.2, 0.42, (230, 200, 60), "L", "Hose", axis="Y")
    cyl(m, (b.x, b.y - 0.7, 0.25), 0.16, 0.5, SILVER, "L", "Hose", axis="Y")


@cat("Police", shape="Slim", fur="a8adb8", second="eef0f4", eyes="3c96ff", pattern="mittens")
def _police(m, A):
    a = G(A)
    navy = (35, 55, 130)
    ears_out(m, A)
    box(m, (0, a.hy, a.top + 0.35), (a.hw * 0.85, a.hd * 0.85, 0.5), navy, "H", "Hat")
    box(m, (0, a.hy, a.top + 0.1), (a.hw * 0.72, a.hd * 0.72, 0.2), INK, "H", "Band", studs=False)
    plate(m, (0, a.hy - a.hd * 0.5, a.top + 0.08), (a.hw * 0.7, 0.6, 0.1), INK, "H", "Visor")
    star(m, (0, 0, 0), 0.4, GOLD, "H", emit=0.2, fr=T(0, a.hy - a.hd * 0.43 - 0.06, a.top + 0.38))
    shirt(m, A, navy, h=a.bh * 0.85)
    star(m, (0, 0, 0), 0.45, GOLD, "B", emit=0.2, fr=T(-0.5, a.bfront - CLOTH - 0.08, a.bz + 0.2))
    belt(m, A, INK, buckle=SILVER)
    box(m, (0.45, a.front - 0.15, a.hb + 0.05), (0.3, 0.2, 0.2), SILVER, "H", "Whistle", studs=False)


@cat("Doctor", shape="Loaf", fur="a8adb8", second="eef0f4", eyes="3c96ff", pattern="socks")
def _doctor(m, A):
    a = G(A)
    coat(m, A, WHITE, trim=(170, 210, 240))
    shirt(m, A, (120, 190, 230), h=0.25)
    for k in range(10):
        t = k / 9
        x = -0.6 + t * 1.2
        z = a.hb - 0.05 - 0.55 * math.sin(math.pi * t)
        box(m, (x, a.bfront - CLOTH - 0.08, z), (0.16, 0.1, 0.16), (60, 60, 75), "B", "Scope", studs=False)
    cyl(m, (0, a.bfront - CLOTH - 0.1, a.hb - 0.75), 0.22, 0.1, SILVER, "B", "Scope", axis="Y")
    cyl(m, (0, a.hy - 0.2, a.top + 0.05), 0.38, 0.08, SILVER, "H", "Mirror", fr=about((0, a.hy - 0.2, a.top), R(0.0, "X")))
    box(m, (-0.6, a.bfront - CLOTH - 0.06, a.bz + 0.1), (0.4, 0.06, 0.4), (230, 50, 60), "B", "Cross", studs=False)
    box(m, (-0.6, a.bfront - CLOTH - 0.07, a.bz + 0.1), (0.14, 0.06, 0.4), WHITE, "B", "Cross", studs=False)
    box(m, (-0.6, a.bfront - CLOTH - 0.07, a.bz + 0.1), (0.4, 0.06, 0.14), WHITE, "B", "Cross", studs=False)


@cat("Chef", shape="Fluffy", fur="ffb066", second="fff4e8", eyes="3c96ff", pattern="tabby", patternColor="e08a3a")
def _chef(m, A):
    a = G(A)
    ears_out(m, A)
    cyl(m, (0, a.hy, a.top + 0.45), a.hw * 0.36, 0.9, WHITE, "H", "Hat")
    for x, y in ((-0.45, 0), (0.45, 0), (0, 0.4), (0, -0.4), (0, 0)):
        ball(m, (x, a.hy + y, a.top + 1.05), 0.55, WHITE, "H", "Hat")
    scarf(m, A, [(220, 40, 50)], tail=False)
    coat(m, A, WHITE)
    for z in (0.35, -0.15):
        for x in (-0.35, 0.35):
            box(m, (x, a.bfront - CLOTH - 0.06, a.bz + z), (0.18, 0.06, 0.18), (60, 60, 70), "B", "Button", studs=False)
    b = held(m, A, -1)
    fr = T(b.x, b.y, 0.0) @ R(0.15, "Y")
    box(m, (0, 0, 0.7), (0.16, 0.16, 1.4), (60, 60, 70), "L", "Spatula", fr=fr, studs=False)
    box(m, (0, 0, 1.65), (0.6, 0.1, 0.6), SILVER, "L", "Spatula", fr=fr, studs=False)
    fx(m, A, "above", "cloud", [(240, 240, 245)], n=3, s=0.5, emit=0.2)


@cat("Samurai", shape="Slim", fur="ff9a3c", second="fff0d8", eyes="52d273", eyeStyle="big")
def _samurai(m, A):
    a = G(A)
    red, black = (190, 35, 45), (40, 36, 48)
    armour(m, A, red, trim=black)
    for s in (-1, 1):
        for k in range(3):
            box(m, (s * (a.bw / 2 + CLOTH + 0.03), a.by - 0.6 + k * 0.6, a.bz - 0.1), (0.08, 0.5, 0.9), black if k % 2 else red, "B", "Plate", studs=False)
    helmet(m, A, black)
    for x in (-1, 1):
        box(m, (x * 0.45, a.hy - a.hd * 0.42, a.top + 0.75), (0.2, 0.14, 1.1), GOLD, "H", "Crest", studs=False,
            fr=about((0, a.hy - a.hd * 0.42, a.top + 0.3), R(x * 0.45, "Y")))
    box(m, (0, a.hy - a.hd * 0.44, a.top + 0.25), (0.4, 0.14, 0.3), GOLD, "H", "Crest", studs=False)
    sword(m, A, blade=(210, 170, 110), hilt=black, guard=GOLD, ln=2.0)


@cat("Viking", shape="Fluffy", fur="b07a4a", second="f6e2c8", eyes="3c96ff", pattern="tabby", patternColor="7a5030")
def _viking(m, A):
    a = G(A)
    steel = (190, 196, 210)
    ears_out(m, A)
    stack(m, (0, a.hy, a.top), a.hw * 0.95, a.hw * 0.45, 0.9, 3, steel, d0=a.hd * 0.95, d1=a.hd * 0.45)
    box(m, (0, a.hy, a.top + 0.1), (a.hw * 0.98, a.hd * 0.98, 0.2), GOLD_DARK, "H", "Band", studs=False)
    for x in (-1, 1):
        for k in range(3):
            box(m, (x * (a.hw * 0.5 + 0.25 + k * 0.3), a.hy, a.top + 0.45 + k * 0.38), (0.4 - k * 0.08, 0.4 - k * 0.08, 0.5),
                (250, 240, 215), "H", "Horn", studs=False)
    box(m, (0, a.front - 0.3, a.mz - 0.55), (1.6, 0.4, 0.9), (220, 120, 50), "H", "Beard")
    for x in (-0.45, 0.45):
        box(m, (x, a.front - 0.3, a.mz - 1.15), (0.35, 0.35, 0.5), (220, 120, 50), "H", "Beard")
    shield(m, A, (170, 115, 65), rim=steel, side=1, round_=True)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.1), 0.1, 2.2, WOOD, "L", "Axe")
    box(m, (b.x - 0.35, b.y, 1.9), (0.6, 0.14, 0.7), steel, "L", "Axe", studs=False)


@cat("Pharaoh", shape="Slim", fur="ffc85a", second="fff0c8", eyes="3c96ff", eyeStyle="big")
def _pharaoh(m, A):
    a = G(A)
    blue, gold = (40, 70, 170), GOLD
    remove(m, ("Ear", "EarIn"))
    box(m, (0, a.hy + 0.05, a.top + 0.15), (a.hw + 0.3, a.hd + 0.2, 0.3), gold, "H", "Nemes")
    for x in (-1, 1):
        for k in range(5):
            box(m, (x * (a.hw / 2 + 0.2), a.hy + 0.1, a.top - 0.25 - k * 0.42), (0.3, a.hd * 0.85, 0.42), blue if k % 2 else gold,
                "H", "Nemes", studs=False)
    box(m, (0, a.hy - a.hd / 2 - 0.08, a.top + 0.35), (0.3, 0.2, 0.4), gold, "H", "Cobra", studs=False)
    for k in range(3):
        box(m, (0, a.by, a.hb - 0.1 - k * 0.2), (a.hw * (0.95 - k * 0.12), a.hd * 0.9, 0.2), blue if k % 2 else gold, "H", "Collar",
            studs=False)
    stick(m, A, gold, h=2.2, top="hook")
    fx(m, A, "orbit", "spark", [GOLD, (255, 240, 170)], n=7, s=0.4, emit=2.5)


@cat("Detective", shape="Loaf", fur="b07a4a", second="f6e2c8", eyes="52d273", pattern="tabby", patternColor="7a5030")
def _detective(m, A):
    a = G(A)
    tweed = (160, 120, 80)
    ears_out(m, A)
    stack(m, (0, a.hy, a.top), a.hw * 0.85, a.hw * 0.55, 0.7, 3, tweed, d0=a.hd * 0.85, d1=a.hd * 0.55)
    for s in (-1, 1):
        plate(m, (0, a.hy + s * a.hd * 0.55, a.top + 0.1), (a.hw * 0.6, 0.6, 0.12), tweed, "H", "Brim")
    box(m, (0, a.hy, a.top + 0.75), (0.25, 0.25, 0.14), tweed, "H", "Hat", studs=False)
    coat(m, A, (190, 160, 110))
    b = held(m, A, -1)
    fr = T(b.x, b.y, 0.0) @ R(0.2, "Y")
    box(m, (0, 0, 0.6), (0.18, 0.18, 1.2), (80, 50, 30), "L", "Lens", fr=fr, studs=False)
    for k in range(10):
        box(m, (0, 0, 0), (0.12, 0.12, 0.26), GOLD, "L", "Lens", fr=fr @ T(0, 0, 1.55) @ R(k * 0.628, "Y") @ T(0.38, 0, 0), studs=False)
    cyl(m, (0, 0, 1.55), 0.36, 0.06, (200, 230, 255), "L", "Lens", fr=fr, axis="Y", alpha=0.5, rough=0.02, coat=1.0)


@cat("Painter", shape="Slim", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="patch", patternColor="b8bcc8")
def _painter(m, A):
    a = G(A)
    beret(m, A, (230, 60, 70))
    coat(m, A, (250, 248, 240))
    for (u, v), c in zip(((-0.3, 0.2), (0.2, -0.2), (0.0, 0.35), (0.3, 0.1)), ((255, 90, 120), (70, 170, 255), (255, 210, 50), (90, 200, 100))):
        box(m, (-(a.bw / 2 + CLOTH + 0.03), a.by + u * a.bl, a.bz + v), (0.06, 0.35, 0.3), c, "B", "Splat", studs=False)
    b = held(m, A, -1)
    plate(m, (b.x, b.y, 0.8), (0.9, 1.1, 0.12), (220, 180, 120), "L", "Palette")
    for (dx, dy), c in zip(((-0.25, -0.3), (0.2, -0.25), (-0.2, 0.15), (0.2, 0.25)), ((255, 90, 120), (70, 170, 255), (255, 210, 50), (90, 200, 100))):
        box(m, (b.x + dx, b.y + dy, 0.9), (0.24, 0.24, 0.08), c, "L", "Paint", studs=False)
    b2 = held(m, A, 1)
    fr = T(b2.x, b2.y, 0.0) @ R(-0.2, "Y")
    box(m, (0, 0, 0.8), (0.12, 0.12, 1.6), WOOD, "L", "Brush", fr=fr, studs=False)
    box(m, (0, 0, 1.75), (0.2, 0.2, 0.3), (70, 170, 255), "L", "Brush", fr=fr, studs=False)
    fx(m, A, "orbit", "pixel", [(255, 90, 120), (70, 170, 255), (255, 210, 50), (90, 200, 100)], n=8, s=0.3, emit=0.3)


@cat("Rock Star", shape="Slim", fur="2b2733", second="3d3846", eyes="b06cff", eyeStyle="big", glowEyes=True)
def _rockstar(m, A):
    a = G(A)
    purple = (140, 70, 220)
    shirt(m, A, purple, h=a.bh * 0.8)
    for s in (-1, 1):
        for k in range(4):
            box(m, (s * (a.bw / 2 + CLOTH + 0.04), a.by - 0.6 + k * 0.4, a.btop + 0.05), (0.08, 0.12, 0.12), SILVER, "B", "Stud", studs=False)
    x = -(a.bw / 2 + CLOTH + 0.12)
    gfr = T(x, a.by - 0.2, a.bz) @ R(0.5, "X")
    box(m, (0, 0.5, 0), (0.25, 1.1, 0.9), (230, 40, 60), "B", "Guitar", fr=gfr)
    box(m, (0, -0.5, 0), (0.15, 1.5, 0.22), (60, 40, 30), "B", "Guitar", fr=gfr, studs=False)
    box(m, (0, -1.35, 0), (0.18, 0.35, 0.35), INK, "B", "Guitar", fr=gfr, studs=False)
    for k in range(3):
        box(m, (-0.14, 0.4 + k * 0.25, 0.0), (0.04, 0.12, 0.7), SILVER, "B", "Guitar", fr=gfr, studs=False)
    glasses(m, A, frame=INK, lens=purple, kind="star", emit=0.3)
    fx(m, A, "orbit", "bolt", [(255, 230, 60), (190, 140, 255)], n=5, s=0.6, emit=2.0)


@cat("DJ", shape="Loaf", fur="b38cff", second="efe6ff", eyes="ffd23c")
def _dj(m, A):
    a = G(A)
    headphones(m, A, INK, (60, 255, 200), wide=0.1)
    cap(m, A, INK, back=True)
    b = held(m, A, -1)
    cyl(m, (b.x - 0.2, b.y, 1.0), 0.75, 0.08, INK, "L", "Record", axis="Y")
    cyl(m, (b.x - 0.2, b.y - 0.06, 1.0), 0.25, 0.08, (255, 80, 180), "L", "Record", axis="Y", emit=0.5)
    shirt(m, A, (40, 36, 48), h=0.9)
    box(m, (a.bw / 2 + CLOTH + 0.03, a.by, a.bz + 0.1), (0.06, 1.2, 0.2), (60, 255, 200), "B", "Neon", studs=False, emit=2.0)
    box(m, (-(a.bw / 2 + CLOTH + 0.03), a.by, a.bz + 0.1), (0.06, 1.2, 0.2), (255, 80, 180), "B", "Neon", studs=False, emit=2.0)
    fx(m, A, "ring", "", [(60, 255, 200), (255, 80, 180)], n=18, s=0.35, emit=3.0, z=(0.15,))


@cat("Football Star", shape="Slim", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="socks")
def _football(m, A):
    a = G(A)
    shirt(m, A, None, stripes=[(40, 160, 80), WHITE, (40, 160, 80), WHITE], h=a.bh * 0.85)
    side_mark(m, A, (40, 160, 80), [(0.0, 0.05, 0.22, 0.75), (-0.12, 0.3, 0.2, 0.2)])
    b = held(m, A, -1)
    ball(m, (b.x + 0.1, b.y - 0.5, 0.45), 0.45, WHITE, "L", "FBall")
    for (dx, dz) in ((0, 0.45), (0.3, 0.2), (-0.3, 0.2), (0.2, -0.15), (-0.2, -0.15)):
        box(m, (b.x + 0.1 + dx * 0.9, b.y - 0.92, 0.45 + dz * 0.9), (0.2, 0.06, 0.2), INK, "L", "FBall", studs=False)
    headband(m, A, (40, 160, 80), knot=False, tails=False)


@cat("Boxer", shape="Loaf", fur="e8503a", second="ffe0d0", eyes="ffd23c", pattern="tabby", patternColor="b03020")
def _boxer(m, A):
    a = G(A)
    red = (220, 30, 40)
    for i in (0, 2):
        p = a.paws[i]
        box(m, (p.x, p.y - 0.45, 0.6), (1.2, 1.3, 1.15), red, "L", "Glove")
        box(m, (p.x, p.y - 0.45, 0.0 + 0.1), (1.0, 1.0, 0.2), WHITE, "L", "Glove", studs=False)
    plate(m, (0, a.by, a.leg + 0.4), (a.bw + 0.44, a.bl + 0.44, 0.75), (40, 70, 200), "B", "Shorts")
    belt(m, A, WHITE, buckle=GOLD, z=a.leg + 0.8)
    headband(m, A, WHITE, knot=False, tails=False)


@cat("Diver", shape="Loaf", fur="ffd24a", second="fff4cc", eyes="3c96ff")
def _diver(m, A):
    a = G(A)
    goggles(m, A, INK, (120, 220, 255), up=False)
    box(m, (a.hw / 2 + 0.1, a.hy - 0.3, a.hz + 0.6), (0.2, 0.2, 1.6), (255, 140, 40), "H", "Snorkel", studs=False)
    shirt(m, A, (40, 120, 200), h=a.bh * 0.85)
    for x in (-1, 1):
        cyl(m, (x * 0.45, a.bback + 0.25, a.btop + 0.3), 0.38, 1.6, (255, 210, 40), "B", "Tank")
    for i in (1, 3):
        p = a.paws[i]
        box(m, (p.x, p.y + 0.5, 0.08), (0.95, 1.6, 0.14), (40, 160, 220), "L", "Fin", studs=False)
    fx(m, A, "rise", "bubble", [(200, 240, 255)], n=8, s=0.4, emit=0.2, z=(1.5, 5.0))


@cat("Pilot", shape="Slim", fur="b07a4a", second="f6e2c8", eyes="3c96ff")
def _pilot(m, A):
    a = G(A)
    leather = (120, 75, 45)
    remove(m, ("Ear", "EarIn"))
    box(m, (0, a.hy + 0.1, a.top + 0.1), (a.hw + 0.26, a.hd + 0.1, 0.4), leather, "H", "Cap")
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.12), a.hy + 0.1, a.hz - 0.1), (0.24, a.hd * 0.8, a.hh * 0.85), leather, "H", "Cap")
        box(m, (x * (a.hw / 2 + 0.12), a.hy + 0.1, a.hz - 0.1), (0.3, 0.6, 0.6), shade(leather, 0.8), "H", "Flap", studs=False)
    goggles(m, A, leather, (255, 200, 80), up=True)
    shirt(m, A, (140, 90, 55), h=a.bh * 0.8)
    scarf(m, A, [WHITE, (240, 240, 245)])
    box(m, (-0.6, a.bfront - CLOTH - 0.06, a.bz + 0.3), (0.5, 0.06, 0.2), GOLD, "B", "Wings", studs=False)


@cat("Builder", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="52d273", pattern="socks")
def _builder(m, A):
    a = G(A)
    yel, org = (255, 205, 40), (255, 130, 30)
    ears_out(m, A)
    stack(m, (0, a.hy, a.top), a.hw * 0.9, a.hw * 0.55, 0.75, 3, yel, d0=a.hd * 0.9, d1=a.hd * 0.55)
    plate(m, (0, a.hy - 0.2, a.top + 0.06), (a.hw * 1.05, a.hd * 1.2, 0.12), yel, "H", "Brim")
    box(m, (0, a.hy, a.top + 0.8), (0.24, a.hd * 0.6, 0.16), shade(yel, 0.85), "H", "Ridge", studs=False)
    shirt(m, A, org, h=a.bh * 0.75)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + CLOTH + 0.03), a.by, a.bz + 0.1), (0.06, a.bl + 0.3, 0.2), (230, 235, 240), "B", "Stripe", studs=False, emit=0.4)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 0.75), 0.1, 1.5, WOOD, "L", "Hammer")
    box(m, (b.x, b.y, 1.55), (0.3, 0.75, 0.3), (120, 125, 140), "L", "Hammer", studs=False)


@cat("Farmer", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="tabby", patternColor="d9681f")
def _farmer(m, A):
    a = G(A)
    straw = (240, 205, 120)
    brim_hat(m, A, straw, band=(220, 50, 50), brim=1.5, h=0.65, cw=0.62)
    overall(m, A, (70, 110, 180))
    shirt(m, A, (220, 60, 60), h=0.55)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.2), 0.08, 2.4, WOOD, "L", "Rake")
    box(m, (b.x, b.y, 2.4), (0.15, 0.9, 0.15), (120, 125, 140), "L", "Rake", studs=False)
    for k in range(4):
        box(m, (b.x, b.y - 0.35 + k * 0.23, 2.62), (0.08, 0.08, 0.3), (120, 125, 140), "L", "Rake", studs=False)
    b2 = held(m, A, 1)
    for k in range(6):
        box(m, (b2.x + 0.2, b2.y, 0.45), (0.85, 0.3, 0.8), (255, 140, 30), "L", "Pumpkin", fr=about((b2.x + 0.2, b2.y, 0.45), R(k * 0.524, "Z")))
    box(m, (b2.x + 0.2, b2.y, 1.0), (0.12, 0.12, 0.3), (80, 150, 60), "L", "Pumpkin", studs=False)


@cat("Magician", shape="Slim", fur="2e2a36", second="ffffff", eyes="7ed957", pattern="tuxedo")
def _magician(m, A):
    a = G(A)
    ears_out(m, A)
    hat_top = top_hat(m, A, BLACK, (200, 40, 50), h=1.2, w=0.6)
    for x in (-1, 1):
        box(m, (x * 0.22, a.hy, hat_top + 0.45), (0.22, 0.18, 0.7), WHITE, "H", "Rabbit")
    box(m, (0, a.hy, hat_top + 0.12), (0.7, 0.55, 0.3), WHITE, "H", "Rabbit")
    cape(m, A, BLACK, inner=(200, 40, 50), collar_up=True)
    bow_tie_col = (200, 40, 50)
    from catparts import bow_tie
    bow_tie(m, A, bow_tie_col)
    tp = stick(m, A, INK, h=1.9, r=0.1, top=None)
    box(m, tp, (0.22, 0.22, 0.3), WHITE, "L", "WandTip", studs=False)
    fx(m, A, "orbit", "spark", [(255, 240, 170), (255, 120, 200), (120, 200, 255)], n=8, s=0.4, emit=2.5)


@cat("Circus Star", shape="Loaf", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="calico", patternColor="ffb066", third="5a5060")
def _circus(m, A):
    a = G(A)
    red = (210, 35, 50)
    top_hat(m, A, red, GOLD, h=1.0, w=0.55)
    shirt(m, A, red, h=a.bh * 0.85)
    for z in (-0.25, 0.15, 0.55):
        for x in (-0.3, 0.3):
            box(m, (x, a.bfront - CLOTH - 0.06, a.bz + z), (0.18, 0.06, 0.18), GOLD, "B", "Button", studs=False)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + CLOTH + 0.03), a.by, a.btop + 0.05), (0.08, a.bl + 0.3, 0.2), GOLD, "B", "Trim", studs=False)
    for k, c in enumerate(((255, 80, 80), (70, 170, 255), (255, 210, 50))):
        ball(m, (-0.9 + k * 0.9, a.front - 0.6, a.top + 0.9 + (k % 2) * 0.5), 0.3, c, "Fx", "Juggle")


@cat("Princess", shape="Fluffy", fur="ffd0e4", second="fff6fa", eyes="5ab0ff", blush=True)
def _princess(m, A):
    a = G(A)
    crown(m, A, GOLD, gems=((255, 90, 150),), w=0.5, h=0.35, tips=3)
    skirt(m, A, (255, 140, 190), layers=3, wide=0.6, col2=(255, 190, 220))
    shirt(m, A, (255, 140, 190), h=0.9)
    necklace(m, A, (255, 245, 235), n=9, r=0.13)
    tp = stick(m, A, GOLD, h=2.2, r=0.08, top="star", top_col=(255, 140, 200))
    fx(m, A, "orbit", "spark", [(255, 150, 210), (255, 220, 240)], n=8, s=0.4, emit=2.5)


@cat("Prince", shape="Slim", fur="ffe6bc", second="fffaf0", eyes="3c96ff")
def _prince(m, A):
    a = G(A)
    crown(m, A, GOLD, gems=((70, 170, 255), (255, 70, 110), (70, 170, 255)), w=0.65, h=0.4, tips=5)
    shirt(m, A, (60, 120, 230), h=a.bh * 0.85)
    cape(m, A, (200, 30, 50), inner=WHITE)
    sash(m, A, GOLD)
    sword(m, A, guard=GOLD, hilt=(60, 120, 230))


@cat("Archer", shape="Slim", fur="b07a4a", second="f6e2c8", eyes="52d273", pattern="mackerel", patternColor="6a4628")
def _archer(m, A):
    a = G(A)
    green = (60, 140, 60)
    ears_out(m, A)
    fr = about((0, a.hy, a.top), R(0.2, "Y"))
    wedge(m, (0, a.hy, a.top + 0.4), (a.hw * 0.8, a.hd * 0.9, 0.8), green, "H", "Hat", fr=fr)
    box(m, (a.hw * 0.25, a.hy + 0.2, a.top + 0.9), (0.12, 0.9, 0.14), (230, 50, 50), "H", "Feather", studs=False,
        fr=fr @ about((a.hw * 0.25, a.hy + 0.2, a.top + 0.9), R(-0.5, "X")))
    shirt(m, A, green, h=a.bh * 0.85)
    belt(m, A, (110, 70, 40))
    b = held(m, A, -1)
    arc(m, (b.x + 0.4, b.y, 1.3), 1.1, math.pi * 0.6, math.pi * 1.4, 9, (0.16, 0.16, 0.42), WOOD)
    box(m, (b.x - 0.14, b.y, 1.3), (0.03, 0.03, 1.85), WHITE, "L", "String", studs=False)
    cyl(m, (0.5, a.bback, a.btop + 0.6), 0.32, 1.4, (120, 75, 45), "B", "Quiver", fr=about((0.5, a.bback, a.btop), R(0.4, "X")))
    for k in range(3):
        box(m, (0.4 + k * 0.1, a.bback + 0.25, a.btop + 1.4), (0.1, 0.1, 0.45), (230, 50, 50), "B", "Arrow", studs=False,
            fr=about((0.5, a.bback, a.btop), R(0.4, "X")))


@cat("Explorer", shape="Loaf", fur="ffe6bc", second="fffaf0", eyes="52d273", pattern="tabby", patternColor="e0b880")
def _explorer(m, A):
    a = G(A)
    khaki = (205, 185, 130)
    ears_out(m, A)
    plate(m, (0, a.hy, a.top + 0.06), (a.hw * 1.15, a.hd * 1.2, 0.12), khaki, "H", "Brim")
    stack(m, (0, a.hy, a.top + 0.1), a.hw * 0.8, a.hw * 0.45, 0.75, 3, khaki, d0=a.hd * 0.8, d1=a.hd * 0.45)
    box(m, (0, a.hy, a.top + 0.25), (a.hw * 0.82, a.hd * 0.82, 0.16), (130, 90, 50), "H", "Band", studs=False)
    shirt(m, A, khaki, h=a.bh * 0.8)
    for s in (-1, 1):
        box(m, (s * 0.4, a.bfront - CLOTH - 0.06, a.bz + 0.2), (0.45, 0.06, 0.4), shade(khaki, 0.85), "B", "Pocket", studs=False)
    for x in (-0.22, 0.22):
        cyl(m, (x, a.front - 0.3, a.hb - 0.3), 0.18, 0.55, INK, "H", "Binocular", axis="Y")


@cat("Scientist", shape="Fluffy", fur="9aa0ac", second="eef0f4", eyes="52d273", pattern="smoke")
def _scientist(m, A):
    a = G(A)
    coat(m, A, WHITE, trim=(200, 210, 220))
    goggles(m, A, (60, 60, 75), (160, 255, 170), up=True)
    glasses(m, A, frame=INK, lens=WHITE, kind="round")
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 0.8), 0.22, 1.2, (220, 240, 255), "L", "Tube", alpha=0.5, rough=0.02, coat=1.0)
    cyl(m, (b.x, b.y, 0.55), 0.2, 0.65, (90, 230, 110), "L", "Tube", emit=1.0)
    fx(m, A, "rise", "bubble", [(120, 255, 140)], n=6, s=0.35, emit=1.0, z=(1.2, 4.5))


@cat("Mail Cat", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="bib")
def _mail(m, A):
    a = G(A)
    blue, red = (40, 70, 170), (220, 40, 50)
    cap(m, A, blue, back=False, logo=red)
    shirt(m, A, blue, h=a.bh * 0.8)
    box(m, (a.bw / 2 + CLOTH + 0.25, a.by - 0.2, a.bz - 0.2), (0.45, 1.3, 1.0), (150, 100, 55), "B", "Bag")
    box(m, (a.bw / 2 + CLOTH + 0.25, a.by - 0.2, a.bz + 0.35), (0.5, 1.35, 0.25), (130, 85, 45), "B", "Bag", studs=False)
    box(m, (a.bw / 2 + CLOTH + 0.3, a.by - 0.2, a.bz + 0.55), (0.12, 0.8, 0.5), WHITE, "B", "Letter", studs=False)
    box(m, (a.bw / 2 + CLOTH + 0.37, a.by - 0.2, a.bz + 0.6), (0.04, 0.2, 0.15), red, "B", "Letter", studs=False)
    box(m, (0, a.by - 0.2, a.btop + 0.25), (a.bw + 0.6, 0.18, 0.08), (130, 85, 45), "B", "Strap", studs=False,
        fr=about((0, a.by - 0.2, a.bz), R(-0.4, "Y")))


@cat("Skater", shape="Slim", fur="ff9a3c", second="fff0d8", eyes="52d273", pattern="tiger", patternColor="b05010")
def _skater(m, A):
    a = G(A)
    under_board(m, A, (90, 200, 110), wheels=(255, 210, 50), z=-0.42)
    ears_out(m, A)
    stack(m, (0, a.hy, a.top), a.hw * 0.95, a.hw * 0.65, 0.7, 2, (255, 120, 40), d0=a.hd * 0.95, d1=a.hd * 0.65)
    for i in (0, 2):
        p = a.paws[i]
        box(m, (p.x, p.y - 0.06, a.leg * 0.6), (1.08, 1.08, 0.35), INK, "L", "Pad")


@cat("Surfer", shape="Slim", fur="9fd2ff", second="e8f5ff", eyes="ffb020", pattern="socks")
def _surfer(m, A):
    a = G(A)
    b = held(m, A, -1)
    fr = T(b.x - 0.3, b.y + 0.6, 1.8) @ R(0.2, "Y")
    box(m, (0, 0, 0), (0.25, 1.2, 3.6), (255, 210, 50), "L", "Surf", fr=fr)
    box(m, (0.13, 0, 0), (0.04, 0.25, 3.4), (255, 90, 120), "L", "Surf", fr=fr, studs=False)
    plate(m, (0, a.by, a.leg + 0.4), (a.bw + 0.44, a.bl + 0.44, 0.7), (60, 170, 230), "B", "Shorts")
    for s in (-1, 1):
        flower(m, (s * (a.bw / 2 + CLOTH + 0.05), a.by, a.leg + 0.45), 0.5, WHITE, bone="B", fr=about((s * (a.bw / 2 + CLOTH + 0.05), a.by, a.leg + 0.45), R(s * math.pi / 2, "Y")))
    glasses(m, A, frame=(255, 120, 40), lens=(40, 60, 90), kind="square")
    fx(m, A, "ground", "drop", [(150, 220, 255)], n=7, s=0.4, emit=0.3)


@cat("Ski Racer", shape="Fluffy", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="masked", patternColor="9aa0ac")
def _ski(m, A):
    a = G(A)
    red = (220, 40, 50)
    for x in (-1, 1):
        px = x * (a.bw / 2 - 0.45)
        plate(m, (px, a.by - 0.3, -0.07), (0.7, a.bl + 2.6, 0.14), red, "L", "Ski")
        wedge(m, (px, a.by - a.bl / 2 - 1.55, 0.08), (0.7, 0.3, 0.3), red, "L", "Ski", fr=about((px, a.by - a.bl / 2 - 1.55, 0.08), R(math.pi, "Z")))
    beanie(m, A, red, band=WHITE, pom=WHITE)
    goggles(m, A, INK, (255, 160, 40), up=False)
    for s in (-1, 1):
        b = held(m, A, s)
        cyl(m, (b.x, b.y, 1.1), 0.07, 2.2, SILVER, "L", "Pole", fr=about((b.x, b.y, 0), R(-s * 0.15, "Y")))
        cyl(m, (b.x, b.y, 0.2), 0.25, 0.06, INK, "L", "Pole")
    shirt(m, A, red, h=a.bh * 0.8)
    fx(m, A, "ground", "flake", [WHITE, (220, 240, 255)], n=7, s=0.4, emit=0.4)


@cat("Ballerina", shape="Slim", fur="ffd0e4", second="fff6fa", eyes="3c96ff", blush=True)
def _ballerina(m, A):
    a = G(A)
    pink = (255, 150, 200)
    skirt(m, A, (255, 200, 225), layers=3, wide=0.65, col2=WHITE)
    shirt(m, A, pink, h=0.9)
    for p in a.paws:
        box(m, (p.x, p.y - 0.06, 0.25), (1.06, 1.12, 0.45), pink, "L", "Shoe")
        box(m, (p.x, p.y - 0.06, 0.75), (1.04, 1.04, 0.1), pink, "L", "Ribbon", studs=False)
    crown(m, A, (230, 230, 245), gems=((255, 150, 200),), w=0.45, h=0.25, tips=3)


@cat("Superhero", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="tabby", patternColor="d9681f")
def _superhero(m, A):
    a = G(A)
    blue, red = (40, 80, 200), (220, 30, 45)
    shirt(m, A, blue, h=a.bh * 0.85)
    cape(m, A, red, long=1.15)
    mask_band(m, A, red)
    belt(m, A, GOLD, buckle=red)
    from catparts import heart as _h
    c = (0, a.bfront - CLOTH - 0.08, a.bz + 0.2)
    box(m, c, (0.5, 0.06, 0.4), GOLD, "B", "Logo", studs=False)
    for k in range(3):
        box(m, (-0.25 + k * 0.25, c[1] - 0.01, c[2] + 0.35), (0.16, 0.06, 0.16), GOLD, "B", "Logo", studs=False)
    boots(m, A, red, h=0.5)


@cat("Royal Guard", shape="Slim", fur="2b2733", second="ffffff", eyes="7ed957", pattern="tuxedo")
def _guard(m, A):
    a = G(A)
    ears_out(m, A)
    box(m, (0, a.hy, a.top + 1.0), (a.hw * 0.75, a.hd * 0.75, 2.0), (25, 22, 30), "H", "Bearskin")
    box(m, (0, a.hy, a.top + 2.05), (a.hw * 0.6, a.hd * 0.6, 0.2), (25, 22, 30), "H", "Bearskin")
    box(m, (0, a.front - 0.1, a.hb + 0.05), (0.2, 0.12, 0.3), GOLD, "H", "Strap", studs=False)
    shirt(m, A, (210, 30, 40), h=a.bh * 0.9)
    belt(m, A, WHITE, buckle=GOLD)
    for z in (-0.2, 0.15, 0.5):
        box(m, (0, a.bfront - CLOTH - 0.06, a.bz + z), (0.16, 0.06, 0.16), GOLD, "B", "Button", studs=False)
    b = held(m, A, 1)
    cyl(m, (b.x + 0.3, b.y, 0.75), 0.6, 0.8, (210, 30, 40), "L", "Drum")
    cyl(m, (b.x + 0.3, b.y, 1.17), 0.62, 0.08, WHITE, "L", "Drum")
    cyl(m, (b.x + 0.3, b.y, 0.33), 0.62, 0.08, GOLD, "L", "Drum")


@cat("Kung Fu", shape="Slim", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="spots", patternColor="2f2a36", seed=11)
def _kungfu(m, A):
    a = G(A)
    yel = (255, 205, 40)
    shirt(m, A, yel, h=a.bh * 0.9)
    belt(m, A, INK, buckle=INK)
    box(m, (0.6, a.bfront - CLOTH - 0.1, a.leg + 0.0), (0.2, 0.08, 0.7), INK, "B", "Belt", studs=False)
    headband(m, A, (220, 40, 50))
    for x in (-0.4, 0.4):
        box(m, (x, a.bfront - CLOTH - 0.06, a.bz + 0.2), (0.3, 0.06, 0.1), INK, "B", "Knot", studs=False)
    cuffs(m, A, INK)


@cat("Sumo", shape="Fluffy", chubby=True, fur="ffe6bc", second="fffaf0", eyes="52d273", eyeStyle="sleepy")
def _sumo(m, A):
    a = G(A)
    white = (250, 248, 240)
    plate(m, (0, a.by, a.leg + 0.3), (a.bw + 0.44, a.bl + 0.44, 0.6), white, "B", "Mawashi")
    box(m, (0, a.bfront - CLOTH - 0.06, a.leg + 0.1), (0.6, 0.12, 0.8), white, "B", "Mawashi", studs=False)
    for k in range(4):
        box(m, (-0.45 + k * 0.3, a.bfront - CLOTH - 0.1, a.leg - 0.3), (0.16, 0.06, 0.5), white, "B", "Fringe", studs=False)
    box(m, (0, a.hy + 0.2, a.top + 0.25), (0.6, 0.9, 0.5), INK, "H", "Topknot")
    box(m, (0, a.hy - 0.15, a.top + 0.6), (0.4, 0.5, 0.3), INK, "H", "Topknot")


@cat("Racer", shape="Slim", fur="a8adb8", second="eef0f4", eyes="3c96ff")
def _racer(m, A):
    a = G(A)
    red = (220, 30, 45)
    helmet(m, A, red, visor=(40, 50, 70))
    box(m, (0, a.front - 0.12, a.eyes[0].z), (a.hw * 0.85, 0.12, 0.7), (40, 60, 100), "H", "Visor", studs=False, rough=0.05, coat=1.0)
    box(m, (0, a.hy, a.top + 0.5), (0.4, a.hd + 0.3, 0.06), WHITE, "H", "Stripe", studs=False)
    shirt(m, A, red, h=a.bh * 0.85)
    side_mark(m, A, WHITE, [(0.0, 0.0, 0.8, 0.8)])
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.2), 0.07, 2.4, SILVER, "L", "Flag")
    for i in range(3):
        for j in range(4):
            box(m, (b.x - 0.05, b.y - 0.15 - j * 0.25, 2.2 - i * 0.25), (0.05, 0.25, 0.25), INK if (i + j) % 2 else WHITE, "L", "Flag", studs=False)


@cat("Gardener", shape="Loaf", fur="a6d98a", second="f0fae8", eyes="b06cff")
def _gardener(m, A):
    a = G(A)
    straw = (230, 200, 130)
    brim_hat(m, A, straw, band=(90, 170, 80), brim=1.45, h=0.6, cw=0.6)
    flower(m, (a.hw * 0.3, a.hy - a.hd * 0.32, a.top + 0.45), 0.55, (255, 120, 160), fr=about((a.hw * 0.3, a.hy - a.hd * 0.32, a.top + 0.45), R(math.pi / 2, "X")))
    plate(m, (0, a.by, a.leg + 0.55), (a.bw + 0.44, a.bl + 0.44, 1.1), (140, 95, 55), "B", "Apron")
    b = held(m, A, -1)
    box(m, (b.x, b.y, 0.55), (0.75, 0.9, 0.9), (70, 160, 220), "L", "Can")
    box(m, (b.x, b.y - 0.75, 0.75), (0.16, 0.8, 0.16), (70, 160, 220), "L", "Can", studs=False,
        fr=about((b.x, b.y - 0.4, 0.55), R(-0.5, "X")))
    box(m, (b.x, b.y + 0.5, 1.0), (0.14, 0.14, 0.6), (50, 130, 190), "L", "Can", studs=False)
    fx(m, A, "orbit", "leaf", [(90, 190, 80), (150, 220, 90)], n=7, s=0.5, emit=0.2)


@cat("Fisher", shape="Loaf", fur="a8adb8", second="eef0f4", eyes="3c96ff", pattern="tabby", patternColor="6a7080")
def _fisher(m, A):
    a = G(A)
    yel = (255, 210, 40)
    ears_out(m, A)
    stack(m, (0, a.hy, a.top), a.hw * 0.85, a.hw * 0.55, 0.65, 2, yel, d0=a.hd * 0.85, d1=a.hd * 0.55)
    plate(m, (0, a.hy + 0.35, a.top + 0.02), (a.hw * 1.15, a.hd * 1.5, 0.12), yel, "H", "Brim")
    coat(m, A, (40, 70, 170))
    boots(m, A, yel, h=0.5)
    b = held(m, A, -1)
    fr = T(b.x, b.y, 0.0) @ R(-0.45, "Y")
    cyl(m, (0, 0, 1.6), 0.07, 3.2, WOOD, "L", "Rod", fr=fr)
    cyl(m, (0.15, 0, 0.6), 0.16, 0.18, SILVER, "L", "Rod", fr=fr, axis="X")
    tip = fr @ T(0, 0, 3.2)
    from mathutils import Vector
    t = tip @ Vector((0, 0, 0))
    box(m, (t.x, t.y, t.z - 0.8), (0.03, 0.03, 1.6), WHITE, "L", "Line", studs=False)
    box(m, (t.x, t.y, t.z - 1.75), (0.18, 0.7, 0.35), (120, 190, 230), "L", "Fish", studs=False)


@cat("Lumberjack", shape="Fluffy", fur="b07a4a", second="f6e2c8", eyes="52d273", pattern="tabby", patternColor="7a5030")
def _lumberjack(m, A):
    a = G(A)
    red, dark = (200, 40, 45), (40, 30, 30)
    shirt(m, A, red, h=a.bh * 0.85)
    for s in (-1, 1):
        x = s * (a.bw / 2 + CLOTH + 0.03)
        for u in (-0.3, 0.0, 0.3):
            box(m, (x, a.by + u * a.bl, a.btop - a.bh * 0.3), (0.06, 0.22, a.bh * 0.9), dark, "B", "Check", studs=False)
        for v in (-0.3, 0.2):
            box(m, (x * 1.01, a.by, a.btop - a.bh * 0.3 + v), (0.06, a.bl + 0.3, 0.2), dark, "B", "Check", studs=False)
    beanie(m, A, (60, 60, 70), band=(40, 40, 50), pom=None)
    box(m, (0, a.front - 0.3, a.mz - 0.5), (1.5, 0.4, 0.8), (110, 70, 40), "H", "Beard")
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.0), 0.1, 2.0, WOOD, "L", "Axe")
    box(m, (b.x - 0.35, b.y, 1.75), (0.6, 0.14, 0.6), (190, 196, 210), "L", "Axe", studs=False)
    box(m, (b.x - 0.08, b.y, 1.75), (0.2, 0.16, 0.6), (200, 40, 45), "L", "Axe", studs=False)


@cat("Barista", shape="Slim", fur="b07a4a", second="f6e2c8", eyes="3c96ff", pattern="bib")
def _barista(m, A):
    a = G(A)
    cap(m, A, (60, 40, 30), back=True)
    shirt(m, A, (245, 235, 215), h=a.bh * 0.85)
    box(m, (0, a.bfront - CLOTH - 0.06, a.bz - 0.1), (a.bw * 0.75, 0.08, a.bh * 0.9), (90, 60, 40), "B", "Apron", studs=False)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 0.6), 0.32, 0.8, WHITE, "L", "Cup", r2=0.4)
    cyl(m, (b.x, b.y, 1.05), 0.42, 0.12, (90, 60, 40), "L", "Cup")
    box(m, (b.x, b.y - 0.32, 0.6), (0.4, 0.06, 0.3), (110, 70, 45), "L", "Cup", studs=False)
    fx(m, A, "above", "cloud", [(240, 240, 245)], n=2, s=0.4, emit=0.1)


@cat("Baker", shape="Fluffy", fur="d8a060", second="fff0d8", eyes="3c96ff", pattern="bib")
def _baker(m, A):
    a = G(A)
    ears_out(m, A)
    cyl(m, (0, a.hy, a.top + 0.35), a.hw * 0.34, 0.7, WHITE, "H", "Hat")
    for x, y in ((-0.4, 0), (0.4, 0), (0, 0.35), (0, -0.35)):
        ball(m, (x, a.hy + y, a.top + 0.85), 0.5, WHITE, "H", "Hat")
    plate(m, (0, a.by, a.leg + 0.6), (a.bw + 0.44, a.bl + 0.44, 1.2), (150, 100, 55), "B", "Apron")
    b = held(m, A, -1)
    fr = T(b.x, b.y, 1.2) @ R(0.35, "Y")
    cyl(m, (0, 0, 0), 0.28, 2.2, (220, 160, 80), "L", "Bread", fr=fr)
    for k in range(4):
        box(m, (0.26, 0, -0.75 + k * 0.5), (0.06, 0.35, 0.12), (250, 220, 160), "L", "Bread", fr=fr, studs=False)


@cat("Teacher", shape="Slim", fur="a8adb8", second="eef0f4", eyes="52d273", pattern="mackerel", patternColor="5a5e6a")
def _teacher(m, A):
    a = G(A)
    glasses(m, A, frame=(130, 80, 40), lens=WHITE, kind="round")
    shirt(m, A, (90, 160, 90), h=a.bh * 0.85)
    collar(m, A, WHITE, h=0.22)
    b = held(m, A, -1)
    box(m, (b.x - 0.1, b.y + 0.2, 1.0), (0.18, 1.6, 1.1), (40, 90, 60), "L", "Board")
    box(m, (b.x - 0.1, b.y + 0.2, 1.0), (0.22, 1.75, 1.25), (150, 100, 55), "L", "Board", studs=False)
    for k, ww in enumerate((0.9, 0.6, 1.0)):
        box(m, (b.x - 0.22, b.y + 0.2, 1.3 - k * 0.25), (0.04, ww, 0.08), WHITE, "L", "Chalk", studs=False)
    b2 = held(m, A, 1)
    cyl(m, (b2.x, b2.y, 1.0), 0.05, 2.0, WOOD, "L", "Pointer", fr=about((b2.x, b2.y, 0), R(-0.3, "Y")))


@cat("Hula Dancer", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", blush=True)
def _hula(m, A):
    a = G(A)
    for k in range(20):
        ang = k * 2 * math.pi / 20
        x, y = math.cos(ang) * (a.bw / 2 + 0.3), a.by + math.sin(ang) * (a.bl / 2 + 0.3)
        box(m, (x, y, a.leg + 0.25), (0.18, 0.4, 0.9), (110, 180, 70) if k % 2 else (150, 205, 90), "B", "Grass", studs=False,
            fr=about((x, y, a.leg + 0.25), R(ang, "Z")))
    plate(m, (0, a.by, a.leg + 0.75), (a.bw + 0.44, a.bl + 0.44, 0.22), (230, 200, 120), "B", "Grass")
    lei(m, A, [(255, 110, 150), (255, 220, 70), (255, 150, 60), WHITE])
    flower(m, (-a.hw / 2 + 0.3, a.hy - 0.3, a.top + 0.2), 0.8, (255, 110, 150), fr=about((-a.hw / 2 + 0.3, a.hy - 0.3, a.top + 0.2), R(math.pi / 2, "X")))


@cat("Ranger", shape="Slim", fur="b07a4a", second="f6e2c8", eyes="52d273", pattern="dorsal", patternColor="7a5030")
def _ranger(m, A):
    a = G(A)
    olive = (70, 100, 60)
    brim_hat(m, A, (150, 115, 70), band=(80, 55, 35), brim=1.5, h=0.75, cw=0.6)
    shirt(m, A, olive, h=a.bh * 0.85)
    star(m, (0, 0, 0), 0.4, GOLD, "B", emit=0.2, fr=T(-0.45, a.bfront - CLOTH - 0.08, a.bz + 0.2))
    cyl(m, (a.bw / 2 + CLOTH + 0.3, a.by - 0.1, a.bz - 0.2), 0.42, 0.3, (120, 125, 140), "B", "Canteen", axis="X")
    cyl(m, (a.bw / 2 + CLOTH + 0.3, a.by - 0.1, a.bz + 0.3), 0.1, 0.2, INK, "B", "Canteen")
    belt(m, A, (90, 60, 40))


@cat("Treasure Hunter", shape="Loaf", fur="b07a4a", second="f6e2c8", eyes="ffd23c", pattern="tabby", patternColor="7a5030")
def _treasure(m, A):
    a = G(A)
    headband(m, A, (220, 40, 50))
    shirt(m, A, (230, 215, 170), h=a.bh * 0.75)
    belt(m, A, (90, 60, 40))
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.0), 0.08, 2.0, WOOD, "L", "Shovel")
    box(m, (b.x, b.y, 0.25), (0.55, 0.12, 0.6), (150, 155, 170), "L", "Shovel", studs=False)
    b2 = held(m, A, 1)
    box(m, (b2.x + 0.3, b2.y, 0.4), (0.9, 0.7, 0.7), (140, 90, 45), "L", "Chest")
    box(m, (b2.x + 0.3, b2.y, 0.85), (0.92, 0.72, 0.3), (120, 75, 40), "L", "Chest")
    box(m, (b2.x + 0.3, b2.y - 0.37, 0.65), (0.2, 0.06, 0.25), GOLD, "L", "Chest", studs=False)
    for k in range(4):
        cyl(m, (b2.x + 0.1 + k * 0.15, b2.y, 1.05 + (k % 2) * 0.05), 0.12, 0.05, GOLD, "L", "Coin")
    box(m, (0, a.by + 0.3, a.btop + 0.28), (1.0, 0.8, 0.06), (240, 220, 170), "B", "Map", studs=False)
    box(m, (0.2, a.by + 0.3, a.btop + 0.32), (0.18, 0.18, 0.04), (220, 40, 50), "B", "Map", studs=False)
    fx(m, A, "orbit", "spark", [GOLD, (255, 240, 170)], n=6, s=0.4, emit=2.5)


@cat("Thai Dancer", shape="Slim", fur="ffc85a", second="fff0c8", eyes="3c96ff", blush=True)
def _thaidancer(m, A):
    a = G(A)
    gold, red = GOLD, (200, 30, 45)
    remove(m, ("Ear", "EarIn"))
    box(m, (0, a.hy, a.top + 0.12), (a.hw * 0.9, a.hd * 0.9, 0.25), gold, "H", "Chada")
    end = stack(m, (0, a.hy, a.top + 0.25), a.hw * 0.6, 0.18, 2.4, 7, [gold, GOLD_DARK], d0=a.hd * 0.6, d1=0.18)
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.05), a.hy, a.hz + 0.2), (0.12, 0.5, 0.9), gold, "H", "Chada", studs=False)
        box(m, (x * (a.hw / 2 + 0.05), a.hy, a.hz + 0.2), (0.14, 0.2, 0.2), red, "H", "Gem", studs=False, emit=0.4)
    shirt(m, A, red, h=a.bh * 0.85)
    sash(m, A, gold)
    for k in range(3):
        box(m, (0, a.by, a.hb + 0.1 - k * 0.16), (a.hw * (0.9 - k * 0.1), a.hd * 0.85, 0.16), gold if k % 2 == 0 else red, "H", "Collar", studs=False)
    for i in (0, 2):
        p = a.paws[i]
        box(m, (p.x, p.y, a.leg * 0.5), (1.08, 1.08, 0.18), gold, "L", "Bangle", studs=False)
    fx(m, A, "orbit", "spark", [GOLD, (255, 240, 170)], n=7, s=0.4, emit=2.5)


for _name, _entry in DESIGNS.items():
    blockcat.DESIGNS[_name] = _entry
