"""Secret tier (round 2): gods and cosmic cats, the rarest; each with its own effect (cateffects by effectKey).
Cat God is in blockcat.py."""
import math
import random

from mathutils import Vector

import blockcat
from blockcat import GOLD, GOLD_DARK, INK, PINK, WHITE, shade
from cateffects import RAINBOW
from catparts import (BLACK, BROWN, CLOTH, SILVER, WOOD, C, G, about, armour, ball, beak, belt, box, cape, collar,
                      cone_hat, crown, cyl, ears_out, flower, glasses, goggles, headphones, held, helmet, mix, necklace,
                      plate, recolor, remove, ring, sash, shell, shirt, skirt, stack, star, stick, sword, tail_swap, wedge,
                      wings)
from cats_legendary import antennae, front_patch, marks, new_ears, side_patch
from cats_mythical import KEYS, cat as _mcat, glow_eyes, horns, mane, spikes
from kit import R, T

DESIGNS = {}


def cat(name, **look):
    def deco(fn):
        _mcat(name, **look)(fn)
        from cats_mythical import DESIGNS as M
        DESIGNS[name] = M.pop(name)
        return fn
    return deco


def disc_back(m, A, r, cols, n=16, ray=0.9, z=None, emit=2.0, centre=None, bone="B"):
    """A big disc behind the cat (sun, eclipse, wheel) with rays."""
    a = G(A)
    c = (0, a.bback + 0.6, (z if z is not None else a.btop + 1.2))
    fr = T(*c) @ R(math.pi / 2, "X")
    if centre:
        cyl(m, (0, 0, 0), r * 0.75, 0.2, centre, bone, "Disc", fr=fr, emit=emit * 0.5)
    for k in range(n):
        f = fr @ R(k * 2 * math.pi / n, "Z") @ T(r, 0, 0)
        box(m, (0, 0, 0), (ray, 0.35, 0.2), cols[k % len(cols)], bone, "Ray", fr=f, studs=False, emit=emit)


def tilted_ring(m, A, rr, n, s, cols, tilt=0.35, z=None, emit=1.5, name="Ring"):
    a = G(A)
    c = (0, a.by - 0.2, z if z is not None else a.bz + 0.3)
    fr = T(*c) @ R(tilt, "X") @ R(0.2, "Y")
    ring(m, (0, 0, 0), rr, n, s, cols, "B", name, fr=fr, emit=emit)


def quarters(m, A, cols, off=0.12):
    """Colour the body in four parts (front-left, front-right, back-left, back-right) with side and top panels."""
    a = G(A)
    for i, (sx, sy) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
        col = cols[i]
        box(m, (sx * (a.bw / 2 + off), a.by + sy * a.bl / 4, a.bz), (0.08, a.bl / 2 - 0.05, a.bh * 0.95), col, "B", "Quarter", studs=False)
        box(m, (sx * a.bw / 4, a.by + sy * a.bl / 4, a.btop + off), (a.bw / 2 - 0.05, a.bl / 2 - 0.05, 0.08), col, "B", "Quarter", studs=False)


# --------------------------------------------------------------------------------------------------------------------
@cat("Sun God Cat", shape="Fluffy", fur="ffc83a", second="fff4c8", eyes="ff8a20", eyeStyle="big", glowEyes=True)
def _sungod(m, A):
    disc_back(m, A, 2.0, [(255, 170, 30), (255, 220, 80)], n=16, ray=1.0, centre=(255, 210, 60))
    crown(m, A, GOLD, gems=((255, 90, 40),), w=0.7, h=0.45, tips=5, emit=0.3)
    necklace(m, A, GOLD, n=10, r=0.14, pendant=(255, 90, 40))


