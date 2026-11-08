"""Legendary tier (round 2): food and animal mixes; the cat's body becomes the thing. Strawberry Cat is in
blockcat.py."""
import math
import random

from mathutils import Vector

import blockcat
from blockcat import GOLD, INK, PINK, WHITE, shade
from catparts import (BLACK, BROWN, CLOTH, GREEN, RED, SILVER, WOOD, C, G, about, ball, beak, box, bow, cyl, ears_out,
                      flower, fx, held, mix, plate, remove, ring, shell, shirt, stack, star, stick, tail_swap, wedge,
                      wings, recolor)
from kit import R, T

DESIGNS = {}
LEAF, LEAF2, STEM = (70, 180, 70), (110, 210, 90), (90, 70, 40)


def cat(name, **look):
    def deco(fn):
        DESIGNS[name] = (fn, look)
        return fn
    return deco


def marks(m, A, n, size, cols, where=("top", "left", "right"), shape="box", seed=1, off=0.1, bone="B", name="Mark",
          head=0, emit=0.0):
    """n small marks scattered on the body (and `head` more on the head); shape box / ball / disc."""
    a = G(A)
    rnd = random.Random(seed)
    cols = cols if isinstance(cols, list) else [cols]
    spots = []
    for k in range(n):
        f = where[k % len(where)]
        u, v = rnd.uniform(-0.42, 0.42), rnd.uniform(-0.4, 0.4)
        if f == "top":
            spots.append(("B", (u * a.bw, a.by + 0.25 + v * (a.bl - 0.5) * 0.6, a.btop + off), "Z"))
        else:
            sx = -1 if f == "left" else 1
            spots.append(("B", (sx * (a.bw / 2 + off), a.by + u * a.bl, a.bz + v * a.bh), "X"))
    for k in range(head):
        f = ("top", "left", "right")[k % 3]
        u, v = rnd.uniform(-0.38, 0.38), rnd.uniform(-0.35, 0.35)
        if f == "top":
            spots.append(("H", (u * a.hw, a.hy + v * a.hd, a.top + off), "Z"))
        else:
            sx = -1 if f == "left" else 1
            spots.append(("H", (sx * (a.hw / 2 + off), a.hy + u * a.hd, a.hz + v * a.hh), "X"))
    for k, (b, c, ax) in enumerate(spots):
        col = cols[k % len(cols)]
        bb = bone if b == "B" else "H"
        if shape == "ball":
            ball(m, c, size / 2, col, bb, name, emit=emit)
        elif shape == "disc":
            cyl(m, c, size / 2, 0.08, col, bb, name, axis=ax, emit=emit)
        else:
            s = (size, size, 0.08) if ax == "Z" else (0.08, size, size)
            box(m, c, s, col, bb, name, studs=False, emit=emit,
                fr=about(c, R(rnd.uniform(-0.4, 0.4), ax)))


def leaf_crown(m, A, n=5, ln=1.2, cols=(LEAF, LEAF2), up=0.5, z=0.0, stem=True):
    a = G(A)
    for k in range(n):
        ang = k * 2 * math.pi / n + 0.3
        fr = T(math.cos(ang) * 0.4, a.hy + math.sin(ang) * 0.4, a.top + 0.1 + z) @ R(ang, "Z") @ R(-up, "Y")
        box(m, (ln / 2, 0, 0), (ln, 0.45, 0.14), cols[k % len(cols)], "H", "Leaf", fr=fr, studs=False)
    if stem:
        box(m, (0, a.hy, a.top + 0.4 + z), (0.28, 0.28, 0.7), STEM, "H", "Stem", studs=False)


def front_patch(m, A, col, w=0.75, h=0.85, off=0.1, name="Belly"):
    """A big colour patch on the chest (the front of the body under the head)."""
    a = G(A)
    box(m, (0, a.bfront - off, a.leg + a.bh * h / 2 + 0.05), (a.bw * w, 0.1, a.bh * h), col, "B", name, studs=False)


def side_patch(m, A, col, h=0.5, off=0.1, name="Belly"):
    a = G(A)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + off), a.by, a.leg + a.bh * h / 2), (0.1, a.bl * 0.95, a.bh * h), col, "B", name, studs=False)


def bands(m, A, cols, n, off=0.12, width=0.3, bone="B", down=0.75):
    """Stripes across the back and down the sides."""
    a = G(A)
    for k in range(n):
        y = a.bfront + 0.4 + k * (a.bl - 0.8) / max(1, n - 1)
        col = cols[k % len(cols)]
        box(m, (0, y, a.btop + off), (a.bw + 0.02, width, 0.08), col, bone, "Band", studs=False)
        for s in (-1, 1):
            box(m, (s * (a.bw / 2 + off), y, a.btop - a.bh * down / 2), (0.08, width, a.bh * down), col, bone, "Band", studs=False)


def eye_stalks(m, A, col, eye_col=WHITE, h=0.9):
    a = G(A)
    for x in (-1, 1):
        box(m, (x * 0.6, a.hy - 0.2, a.top + h / 2), (0.22, 0.22, h), col, "H", "Stalk", studs=False)
        ball(m, (x * 0.6, a.hy - 0.2, a.top + h + 0.15), 0.3, eye_col, "H", "Stalk")
        ball(m, (x * 0.6, a.hy - 0.45, a.top + h + 0.18), 0.12, INK, "H", "Stalk")


def antennae(m, A, col, tip=None, h=1.1):
    a = G(A)
    for x in (-1, 1):
        box(m, (x * 0.4, a.hy, a.top + h / 2), (0.1, 0.1, h), col, "H", "Antenna", studs=False,
            fr=about((x * 0.4, a.hy, a.top), R(x * 0.35, "Y")))
        tp = about((x * 0.4, a.hy, a.top), R(x * 0.35, "Y")) @ Vector((x * 0.4, a.hy, a.top + h))
        ball(m, tp, 0.18, tip or col, "H", "Antenna")


def new_ears(m, A, build):
    remove(m, ("Ear", "EarIn"))
    build(G(A))


# --------------------------------------------------------------------------------------------------------------------
@cat("Banana Cat", shape="Slim", fur="fff8e6", second="ffffff", eyes="3c96ff", blush=True)
def _banana(m, A):
    a = G(A)
    yel, tip = (255, 205, 30), (110, 80, 40)
    for x in (-1, 1):
        fr = about((x * (a.bw / 2), a.by, a.btop + 0.1), R(x * 0.45, "Y"))
        box(m, (x * (a.bw / 2 + 0.2), a.by, a.btop - 0.55), (0.18, a.bl * 0.8, 1.4), yel, "B", "Peel", fr=fr)
        box(m, (x * (a.bw / 2 + 0.2), a.by, a.btop - 1.32), (0.2, a.bl * 0.5, 0.2), shade(yel, 0.8), "B", "Peel", studs=False, fr=fr)
    fr = about((0, a.bback, a.btop + 0.1), R(-0.45, "X"))
    box(m, (0, a.bback + 0.2, a.btop - 0.55), (a.bw * 0.7, 0.18, 1.4), yel, "B", "Peel", fr=fr)
    plate(m, (0, a.by + 0.2, a.btop + 0.1), (a.bw + 0.2, a.bl * 0.75, 0.2), yel, "B", "Peel")
    ears_out(m, A)
    stack(m, (0, a.hy, a.top - 0.1), a.hw * 0.8, a.hw * 0.3, 1.1, 4, yel, d0=a.hd * 0.8, d1=a.hd * 0.3)
    box(m, (0, a.hy, a.top + 1.15), (0.3, 0.3, 0.4), tip, "H", "Stem", studs=False)