@cat("Moon Goddess Cat", shape="Slim", fur="e8ecf8", second="ffffff", eyes="3c60d0", eyeStyle="big")
def _moongoddess(m, A):
    a = G(A)
    for k in range(7):
        ang = math.pi * 0.15 + k * math.pi * 0.7 / 6
        box(m, (math.cos(ang) * 0.9 - 0.0, a.hy + 0.1, a.top + 0.3 + math.sin(ang) * 0.9), (0.42, 0.32, 0.42), (255, 235, 150), "H", "Moon",
            studs=False, emit=1.5)
    cape(m, A, (40, 60, 160), inner=(200, 210, 255), long=1.1)
    for k in range(6):
        star(m, (0, 0, 0), 0.3, (255, 240, 170), "B", emit=1.5,
             fr=T(-(a.bw / 2 + 0.33), a.by - 0.6 + (k % 3) * 0.6, a.bz + (k // 3) * 0.6 - 0.3) @ R(math.pi / 2, "Z"))


@cat("Star Emperor Cat", shape="Slim", fur="2a3a8a", second="8aa0e0", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _staremperor(m, A):
    a = G(A)
    cape(m, A, (20, 25, 70), inner=GOLD, collar_up=True, long=1.15)
    crown(m, A, GOLD, gems=((90, 160, 255), (255, 240, 170), (90, 160, 255)), w=0.7, h=0.45, tips=5)
    tp = stick(m, A, GOLD, h=2.6, top="star", top_col=(255, 230, 90))
    for k in range(5):
        star(m, (0, 0, 0), 0.32, (255, 230, 90), "B", emit=1.0,
             fr=T(a.bw / 2 + 0.52, a.by - 0.6 + k * 0.3, a.bz - 0.3 + (k % 2) * 0.5) @ R(math.pi / 2, "Z"))


@cat("Galaxy Cat", shape="Fluffy", fur="5a2a9a", second="c8a0f0", eyes="ffffff", eyeStyle="big")
def _galaxy(m, A):
    marks(m, A, 8, 0.9, [(220, 90, 200), (90, 120, 230)], seed=4, head=3, emit=0.6)
    marks(m, A, 18, 0.12, [(255, 255, 255), (255, 240, 170)], seed=8, head=6, off=0.14, emit=4.0)


@cat("Black Hole Cat", shape="Loaf", fur="1e1a24", second="2e2a36", eyes="b06cff", eyeStyle="big", glowEyes=True)
def _blackhole(m, A):
    a = G(A)
    tilted_ring(m, A, max(a.bw, a.bl) / 2 + 0.9, 28, (0.6, 0.5, 0.2), [(255, 150, 60), (255, 210, 120), (200, 90, 255)], tilt=0.35, emit=3.0)
    tilted_ring(m, A, max(a.bw, a.bl) / 2 + 0.4, 22, (0.4, 0.4, 0.15), [(150, 70, 255)], tilt=0.35, emit=3.0, name="Ring2")


@cat("Time Keeper Cat", shape="Slim", fur="ffd060", second="fff4d0", eyes="3c96ff")
def _timekeeper(m, A):
    a = G(A)
    b = held(m, A, -1)
    for z, w in ((0.15, 0.9), (1.75, 0.9)):
        box(m, (b.x, b.y, z), (w, w, 0.2), GOLD, "L", "Hourglass")
    for x in (-1, 1):
        for y in (-1, 1):
            cyl(m, (b.x + x * 0.38, b.y + y * 0.38, 0.95), 0.06, 1.6, GOLD, "L", "Hourglass")
    cyl(m, (b.x, b.y, 0.6), 0.35, 0.7, (200, 230, 255), "L", "Glass", r2=0.06, alpha=0.4)
    cyl(m, (b.x, b.y, 1.3), 0.06, 0.7, (200, 230, 255), "L", "Glass", r2=0.35, alpha=0.4)
    cyl(m, (b.x, b.y, 0.45), 0.25, 0.3, (255, 210, 120), "L", "Sand")
    cape(m, A, (40, 90, 180), inner=GOLD)
    cyl(m, (0, a.bfront - 0.15, a.bz + 0.1), 0.55, 0.1, (255, 245, 220), "B", "Clock", axis="Y", emit=0.4)
    for k in range(12):
        box(m, (0, 0, 0.45), (0.05, 0.04, 0.1), INK, "B", "Clock", studs=False, fr=T(0, a.bfront - 0.21, a.bz + 0.1) @ R(k * 0.524, "Y"))
    glasses(m, A, frame=GOLD, lens=WHITE, kind="round")


@cat("Thunder God Cat", shape="Fluffy", fur="ffffff", second="fff8e0", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _thundergod(m, A):
    a = G(A)
    helmet(m, A, SILVER)
    for x in (-1, 1):
        for k in range(3):
            box(m, (x * (a.hw / 2 + 0.4 + k * 0.25), a.hy + 0.2 + k * 0.1, a.top + 0.1 + k * 0.3), (0.5, 0.15, 0.35 - k * 0.05), WHITE, "H", "Wing",
                studs=False, fr=about((x * (a.hw / 2), a.hy, a.top), R(-x * 0.3, "Y")))
    cape(m, A, (210, 30, 40), inner=(150, 20, 30))
    armour(m, A, (190, 196, 210), trim=(255, 210, 60))
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 0.6), 0.1, 1.2, WOOD, "L", "Hammer")
    box(m, (b.x, b.y, 1.4), (0.9, 1.4, 0.75), (170, 176, 190), "L", "Hammer")
    box(m, (b.x - 0.47, b.y, 1.4), (0.06, 0.5, 0.4), (255, 230, 60), "L", "Bolt", studs=False, emit=2.0)


@cat("Ocean God Cat", shape="Slim", fur="2a6ac8", second="a8d8ff", eyes="ffd23c")
def _oceangod(m, A):
    a = G(A)
    coral = [(255, 120, 120), (255, 170, 90), (255, 110, 170)]
    for k in range(5):
        x = -0.8 + k * 0.4
        h = 0.6 + (k % 2) * 0.5
        box(m, (x, a.hy - 0.1, a.top + h / 2), (0.22, 0.22, h), coral[k % 3], "H", "Coral", studs=False)
        box(m, (x + 0.15, a.hy - 0.1, a.top + h * 0.7), (0.3, 0.18, 0.18), coral[k % 3], "H", "Coral", studs=False)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.5), 0.08, 3.0, GOLD, "L", "Trident")
    box(m, (b.x, b.y, 3.0), (0.9, 0.15, 0.15), GOLD, "L", "Trident", studs=False)
    for x in (-0.4, 0.0, 0.4):
        stack(m, (b.x + x, b.y, 3.05), 0.16, 0.06, 0.55, 3, GOLD, "L", "Trident", studs=False)
    sash(m, A, GOLD)
    marks(m, A, 6, 0.4, [(255, 240, 220), (255, 200, 210)], where=("left", "right"), seed=3)


@cat("Earth Titan Cat", shape="Fluffy", big=True, fur="8a5a34", second="c8a070", eyes="7ed957")
def _earthtitan(m, A):
    a = G(A)
    stack(m, (-0.3, a.bback - 0.6, a.btop - 0.1), a.bw * 1.05, 0.3, 4.8, 8, [(130, 130, 140), (120, 120, 130), (130, 130, 140), (150, 150, 160), (140, 140, 150), (150, 150, 160), WHITE, WHITE], "B", "Mountain",
          d0=a.bl * 0.55, d1=0.3)
    for x, y in ((-0.9, 1.2), (1.0, -0.1), (-0.8, -0.3)):
        cyl(m, (x, a.by + y, a.btop + 0.3), 0.12, 0.6, (110, 75, 45), "B", "Tree")
        stack(m, (x, a.by + y, a.btop + 0.5), 0.8, 0.2, 1.0, 3, [(60, 150, 60), (80, 180, 70)], "B", "Tree")
    marks(m, A, 6, 0.6, [(80, 170, 70), (110, 190, 80)], where=("left", "right"), seed=2)


@cat("Fire Emperor Cat", shape="Fluffy", fur="d8302a", second="ffd080", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _fireemperor(m, A):
    a = G(A)
    crown(m, A, GOLD, gems=((255, 120, 30),), w=0.7, h=0.4, tips=5)
    for k in range(5):
        x = -0.8 + k * 0.4
        m.blob((0.22, 0.22, 0.55 + (k % 2) * 0.2), (255, 140, 40), T(x, a.hy, a.top + 1.05 + (k % 2) * 0.2), e1=0.8, e2=1.0, nu=8, nv=6,
               name="H_Flame", emit=3.0)
    cape(m, A, (255, 120, 30), inner=GOLD, collar_up=True)
    for p in a.paws:
        box(m, (p.x, p.y, a.leg * 0.55), (1.08, 1.08, 0.2), GOLD, "L", "Bangle", studs=False)


@cat("Ice Queen Cat", shape="Slim", fur="bfe0ff", second="ffffff", eyes="3c60d0", eyeStyle="big", blush=True)
def _icequeen(m, A):
    a = G(A)
    ice = (110, 190, 255)
    ears_out(m, A)
    box(m, (0, a.hy, a.top + 0.15), (a.hw * 0.7, a.hd * 0.7, 0.3), ice, "H", "Crown", emit=0.5)
    for k in range(7):
        x = -a.hw * 0.3 + k * a.hw * 0.1
        h = 0.5 + (3 - abs(k - 3)) * 0.3
        box(m, (x, a.hy - a.hd * 0.3, a.top + 0.3 + h / 2), (0.2, 0.2, h), ice, "H", "Crown", studs=False, emit=1.0, rough=0.05, coat=1.0)
    skirt(m, A, (170, 220, 255), layers=3, wide=0.55, col2=WHITE)
    for k in range(8):
        box(m, (0, 0, 0), (0.25, 0.25, 0.5), (190, 235, 255), "B", "Crystal", studs=False, emit=0.6, rough=0.05, coat=1.0,
            fr=T(math.cos(k * 0.785) * (a.bw / 2 + 0.9), a.by + math.sin(k * 0.785) * (a.bl / 2 + 0.9), a.leg + 0.15) @ R(0.785, "Z"))


@cat("Wind Spirit Cat", shape="Slim", fur="a8f0d8", second="e0fff4", eyes="2a8a70", eyeStyle="big")
def _windspirit(m, A):
    a = G(A)
    for k, (z, ph) in enumerate(((0.8, 0.0), (1.8, 1.4), (3.0, 2.8))):
        for j in range(10):
            ang = ph + j * 0.45
            r = max(a.bw, a.bl) / 2 + 0.6
            box(m, (math.cos(ang) * r, a.by + math.sin(ang) * r, z + j * 0.05), (0.15, 0.6, 0.12), (150, 255, 220), "B", "Ribbon", studs=False, emit=1.0,
                fr=about((math.cos(ang) * r, a.by + math.sin(ang) * r, z), R(ang, "Z")))
    for o in m.objects:
        if o.name.split(".")[0] in ("Body", "Head", "Leg", "Tail"):
            for mt in o.data.materials:
                try:
                    mt.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.85
                except Exception:
                    pass


@cat("Angel Cat", shape="Fluffy", fur="ffffff", second="fff8f0", eyes="5ab0ff", blush=True)
def _angel(m, A):
    a = G(A)
    wings(m, A, [(255, 255, 255), (255, 215, 120), (255, 255, 255), (255, 200, 90)], kind="feather", span=1.4, up=0.6, emit=0.2)
    ring(m, (0, a.hy + 0.2, a.top + 0.9), 0.9, 14, (0.4, 0.2, 0.15), GOLD, "H", "Halo", emit=3.0)
    skirt(m, A, WHITE, layers=1, wide=0.3)
    sash(m, A, GOLD)


@cat("Shadow King Cat", shape="Slim", fur="1e1a24", second="2e2a36", eyes="b06cff", eyeStyle="big", glowEyes=True)
def _shadowking(m, A):
    a = G(A)
    ears_out(m, A)
    box(m, (0, a.hy, a.top + 0.15), (a.hw * 0.75, a.hd * 0.75, 0.3), (40, 30, 55), "H", "Crown")
    for k in range(5):
        x = -a.hw * 0.3 + k * a.hw * 0.15
        stack(m, (x, a.hy - a.hd * 0.3, a.top + 0.3), 0.3, 0.06, 0.6 + (k % 2) * 0.4, 3, (60, 40, 90), "H", "Crown", studs=False)
    box(m, (0, a.hy - a.hd * 0.39, a.top + 0.15), (0.3, 0.08, 0.3), (180, 100, 255), "H", "Gem", studs=False, emit=3.0)
    cape(m, A, (30, 20, 45), inner=(120, 60, 200), collar_up=True, long=1.2)
    for k in range(5):
        box(m, (-a.bw / 2 - 0.25 + k * 0.0, a.bback + 0.18, 0.4 - (k % 2) * 0.2), (0.3, 0.14, 0.3), (30, 20, 45), "B", "Tatter", studs=False,
            fr=T(k * (a.bw + 0.5) / 4, 0, 0))


@cat("Rainbow Spirit Cat", shape="Fluffy", fur="ffffff", second="ffffff", eyes="b06cff", eyeStyle="big", blush=True)
def _rainbowspirit(m, A):
    a = G(A)
    for k, col in enumerate(RAINBOW):
        y = a.bfront + 0.25 + k * (a.bl - 0.5) / 5
        box(m, (0, y, a.btop + 0.1), (a.bw + 0.02, a.bl / 6, 0.08), col, "B", "Band", studs=False, emit=0.3)
        for s in (-1, 1):
            box(m, (s * (a.bw / 2 + 0.1), y, a.bz), (0.08, a.bl / 6, a.bh), col, "B", "Band", studs=False, emit=0.3)
    mane(m, A, RAINBOW, n=6)


@cat("Crystal Titan Cat", shape="Fluffy", big=True, fur="8ec8f0", second="e0f4ff", eyes="b06cff", eyeStyle="big", glowEyes=True)
def _crystaltitan(m, A):
    a = G(A)
    cols = [(120, 200, 255), (190, 140, 255), (255, 150, 230)]
    rnd = random.Random(7)
    for k in range(12):
        f = k % 3
        if f == 0:
            base = (rnd.uniform(-0.4, 0.4) * a.bw, a.by + rnd.uniform(0.0, 0.45) * a.bl, a.btop)
            rot = R(rnd.uniform(-0.4, 0.4), "Y") @ R(rnd.uniform(-0.3, 0.3), "X")
        else:
            sx = -1 if f == 1 else 1
            base = (sx * a.bw / 2, a.by + rnd.uniform(-0.4, 0.4) * a.bl, a.bz + rnd.uniform(-0.2, 0.4) * a.bh)
            rot = R(sx * (1.0 + rnd.uniform(-0.2, 0.2)), "Y")
        h = rnd.uniform(0.9, 1.7)
        box(m, (base[0], base[1], base[2] + h / 2 - 0.1), (0.5, 0.5, h), cols[k % 3], "B", "Crystal", studs=False, emit=0.8, rough=0.05,
            coat=1.0, fr=about(base, rot @ R(0.785, "Z")))
    for k in range(3):
        box(m, (-0.5 + k * 0.5, a.hy, a.top + 0.6), (0.4, 0.4, 1.1 + (k == 1) * 0.6), cols[k], "H", "Crystal", studs=False, emit=0.8,
            fr=about((-0.5 + k * 0.5, a.hy, a.top), R((k - 1) * 0.3, "Y") @ R(0.785, "Z")))


@cat("Celestial Dragon Cat", shape="Slim", fur="fffaf0", second="ffffff", eyes="ff8a20", eyeStyle="big")
def _celestialdragon(m, A):
    a = G(A)
    for x in (-1, 1):
        bx = x * (a.hw / 2 - 0.45)
        box(m, (bx, a.hy + 0.3, a.top + 0.6), (0.22, 0.22, 1.2), GOLD, "H", "Antler", studs=False)
        box(m, (bx + x * 0.3, a.hy + 0.3, a.top + 1.0), (0.6, 0.2, 0.2), GOLD, "H", "Antler", studs=False)
        box(m, (bx + x * 0.55, a.hy + 0.3, a.top + 1.3), (0.2, 0.2, 0.5), GOLD, "H", "Antler", studs=False)
        for k in range(5):
            box(m, (x * (0.45 + k * 0.32), a.front - 0.55 - k * 0.1, a.mz - k * 0.22), (0.35, 0.12, 0.12), GOLD, "H", "Whisker", studs=False)
    mane(m, A, [(255, 120, 60), (255, 180, 70)], n=6)
    marks(m, A, 10, 0.35, [GOLD, (255, 230, 150)], seed=5, emit=0.3)
    b = held(m, A, -1)
    ball(m, (b.x, b.y, 0.8), 0.45, (220, 240, 255), "L", "Pearl", emit=1.0, rough=0.05, coat=1.0)

    def build(m, A, root):
        for k in range(6):
            box(m, (0.35 * math.sin(k * 1.1), root.y + 0.4 + k * 0.45, root.z + 0.1 + k * 0.25), (0.7 - k * 0.05, 0.6, 0.6 - k * 0.04),
                (255, 250, 240) if k % 2 else GOLD, "T", "Tail")
        box(m, (0.35 * math.sin(6.6), root.y + 3.1, root.z + 1.7), (0.9, 0.5, 0.9), (255, 120, 60), "T", "Tuft")
    tail_swap(m, A, build)


@cat("Cosmic Whale Cat", shape="Fluffy", fur="1e2a6a", second="5a6ac8", eyes="ffffff", eyeStyle="big", pattern="bib")
def _cosmicwhale(m, A):
    a = G(A)
    marks(m, A, 18, 0.12, [(255, 255, 255), (255, 240, 170), (180, 220, 255)], seed=6, head=6, off=0.12, emit=4.0)
    marks(m, A, 5, 0.9, [(120, 80, 220), (60, 140, 230)], seed=2, emit=0.5)

    def build(m, A, root):
        box(m, (0, root.y + 0.4, root.z + 0.2), (0.7, 0.9, 0.6), (30, 42, 106), "T", "Tail")
        for x in (-1, 1):
            box(m, (x * 0.7, root.y + 1.0, root.z + 0.65), (1.3, 0.6, 0.18), (30, 42, 106), "T", "Fluke",
                fr=about((x * 0.2, root.y + 1.0, root.z + 0.6), R(x * -0.3, "Y")))
    tail_swap(m, A, build)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.4), a.bfront + 0.6, a.leg + 0.4), (0.8, 0.6, 0.16), (30, 42, 106), "B", "Fin",
            fr=about((s * (a.bw / 2), a.bfront + 0.6, a.leg + 0.4), R(s * -0.5, "Y")))