@cat("Watermelon Cat", shape="Fluffy", fur="3cae4a", second="ff5060", eyes="3c96ff", pattern="ribs", patternColor="1f7a2e")
def _watermelon(m, A):
    a = G(A)
    front_patch(m, A, (255, 80, 100), w=0.85, h=0.95)
    for k in range(6):
        box(m, (-0.6 + (k % 3) * 0.6, a.bfront - 0.17, a.leg + 0.5 + (k // 3) * 0.7), (0.14, 0.06, 0.24), INK, "B", "Seed", studs=False)
    box(m, (0, a.bfront - 0.13, a.leg + a.bh + 0.0), (a.bw * 0.88, 0.1, 0.2), WHITE, "B", "Rind", studs=False)
    leaf_crown(m, A, n=3, ln=0.8)


@cat("Avocado Cat", shape="Loaf", fur="3f7a2a", second="d8e87a", eyes="ffb020", pattern="smoke")
def _avocado(m, A):
    a = G(A)
    front_patch(m, A, (215, 230, 120), w=0.85, h=0.95)
    side_patch(m, A, (215, 230, 120), h=0.55)
    ball(m, (0, a.bfront - 0.3, a.leg + a.bh * 0.45), 0.55, (140, 90, 50), "B", "Pit")
    box(m, (0, a.hy, a.top + 0.25), (0.25, 0.25, 0.5), STEM, "H", "Stem", studs=False)


@cat("Cherry Cat", shape="Loaf", fur="b01e32", second="ffd8de", eyes="ffd23c")
def _cherry(m, A):
    a = G(A)
    for x in (-0.55, 0.55):
        ball(m, (x, a.hy - 0.1, a.top + 0.5), 0.5, (200, 20, 40), "H", "Cherry", emit=0.1)
        box(m, (x * 0.6, a.hy - 0.1, a.top + 1.25), (0.12, 0.12, 0.9), (60, 130, 50), "H", "Stem", studs=False,
            fr=about((x, a.hy - 0.1, a.top + 0.9), R(-x * 0.5, "Y")))
    box(m, (0.0, a.hy - 0.1, a.top + 1.7), (0.2, 0.2, 0.2), (60, 130, 50), "H", "Stem", studs=False)
    box(m, (0.4, a.hy - 0.1, a.top + 1.75), (0.7, 0.3, 0.1), LEAF, "H", "Leaf", studs=False, fr=about((0.1, a.hy, a.top + 1.7), R(-0.3, "Y")))
    marks(m, A, 6, 0.22, (255, 120, 140), seed=3, head=2)


@cat("Pineapple Cat", shape="Fluffy", fur="ffc83a", second="fff2c4", eyes="52d273")
def _pineapple(m, A):
    a = G(A)
    for s in (-1, 1):
        for i in range(4):
            for j in range(3):
                c = (s * (a.bw / 2 + 0.1), a.by - a.bl * 0.38 + i * a.bl * 0.25 + (j % 2) * 0.35, a.leg + 0.4 + j * 0.6)
                box(m, c, (0.08, 0.4, 0.4), (200, 140, 30), "B", "Scale", studs=False, fr=about(c, R(0.785, "X")))
    leaf_crown(m, A, n=7, ln=1.5, up=1.0, stem=False)
    leaf_crown(m, A, n=5, ln=1.0, up=1.3, stem=False, z=0.3)


@cat("Orange Cat", shape="Loaf", chubby=True, fur="ff9020", second="fff0d0", eyes="52d273")
def _orange(m, A):
    a = G(A)
    marks(m, A, 14, 0.14, (240, 120, 10), seed=5, head=6)
    box(m, (0, a.hy, a.top + 0.2), (0.25, 0.25, 0.4), STEM, "H", "Stem", studs=False)
    box(m, (0.45, a.hy, a.top + 0.35), (0.8, 0.35, 0.12), LEAF, "H", "Leaf", studs=False, fr=about((0.1, a.hy, a.top + 0.3), R(-0.3, "Y")))


@cat("Grape Cat", shape="Fluffy", fur="7a3aa8", second="d8b8f0", eyes="ffd23c")
def _grape(m, A):
    a = G(A)
    rnd = random.Random(4)
    cols = [(120, 60, 170), (100, 45, 150), (140, 80, 190)]
    for k in range(18):
        f = k % 3
        if f == 0:
            c = (rnd.uniform(-0.4, 0.4) * a.bw, a.by + rnd.uniform(-0.1, 0.45) * a.bl, a.btop + 0.15)
        else:
            sx = -1 if f == 1 else 1
            c = (sx * (a.bw / 2 + 0.15), a.by + rnd.uniform(-0.45, 0.45) * a.bl, a.bz + rnd.uniform(-0.35, 0.4) * a.bh)
        ball(m, c, 0.36, cols[k % 3], "B", "Grape")
    for k in range(5):
        ball(m, (rnd.uniform(-0.35, 0.35) * a.hw, a.hy + rnd.uniform(-0.3, 0.3) * a.hd, a.top + 0.15), 0.33, cols[k % 3], "H", "Grape")
    box(m, (0, a.hy, a.top + 0.6), (0.2, 0.2, 0.6), STEM, "H", "Stem", studs=False)
    box(m, (0.5, a.hy, a.top + 0.75), (0.9, 0.5, 0.1), LEAF, "H", "Leaf", studs=False)


@cat("Mango Cat", shape="Slim", fur="ffb428", second="fff0c0", eyes="52d273", pattern="smoke", blush=True)
def _mango(m, A):
    a = G(A)
    side_patch(m, A, (255, 120, 60), h=0.35)
    t = A["tail"][-1]
    box(m, (t.x, t.y + 0.4, t.z + 0.6), (0.4, 1.1, 0.12), LEAF, "T", "Leaf", studs=False, fr=about((t.x, t.y, t.z + 0.4), R(-0.6, "X")))
    box(m, (t.x, t.y, t.z + 0.5), (0.15, 0.15, 0.3), STEM, "T", "Stem", studs=False)


@cat("Coconut Cat", shape="Loaf", fur="ffffff", second="ffffff", eyes="7a4a2a", pattern="patch", patternColor="8a5a34")
def _coconut(m, A):
    a = G(A)
    brown = (120, 80, 45)
    ears_out(m, A)
    stack(m, (0, a.hy, a.top - 0.4), a.hw + 0.3, a.hw * 0.5, 1.2, 3, brown, d0=a.hd + 0.3, d1=a.hd * 0.5)
    box(m, (0, a.hy, a.top - 0.35), (a.hw + 0.34, a.hd + 0.34, 0.14), WHITE, "H", "Rim", studs=False)
    marks(m, A, 0, 0.1, (90, 60, 30), head=0)
    fr = about((0.3, a.hy, a.top + 0.6), R(-0.35, "Y"))
    cyl(m, (0.3, a.hy, a.top + 1.4), 0.1, 1.8, (255, 100, 150), "H", "Straw", fr=fr)
    cyl(m, (-0.6, a.hy + 0.2, a.top + 1.7), 0.9, 0.12, (90, 200, 220), "H", "Umbrella", r2=0.05, fr=about((-0.6, a.hy, a.top + 1.6), R(0.3, "Y")))
    cyl(m, (-0.6, a.hy + 0.2, a.top + 1.2), 0.04, 1.0, WOOD, "H", "Umbrella", fr=about((-0.6, a.hy, a.top + 1.6), R(0.3, "Y")))


@cat("Cupcake Cat", shape="Fluffy", fur="ffd0e0", second="fff6fa", eyes="5ab0ff", blush=True)
def _cupcake(m, A):
    a = G(A)
    for k in range(20):
        ang = k * 2 * math.pi / 20
        x, y = math.cos(ang) * (a.bw / 2 + 0.25), a.by + math.sin(ang) * (a.bl / 2 + 0.25)
        box(m, (x, y, a.leg + 0.55), (0.3, 0.55, 1.3), (255, 140, 180) if k % 2 else (255, 200, 220), "B", "Cup", studs=False,
            fr=about((x, y, a.leg), R(ang, "Z")))
    ears_out(m, A)
    stack(m, (0, a.hy, a.top - 0.05), a.hw * 0.95, a.hw * 0.35, 1.2, 4, [(255, 245, 235), (255, 230, 240)], d0=a.hd * 0.95, d1=a.hd * 0.35)
    ball(m, (0, a.hy, a.top + 1.35), 0.32, (220, 20, 50), "H", "Cherry")
    fx(m, A, "orbit", "pixel", [(255, 90, 160), (70, 180, 255), (255, 210, 50), (120, 220, 120)], n=14, s=0.25, emit=0.2)


@cat("Donut Cat", shape="Loaf", fur="d89a4a", second="fff0d0", eyes="3c96ff")
def _donut(m, A):
    a = G(A)
    rr = max(a.bw, a.bl) / 2 + 0.7
    for k in range(18):
        ang = k * 2 * math.pi / 18
        c = (math.cos(ang) * rr * 0.8, a.by + math.sin(ang) * rr, a.bz + 0.1)
        box(m, c, (1.2, 1.0, 1.0), (210, 150, 80), "B", "Donut", fr=about(c, R(ang, "Z")))
        box(m, (c[0], c[1], c[2] + 0.55), (1.24, 1.04, 0.16), (255, 140, 190), "B", "Icing", studs=False, fr=about(c, R(ang, "Z")))
        box(m, (c[0], c[1], c[2] + 0.66), (0.2, 0.08, 0.08), [(255, 255, 255), (70, 180, 255), (255, 210, 50)][k % 3], "B", "Sprinkle",
            studs=False, fr=about(c, R(ang + k, "Z")))


@cat("Ice Cream Cat", shape="Fluffy", fur="e8b878", second="fff0d8", eyes="3c96ff", blush=True)
def _icecream(m, A):
    a = G(A)
    for s in (-1, 1):
        for k in range(4):
            box(m, (s * (a.bw / 2 + 0.1), a.by - a.bl * 0.35 + k * a.bl * 0.24, a.bz), (0.08, 0.12, a.bh * 0.95), (190, 130, 70), "B", "Waffle", studs=False)
        for v in (-0.3, 0.05, 0.4):
            box(m, (s * (a.bw / 2 + 0.11), a.by, a.bz + v * a.bh), (0.08, a.bl * 0.95, 0.12), (190, 130, 70), "B", "Waffle", studs=False)
    ears_out(m, A)
    for k, col in enumerate(((255, 160, 200), (150, 230, 190), (255, 245, 225))):
        box(m, (0, a.hy, a.top + 0.35 + k * 0.75), (a.hw * (0.9 - k * 0.15), a.hd * (0.9 - k * 0.15), 0.75), col, "H", "Scoop")
    ball(m, (0, a.hy, a.top + 2.5), 0.28, (220, 20, 50), "H", "Cherry")
    for x in (-0.6, 0.3):
        box(m, (x, a.hy - a.hd * 0.45, a.top + 0.05), (0.25, 0.12, 0.5), (255, 160, 200), "H", "Drip", studs=False)


@cat("Cake Cat", shape="Loaf", fur="ffffff", second="ffffff", eyes="3c96ff", blush=True)
def _cake(m, A):
    a = G(A)
    shirt(m, A, None, stripes=[(255, 245, 235), (230, 60, 80), (255, 245, 235), (230, 60, 80), (255, 245, 235)], h=a.bh)
    for k in range(10):
        box(m, (-a.bw / 2 + 0.2 + (k % 5) * (a.bw - 0.4) / 4, a.bfront - CLOTH - 0.05 if k < 5 else a.bback + CLOTH + 0.05, a.btop + 0.05),
            (0.3, 0.14, 0.35), (230, 60, 80), "B", "Drip", studs=False)
    for x in (-0.6, 0.0, 0.6):
        cyl(m, (x, a.hy, a.top + 0.45), 0.12, 0.9, [(255, 120, 160), (90, 180, 255), (255, 210, 60)][int(x / 0.6) + 1], "H", "Candle")
        m.blob((0.12, 0.12, 0.22), (255, 190, 60), T(x, a.hy, a.top + 1.05), e1=0.8, e2=1.0, nu=8, nv=6, name="H_Flame", emit=3.0)
    ball(m, (0.9, a.hy - 0.6, a.top + 0.25), 0.3, (220, 20, 50), "H", "Strawberry")


@cat("Sushi Cat", shape="Loaf", fur="ff8a5a", second="fff0e8", eyes="3c96ff", pattern="mackerel", patternColor="fff0e8")
def _sushi(m, A):
    a = G(A)
    plate(m, (0, a.by, -0.0 + 0.2), (a.bw + 1.0, a.bl + 1.2, 0.4), (250, 250, 245), "B", "Rice")
    rnd = random.Random(2)
    for k in range(10):
        box(m, (rnd.uniform(-1, 1) * (a.bw / 2 + 0.4), a.by + rnd.uniform(-1, 1) * (a.bl / 2 + 0.5), 0.42), (0.25, 0.14, 0.12), WHITE,
            "B", "Grain", studs=False)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.25), a.by, a.bz - 0.1), (0.1, 1.0, a.bh + 0.4), (30, 45, 35), "B", "Nori", studs=False)
    box(m, (0, a.by, a.btop + 0.25), (a.bw + 0.5, 1.0, 0.1), (30, 45, 35), "B", "Nori", studs=False)


@cat("Burger Cat", shape="Fluffy", fur="b07a4a", second="f6e2c8", eyes="3c96ff")
def _burger(m, A):
    a = G(A)
    bun = (215, 150, 70)
    plate(m, (0, a.by, a.leg - 0.1), (a.bw + 0.9, a.bl + 0.9, 0.45), bun, "B", "Bun")
    for k in range(12):
        ang = k * 2 * math.pi / 12
        box(m, (math.cos(ang) * (a.bw / 2 + 0.4), a.by + math.sin(ang) * (a.bl / 2 + 0.4), a.leg + 0.2), (0.6, 0.6, 0.12), (100, 200, 70),
            "B", "Lettuce", studs=False, fr=about((0, a.by, 0), R(ang, "Z")))
    plate(m, (0, a.by, a.leg + 0.45), (a.bw + 0.5, a.bl + 0.5, 0.12), (255, 205, 40), "B", "Cheese")
    for x, y in ((-1, -1), (1, 1), (1, -1)):
        wedge(m, (x * (a.bw / 2 + 0.3), a.by + y * (a.bl / 2 + 0.3), a.leg + 0.25), (0.5, 0.5, 0.4), (255, 205, 40), "B", "Cheese",
              fr=about((x * (a.bw / 2 + 0.3), a.by + y * (a.bl / 2 + 0.3), a.leg + 0.25), R(math.atan2(y, x) - math.pi / 2, "Z") @ R(math.pi, "X")))
    ears_out(m, A)
    stack(m, (0, a.hy, a.top), a.hw * 1.05, a.hw * 0.6, 0.8, 3, bun, d0=a.hd * 1.05, d1=a.hd * 0.6)
    for x, y in ((-0.6, -0.3), (0.3, -0.5), (0.7, 0.2), (-0.2, 0.3), (0.1, -0.05)):
        box(m, (x, a.hy + y, a.top + 0.84), (0.2, 0.12, 0.06), (255, 245, 220), "H", "Seed", studs=False)