@cat("Nebula Cat", shape="Slim", fur="f0a0d8", second="ffe0f4", eyes="3c60d0", eyeStyle="big")
def _nebula(m, A):
    marks(m, A, 9, 0.9, [(140, 200, 255), (200, 150, 255)], shape="ball", seed=3, head=3, off=0.1, emit=1.2)
    marks(m, A, 12, 0.12, [(255, 255, 255)], seed=9, head=4, off=0.14, emit=4.0)


@cat("Comet Rider Cat", shape="Slim", fur="9fd0ff", second="ffffff", eyes="3c60d0")
def _cometrider(m, A):
    a = G(A)
    box(m, (0, a.by, -0.35), (a.bw + 0.8, a.bl + 0.6, 0.7), (120, 110, 130), "B", "Comet")
    for k in range(6):
        box(m, (0, a.bback + 0.6 + k * 0.6, -0.3 + k * 0.08), (a.bw + 0.6 - k * 0.3, 0.6, 0.6 - k * 0.07),
            [(255, 255, 255), (150, 220, 255), (200, 160, 255)][k % 3], "B", "CometTail", studs=False, emit=2.5 - k * 0.3, alpha=0.9 - k * 0.1)
    goggles(m, A, (60, 60, 80), (150, 220, 255), up=True)
    from catparts import scarf
    scarf(m, A, [(255, 255, 255), (150, 220, 255)])