@cat("Pizza Cat", shape="Slim", fur="ffd24a", second="fff4c4", eyes="52d273")
def _pizza(m, A):
    a = G(A)
    marks(m, A, 9, 0.55, (210, 50, 40), shape="disc", seed=7, head=3, off=0.1)
    box(m, (0, a.bback + 0.15, a.bz + 0.2), (a.bw + 0.2, 0.35, a.bh + 0.4), (210, 140, 60), "B", "Crust")
    for x in (-0.5, 0.4):
        box(m, (x, a.bfront - 0.1, a.btop - 0.3), (0.25, 0.1, 0.6), (255, 215, 80), "B", "Drip", studs=False)
    marks(m, A, 6, 0.18, (70, 160, 60), seed=9, off=0.12)


@cat("Taco Cat", shape="Loaf", fur="b07a4a", second="f6e2c8", eyes="ffd23c")
def _taco(m, A):
    a = G(A)
    shell = (245, 195, 80)
    for s in (-1, 1):
        c = (s * (a.bw / 2 + 0.35), a.by, a.bz - 0.1)
        box(m, c, (0.3, a.bl + 0.8, a.bh + 0.6), shell, "B", "Shell", fr=about((s * (a.bw / 2), a.by, a.leg), R(s * 0.2, "Y")))
        for k in range(7):
            box(m, (s * (a.bw / 2 + 0.25), a.bfront - 0.2 + k * (a.bl + 0.4) / 6, a.btop + 0.3), (0.35, 0.4, 0.3),
                (100, 200, 70) if k % 3 else (230, 50, 50), "B", "Lettuce", studs=False)
    plate(m, (0, a.by, a.leg - 0.15), (a.bw + 0.6, a.bl + 0.8, 0.3), shell, "B", "Shell")
    marks(m, A, 6, 0.3, (255, 210, 60), where=("top",), seed=3, off=0.14)


@cat("Hotdog Cat", shape="Slim", fur="c8503a", second="ffd8c8", eyes="ffd23c")
def _hotdog(m, A):
    a = G(A)
    bun = (225, 165, 85)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.3), a.by, a.leg + 0.45), (0.6, a.bl + 0.9, 1.1), bun, "B", "Bun")
    plate(m, (0, a.by, a.leg - 0.05), (a.bw + 1.2, a.bl + 0.9, 0.2), bun, "B", "Bun")
    for k in range(7):
        box(m, (0.35 * (1 if k % 2 else -1), a.bfront + 0.3 + k * (a.bl - 0.6) / 6, a.btop + 0.12), (0.7, 0.18, 0.1), (255, 215, 40),
            "B", "Mustard", studs=False, fr=about((0.35 * (1 if k % 2 else -1), a.bfront + 0.3 + k * (a.bl - 0.6) / 6, a.btop), R(0.6 if k % 2 else -0.6, "Z")))


@cat("Popcorn Cat", shape="Fluffy", fur="fff4d8", second="ffffff", eyes="3c96ff", blush=True)
def _popcorn(m, A):
    a = G(A)
    for k in range(16):
        ang = k * 2 * math.pi / 16
        x, y = math.cos(ang) * (a.bw / 2 + 0.3), a.by + math.sin(ang) * (a.bl / 2 + 0.3)
        box(m, (x, y, a.leg + 0.6), (0.3, 0.7, 1.4), (220, 40, 50) if k % 2 else WHITE, "B", "Bucket", studs=False, fr=about((x, y, 0), R(ang, "Z")))
    marks(m, A, 10, 0.55, [(255, 250, 230), (255, 235, 170)], shape="ball", where=("top",), seed=4, head=5, off=0.2)
    fx(m, A, "orbit", "cloud", [(255, 250, 230)], n=5, s=0.35, emit=0.1, z=(2.0, 4.5))


@cat("Boba Cat", shape="Loaf", fur="c8a07a", second="fff0e0", eyes="3c96ff")
def _boba(m, A):
    a = G(A)
    box(m, (0, a.by, a.bz - 0.1), (a.bw + 0.6, a.bl + 0.6, a.bh + 0.9), (220, 235, 255), "B", "Cup", studs=False, alpha=0.3, rough=0.02, coat=1.0)
    rnd = random.Random(1)
    for k in range(16):
        ball(m, (rnd.uniform(-1, 1) * (a.bw / 2 + 0.15), a.by + rnd.uniform(-1, 1) * (a.bl / 2 + 0.15), 0.2 + rnd.uniform(0, 0.4)), 0.2, INK, "B", "Pearl")
    box(m, (0, a.by, a.btop + 0.35), (a.bw + 0.7, a.bl + 0.7, 0.12), (255, 150, 190), "B", "Lid", studs=False, alpha=0.6)
    cyl(m, (0.6, a.by + 0.6, a.btop + 1.0), 0.22, 2.4, (255, 120, 170), "B", "Straw", fr=about((0.6, a.by + 0.6, a.btop), R(0.25, "Y")))


@cat("Mochi Cat", shape="Fluffy", chubby=True, fur="fff6f8", second="ffffff", eyes="ff7aa8", eyeStyle="sleepy", blush=True)
def _mochi(m, A):
    a = G(A)
    marks(m, A, 10, 0.12, (255, 255, 255), seed=8, head=4)
    flower(m, (0, a.hy, a.top + 0.1), 0.8, (255, 170, 200))
    box(m, (0.6, a.hy, a.top + 0.1), (0.8, 0.4, 0.1), LEAF, "H", "Leaf", studs=False)


@cat("Macaron Cat", shape="Loaf", fur="ffd0e4", second="fff6fa", eyes="5ab0ff", blush=True)
def _macaron(m, A):
    a = G(A)
    ears_out(m, A)
    z = a.top
    for k, col in enumerate(((150, 220, 200), (255, 170, 200), (210, 180, 255))):
        cyl(m, (0, a.hy, z + 0.15), a.hw * (0.42 - k * 0.04), 0.3, col, "H", "Macaron")
        cyl(m, (0, a.hy, z + 0.38), a.hw * (0.4 - k * 0.04), 0.16, (255, 250, 240), "H", "Cream")
        cyl(m, (0, a.hy, z + 0.6), a.hw * (0.42 - k * 0.04), 0.3, col, "H", "Macaron")
        z += 0.75


@cat("Lollipop Cat", shape="Slim", fur="ffd0e4", second="ffffff", eyes="5ab0ff", pattern="mackerel", patternColor="ffffff")
def _lollipop(m, A):
    a = G(A)

    def build(m, A, root):
        cyl(m, (0, root.y + 0.3, root.z + 1.0), 0.1, 2.0, WHITE, "T", "Stick", fr=about((0, root.y, root.z), R(-0.3, "X")))
        c = about((0, root.y, root.z), R(-0.3, "X")) @ Vector((0, root.y + 0.3, root.z + 2.4))
        for k in range(5):
            cyl(m, c, 1.0 - k * 0.2, 0.25 + k * 0.02, (255, 120, 170) if k % 2 == 0 else WHITE, "T", "Lolly", axis="Y")
    tail_swap(m, A, build)


@cat("Cookie Cat", shape="Loaf", fur="d8a050", second="f6e2c0", eyes="52d273")
def _cookie(m, A):
    a = G(A)
    marks(m, A, 14, 0.32, (80, 45, 25), seed=6, head=5, off=0.1)
    remove_one = [o for o in m.objects if o.name.startswith("Ear")]
    fx(m, A, "ground", "cube", [(200, 150, 80), (90, 55, 30)], n=7, s=0.25, emit=0.0)


@cat("Whale Cat", shape="Fluffy", fur="3a70c8", second="eaf2ff", eyes="ffd23c", pattern="bib")
def _whale(m, A):
    a = G(A)

    def build(m, A, root):
        box(m, (0, root.y + 0.4, root.z + 0.2), (0.7, 0.9, 0.6), (58, 112, 200), "T", "Tail")
        for x in (-1, 1):
            box(m, (x * 0.7, root.y + 1.0, root.z + 0.65), (1.3, 0.6, 0.18), (58, 112, 200), "T", "Fluke",
                fr=about((x * 0.2, root.y + 1.0, root.z + 0.6), R(x * -0.3, "Y")))
    tail_swap(m, A, build)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.4), a.bfront + 0.6, a.leg + 0.4), (0.8, 0.6, 0.16), (58, 112, 200), "B", "Fin",
            fr=about((s * (a.bw / 2), a.bfront + 0.6, a.leg + 0.4), R(s * -0.5, "Y")))
    for k in range(4):
        box(m, (0, a.bfront - 0.12, a.leg + 0.3 + k * 0.4), (a.bw * 0.6, 0.06, 0.08), (200, 215, 240), "B", "Groove", studs=False)
    for k in range(5):
        fx_c = (0.0 + (k - 2) * 0.25, a.hy + 0.2, a.top + 0.6 + k * 0.35 - abs(k - 2) * 0.25)
        ball(m, fx_c, 0.22, (150, 210, 255), "Fx", "Spout", emit=0.4, alpha=0.8)


@cat("Shark Cat", shape="Slim", fur="8aa0b8", second="ffffff", eyes="3c96ff", pattern="bicolor")
def _shark(m, A):
    a = G(A)
    remove(m, ("Ear", "EarIn"))
    grey = (110, 135, 160)
    box(m, (0, a.hy + 0.15, a.top + 0.15), (a.hw + 0.3, a.hd + 0.1, 0.35), grey, "H", "Hood")
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.15), a.hy + 0.15, a.hz + 0.2), (0.3, a.hd + 0.1, a.hh * 0.75), grey, "H", "Hood")
    for k in range(7):
        wedge(m, (-a.hw * 0.42 + k * a.hw * 0.14, a.front - 0.15, a.top - 0.25), (0.3, 0.2, 0.3), WHITE, "H", "Tooth",
              fr=about((-a.hw * 0.42 + k * a.hw * 0.14, a.front - 0.15, a.top - 0.25), R(math.pi, "X")))
    wedge(m, (0, a.hy + 0.3, a.top + 0.85), (0.25, 1.2, 1.1), grey, "H", "Fin", fr=about((0, a.hy + 0.3, a.top + 0.85), R(math.pi, "Z")))
    wedge(m, (0, a.by + 0.3, a.btop + 0.55), (0.25, 1.0, 0.9), grey, "B", "Fin", fr=about((0, a.by + 0.3, a.btop + 0.55), R(math.pi, "Z")))


@cat("Gorilla Cat", shape="Fluffy", big=True, fur="2e2a33", second="7a7480", eyes="ffb020")
def _gorilla(m, A):
    a = G(A)
    face = (130, 120, 135)
    box(m, (0, a.front - 0.04, a.hz - 0.15), (a.hw * 0.75, 0.1, a.hh * 0.7), face, "H", "Face", studs=False)
    box(m, (0, a.front - 0.15, a.eyes[0].z + 0.45), (a.hw * 0.85, 0.3, 0.3), (40, 36, 44), "H", "Brow")
    front_patch(m, A, face, w=0.7, h=0.75)
    for i in (0, 2):
        p = a.paws[i]
        s = -1 if p.x < 0 else 1
        box(m, (p.x + s * 0.35, p.y - 0.2, a.leg * 0.5 + 0.5), (1.3, 1.3, a.leg + 1.6), (46, 42, 51), "L", "Arm")
        box(m, (p.x + s * 0.35, p.y - 0.3, 0.25), (1.4, 1.5, 0.5), face, "L", "Fist")


@cat("Panda Cat", shape="Fluffy", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="points", patternColor="2b2733")
def _panda(m, A):
    a = G(A)
    remove(m, ("Mask",))
    for e in a.eyes:
        box(m, (e.x, a.front - 0.03, e.z - 0.05), (0.95, 0.08, 1.1), (43, 39, 51), "H", "Patch", studs=False,
            fr=about((e.x, a.front, e.z), R(0.3 if e.x > 0 else -0.3, "Y")))
    recolor(m, ("Muzzle",), WHITE)
    b = held(m, A, -1)
    for k in range(4):
        cyl(m, (b.x, b.y, 0.4 + k * 0.6), 0.16, 0.56, (110, 190, 80), "L", "Bamboo")
        cyl(m, (b.x, b.y, 0.7 + k * 0.6), 0.18, 0.06, (80, 150, 60), "L", "Bamboo")
    box(m, (b.x - 0.35, b.y, 2.3), (0.6, 0.12, 0.25), LEAF, "L", "Leaf", studs=False, fr=about((b.x, b.y, 2.3), R(0.4, "Y")))