@cat("Planet Cat", shape="Loaf", chubby=True, fur="f0a050", second="ffe0b0", eyes="3c96ff")
def _planet(m, A):
    a = G(A)
    for k, col in enumerate(((220, 130, 60), (250, 200, 130), (200, 110, 50))):
        z = a.leg + 0.35 + k * 0.55
        for s in (-1, 1):
            box(m, (s * (a.bw / 2 + 0.08), a.by, z), (0.08, a.bl * 0.95, 0.3), col, "B", "Band", studs=False)
    tilted_ring(m, A, max(a.bw, a.bl) / 2 + 1.0, 30, (0.7, 0.55, 0.12), [(230, 210, 170), (200, 180, 140), (250, 235, 200)], tilt=0.3, emit=0.3)


@cat("Aurora Cat", shape="Fluffy", fur="2a6a6a", second="a8e8d8", eyes="ffffff", eyeStyle="big")
def _aurora(m, A):
    a = G(A)
    cols = [(80, 255, 170), (120, 200, 255), (200, 120, 255)]
    for k in range(9):
        y = a.bfront + 0.3 + k * (a.bl - 0.6) / 8
        for s in (-1, 1):
            box(m, (s * (a.bw / 2 + 0.1), y, a.bz + 0.2 * math.sin(k)), (0.08, 0.3, a.bh * 0.8), cols[k % 3], "B", "Aurora", studs=False, emit=1.5)
    mane(m, A, cols, n=5)


@cat("Dream Weaver Cat", shape="Fluffy", fur="c8b8f0", second="f4f0ff", eyes="7a6ad0", eyeStyle="sleepy", blush=True)
def _dreamweaver(m, A):
    a = G(A)
    tip = cone_hat(m, A, [(110, 90, 200), (110, 90, 200), (90, 70, 180), (110, 90, 200)], h=1.7, w=a.hw * 0.8, tilt=0.6, n=4)
    ball(m, tip, 0.3, (255, 240, 170), "H", "Pom", emit=1.5)
    for c in ((-0.5, a.hy - a.hd * 0.33, a.top + 0.5), (0.4, a.hy - a.hd * 0.28, a.top + 0.9)):
        star(m, (0, 0, 0), 0.3, (255, 240, 170), "H", emit=1.5, fr=T(*c))
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 0.5), 0.35, 0.8, (210, 190, 255), "L", "Spool", emit=0.5)
    cyl(m, (b.x, b.y, 0.08), 0.45, 0.12, WOOD, "L", "Spool")
    cyl(m, (b.x, b.y, 0.92), 0.45, 0.12, WOOD, "L", "Spool")
    for k in range(8):
        box(m, (b.x + 0.3 + k * 0.3, b.y - 0.2, 0.5 + math.sin(k) * 0.3), (0.3, 0.05, 0.05), (230, 210, 255), "L", "Thread", studs=False, emit=1.5)


@cat("Void Walker Cat", shape="Slim", fur="1e1a24", second="2e2a36", eyes="40e0ff", eyeStyle="big", glowEyes=True)
def _voidwalker(m, A):
    a = G(A)
    cyan = (60, 230, 255)
    ring(m, (0, a.by, 0.08), max(a.bw, a.bl) / 2 + 0.6, 24, (0.4, 0.3, 0.12), [cyan, (170, 90, 255)], "B", "Portal", emit=3.0)
    cyl(m, (0, a.by, 0.04), max(a.bw, a.bl) / 2 + 0.4, 0.05, (30, 10, 60), "B", "Portal", emit=0.5)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.06), a.by, a.bz), (0.06, a.bl * 0.9, 0.1), cyan, "B", "Neon", studs=False, emit=3.0)
        box(m, (s * (a.bw / 2 + 0.06), a.by - 0.5, a.bz - 0.3), (0.06, 0.1, 0.7), cyan, "B", "Neon", studs=False, emit=3.0)


@cat("AI God Cat", shape="Loaf", fur="f4f6fa", second="ffffff", eyes="40e0ff", noEyes=True)
def _aigod(m, A):
    a = G(A)
    cyan = (60, 230, 255)
    box(m, (0, a.front - 0.08, a.hz + 0.05), (a.hw * 0.8, 0.12, a.hh * 0.55), (20, 26, 40), "H", "Screen", studs=False, rough=0.05, coat=1.0)
    for e in a.eyes:
        box(m, (e.x, a.front - 0.15, e.z), (0.5, 0.06, 0.5), cyan, "H", "ScreenEye", studs=False, emit=3.0)
    box(m, (0, a.front - 0.15, a.mz - 0.05), (0.6, 0.06, 0.1), cyan, "H", "ScreenEye", studs=False, emit=3.0)
    rnd = random.Random(3)
    for s in (-1, 1):
        for k in range(5):
            y = a.by - a.bl * 0.4 + k * a.bl * 0.2
            box(m, (s * (a.bw / 2 + 0.07), y, a.bz), (0.06, 0.08, a.bh * rnd.uniform(0.4, 0.8)), cyan, "B", "Circuit", studs=False, emit=2.5)
            box(m, (s * (a.bw / 2 + 0.07), y + 0.15, a.bz + rnd.uniform(-0.4, 0.4)), (0.06, 0.3, 0.08), cyan, "B", "Circuit", studs=False, emit=2.5)
    ring(m, (0, a.hy, a.top + 0.6), 0.8, 12, (0.3, 0.15, 0.1), cyan, "H", "Halo", emit=3.0)


@cat("Mecha Titan Cat", shape="Fluffy", big=True, fur="9aa4b4", second="c8d0dc", eyes="40e0ff")
def _mechatitan(m, A):
    a = G(A)
    steel, gold = (130, 140, 158), GOLD
    armour(m, A, steel, trim=gold)
    helmet(m, A, steel, visor=(30, 34, 44), crest=gold)
    box(m, (0, a.front - 0.12, a.eyes[0].z), (a.hw * 0.8, 0.1, 0.3), (60, 230, 255), "H", "Visor", studs=False, emit=3.0)
    for x in (-0.6, 0.6):
        cyl(m, (x, a.bback + 0.3, a.btop + 0.2), 0.35, 1.2, (90, 96, 110), "B", "Jet")
        cyl(m, (x, a.bback + 0.3, a.btop - 0.5), 0.25, 0.3, (60, 64, 76), "B", "Jet")
    wings(m, A, [steel, gold, steel], kind="stone", span=1.1, up=0.3)
    for p in a.paws:
        box(m, (p.x, p.y - 0.06, 0.3), (1.12, 1.16, 0.55), steel, "L", "Boot")


@cat("Diamond Emperor Cat", shape="Fluffy", fur="d8f0ff", second="ffffff", eyes="3c60d0", eyeStyle="big")
def _diamondemperor(m, A):
    a = G(A)
    rnd = random.Random(4)
    for k in range(14):
        f = k % 3
        if f == 0:
            c = (rnd.uniform(-0.42, 0.42) * a.bw, a.by + rnd.uniform(-0.1, 0.45) * a.bl, a.btop + 0.15)
        else:
            sx = -1 if f == 1 else 1
            c = (sx * (a.bw / 2 + 0.15), a.by + rnd.uniform(-0.45, 0.45) * a.bl, a.bz + rnd.uniform(-0.4, 0.4) * a.bh)
        box(m, c, (0.5, 0.5, 0.5), [(200, 240, 255), (230, 220, 255), (255, 255, 255)][k % 3], "B", "Diamond", studs=False, emit=0.6,
            rough=0.02, coat=1.0, fr=about(c, R(0.785, "Z") @ R(0.6, "X")))
    crown(m, A, GOLD, gems=((150, 220, 255), (255, 255, 255), (150, 220, 255)), w=0.75, h=0.45, tips=5)
    cape(m, A, (90, 60, 170), inner=GOLD)