@cat("Bee Cat", shape="Loaf", fur="ffd23a", second="fff4c4", eyes="3c96ff", pattern="tiger", patternColor="2b2733", blush=True)
def _bee(m, A):
    wings(m, A, [(220, 240, 255), (200, 230, 255)], kind="bug", span=1.1, up=0.6, alpha=0.5)
    antennae(m, A, (43, 39, 51), tip=(43, 39, 51))
    a = G(A)

    def build(m, A, root):
        wedge(m, (0, root.y + 0.4, root.z + 0.1), (0.5, 0.7, 0.4), (43, 39, 51), "T", "Stinger", fr=about((0, root.y + 0.4, root.z + 0.1), R(math.pi / 2, "X")))
    tail_swap(m, A, build)


@cat("Frog Cat", shape="Loaf", fur="5cc04a", second="d8f0b0", eyes="2b2733")
def _frog(m, A):
    a = G(A)
    remove(m, ("Ear", "EarIn"))
    green = (90, 190, 75)
    box(m, (0, a.hy + 0.1, a.top + 0.15), (a.hw + 0.3, a.hd + 0.2, 0.35), green, "H", "Hood")
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.15), a.hy + 0.1, a.hz + 0.2), (0.3, a.hd + 0.2, a.hh * 0.75), green, "H", "Hood")
        ball(m, (x * 0.7, a.hy - 0.3, a.top + 0.6), 0.55, green, "H", "FrogEye")
        ball(m, (x * 0.7, a.hy - 0.65, a.top + 0.7), 0.33, WHITE, "H", "FrogEye")
        ball(m, (x * 0.7, a.hy - 0.9, a.top + 0.72), 0.16, INK, "H", "FrogEye")
    box(m, (0, a.front - 0.04, a.hb + 0.35), (a.hw * 0.75, 0.1, 0.12), (220, 80, 100), "H", "Mouth", studs=False)
    marks(m, A, 6, 0.3, (60, 150, 50), seed=2, off=0.1)


@cat("Penguin Cat", shape="Loaf", fur="2b2733", second="ffffff", eyes="3c96ff", pattern="tuxedo")
def _penguin(m, A):
    a = G(A)
    orange = (255, 150, 40)
    front_patch(m, A, WHITE, w=0.85, h=0.95)
    beak(m, A, orange, long=0.5)
    for p in a.paws:
        box(m, (p.x, p.y - 0.3, 0.12), (1.1, 1.5, 0.24), orange, "L", "Foot", studs=False)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.15), a.by - 0.2, a.bz), (0.2, 1.2, a.bh * 0.9), (43, 39, 51), "B", "Flipper",
            fr=about((s * (a.bw / 2), a.by, a.btop), R(s * 0.25, "Y")))
    box(m, (0, a.hy, a.top - 0.2), (a.hw + 0.15, a.hd + 0.15, 0.3), (60, 60, 80), "H", "Cap", studs=False)


@cat("Bunny Cat", shape="Fluffy", fur="ffffff", second="fff2f6", eyes="ff7aa8", blush=True)
def _bunny(m, A):
    a = G(A)

    def ears(a):
        for x in (-1, 1):
            fr = about((x * 0.6, a.hy + 0.1, a.top), R(x * 0.15, "Y"))
            box(m, (x * 0.6, a.hy + 0.1, a.top + 1.1), (0.7, 0.4, 2.2), WHITE, "H", "Ear", fr=fr)
            box(m, (x * 0.6, a.hy - 0.12, a.top + 1.1), (0.4, 0.06, 1.8), (255, 160, 200), "H", "EarIn", fr=fr, studs=False)
    new_ears(m, A, ears)

    def build(m, A, root):
        ball(m, (0, root.y + 0.35, root.z + 0.4), 0.6, WHITE, "T", "Puff")
    tail_swap(m, A, build)
    box(m, (0, a.front - 0.48, a.mz - 0.32), (0.4, 0.08, 0.3), WHITE, "H", "Teeth", studs=False)