@cat("Bastet Cat", shape="Slim", fur="1e1a24", second="2e2a36", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _bastet(m, A):
    a = G(A)
    for k in range(3):
        box(m, (0, a.by, a.hb + 0.1 - k * 0.16), (a.hw * (0.95 - k * 0.1), a.hd * 0.9, 0.16), GOLD if k % 2 == 0 else (40, 120, 200), "H", "Collar", studs=False)
    for x in (-1, 1):
        cyl(m, (x * (a.hw / 2 + 0.05), a.hy - 0.1, a.hz - 0.3), 0.22, 0.08, GOLD, "H", "Earring", axis="X")
    for e in a.eyes:
        box(m, (e.x + (0.45 if e.x > 0 else -0.45), a.front - 0.05, e.z - 0.1), (0.5, 0.06, 0.1), GOLD, "H", "Liner", studs=False)
    for p in a.paws:
        box(m, (p.x, p.y, a.leg * 0.55), (1.08, 1.08, 0.22), GOLD, "L", "Bangle", studs=False)
    b = held(m, A, -1)
    box(m, (b.x, b.y, 0.9), (0.18, 0.18, 1.6), GOLD, "L", "Ankh", studs=False)
    box(m, (b.x, b.y, 1.3), (0.8, 0.18, 0.18), GOLD, "L", "Ankh", studs=False)
    for k in range(8):
        box(m, (0, 0, 0.32), (0.15, 0.15, 0.18), GOLD, "L", "Ankh", studs=False, fr=T(b.x, b.y, 1.75) @ R(k * 0.785, "Y"))


@cat("Zodiac Cat", shape="Fluffy", fur="1e2a6a", second="5a6ac8", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _zodiac(m, A):
    disc_back(m, A, 2.2, [(255, 210, 80), (120, 150, 255)], n=12, ray=0.6, centre=(40, 50, 120), emit=1.5)
    marks(m, A, 14, 0.12, [(255, 240, 170)], seed=4, head=5, off=0.12, emit=4.0)
    crown(m, A, GOLD, gems=((120, 150, 255),), w=0.55, h=0.3, tips=3)


@cat("Elemental Cat", shape="Fluffy", fur="b8b0a8", second="f0ece6", eyes="ffffff", eyeStyle="big")
def _elemental(m, A):
    quarters(m, A, [(255, 90, 50), (70, 160, 255), (110, 210, 90), (170, 120, 70)])
    a = G(A)
    for k, col in enumerate(((255, 90, 50), (70, 160, 255), (110, 210, 90), (170, 120, 70))):
        box(m, (-0.75 + k * 0.5, a.hy - a.hd * 0.4, a.top + 0.15), (0.35, 0.12, 0.3), col, "H", "Gem", studs=False, emit=1.0)


@cat("Phoenix Emperor Cat", shape="Slim", fur="ffc83a", second="fff0c0", eyes="ff5020", eyeStyle="big", glowEyes=True)
def _phoenixemperor(m, A):
    a = G(A)
    wings(m, A, [(255, 80, 30), (255, 150, 40), (255, 210, 60), (255, 110, 40)], kind="feather", span=1.5, up=0.55, emit=1.0)
    for k in range(5):
        ang = -0.6 + k * 0.3
        box(m, (0, 0, 0.6), (0.18, 0.12, 1.2 - abs(k - 2) * 0.2), [(255, 80, 30), GOLD][k % 2], "H", "Crest", studs=False, emit=1.0,
            fr=T(0, a.hy, a.top) @ R(ang, "Y"))
    beak(m, A, GOLD, long=0.35)
    crown(m, A, GOLD, gems=((255, 80, 30),), w=0.5, h=0.25, tips=3)


@cat("Kraken Lord Cat", shape="Fluffy", fur="5a2a8a", second="a87ad8", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _krakenlord(m, A):
    a = G(A)
    col = (110, 60, 160)
    for s in (-1, 1):
        for t in range(2):
            base = (s * (a.bw / 2 + 0.2), a.by - 0.5 + t * 1.2, a.bz)
            for j in range(6):
                c = (base[0] + s * (0.4 + j * 0.45), base[1] + math.sin(j + t) * 0.35, base[2] + 0.7 * math.sin(j * 0.9 + t))
                box(m, c, (0.7 - j * 0.08, 0.7 - j * 0.08, 0.7 - j * 0.08), col, "B", "Tentacle")
    coral = [(255, 120, 120), GOLD, (255, 110, 170)]
    for k in range(5):
        x = -0.8 + k * 0.4
        h = 0.6 + (k % 2) * 0.5
        box(m, (x, a.hy - 0.1, a.top + h / 2), (0.22, 0.22, h), coral[k % 3], "H", "Coral", studs=False)
    collar(m, A, GOLD, gem=(90, 220, 255))


@cat("World Tree Cat", shape="Fluffy", fur="6aa84a", second="d8f0b0", eyes="ffd23c")
def _worldtree(m, A):
    a = G(A)
    c = (0, a.by + 0.6, a.btop)
    box(m, (c[0], c[1], c[2] + 1.2), (0.7, 0.7, 2.4), (120, 80, 45), "B", "Trunk")
    for x in (-1, 1):
        box(m, (x * 0.6, c[1], c[2] + 2.0), (1.0, 0.3, 0.3), (120, 80, 45), "B", "Branch", studs=False, fr=about((0, c[1], c[2] + 1.8), R(x * 0.5, "Y")))
    for k, (x, y, z, s) in enumerate(((0, 0, 3.0, 1.6), (-1.0, 0.2, 2.6, 1.1), (1.0, -0.2, 2.7, 1.2), (0.3, 0.6, 3.6, 1.0), (-0.4, -0.5, 3.4, 1.0))):
        box(m, (x, c[1] + y, c[2] + z), (s, s, s * 0.8), [(70, 170, 70), (110, 200, 80), (255, 210, 80)][k % 3], "B", "Leaves", emit=0.2 if k % 3 == 2 else 0.0)
    marks(m, A, 6, 0.4, [(255, 220, 90)], where=("left", "right"), seed=2, emit=1.0)


@cat("Sky Whale Cat", shape="Fluffy", fur="8ac8ff", second="ffffff", eyes="3c60d0", pattern="bib")
def _skywhale(m, A):
    a = G(A)

    def build(m, A, root):
        box(m, (0, root.y + 0.4, root.z + 0.2), (0.7, 0.9, 0.6), (138, 200, 255), "T", "Tail")
        for x in (-1, 1):
            box(m, (x * 0.7, root.y + 1.0, root.z + 0.65), (1.3, 0.6, 0.18), (138, 200, 255), "T", "Fluke",
                fr=about((x * 0.2, root.y + 1.0, root.z + 0.6), R(x * -0.3, "Y")))
    tail_swap(m, A, build)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.6), a.by - 0.2, a.bz + 0.3), (1.4, 0.8, 0.18), (110, 180, 245), "B", "Fin",
            fr=about((s * (a.bw / 2), a.by, a.bz + 0.3), R(s * -0.35, "Y")))
    marks(m, A, 5, 0.9, [(255, 255, 255)], shape="ball", where=("top",), seed=3, off=0.3)


@cat("Thunder Dragon King Cat", shape="Slim", fur="2a3a8a", second="8aa0e0", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _thunderdragon(m, A):
    a = G(A)
    for x in (-1, 1):
        for k, (dx, dz) in enumerate(((0.0, 0.3), (0.2, 0.75), (0.0, 1.2))):
            box(m, (x * (a.hw / 2 - 0.4 + dx), a.hy + 0.3, a.top + dz), (0.25, 0.25, 0.5), (255, 230, 60), "H", "Horn", studs=False, emit=1.5,
                fr=about((x * (a.hw / 2 - 0.4 + dx), a.hy + 0.3, a.top + dz), R(x * (0.5 if k % 2 else -0.5), "Y")))
    wings(m, A, [(30, 40, 110), (255, 220, 60)], kind="bat", span=1.3, up=0.4, emit=0.8)
    spikes(m, A, (255, 220, 60))
    crown(m, A, GOLD, gems=((90, 160, 255),), w=0.5, h=0.25, tips=3)


@cat("Infinity Cat", shape="Slim", fur="ffffff", second="ffffff", eyes="b06cff", eyeStyle="big")
def _infinity(m, A):
    a = G(A)
    for x in (-0.55, 0.55):
        ring(m, (0, 0, 0), 0.5, 12, (0.24, 0.24, 0.18), RAINBOW, "H", "Infinity", emit=2.0, fr=T(x, a.hy, a.top + 1.4) @ R(math.pi / 2, "X"))
    for k, col in enumerate(RAINBOW):
        box(m, (-(a.bw / 2 + 0.1), a.bfront + 0.3 + k * (a.bl - 0.6) / 5, a.bz), (0.08, 0.35, a.bh * 0.9), col, "B", "Band", studs=False, emit=0.3)


@cat("Game God Cat", shape="Loaf", fur="9a5af0", second="d8c0ff", eyes="40ff80", eyeStyle="big", glowEyes=True)
def _gamegod(m, A):
    a = G(A)
    headphones(m, A, (40, 36, 48), (80, 255, 130), wide=0.1)
    b = held(m, A, -1)
    box(m, (b.x, b.y - 0.2, 0.9), (0.4, 1.4, 0.8), (40, 36, 48), "L", "Pad")
    for y in (-0.5, 0.1):
        box(m, (b.x - 0.22, b.y - 0.2 + y, 1.0), (0.06, 0.3, 0.1), (80, 255, 130), "L", "Pad", studs=False, emit=2.0)
    for z, col in ((1.1, (255, 80, 80)), (0.8, (80, 160, 255))):
        cyl(m, (b.x - 0.22, b.y + 0.3, z), 0.1, 0.06, col, "L", "Button", axis="X", emit=1.5)
    crown(m, A, (80, 255, 130), gems=((255, 80, 200),), w=0.5, h=0.25, tips=3, emit=0.8)


@cat("Candy Queen Cat", shape="Fluffy", fur="ffc0dc", second="fff4fa", eyes="b06cff", blush=True)
def _candyqueen(m, A):
    a = G(A)
    crown(m, A, (255, 120, 180), gems=((120, 200, 255), (255, 230, 80), (120, 220, 140)), w=0.7, h=0.4, tips=5)
    skirt(m, A, (255, 140, 190), layers=3, wide=0.6, col2=WHITE)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.2), 0.07, 2.4, WHITE, "L", "Stick")
    for k in range(5):
        cyl(m, (b.x, b.y, 2.6), 0.75 - k * 0.15, 0.2 + k * 0.02, (255, 100, 160) if k % 2 == 0 else WHITE, "L", "Lolly", axis="Y")


@cat("Music Goddess Cat", shape="Slim", fur="ffd060", second="fff4d0", eyes="7a4ad8", eyeStyle="big")
def _musicgoddess(m, A):
    a = G(A)
    for k in range(9):
        ang = k * 2 * math.pi / 9
        box(m, (math.cos(ang) * (a.hw / 2 - 0.2), a.hy + math.sin(ang) * (a.hd / 2 - 0.2), a.top + 0.1), (0.4, 0.2, 0.14), (90, 180, 80), "H", "Laurel",
            studs=False, fr=about((math.cos(ang) * (a.hw / 2 - 0.2), a.hy + math.sin(ang) * (a.hd / 2 - 0.2), a.top + 0.1), R(ang + 0.5, "Z")))
    b = held(m, A, -1)
    for k in range(7):
        ang = math.pi * 0.2 + k * math.pi * 0.6 / 6
        box(m, (b.x + math.cos(ang) * 0.9 - 0.3, b.y, 0.2 + math.sin(ang) * 1.6), (0.22, 0.22, 0.4), GOLD, "L", "Harp", studs=False)
    box(m, (b.x - 0.6, b.y, 0.9), (0.2, 0.2, 1.7), GOLD, "L", "Harp", studs=False)
    for k in range(4):
        box(m, (b.x - 0.35 + k * 0.2, b.y, 0.95), (0.03, 0.03, 1.3 - k * 0.15), WHITE, "L", "String", studs=False, emit=0.8)
    shirt(m, A, (150, 90, 220), h=a.bh * 0.85)
    sash(m, A, GOLD)


@cat("Four Seasons Cat", shape="Fluffy", fur="c8c4be", second="ffffff", eyes="3c96ff", eyeStyle="big")
def _fourseasons(m, A):
    quarters(m, A, [(255, 170, 200), (110, 200, 90), (255, 150, 50), (230, 240, 255)])
    a = G(A)
    flower(m, (-0.7, a.hy - 0.3, a.top + 0.15), 0.6, (255, 150, 190))
    box(m, (-0.2, a.hy - 0.3, a.top + 0.12), (0.5, 0.25, 0.08), (110, 200, 90), "H", "Leaf", studs=False)
    box(m, (0.3, a.hy - 0.3, a.top + 0.12), (0.5, 0.25, 0.08), (255, 140, 40), "H", "Leaf", studs=False)
    for k in range(3):
        box(m, (0.8, a.hy - 0.3, a.top + 0.15), (0.1, 0.1, 0.5), (220, 240, 255), "H", "Flake", studs=False, emit=0.6, fr=about((0.8, a.hy - 0.3, a.top + 0.15), R(k * 1.047, "Y")))


@cat("Sakura Goddess Cat", shape="Slim", fur="ffd0e4", second="fff6fa", eyes="7a4ad8", blush=True)
def _sakura(m, A):
    a = G(A)
    box(m, (0.2, a.hy, a.top + 0.25), (1.6, 0.18, 0.18), (110, 70, 45), "H", "Branch", studs=False, fr=about((0.2, a.hy, a.top + 0.25), R(-0.3, "Y")))
    for k in range(5):
        flower(m, (-0.5 + k * 0.35, a.hy - 0.15, a.top + 0.25 + k * 0.1), 0.45, (255, 170, 210), fr=about((-0.5 + k * 0.35, a.hy - 0.15, a.top + 0.25 + k * 0.1), R(math.pi / 2, "X")))
    shirt(m, A, (255, 150, 190), h=a.bh * 0.9)
    belt(m, A, (200, 40, 80), buckle=GOLD, z=a.bz)
    for s in (-1, 1):
        for k in range(3):
            flower(m, (s * (a.bw / 2 + CLOTH + 0.05), a.by - 0.6 + k * 0.6, a.bz - 0.35), 0.4, WHITE, bone="B",
                   fr=about((s * (a.bw / 2 + CLOTH + 0.05), a.by - 0.6 + k * 0.6, a.bz - 0.35), R(s * math.pi / 2, "Y")))


@cat("Lotus Spirit Cat", shape="Fluffy", fur="ffd0e4", second="fff6fa", eyes="3c96ff", eyeStyle="sleepy", blush=True)
def _lotus(m, A):
    a = G(A)
    for k in range(12):
        ang = k * 2 * math.pi / 12
        rr = max(a.bw, a.bl) / 2 + 0.3
        c = (math.cos(ang) * rr, a.by + math.sin(ang) * rr, 0.5)
        box(m, c, (0.8, 0.3, 1.2), (255, 160, 200) if k % 2 else (255, 200, 225), "B", "Lotus", studs=False, emit=0.5,
            fr=about((math.cos(ang) * (rr - 0.3), a.by + math.sin(ang) * (rr - 0.3), 0), R(ang + math.pi / 2, "Z") @ R(0.4, "X")))
    plate(m, (0, a.by, 0.06), (a.bw + 2.0, a.bl + 2.0, 0.12), (80, 170, 90), "B", "Pad")
    box(m, (0, a.front - 0.04, a.top - 0.4), (0.25, 0.06, 0.25), (255, 120, 170), "H", "Dot", studs=False, emit=1.0,
        fr=about((0, a.front, a.top - 0.4), R(0.785, "Y")))