@cat("Owl Cat", shape="Fluffy", fur="a8784a", second="f0e0c8", eyes="ffb020", eyeStyle="big")
def _owl(m, A):
    a = G(A)
    for e in a.eyes:
        cyl(m, (e.x, a.front - 0.04, e.z - 0.05), 0.65, 0.08, (240, 225, 200), "H", "EyeRing", axis="Y")
    beak(m, A, (230, 170, 60), long=0.35)
    wings(m, A, [(140, 100, 60), (170, 125, 80)], kind="feather", span=0.75, up=1.2)
    front_patch(m, A, (240, 225, 200), w=0.8, h=0.9)
    for k in range(6):
        box(m, (-0.5 + (k % 3) * 0.5, a.bfront - 0.17, a.leg + 0.6 + (k // 3) * 0.6), (0.3, 0.06, 0.12), (170, 125, 80), "B", "Feather", studs=False)


@cat("Turtle Cat", shape="Loaf", fur="7ac85a", second="e8f5c8", eyes="3c96ff")
def _turtle(m, A):
    shell(m, A, (130, 90, 50), col2=(160, 115, 65))
    a = G(A)
    for x, y in ((-0.5, -0.4), (0.5, -0.4), (0, 0.3), (-0.5, 0.9), (0.5, 0.9)):
        box(m, (x, a.by + y, a.btop + 1.2), (0.5, 0.5, 0.1), (100, 70, 40), "B", "Scute", studs=False)


@cat("Fox Cat", shape="Slim", fur="ff8a2a", second="ffffff", eyes="ffd23c", pattern="bib", ears="big")
def _fox(m, A):
    a = G(A)

    def build(m, A, root):
        for k, (y, z, s) in enumerate(((0.4, 0.3, 0.9), (0.9, 0.9, 1.2), (1.2, 1.7, 1.2), (1.25, 2.4, 0.9))):
            box(m, (0, root.y + y, root.z + z), (s, s, 0.9), WHITE if k == 3 else (255, 138, 42), "T", "Tail")
    tail_swap(m, A, build)
    box(m, (0, a.front - 0.55, a.mz - 0.05), (0.8, 0.35, 0.5), WHITE, "H", "Snout")
    box(m, (0, a.front - 0.75, a.mz + 0.12), (0.3, 0.1, 0.2), INK, "H", "Nose", studs=False)
    for o in m.objects:
        if o.name.startswith("Ear") and not o.name.startswith("EarIn"):
            pass
    for p in a.paws:
        box(m, (p.x, p.y - 0.06, 0.3), (1.08, 1.12, 0.55), (60, 45, 40), "L", "Sock")


@cat("Bear Cat", shape="Fluffy", fur="9a6a44", second="f0dcc0", eyes="3c96ff")
def _bear(m, A):
    a = G(A)

    def ears(a):
        for x in (-1, 1):
            cyl(m, (x * (a.hw / 2 - 0.45), a.hy + 0.1, a.top + 0.35), 0.55, 0.35, (154, 106, 68), "H", "Ear", axis="Y")
            cyl(m, (x * (a.hw / 2 - 0.45), a.hy - 0.08, a.top + 0.35), 0.3, 0.06, (240, 220, 190), "H", "EarIn", axis="Y")
    new_ears(m, A, ears)
    b = held(m, A, -1)
    box(m, (b.x, b.y, 0.55), (0.9, 0.9, 1.0), (240, 180, 50), "L", "Honey")
    box(m, (b.x, b.y, 1.1), (1.0, 1.0, 0.2), (200, 70, 50), "L", "Honey", studs=False)
    box(m, (b.x, b.y - 0.46, 0.55), (0.6, 0.06, 0.35), WHITE, "L", "Label", studs=False)
    box(m, (b.x + 0.2, b.y - 0.3, 1.25), (0.25, 0.25, 0.2), (240, 180, 50), "L", "Drip", studs=False)


@cat("Lion Cat", shape="Fluffy", fur="f2b84a", second="fff0d0", eyes="ffb020")
def _lion(m, A):
    a = G(A)
    mane = (220, 110, 40)
    for k in range(14):
        ang = k * 2 * math.pi / 14
        x, z = math.cos(ang) * (a.hw / 2 + 0.25), a.hz + math.sin(ang) * (a.hh / 2 + 0.2)
        box(m, (x, a.hy + 0.3, z), (0.8, a.hd * 0.8, 0.8), mane if k % 2 else (200, 90, 30), "H", "Mane", fr=about((x, a.hy, z), R(-ang, "Y")))

    def build(m, A, root):
        for k in range(3):
            box(m, (0, root.y + 0.3 + k * 0.35, root.z + 0.2 + k * 0.6), (0.4, 0.4, 0.7), (242, 184, 74), "T", "Tail")
        box(m, (0, root.y + 1.1, root.z + 2.0), (0.8, 0.8, 0.8), mane, "T", "Tuft")
    tail_swap(m, A, build)


@cat("Bat Cat", shape="Slim", fur="4a2e6a", second="8a6aaa", eyes="ffd23c", ears="big", eyeStyle="big")
def _bat(m, A):
    wings(m, A, [(60, 40, 80), (110, 80, 150)], kind="bat", span=1.0, up=0.4)
    a = G(A)
    for x in (-0.25, 0.25):
        wedge(m, (x, a.front - 0.48, a.mz - 0.3), (0.14, 0.1, 0.22), WHITE, "H", "Fang", fr=about((x, a.front - 0.48, a.mz - 0.3), R(math.pi, "X")))


@cat("Octopus Cat", shape="Fluffy", fur="e88ac8", second="ffe0f2", eyes="3c96ff", blush=True)
def _octopus(m, A):
    a = G(A)
    remove(m, ("Leg", "Paw"))
    col = (225, 120, 190)
    for k in range(6):
        ang = k * 2 * math.pi / 6 + 0.5
        bx, by_ = math.cos(ang) * (a.bw / 2 - 0.3), a.by + math.sin(ang) * (a.bl / 2 - 0.3)
        for j in range(4):
            r = 0.5 + j * 0.6
            z = 0.45 - j * 0.12 + (0.45 if j == 3 else 0)
            c = (math.cos(ang) * r + bx * 0.5, a.by + math.sin(ang) * r * 1.1 + (by_ - a.by) * 0.5, z)
            box(m, c, (0.95 - j * 0.12, 0.95 - j * 0.12, 0.8 - j * 0.1), col, "L", "Tentacle", fr=about(c, R(ang, "Z")))
            if j < 3:
                cyl(m, (c[0], c[1], c[2] - 0.42 + j * 0.05), 0.16, 0.05, (255, 200, 230), "L", "Sucker")
    fx(m, A, "ground", "drop", [(80, 60, 110)], n=5, s=0.35, emit=0.0)


@cat("Crab Cat", shape="Loaf", fur="e8402a", second="ffd0c0", eyes="2b2733")
def _crab(m, A):
    a = G(A)
    for s in (-1, 1):
        b = held(m, A, s)
        box(m, (b.x, b.y - 0.2, 0.9), (0.4, 0.4, 1.4), (230, 64, 42), "L", "Arm")
        box(m, (b.x, b.y - 0.3, 1.85), (0.9, 1.0, 0.7), (230, 64, 42), "L", "Claw")
        box(m, (b.x, b.y - 0.55, 2.4), (0.6, 0.4, 0.7), (230, 64, 42), "L", "Claw", fr=about((b.x, b.y - 0.3, 2.2), R(0.4, "X")))
        box(m, (b.x, b.y - 0.05, 2.4), (0.6, 0.35, 0.55), (230, 64, 42), "L", "Claw", fr=about((b.x, b.y - 0.3, 2.2), R(-0.3, "X")))
    eye_stalks(m, A, (230, 64, 42))


@cat("Duck Cat", shape="Loaf", fur="ffd84a", second="fff4c4", eyes="3c96ff", blush=True)
def _duck(m, A):
    a = G(A)
    beak(m, A, (255, 140, 40), long=0.7)
    rr = max(a.bw, a.bl) / 2 + 0.45
    for k in range(16):
        ang = k * 2 * math.pi / 16
        c = (math.cos(ang) * rr * 0.8, a.by + math.sin(ang) * rr, a.leg + 0.3)
        box(m, c, (0.75, 0.75, 0.7), (230, 50, 60) if (k // 2) % 2 else WHITE, "B", "Ring", fr=about(c, R(ang, "Z")))
    box(m, (0, a.hy - 0.1, a.top + 0.25), (0.25, 0.6, 0.5), (255, 200, 40), "H", "Tuft", studs=False)


@cat("Sheep Cat", shape="Fluffy", fur="fffaf2", second="ffffff", eyes="3c96ff", cloud=True, patternColor="f2ede4")
def _sheep(m, A):
    a = G(A)
    marks(m, A, 12, 0.7, [(255, 252, 245), (245, 240, 230)], shape="ball", seed=3, head=4, off=0.15)
    for x in (-1, 1):
        for k in range(5):
            ang = k * 1.2
            box(m, (x * (a.hw / 2 + 0.25 + 0.3 * math.cos(ang)), a.hy + 0.2, a.hz + 0.4 + 0.35 * math.sin(ang)), (0.32, 0.4, 0.32),
                (200, 170, 130), "H", "Horn", studs=False)
    box(m, (0, a.front - 0.04, a.hz - 0.25), (a.hw * 0.55, 0.08, a.hh * 0.45), (90, 80, 85), "H", "Face", studs=False)


@cat("Deer Cat", shape="Slim", fur="b07a4a", second="f6e2c8", eyes="2b2733", pattern="spots", patternColor="fff4e0", seed=12)
def _deer(m, A):
    a = G(A)
    ant = (200, 165, 110)
    for x in (-1, 1):
        bx = x * (a.hw / 2 - 0.4)
        box(m, (bx, a.hy + 0.2, a.top + 0.7), (0.22, 0.22, 1.4), ant, "H", "Antler", studs=False)
        box(m, (bx + x * 0.35, a.hy + 0.2, a.top + 1.2), (0.7, 0.2, 0.2), ant, "H", "Antler", studs=False)
        box(m, (bx + x * 0.65, a.hy + 0.2, a.top + 1.55), (0.2, 0.2, 0.7), ant, "H", "Antler", studs=False)
        box(m, (bx - x * 0.25, a.hy + 0.2, a.top + 1.55), (0.2, 0.2, 0.5), ant, "H", "Antler", studs=False)
    box(m, (0, a.front - 0.5, a.mz + 0.2), (0.4, 0.12, 0.3), INK, "H", "Nose", studs=False)


@cat("Elephant Cat", shape="Fluffy", fur="9aa0ac", second="c8ccd6", eyes="3c96ff")
def _elephant(m, A):
    a = G(A)

    def ears(a):
        for x in (-1, 1):
            box(m, (x * (a.hw / 2 + 0.6), a.hy + 0.2, a.hz + 0.2), (1.2, 0.25, 1.8), (150, 158, 172), "H", "Ear",
                fr=about((x * (a.hw / 2), a.hy + 0.2, a.hz), R(x * 0.0, "Z") @ R(0.3 * x, "Z")))
            box(m, (x * (a.hw / 2 + 0.6), a.hy + 0.05, a.hz + 0.2), (0.85, 0.06, 1.3), (230, 170, 190), "H", "EarIn", studs=False,
                fr=about((x * (a.hw / 2), a.hy + 0.2, a.hz), R(0.3 * x, "Z")))
    new_ears(m, A, ears)
    for k in range(3):
        box(m, (0, a.front - 0.5 - k * 0.3, a.mz - 0.1 - k * 0.35), (0.6 - k * 0.07, 0.5, 0.5), (154, 160, 172), "H", "Trunk")
    for x in (-0.55, 0.55):
        wedge(m, (x, a.front - 0.35, a.mz - 0.45), (0.2, 0.5, 0.2), WHITE, "H", "Tusk", fr=about((x, a.front - 0.35, a.mz - 0.45), R(math.pi, "Z")))
    fx(m, A, "above", "drop", [(150, 210, 255)], n=5, s=0.35, emit=0.3)


@cat("Koala Cat", shape="Fluffy", fur="9aa0ac", second="ffffff", eyes="2b2733")
def _koala(m, A):
    a = G(A)

    def ears(a):
        for x in (-1, 1):
            ball(m, (x * (a.hw / 2 + 0.1), a.hy + 0.1, a.top + 0.1), (0.75, 0.4, 0.7), (154, 160, 172), "H", "Ear")
            ball(m, (x * (a.hw / 2 + 0.1), a.hy - 0.2, a.top + 0.1), (0.5, 0.15, 0.45), WHITE, "H", "EarIn")
    new_ears(m, A, ears)
    box(m, (0, a.front - 0.45, a.mz + 0.15), (0.7, 0.3, 0.6), (43, 39, 51), "H", "BigNose")
    b = held(m, A, -1)
    fr = T(b.x - 0.2, b.y, 0.0) @ R(0.15, "Y")
    cyl(m, (0, 0, 1.4), 0.22, 2.8, (140, 100, 60), "L", "Branch", fr=fr)
    for k in range(3):
        box(m, (0.3, 0, 1.6 + k * 0.5), (0.7, 0.35, 0.12), (110, 170, 120), "L", "Leaf", fr=fr, studs=False)


@cat("Axolotl Cat", shape="Slim", fur="ffb0c8", second="ffe6ee", eyes="2b2733", blush=True)
def _axolotl(m, A):
    a = G(A)
    for x in (-1, 1):
        for k in range(3):
            box(m, (x * (a.hw / 2 + 0.45), a.hy + 0.3, a.hz + 0.6 - k * 0.5), (0.9, 0.18, 0.25), (255, 100, 150), "H", "Gill",
                fr=about((x * (a.hw / 2), a.hy + 0.3, a.hz + 0.4 - k * 0.5), R(x * (0.4 - k * 0.4), "Y")))

    def build(m, A, root):
        box(m, (0, root.y + 0.8, root.z + 0.1), (0.25, 1.6, 1.0), (255, 176, 200), "T", "Paddle")
        box(m, (0, root.y + 0.8, root.z + 0.7), (0.15, 1.3, 0.3), (255, 140, 180), "T", "Fin", studs=False)
    tail_swap(m, A, build)
    fx(m, A, "rise", "bubble", [(200, 240, 255)], n=6, s=0.35, emit=0.2, z=(1.0, 4.5))


@cat("Peacock Cat", shape="Slim", fur="2aa8a0", second="d0f0ec", eyes="ffd23c")
def _peacock(m, A):
    a = G(A)

    def build(m, A, root):
        for k in range(9):
            ang = -1.2 + k * 0.3
            fr = T(0, root.y + 0.3, root.z + 0.3) @ R(ang, "Y") @ R(-0.25, "X")
            box(m, (0, 0, 1.5), (0.4, 0.12, 3.0), (40, 150, 110), "T", "Feather", fr=fr, studs=False)
            box(m, (0, -0.07, 2.7), (0.6, 0.08, 0.6), (40, 90, 200), "T", "Eye", fr=fr, studs=False, emit=0.2)
            box(m, (0, -0.1, 2.7), (0.28, 0.06, 0.28), GOLD, "T", "Eye", fr=fr, studs=False, emit=0.4)
    tail_swap(m, A, build)
    for k in range(3):
        box(m, (-0.2 + k * 0.2, a.hy, a.top + 0.5), (0.08, 0.08, 0.9), (40, 150, 110), "H", "Crest", studs=False)
        ball(m, (-0.2 + k * 0.2, a.hy, a.top + 1.0), 0.13, (40, 90, 200), "H", "Crest")
    fx(m, A, "orbit", "spark", [(120, 255, 220), (255, 230, 120), (180, 140, 255)], n=7, s=0.4, emit=2.0)


@cat("Snail Cat", shape="Loaf", fur="ffe6bc", second="fffaf0", eyes="2b2733")
def _snail(m, A):
    shell(m, A, (200, 130, 70), col2=(240, 180, 110), spiral=True)
    eye_stalks(m, A, (255, 230, 188), eye_col=(255, 230, 188), h=0.8)


@cat("Ladybug Cat", shape="Loaf", fur="2b2733", second="3d3846", eyes="ffd23c", eyeStyle="big")
def _ladybug(m, A):
    a = G(A)
    red = (225, 35, 45)
    for s in (-1, 1):
        c = (s * (a.bw / 4 + 0.08), a.by + 0.2, a.btop + 0.2)
        box(m, c, (a.bw / 2 + 0.05, a.bl + 0.3, 0.4), red, "B", "Shell", fr=about((0, a.by, a.btop), R(s * 0.12, "Y")))
        box(m, (s * (a.bw / 2 + 0.2), a.by + 0.2, a.bz + 0.1), (0.2, a.bl + 0.3, a.bh * 0.7), red, "B", "Shell")
        for u, v in ((-0.3, 0.0), (0.1, 0.0), (0.4, 0.0)):
            box(m, (c[0], a.by + u * a.bl + 0.2, a.btop + 0.42), (0.45, 0.45, 0.06), INK, "B", "Dot", studs=False)
        for u in (-0.2, 0.25):
            box(m, (s * (a.bw / 2 + 0.31), a.by + u * a.bl, a.bz + 0.1), (0.06, 0.45, 0.45), INK, "B", "Dot", studs=False)
    antennae(m, A, INK, tip=INK)


for _name, _entry in DESIGNS.items():
    blockcat.DESIGNS[_name] = _entry