@cat("Starfall Knight Cat", shape="Slim", fur="c8d0e0", second="f0f4fa", eyes="3c60d0", eyeStyle="big")
def _starfall(m, A):
    a = G(A)
    navy = (40, 60, 150)
    helmet(m, A, SILVER, visor=navy, crest=(255, 230, 90))
    armour(m, A, SILVER, trim=navy)
    star(m, (0, 0, 0), 0.7, (255, 230, 90), "B", emit=1.5, fr=T(0, a.bfront - CLOTH - 0.1, a.bz + 0.1))
    sword(m, A, blade=(150, 210, 255), hilt=navy, guard=(255, 230, 90), emit=2.0)
    cape(m, A, navy, inner=(255, 230, 90))


@cat("Eclipse Cat", shape="Loaf", fur="1e1a24", second="2e2a36", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _eclipse(m, A):
    disc_back(m, A, 1.9, [(255, 210, 90), (255, 160, 60)], n=20, ray=0.6, centre=(10, 8, 14), emit=3.0)


@cat("Prism Cat", shape="Slim", fur="e8f4ff", second="ffffff", eyes="b06cff", eyeStyle="big")
def _prism(m, A):
    a = G(A)
    for o in m.objects:
        if o.name.split(".")[0] in ("Body", "Head"):
            for mt in o.data.materials:
                try:
                    mt.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.6
                    mt.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.02
                except Exception:
                    pass
    wedge(m, (0, a.by + 0.3, a.btop + 0.6), (0.9, 1.4, 1.2), (220, 240, 255), "B", "Prism", alpha=0.6, rough=0.02, coat=1.0)
    for k, col in enumerate(RAINBOW):
        box(m, (-a.bw / 2 - 1.0, a.by + 0.3 + (k - 2.5) * 0.18, a.btop + 0.6 - k * 0.12), (2.2, 0.16, 0.12), col, "Fx", "Beam", studs=False, emit=2.5,
            fr=about((-a.bw / 2, a.by + 0.3, a.btop + 0.6), R(0.25 + k * 0.04, "Y")))


@cat("Golden Paw Cat", shape="Loaf", fur="ffc83a", second="ffe08a", eyes="ff8a20", eyeStyle="big")
def _goldenpaw(m, A):
    a = G(A)
    recolor(m, ("Body", "Head", "Leg", "Ear", "Tail", "Muzzle", "Paw", "Chest"), (255, 196, 46))
    for o in m.objects:
        for mt in o.data.materials:
            try:
                mt.node_tree.nodes["Principled BSDF"].inputs["Metallic"].default_value = 0.8
                mt.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.2
            except Exception:
                pass
    p = a.paws[0]
    box(m, (p.x - 0.2, p.y - 0.6, 0.45), (1.6, 1.7, 0.9), (255, 196, 46), "L", "BigPaw")
    for k in range(4):
        box(m, (p.x - 0.7 + k * 0.35, p.y - 1.5, 0.55), (0.3, 0.12, 0.3), (255, 150, 180), "L", "Bean", studs=False)
    box(m, (p.x - 0.2, p.y - 1.5, 0.25), (0.8, 0.12, 0.35), (255, 150, 180), "L", "Bean", studs=False)
    crown(m, A, (255, 220, 100), gems=((255, 80, 120),), w=0.55, h=0.3, tips=3)


@cat("Quantum Cat", shape="Slim", fur="6a8af0", second="c8d4ff", eyes="ffffff", eyeStyle="big")
def _quantum(m, A):
    a = G(A)
    for dx, col in ((0.9, (90, 220, 255)), (-0.9, (190, 120, 255))):
        box(m, (dx, a.by + 0.2, a.bz), (a.bw, a.bl, a.bh), col, "Fx", "Ghost", studs=False, alpha=0.3, emit=0.8)
        box(m, (dx, a.hy + 0.2, a.hz), (a.hw, a.hd, a.hh), col, "Fx", "Ghost", studs=False, alpha=0.3, emit=0.8)
    marks(m, A, 8, 0.25, [(90, 220, 255), (190, 120, 255)], seed=5, head=3, emit=2.0)


@cat("Creator Cat", shape="Fluffy", fur="ffffff", second="ffffff", eyes="3c96ff", eyeStyle="big", blush=True)
def _creator(m, A):
    a = G(A)
    marks(m, A, 12, 0.45, RAINBOW, seed=7, head=4, off=0.1)
    from catparts import beret
    beret(m, A, (170, 100, 255))
    b = held(m, A, -1)
    fr = T(b.x, b.y, 0.0) @ R(0.2, "Y")
    cyl(m, (0, 0, 1.3), 0.12, 2.6, WOOD, "L", "Brush", fr=fr)
    box(m, (0, 0, 2.75), (0.35, 0.35, 0.5), SILVER, "L", "Brush", fr=fr, studs=False)
    box(m, (0, 0, 3.15), (0.4, 0.4, 0.45), (255, 90, 120), "L", "Brush", fr=fr, studs=False, emit=1.0)
    b2 = held(m, A, 1)
    plate(m, (b2.x, b2.y, 0.8), (1.0, 1.2, 0.12), (220, 180, 120), "L", "Palette")
    for k, col in enumerate(RAINBOW):
        box(m, (b2.x - 0.3 + (k % 3) * 0.3, b2.y - 0.3 + (k // 3) * 0.5, 0.9), (0.22, 0.22, 0.08), col, "L", "Paint", studs=False)


@cat("Sweetpotato Legend", shape="Fluffy", fur="a85ac0", second="f0d8f8", eyes="ffd23c", eyeStyle="big", glowEyes=True, blush=True)
def _sweetpotato(m, A):
    a = G(A)
    ears_out(m, A)
    m.blob((a.hw * 0.42, a.hd * 0.38, 0.75), (170, 90, 190), T(0, a.hy, a.top + 0.55) @ R(math.pi / 2, "Y"), e1=1.0, e2=1.0, nu=18, nv=12,
           name="H_Potato", rough=0.4)
    for k in range(4):
        box(m, (-0.6 + k * 0.4, a.hy - 0.1, a.top + 1.0 + (k % 2) * 0.1), (0.1, 0.2, 0.1), (210, 150, 220), "H", "Spot", studs=False)
    for k in range(3):
        box(m, (0.2 * (k - 1), a.hy, a.top + 1.55), (0.5, 0.18, 0.12), (90, 180, 80), "H", "Leaf", studs=False,
            fr=about((0, a.hy, a.top + 1.4), R((k - 1) * 0.7, "Y")))
    crown(m, A, GOLD, gems=((170, 90, 190), (255, 240, 170), (170, 90, 190)), w=0.82, h=0.35, tips=5)
    cape(m, A, (120, 60, 160), inner=GOLD, collar_up=True)
    necklace(m, A, GOLD, n=10, r=0.13, pendant=(170, 90, 190))


for _name, _entry in DESIGNS.items():
    blockcat.DESIGNS[_name] = _entry
