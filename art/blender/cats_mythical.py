"""Mythical tier (round 2): fantasy creatures, each with its own effect round the body (cateffects.STYLE by the
design's effectKey). Dragon Cat is in blockcat.py."""
import json
import math
import os
import random

from mathutils import Vector

import blockcat
from blockcat import GOLD, GOLD_DARK, INK, PINK, WHITE, shade
from cateffects import effect
from catparts import (BLACK, BROWN, CLOTH, SILVER, WOOD, C, G, about, armour, ball, beak, box, cape, collar, cone_hat,
                      crown, cyl, ears_out, flower, glasses, held, helmet, mix, plate, recolor, remove, ring, shell, shirt,
                      stack, star, stick, sword, tail_swap, wedge, wings, belt)
from cats_legendary import antennae, front_patch, marks, new_ears, side_patch
from kit import R, T

DESIGNS = {}
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "source", "cat_designs.json"), encoding="utf-8") as _f:
    KEYS = {d["en"]: d["effectKey"] for d in json.load(_f) if d["effectKey"]}


def cat(name, **look):
    def deco(fn):
        def full(m, A):
            fn(m, A)
            effect(m, A, KEYS[name])
        DESIGNS[name] = (full, look)
        return fn
    return deco


def horns(m, A, col, n=3, spread=0.35, back=0.42, size=0.55, curl=0.0):
    a = G(A)
    for x in (-1, 1):
        for k in range(n):
            box(m, (x * (a.hw / 2 - spread - k * 0.04 - curl * k * k * 0.1), a.hy + back + k * 0.42, a.top + 0.3 + k * 0.4),
                (size - k * 0.12, 0.55 - k * 0.08, 0.5), col, "H", "Horn", studs=False)


def spikes(m, A, col, n=4, tail=True, size=0.8):
    a = G(A)
    for k in range(n):
        y = a.by - 0.9 + k * (a.bl - 0.8) / max(1, n - 1)
        s = size - abs(k - (n - 1) / 2) * 0.12
        c = (0, y, a.btop + s * 0.35)
        box(m, c, (0.3, s, s), col, "B", "Spike", studs=False, fr=about(c, R(0.785, "X")))
    if tail:
        for t in A["tail"]:
            c = (0, t.y + 0.3, t.z + 0.1)
            box(m, c, (0.2, 0.4, 0.4), col, "T", "Spike", studs=False, fr=about(c, R(0.785, "X")))


def mane(m, A, cols, n=6, down=True):
    a = G(A)
    for k in range(n):
        col = cols[k % len(cols)]
        box(m, (0, a.hy + a.hd / 2 + 0.2 - k * 0.0, a.top - 0.2 - k * 0.4), (0.6, 0.45, 0.45), col, "H", "Mane")
        if k < 4:
            box(m, (0, a.hy - 0.3 + k * 0.45, a.top + 0.2), (0.55, 0.45, 0.4), col, "H", "Mane")


def remove_back_legs(m, A):
    a = G(A)
    for o in list(m.objects):
        n = o.name.split(".")[0]
        if n in ("Leg", "Paw", "Sock"):
            c = sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
            if c.y > a.by:
                m.objects.remove(o)
                import bpy
                bpy.data.objects.remove(o)


def glow_eyes(m, A, col, size=1.0):
    a = G(A)
    for e in a.eyes:
        box(m, (e.x, a.front - 0.15, e.z - 0.1), (0.55 * size, 0.06, 0.4 * size), col, "H", "Glow", studs=False, emit=3.0)


# --------------------------------------------------------------------------------------------------------------------
@cat("Fire Dragon Cat", shape="Slim", fur="e8402a", second="ffd080", eyes="ffd23c")
def _firedragon(m, A):
    horns(m, A, (60, 40, 40))
    spikes(m, A, (255, 160, 40))
    wings(m, A, [(120, 30, 20), (255, 120, 40)], kind="bat", span=1.1, up=0.4, emit=0.6)
    a = G(A)
    for k in range(4):
        box(m, (0, a.bfront + 0.5 + k * 0.6, a.leg - 0.02), (a.bw * 0.6, 0.45, 0.12), (255, 190, 80), "B", "Belly", studs=False)


@cat("Ice Dragon Cat", shape="Slim", fur="6fb8f0", second="e8f6ff", eyes="ffffff")
def _icedragon(m, A):
    horns(m, A, WHITE)
    spikes(m, A, (230, 250, 255))
    wings(m, A, [(170, 225, 255), (110, 180, 245), (210, 240, 255)], kind="stone", span=1.25, up=0.45, emit=0.4)
    marks(m, A, 8, 0.3, (220, 245, 255), seed=3, emit=0.3)


@cat("Phoenix Cat", shape="Slim", fur="ff8a2a", second="ffe08a", eyes="ffd23c")
def _phoenix(m, A):
    wings(m, A, [(255, 90, 30), (255, 160, 40), (255, 220, 70), (255, 120, 40)], kind="feather", span=1.15, up=0.6, emit=0.6)
    a = G(A)
    for k in range(3):
        box(m, (-0.2 + k * 0.2, a.hy + 0.1 - k * 0.1, a.top + 0.5 + k * 0.1), (0.15, 0.5, 1.0 - k * 0.15), (255, 200, 60), "H", "Crest",
            studs=False, emit=0.8, fr=about((0, a.hy, a.top), R(-0.4, "X")))

    def build(m, A, root):
        for k, col in enumerate(((255, 90, 30), (255, 160, 40), (255, 220, 70))):
            fr = T(0, root.y, root.z) @ R((k - 1) * 0.35, "Z") @ R(-1.0, "X")
            box(m, (0, 0, 1.4), (0.35, 0.12, 2.8), col, "T", "Feather", fr=fr, studs=False, emit=0.8)
    tail_swap(m, A, build)
    beak(m, A, (255, 200, 60), long=0.35)


@cat("Unicorn Cat", shape="Fluffy", fur="ffffff", second="fff6fa", eyes="b06cff", blush=True)
def _unicorn(m, A):
    a = G(A)
    stack(m, (0, a.hy - a.hd * 0.3, a.top - 0.05), 0.55, 0.12, 1.5, 6, [GOLD, (255, 240, 170)], "H", "Horn")
    rb = [(255, 110, 140), (255, 180, 60), (255, 230, 80), (120, 220, 120), (100, 180, 255), (180, 130, 255)]
    for k, col in enumerate(rb):
        box(m, (0, a.hy + a.hd / 2 + 0.15, a.top - 0.1 - k * 0.38), (0.9, 0.4, 0.4), col, "H", "Mane", studs=False)
        if k < 3:
            box(m, (0, a.hy + 0.55 - k * 0.0, a.top + 0.15 + k * 0.0), (0.6 - k * 0.1, 0.4, 0.3), col, "H", "Mane", studs=False,
                fr=T(0, -k * 0.35, 0))

    def build(m, A, root):
        for k, col in enumerate(rb):
            box(m, (0, root.y + 0.3 + k * 0.18, root.z + 0.1 + k * 0.35), (0.7, 0.5, 0.4), col, "T", "Tail", studs=False)
    tail_swap(m, A, build)
    for p in a.paws:
        box(m, (p.x, p.y - 0.06, 0.2), (1.08, 1.12, 0.4), GOLD, "L", "Hoof")


@cat("Pegasus Cat", shape="Slim", fur="f2f6ff", second="ffffff", eyes="3c96ff")
def _pegasus(m, A):
    wings(m, A, [(255, 255, 255), (170, 210, 255), (255, 255, 255), (140, 190, 250)], kind="feather", span=1.3, up=0.6)
    mane(m, A, [(150, 200, 255), (110, 170, 245)], n=5)


@cat("Griffin Cat", shape="Fluffy", fur="d8a050", second="f6e2c0", eyes="ffb020")
def _griffin(m, A):
    a = G(A)
    box(m, (0, a.hy, a.top - 0.4), (a.hw + 0.2, a.hd + 0.2, 0.9), WHITE, "H", "Feathers")
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 - 0.3), a.hy + 0.3, a.top + 0.3), (0.5, 0.8, 0.6), WHITE, "H", "Tuft",
            fr=about((x * (a.hw / 2 - 0.3), a.hy + 0.3, a.top), R(-0.6, "X")))
    beak(m, A, (255, 200, 50), long=0.7)
    wings(m, A, [(140, 95, 50), (180, 130, 70), (230, 190, 120)], kind="feather", span=1.1, up=0.6)
    for p in a.paws[:1] + a.paws[2:3]:
        box(m, (p.x, p.y - 0.06, 0.25), (1.08, 1.12, 0.5), (255, 200, 50), "L", "Talon")


@cat("Mermaid Cat", shape="Slim", fur="ffd0e4", second="fff6fa", eyes="3c96ff", blush=True)
def _mermaid(m, A):
    a = G(A)
    remove_back_legs(m, A)
    teal = (40, 190, 180)
    for k in range(4):
        c = (0, a.by + 0.6 + k * 0.55, a.leg - 0.1 - k * 0.12)
        box(m, c, (a.bw * (0.9 - k * 0.15), 0.7, 0.8 - k * 0.1), teal if k % 2 == 0 else (60, 210, 200), "B", "FishTail")
    for x in (-1, 1):
        box(m, (x * 0.6, a.bback + 1.6, 0.25), (1.1, 0.8, 0.14), (120, 230, 220), "B", "Fin", studs=False,
            fr=about((0, a.bback + 1.3, 0.25), R(x * 0.5, "Z")))
    side_patch(m, A, teal, h=0.6)
    for x in (-0.5, 0.5):
        box(m, (x, a.bfront - 0.15, a.btop - 0.5), (0.6, 0.12, 0.5), (255, 150, 190), "B", "Shell", studs=False)
    flower(m, (-a.hw / 2 + 0.3, a.hy - 0.3, a.top + 0.15), 0.7, (255, 150, 190), fr=about((-a.hw / 2 + 0.3, a.hy - 0.3, a.top + 0.15), R(math.pi / 2, "X")))


@cat("Kraken Cat", shape="Fluffy", fur="4a2a6a", second="8a6aaa", eyes="60ffd0", eyeStyle="big", glowEyes=True)
def _kraken(m, A):
    a = G(A)
    col = (90, 50, 130)
    for s in (-1, 1):
        for t in range(2):
            base = (s * (a.bw / 2 + 0.2), a.by - 0.5 + t * 1.2, a.bz)
            for j in range(5):
                c = (base[0] + s * (0.4 + j * 0.45), base[1] + math.sin(j + t) * 0.3, base[2] + 0.5 * math.sin(j * 0.9 + t))
                box(m, c, (0.6 - j * 0.07, 0.6 - j * 0.07, 0.6 - j * 0.07), col, "B", "Tentacle")
                if j < 4:
                    cyl(m, (c[0], c[1], c[2] - 0.32), 0.12, 0.05, (200, 160, 240), "B", "Sucker")
    glow_eyes(m, A, (90, 255, 210))


@cat("Yeti Cat", shape="Fluffy", big=True, fur="ffffff", second="dff0ff", eyes="3c96ff")
def _yeti(m, A):
    a = G(A)
    rnd = random.Random(2)
    for k in range(18):
        s = rnd.choice((-1, 1))
        box(m, (s * (a.bw / 2 + 0.15), a.by + rnd.uniform(-0.45, 0.45) * a.bl, a.leg + rnd.uniform(0.0, 0.5)), (0.3, 0.5, 0.9), (240, 248, 255), "B", "Fur")
    for k in range(7):
        box(m, (-a.hw * 0.4 + k * a.hw * 0.13, a.front - 0.15, a.top - 0.25), (0.35, 0.3, 0.7), (240, 248, 255), "H", "Fur")
    box(m, (0, a.front - 0.05, a.hz - 0.3), (a.hw * 0.6, 0.1, a.hh * 0.5), (150, 190, 230), "H", "Face", studs=False)


@cat("Stone Golem Cat", shape="Loaf", fur="8a8c96", second="a8aab4", eyes="60ffd0")
def _golem(m, A):
    a = G(A)
    rnd = random.Random(5)
    for k in range(10):
        f = k % 3
        if f == 0:
            c = (rnd.uniform(-0.4, 0.4) * a.bw, a.by + rnd.uniform(-0.2, 0.45) * a.bl, a.btop + 0.2)
        else:
            sx = -1 if f == 1 else 1
            c = (sx * (a.bw / 2 + 0.2), a.by + rnd.uniform(-0.45, 0.45) * a.bl, a.bz + rnd.uniform(-0.3, 0.4) * a.bh)
        box(m, c, (0.8, 0.8, 0.6), (120, 122, 132), "B", "Rock", fr=about(c, R(rnd.uniform(-0.4, 0.4), "Z") @ R(0.3, "X")))
    marks(m, A, 6, 0.55, [(100, 170, 80), (130, 190, 90)], where=("top",), seed=8, head=3, off=0.14)
    glow_eyes(m, A, (90, 255, 210), 1.1)
    for x in (-0.4, 0.3):
        box(m, (x, a.front - 0.05, a.top - 0.4), (0.1, 0.08, 0.5), (70, 70, 80), "H", "Crack", studs=False)


@cat("Crystal Cat", shape="Slim", fur="8ec8f0", second="e8f6ff", eyes="b06cff", eyeStyle="big")
def _crystal(m, A):
    a = G(A)
    cols = [(120, 200, 255), (190, 140, 255), (255, 150, 230)]
    rnd = random.Random(3)
    for k in range(7):
        y = a.by - 0.8 + k * (a.bl - 0.6) / 6
        c = (rnd.uniform(-0.4, 0.4), y, a.btop + 0.4)
        box(m, c, (0.4, 0.4, 0.9 + rnd.uniform(0, 0.6)), cols[k % 3], "B", "Crystal", studs=False, emit=0.6, rough=0.05, coat=1.0,
            fr=about((c[0], c[1], a.btop), R(rnd.uniform(-0.4, 0.4), "Y") @ R(0.785, "Z")))
    for k in range(3):
        box(m, (-0.4 + k * 0.4, a.hy, a.top + 0.6), (0.35, 0.35, 1.0 + (k == 1) * 0.5), cols[k], "H", "Crystal", studs=False, emit=0.6,
            rough=0.05, coat=1.0, fr=about((-0.4 + k * 0.4, a.hy, a.top), R((k - 1) * 0.3, "Y") @ R(0.785, "Z")))


@cat("Fairy Cat", shape="Slim", fur="ffd0e4", second="fff6fa", eyes="52d273", blush=True)
def _fairy(m, A):
    wings(m, A, [(120, 230, 160), (255, 140, 210)], kind="butterfly", span=1.3, up=0.5, alpha=0.8, emit=0.5)
    a = G(A)
    for k, col in enumerate(((255, 130, 180), (255, 220, 80), (150, 220, 255))):
        flower(m, (-0.6 + k * 0.6, a.hy - a.hd * 0.35, a.top + 0.15), 0.5, col, fr=about((-0.6 + k * 0.6, a.hy - a.hd * 0.35, a.top + 0.15), R(math.pi / 2, "X")))
    tp = stick(m, A, (120, 200, 120), h=2.2, r=0.07)
    flower(m, tp, 0.7, (255, 130, 180), bone="L", fr=about(tp, R(math.pi / 2, "X")))


@cat("Elf Cat", shape="Slim", fur="ffe6bc", second="fffaf0", eyes="52d273")
def _elf(m, A):
    a = G(A)

    def ears(a):
        for x in (-1, 1):
            box(m, (x * (a.hw / 2 + 0.55), a.hy + 0.1, a.hz + 0.5), (1.4, 0.3, 0.5), (255, 230, 188), "H", "Ear",
                fr=about((x * (a.hw / 2), a.hy, a.hz + 0.4), R(x * -0.5, "Y")))
            box(m, (x * (a.hw / 2 + 0.55), a.hy - 0.06, a.hz + 0.5), (1.0, 0.08, 0.25), PINK, "H", "EarIn", studs=False,
                fr=about((x * (a.hw / 2), a.hy, a.hz + 0.4), R(x * -0.5, "Y")))
    new_ears(m, A, ears)
    green = (60, 150, 70)
    cone_hat(m, A, green, h=1.6, w=a.hw * 0.7, tilt=0.5, n=4, pom=GOLD)
    shirt(m, A, green, h=a.bh * 0.85)
    belt(m, A, GOLD_DARK, buckle=GOLD)


@cat("Vampire Cat", shape="Slim", fur="2b2733", second="ffffff", eyes="ff4060", pattern="tuxedo", eyeStyle="big", glowEyes=True)
def _vampire(m, A):
    cape(m, A, (25, 20, 30), inner=(200, 30, 50), collar_up=True, long=1.2)
    a = G(A)
    for x in (-0.25, 0.25):
        wedge(m, (x, a.front - 0.48, a.mz - 0.3), (0.14, 0.1, 0.22), WHITE, "H", "Fang", fr=about((x, a.front - 0.48, a.mz - 0.3), R(math.pi, "X")))
    box(m, (0, a.front - 0.12, a.hb + 0.1), (0.4, 0.14, 0.3), (200, 30, 50), "H", "Gem", studs=False, emit=0.6,
        fr=about((0, a.front - 0.12, a.hb + 0.1), R(0.785, "Y")))
    box(m, (0, a.front - 0.04, a.top - 0.35), (0.5, 0.08, 0.5), (43, 39, 51), "H", "Peak", studs=False, fr=about((0, a.front, a.top - 0.35), R(0.785, "Y")))


@cat("Werewolf Cat", shape="Fluffy", fur="5a5866", second="9a98a6", eyes="ffd23c", ears="tufts", eyeStyle="big", glowEyes=True)
def _werewolf(m, A):
    a = G(A)
    for x in (-1, 1):
        for k in range(3):
            box(m, (x * (a.hw / 2 + 0.2), a.hy - 0.2 + k * 0.4, a.hz - 0.6 - k * 0.15), (0.4, 0.4, 0.7), (110, 108, 120), "H", "Fur")
    for k in range(5):
        box(m, (-0.8 + k * 0.4, a.bfront - 0.15, a.hb - 0.3), (0.35, 0.3, 0.8), (150, 148, 160), "B", "Fur")
    box(m, (0, a.front - 0.6, a.mz), (0.9, 0.5, 0.6), (130, 128, 140), "H", "Snout")
    box(m, (0, a.front - 0.86, a.mz + 0.15), (0.4, 0.1, 0.25), INK, "H", "Nose", studs=False)


@cat("Zombie Cat", shape="Loaf", fur="a8d8a0", second="d8f0d0", eyes="ffd23c", eyes2="ff6060")
def _zombie(m, A):
    a = G(A)
    bandage = (245, 240, 225)
    box(m, (0, a.hy, a.top - 0.4), (a.hw + 0.22, a.hd + 0.22, 0.35), bandage, "H", "Bandage", studs=False,
        fr=about((0, a.hy, a.top - 0.4), R(0.15, "Y")))
    box(m, (0, a.by, a.bz), (a.bw + 0.22, 0.5, a.bh + 0.22), bandage, "B", "Bandage", studs=False)
    p = a.paws[2]
    box(m, (p.x, p.y, a.leg * 0.6), (1.06, 1.06, 0.35), bandage, "L", "Bandage", studs=False)
    for k in range(3):
        box(m, (0.6, a.front - 0.05, a.hz + 0.6 - k * 0.2), (0.4, 0.06, 0.06), (90, 120, 90), "H", "Stitch", studs=False)
    box(m, (0.6, a.front - 0.05, a.hz + 0.4), (0.06, 0.06, 0.6), (90, 120, 90), "H", "Stitch", studs=False)


@cat("Ghost Cat", shape="Fluffy", fur="d8d4f6", second="f4f2ff", eyes="5a60d0", eyeStyle="big", blush=True)
def _ghost(m, A):
    a = G(A)
    remove(m, ("Leg", "Paw"))
    for k in range(8):
        ang = k * 2 * math.pi / 8
        c = (math.cos(ang) * (a.bw / 2 - 0.3), a.by + math.sin(ang) * (a.bl / 2 - 0.3), a.leg - 0.25 - (k % 2) * 0.2)
        box(m, c, (0.8, 0.8, 0.6), (216, 212, 246), "L", "Wisp", alpha=0.8)
    for o in m.objects:
        if not o.name.startswith("Fx"):
            for mt in o.data.materials:
                try:
                    mt.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.8
                except Exception:
                    pass


@cat("Mummy Cat", shape="Slim", fur="d8c8a0", second="f0e6cc", eyes="60ffd0", eyeStyle="big", glowEyes=True)
def _mummy(m, A):
    a = G(A)
    band = (235, 225, 195)
    for k in range(6):
        z = a.leg + 0.15 + k * a.bh / 6
        box(m, (0, a.by, z), (a.bw + 0.24, a.bl + 0.24, 0.16), band if k % 2 else shade(band, 0.92), "B", "Bandage", studs=False,
            fr=about((0, a.by, z), R(0.06 * (1 if k % 2 else -1), "Y")))
    for k in range(5):
        z = a.hb + 0.2 + k * a.hh / 5
        if abs(z - a.eyes[0].z) < 0.35:
            continue
        box(m, (0, a.hy, z), (a.hw + 0.24, a.hd + 0.24, 0.18), band if k % 2 else shade(band, 0.92), "H", "Bandage", studs=False,
            fr=about((0, a.hy, z), R(0.08 * (1 if k % 2 else -1), "Y")))
    for p in a.paws:
        box(m, (p.x, p.y, a.leg * 0.5), (1.06, 1.06, 0.3), band, "L", "Bandage", studs=False)


@cat("Mech Cat", shape="Loaf", fur="b8c0cc", second="dde2ea", eyes="40e0ff")
def _mech(m, A):
    a = G(A)
    steel, neon = (150, 158, 172), (60, 230, 255)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.15), a.by, a.bz), (0.2, a.bl * 0.8, a.bh * 0.7), steel, "B", "Plate")
        box(m, (s * (a.bw / 2 + 0.27), a.by, a.bz), (0.06, a.bl * 0.6, 0.12), neon, "B", "Neon", studs=False, emit=2.5)
    for p in a.paws:
        cyl(m, (p.x, p.y, a.leg * 0.6), 0.5, 0.25, steel, "L", "Joint", axis="X")
    box(m, (0, a.front - 0.1, a.eyes[0].z), (a.hw * 0.85, 0.12, 0.55), (30, 34, 44), "H", "Visor", studs=False)
    box(m, (0, a.front - 0.17, a.eyes[0].z), (a.hw * 0.7, 0.06, 0.2), neon, "H", "Visor", studs=False, emit=3.0)
    box(m, (0.6, a.hy, a.top + 0.6), (0.1, 0.1, 1.2), steel, "H", "Antenna", studs=False)
    ball(m, (0.6, a.hy, a.top + 1.25), 0.18, (255, 70, 70), "H", "Antenna", emit=2.0)


@cat("Cyborg Cat", shape="Slim", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="patch", patternColor="b8c0cc")
def _cyborg(m, A):
    a = G(A)
    steel = (140, 150, 170)
    box(m, (a.hw * 0.25, a.hy, a.hz + 0.2), (a.hw * 0.55, a.hd + 0.2, a.hh * 0.8), steel, "H", "Plate")
    e = a.eyes[1]
    box(m, (e.x, a.front - 0.15, e.z), (0.6, 0.12, 0.5), (255, 50, 60), "H", "Laser", studs=False, emit=3.0)
    box(m, (e.x - 2.0, a.front - 1.6, e.z - 0.2), (0.05, 3.0, 0.05), (255, 60, 70), "Fx", "Beam", studs=False, emit=4.0,
        fr=about((e.x, a.front - 0.15, e.z), R(0.25, "Z")))
    for s in (1,):
        box(m, (s * (a.bw / 2 + 0.15), a.by, a.bz), (0.2, a.bl * 0.9, a.bh * 0.8), steel, "B", "Plate")
        for k in range(3):
            box(m, (s * (a.bw / 2 + 0.27), a.by - 0.6 + k * 0.6, a.bz), (0.06, 0.3, 0.3), (60, 140, 255), "B", "Light", studs=False, emit=2.0)


@cat("Alien Cat", shape="Slim", fur="a8f060", second="e8ffd0", eyes="2b2733", noEyes=True)
def _alien(m, A):
    a = G(A)
    for e in a.eyes:
        box(m, (e.x, a.front - 0.07, e.z - 0.05), (0.95, 0.14, 1.15), (20, 20, 30), "H", "Eye", studs=False, rough=0.05, coat=1.0,
            fr=about((e.x, a.front, e.z), R(0.35 if e.x < 0 else -0.35, "Y")))
        box(m, (e.x - 0.2, a.front - 0.16, e.z + 0.25), (0.22, 0.06, 0.22), WHITE, "H", "Shine", studs=False, emit=0.6)
    remove(m, ("Ear", "EarIn"))
    antennae(m, A, (120, 220, 80), tip=(255, 120, 220), h=1.3)
    shirt(m, A, (60, 60, 80), h=a.bh * 0.85)
    star(m, (0, 0, 0), 0.5, (120, 255, 160), "B", emit=1.0, fr=T(-0.4, a.bfront - CLOTH - 0.08, a.bz + 0.2))


@cat("UFO Cat", shape="Loaf", fur="b38cff", second="efe6ff", eyes="ffd23c")
def _ufo(m, A):
    a = G(A)
    rr = max(a.bw, a.bl) / 2 + 1.1
    cyl(m, (0, a.by, a.leg + 0.3), rr, 0.5, (200, 208, 222), "B", "Saucer", r2=rr - 0.3)
    cyl(m, (0, a.by, a.leg + 0.0), rr - 0.5, 0.3, (160, 168, 185), "B", "Saucer")
    for k in range(8):
        ang = k * math.pi / 4
        ball(m, (math.cos(ang) * (rr - 0.15), a.by + math.sin(ang) * (rr - 0.15), a.leg + 0.3), 0.16,
             [(255, 80, 80), (80, 255, 160), (80, 180, 255), (255, 220, 80)][k % 4], "B", "Light", emit=3.0)
    ball(m, (0, a.hy + 0.4, a.hz - 0.2), (a.hw * 0.85, a.hd * 1.0, a.hh * 0.85), (200, 240, 255), "H", "Dome", alpha=0.25, rough=0.02, coat=1.0)
    cyl(m, (0, a.by, 0.2), rr - 0.6, 0.6, (150, 255, 150), "Fx", "Beam", r2=0.6, alpha=0.35, emit=1.5)


@cat("Pumpkin King Cat", shape="Fluffy", fur="ff8a20", second="ffd8a0", eyes="ffd23c", pattern="ribs", patternColor="d06010")
def _pumpkinking(m, A):
    a = G(A)
    for k in range(4):
        box(m, (-a.hw * 0.33 + k * a.hw * 0.22, a.front - 0.04, a.hz + 0.25), (0.12, 0.08, a.hh * 0.8), (210, 100, 20), "H", "Rib", studs=False)
    crown(m, A, (40, 30, 40), gems=((255, 140, 30), (160, 60, 220), (255, 140, 30)), w=0.6, h=0.4, tips=5)
    box(m, (0, a.hy, a.top + 1.0), (0.25, 0.25, 0.4), (80, 140, 50), "H", "Stem", studs=False)
    cape(m, A, (50, 30, 60), inner=(255, 140, 30), collar_up=True)


@cat("Witch Cat", shape="Slim", fur="2b2733", second="3d3846", eyes="7ed957", eyeStyle="big")
def _witch(m, A):
    a = G(A)
    purple = (110, 60, 180)
    cone_hat(m, A, [(50, 35, 70), (50, 35, 70), purple, (50, 35, 70), (50, 35, 70), (50, 35, 70)], h=2.3, w=1.4, tilt=-0.3, brim=1.45, n=6)
    b = held(m, A, -1)
    fr = T(b.x, b.y + 0.3, 0.0) @ R(0.25, "Y") @ R(-0.25, "X")
    cyl(m, (0, 0, 1.4), 0.08, 2.8, WOOD, "L", "Broom", fr=fr)
    for k in range(10):
        ang = k * 0.628
        box(m, (math.cos(ang) * 0.2, math.sin(ang) * 0.2, 0.25), (0.12, 0.12, 0.7), (220, 180, 90), "L", "Broom", fr=fr, studs=False)
    b2 = held(m, A, 1)
    cyl(m, (b2.x + 0.4, b2.y, 0.5), 0.6, 0.9, (40, 36, 48), "L", "Cauldron", r2=0.5)
    cyl(m, (b2.x + 0.4, b2.y, 0.97), 0.5, 0.06, (160, 90, 255), "L", "Potion", emit=1.5)


@cat("Snow Spirit Cat", shape="Fluffy", fur="cfe8ff", second="ffffff", eyes="3c7ad0", blush=True)
def _snowspirit(m, A):
    a = G(A)
    ice = (110, 190, 255)
    crown(m, A, ice, gems=((90, 160, 255),), w=0.6, h=0.3, tips=5, emit=0.5)
    c = (0, a.bfront - 0.15, a.bz + 0.1)
    for k in range(3):
        box(m, (0, 0, 0), (0.12, 0.1, 1.0), ice, "B", "Flake", studs=False, emit=0.8, fr=T(*c) @ R(k * 1.047, "Y"))
    marks(m, A, 8, 0.3, (200, 235, 255), seed=4, emit=0.3, head=3)


@cat("Thunderbird Cat", shape="Slim", fur="2a3a8a", second="8aa0e0", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _thunderbird(m, A):
    a = G(A)
    wings(m, A, [(255, 220, 50), (40, 60, 150), (255, 220, 50), (40, 60, 150)], kind="feather", span=1.2, up=0.65, emit=0.4)
    beak(m, A, (255, 210, 50), long=0.45)
    for k in range(3):
        box(m, (0.1 * (1 if k % 2 else -1), a.hy + 0.2 - k * 0.1, a.top + 0.3 + k * 0.4), (0.18, 0.4, 0.55), (255, 220, 50), "H", "Crest",
            studs=False, emit=1.0, fr=about((0, a.hy, a.top + 0.3 + k * 0.4), R(0.5 if k % 2 else -0.5, "Y")))


@cat("Kitsune Cat", shape="Slim", fur="ffffff", second="ffffff", eyes="ff4060", ears="big")
def _kitsune(m, A):
    a = G(A)
    red = (220, 40, 50)

    def build(m, A, root):
        for k in range(9):
            ang = -1.1 + k * 0.275
            fr = T(0, root.y, root.z) @ R(ang, "Y") @ R(-0.5, "X")
            box(m, (0, 0, 0.8), (0.5, 0.5, 1.4), WHITE, "T", "Tail", fr=fr)
            box(m, (0, 0, 1.65), (0.55, 0.55, 0.35), red, "T", "Tail", fr=fr, studs=False)
    tail_swap(m, A, build)
    for e in a.eyes:
        box(m, (e.x * 1.25, a.front - 0.05, e.z + 0.35), (0.35, 0.08, 0.12), red, "H", "Mark", studs=False)
    box(m, (0, a.front - 0.05, a.top - 0.25), (0.14, 0.08, 0.4), red, "H", "Mark", studs=False)
    fr = about((-a.hw / 2 - 0.05, a.hy, a.hz + 0.4), R(-0.3, "Z"))
    box(m, (-a.hw / 2 - 0.15, a.hy - 0.2, a.hz + 0.4), (0.15, 1.0, 1.0), WHITE, "H", "FoxMask", studs=False, fr=fr)
    box(m, (-a.hw / 2 - 0.25, a.hy - 0.4, a.hz + 0.5), (0.06, 0.2, 0.12), red, "H", "FoxMask", studs=False, fr=fr)


@cat("Naga Cat", shape="Slim", fur="5aa850", second="e8e090", eyes="ffd23c", eyeStyle="big")
def _naga(m, A):
    a = G(A)
    for k in range(7):
        ang = -0.9 + k * 0.3
        fr = T(0, a.hy + a.hd / 2 + 0.1, a.hz) @ R(ang, "Y")
        box(m, (0, 0, 1.6), (0.4, 0.2, 1.0), GOLD if k % 2 else (90, 170, 80), "H", "Crest", fr=fr, studs=False, emit=0.2)
    marks(m, A, 12, 0.3, [GOLD, (230, 210, 90)], seed=7, head=2)

    def build(m, A, root):
        for k in range(6):
            box(m, (0.25 * math.sin(k), root.y + 0.4 + k * 0.4, root.z - 0.6 + k * 0.05), (0.6 - k * 0.06, 0.55, 0.5 - k * 0.04), (90, 170, 80) if k % 2 else GOLD, "T", "Tail")
    tail_swap(m, A, build)


@cat("Garuda Cat", shape="Fluffy", fur="d8302a", second="ffd080", eyes="ffd23c")
def _garuda(m, A):
    a = G(A)
    wings(m, A, [(220, 50, 40), GOLD, (220, 50, 40), GOLD], kind="feather", span=1.25, up=0.6, emit=0.2)
    beak(m, A, GOLD, long=0.6)
    remove(m, ("Ear", "EarIn"))
    box(m, (0, a.hy, a.top + 0.12), (a.hw * 0.9, a.hd * 0.9, 0.25), GOLD, "H", "Chada")
    stack(m, (0, a.hy, a.top + 0.25), a.hw * 0.55, 0.16, 2.0, 6, [GOLD, GOLD_DARK], "H", "Chada", d0=a.hd * 0.55, d1=0.16)
    for k in range(3):
        box(m, (0, a.by, a.hb + 0.1 - k * 0.16), (a.hw * (0.9 - k * 0.1), a.hd * 0.85, 0.16), GOLD if k % 2 == 0 else (220, 50, 40), "H", "Collar", studs=False)


@cat("Cerberus Cat", shape="Fluffy", fur="2b2733", second="4a4552", eyes="ff5040", eyeStyle="big", glowEyes=True)
def _cerberus(m, A):
    a = G(A)
    for s in (-1, 1):
        c = (s * (a.hw / 2 + 0.75), a.hy + 0.4, a.hz - 0.4)
        box(m, c, (1.5, 1.5, 1.5), (43, 39, 51), "H", "Head2")
        for x in (-0.35, 0.35):
            box(m, (c[0] + x, c[1] - 0.78, c[2] + 0.15), (0.3, 0.08, 0.38), INK, "H", "Eye2", studs=False)
            box(m, (c[0] + x, c[1] - 0.82, c[2] + 0.1), (0.2, 0.06, 0.18), (255, 80, 64), "H", "Eye2", studs=False, emit=2.0)
        box(m, (c[0], c[1] - 0.85, c[2] - 0.35), (0.6, 0.2, 0.4), (74, 69, 82), "H", "Muzzle2")
        for x in (-0.45, 0.45):
            box(m, (c[0] + x, c[1], c[2] + 0.95), (0.4, 0.35, 0.5), (43, 39, 51), "H", "Ear2")
    collar(m, A, (200, 30, 40), h=0.35)
    for k in range(8):
        ang = k * math.pi / 4
        box(m, (math.cos(ang) * (a.hw / 2 + 0.2), a.hy + math.sin(ang) * (a.hd / 2 + 0.2), a.hb + 0.2), (0.22, 0.22, 0.3), SILVER, "H", "Spike", studs=False)


@cat("Hydra Cat", shape="Slim", fur="2aa890", second="c8f0e0", eyes="ffd23c")
def _hydra(m, A):
    a = G(A)

    def build(m, A, root):
        for k, ang in enumerate((-0.6, 0.0, 0.6)):
            fr = T(0, root.y, root.z) @ R(ang, "Y") @ R(-0.5, "X")
            for j in range(3):
                box(m, (0, 0, 0.4 + j * 0.5), (0.45, 0.45, 0.55), (42, 168, 144) if j % 2 else (60, 190, 160), "T", "Neck", fr=fr)
            box(m, (0, -0.15, 2.0), (0.7, 0.9, 0.55), (42, 168, 144), "T", "SnakeHead", fr=fr)
            for x in (-0.2, 0.2):
                box(m, (x, -0.55, 2.15), (0.14, 0.06, 0.14), (255, 220, 60), "T", "SnakeEye", fr=fr, studs=False, emit=1.5)
    tail_swap(m, A, build)
    marks(m, A, 10, 0.3, (90, 200, 170), seed=4)


@cat("Treant Cat", shape="Loaf", fur="8a5a34", second="c89a6a", eyes="7ed957")
def _treant(m, A):
    a = G(A)
    for s in (-1, 1):
        for k in range(4):
            box(m, (s * (a.bw / 2 + 0.08), a.by - 0.9 + k * 0.6, a.bz), (0.08, 0.12, a.bh * 0.9), (110, 70, 40), "B", "Bark", studs=False)
    for x in (-1, 1):
        box(m, (x * 0.6, a.hy + 0.2, a.top + 0.6), (0.25, 0.25, 1.2), (120, 80, 45), "H", "Branch", studs=False, fr=about((x * 0.6, a.hy, a.top), R(x * 0.4, "Y")))
        for j in range(3):
            c = about((x * 0.6, a.hy, a.top), R(x * 0.4, "Y")) @ Vector((x * 0.6 + x * 0.3 * (j - 1), a.hy + 0.2, a.top + 1.1 + j * 0.25))
            box(m, c, (0.6, 0.6, 0.5), [(80, 170, 70), (110, 200, 80)][j % 2], "H", "Leaves")
    marks(m, A, 6, 0.5, [(80, 170, 70), (110, 200, 80)], where=("top",), seed=4, off=0.2)


@cat("Mushroom Spirit Cat", shape="Fluffy", fur="ffe6bc", second="fffaf0", eyes="60d0ff", eyeStyle="big", blush=True)
def _mushroomspirit(m, A):
    a = G(A)
    ears_out(m, A)
    red = (225, 50, 70)
    stack(m, (0, a.hy, a.top), a.hw * 1.2, a.hw * 0.5, 1.1, 3, red, d0=a.hd * 1.2, d1=a.hd * 0.5, emit=0.3)
    for x, y, z in ((-0.9, -0.4, 0.2), (0.7, -0.6, 0.2), (0.0, -0.2, 1.0), (-0.5, -0.65, 0.6), (0.9, 0.3, 0.3), (0.45, -0.75, 0.6)):
        box(m, (x, a.hy + y * a.hd * 0.85, a.top + z), (0.32, 0.32, 0.32), (220, 255, 240), "H", "Dot", studs=False, emit=2.0)
    for x, y in ((-0.6, 0.6), (0.5, 1.0), (0.0, 0.2)):
        cyl(m, (x, a.by + y, a.btop + 0.25), 0.12, 0.5, (255, 245, 220), "B", "Shroom")
        cyl(m, (x, a.by + y, a.btop + 0.55), 0.3, 0.2, (120, 220, 255), "B", "Shroom", emit=1.5)


@cat("Lava Cat", shape="Loaf", fur="2b2628", second="4a4245", eyes="ffb020", eyeStyle="big", glowEyes=True)
def _lava(m, A):
    a = G(A)
    lava = (255, 120, 30)
    rnd = random.Random(6)
    for s in (-1, 1):
        for k in range(5):
            c = (s * (a.bw / 2 + 0.05), a.by + rnd.uniform(-0.45, 0.45) * a.bl, a.bz + rnd.uniform(-0.4, 0.4) * a.bh)
            box(m, c, (0.08, rnd.uniform(0.4, 0.9), 0.12), lava, "B", "Crack", studs=False, emit=3.0, fr=about(c, R(rnd.uniform(-0.8, 0.8), "X")))
    for k in range(4):
        c = (rnd.uniform(-0.4, 0.4) * a.bw, a.by + rnd.uniform(0, 0.45) * a.bl, a.btop + 0.04)
        box(m, c, (rnd.uniform(0.4, 0.9), 0.12, 0.08), lava, "B", "Crack", studs=False, emit=3.0, fr=about(c, R(rnd.uniform(-1, 1), "Z")))
    for x in (-0.6, 0.5):
        box(m, (x, a.front - 0.04, a.top - 0.45), (0.12, 0.08, 0.6), lava, "H", "Crack", studs=False, emit=3.0)
    for p in a.paws:
        box(m, (p.x, p.y - 0.06, 0.2), (1.08, 1.12, 0.35), lava, "L", "Glow", emit=2.0)


@cat("Cloud Dragon Cat", shape="Slim", fur="e2eefc", second="ffffff", eyes="3c7ad0")
def _clouddragon(m, A):
    a = G(A)
    horns(m, A, (110, 160, 240), n=3, size=0.45)
    for x in (-1, 1):
        for k in range(4):
            box(m, (x * (0.4 + k * 0.35), a.front - 0.55 - k * 0.12, a.mz - k * 0.18), (0.4, 0.12, 0.12), (110, 160, 240), "H", "Whisker", studs=False)
    marks(m, A, 8, 0.8, [(255, 255, 255), (230, 240, 255)], shape="ball", where=("top",), seed=3, off=0.2)

    def build(m, A, root):
        for k in range(5):
            ball(m, (0.3 * math.sin(k * 1.3), root.y + 0.4 + k * 0.5, root.z + 0.2 + k * 0.3), 0.55 - k * 0.05, (255, 255, 255) if k % 2 else (220, 235, 255), "T", "Puff")
    tail_swap(m, A, build)


@cat("Sea Serpent Cat", shape="Slim", fur="2a6ac8", second="a8e0d0", eyes="ffd23c")
def _seaserpent(m, A):
    a = G(A)
    teal = (40, 190, 160)
    for k in range(6):
        y = a.bfront + 0.2 + k * (a.bl - 0.2) / 5
        wedge(m, (0, y, a.btop + 0.4), (0.15, 0.6, 0.7), teal, "B", "Fin", fr=about((0, y, a.btop + 0.4), R(math.pi, "Z")))
    wedge(m, (0, a.hy + 0.4, a.top + 0.45), (0.15, 0.9, 0.9), teal, "H", "Fin", fr=about((0, a.hy + 0.4, a.top + 0.45), R(math.pi, "Z")))

    def ears(a):
        for x in (-1, 1):
            box(m, (x * (a.hw / 2 + 0.4), a.hy + 0.2, a.hz + 0.3), (0.8, 0.12, 0.9), teal, "H", "Ear", studs=False,
                fr=about((x * (a.hw / 2), a.hy + 0.2, a.hz + 0.3), R(x * 0.3, "Z")))
    new_ears(m, A, ears)
    marks(m, A, 10, 0.3, [(40, 190, 160), (80, 150, 230)], seed=5)


@cat("Gargoyle Cat", shape="Loaf", fur="7a7c86", second="9a9ca6", eyes="ffb020", eyeStyle="big")
def _gargoyle(m, A):
    wings(m, A, [(110, 112, 122), (95, 97, 106), (125, 127, 137)], kind="stone", span=1.0, up=0.5)
    horns(m, A, (90, 92, 100), n=2, size=0.45)
    a = G(A)
    for x in (-0.5, 0.4):
        box(m, (x, a.front - 0.05, a.top - 0.4), (0.1, 0.08, 0.5), (80, 82, 90), "H", "Crack", studs=False)
    marks(m, A, 5, 0.5, [(110, 160, 90)], where=("top",), seed=2, off=0.14)


@cat("Genie Cat", shape="Slim", fur="5ab0ff", second="d8f0ff", eyes="ffd23c")
def _genie(m, A):
    a = G(A)
    remove_back_legs(m, A)
    for k in range(4):
        ball(m, (0.2 * math.sin(k * 1.7), a.by + 0.8 + k * 0.45, a.leg - 0.2 - k * 0.15), 0.9 - k * 0.15, (130, 190, 255), "B", "Smoke", alpha=0.8)
    for i in (0, 2):
        p = a.paws[i]
        box(m, (p.x, p.y, a.leg * 0.55), (1.1, 1.1, 0.25), GOLD, "L", "Bangle", studs=False)
    box(m, (0, a.hy, a.top + 0.3), (0.5, 0.5, 0.6), (40, 70, 170), "H", "Topknot")
    box(m, (0, a.hy, a.top + 0.05), (a.hw * 0.4, a.hd * 0.4, 0.15), GOLD, "H", "Band", studs=False)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 0.35), 0.45, 0.5, GOLD, "L", "Lamp", r2=0.25)
    box(m, (b.x, b.y - 0.55, 0.45), (0.15, 0.6, 0.15), GOLD, "L", "Lamp", studs=False, fr=about((b.x, b.y - 0.3, 0.4), R(-0.4, "X")))
    box(m, (b.x, b.y + 0.45, 0.4), (0.12, 0.3, 0.3), GOLD, "L", "Lamp", studs=False)


@cat("Dark Knight Cat", shape="Slim", fur="2b2733", second="3d3846", eyes="b06cff", eyeStyle="big", glowEyes=True)
def _darkknight(m, A):
    dark, purple = (45, 40, 55), (150, 70, 230)
    helmet(m, A, dark, visor=(30, 26, 36), crest=purple)
    armour(m, A, dark, trim=purple)
    sword(m, A, blade=(180, 110, 255), hilt=dark, guard=purple, emit=2.0)
    cape(m, A, (60, 30, 90), inner=purple)


@cat("Oni Cat", shape="Fluffy", fur="e8402a", second="ffd0c0", eyes="ffd23c")
def _oni(m, A):
    a = G(A)
    for x in (-0.6, 0.6):
        stack(m, (x, a.hy - 0.2, a.top), 0.45, 0.15, 0.8, 3, (255, 240, 200), "H", "Horn")
    box(m, (0, a.hy, a.top + 0.1), (0.9, 0.8, 0.2), (40, 36, 48), "H", "Hair", studs=False)
    plate(m, (0, a.by, a.leg + 0.3), (a.bw + 0.44, a.bl + 0.44, 0.6), (255, 200, 40), "B", "Cloth")
    for s in (-1, 1):
        for k in range(4):
            box(m, (s * (a.bw / 2 + CLOTH + 0.03), a.by - 0.9 + k * 0.6, a.leg + 0.3), (0.06, 0.15, 0.5), INK, "B", "Stripe", studs=False)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 1.2), 0.25, 2.4, (130, 85, 50), "L", "Club", r2=0.35)
    for k in range(6):
        box(m, (b.x + 0.35 * math.cos(k), b.y + 0.35 * math.sin(k), 1.6 + k * 0.12), (0.16, 0.16, 0.16), SILVER, "L", "Stud", studs=False)


@cat("Toy Soldier Cat", shape="Slim", fur="ffe6bc", second="fffaf0", eyes="3c96ff", blush=True)
def _toysoldier(m, A):
    a = G(A)
    red, blue = (210, 30, 45), (40, 70, 180)
    ears_out(m, A)
    box(m, (0, a.hy, a.top + 0.6), (a.hw * 0.7, a.hd * 0.7, 1.2), blue, "H", "Hat")
    plate(m, (0, a.hy - a.hd * 0.4, a.top + 0.05), (a.hw * 0.6, 0.5, 0.1), INK, "H", "Visor")
    box(m, (0, a.hy - a.hd * 0.36, a.top + 0.9), (0.4, 0.08, 0.4), GOLD, "H", "Badge", studs=False)
    shirt(m, A, red, h=a.bh * 0.9)
    belt(m, A, WHITE, buckle=GOLD)
    for x in (-1, 1):
        box(m, (x * 0.5, a.bfront - CLOTH - 0.06, a.bz + 0.1), (0.1, 0.06, a.bh * 0.7), WHITE, "B", "Strap", studs=False)
    c = (0, a.bback + CLOTH + 0.3, a.bz + 0.3)
    cyl(m, c, 0.12, 0.6, GOLD, "B", "Key", axis="Y")
    for x in (-1, 1):
        box(m, (c[0] + x * 0.35, c[1] + 0.35, c[2]), (0.5, 0.12, 0.5), GOLD, "B", "Key", studs=False)


@cat("Teddy Bear Cat", shape="Fluffy", fur="d8a878", second="f6e2c8", eyes="2b2733", noEyes=True, blush=True)
def _teddy(m, A):
    a = G(A)

    def ears(a):
        for x in (-1, 1):
            cyl(m, (x * (a.hw / 2 - 0.45), a.hy + 0.1, a.top + 0.35), 0.55, 0.35, (216, 168, 120), "H", "Ear", axis="Y")
            cyl(m, (x * (a.hw / 2 - 0.45), a.hy - 0.08, a.top + 0.35), 0.3, 0.06, (246, 226, 200), "H", "EarIn", axis="Y")
    new_ears(m, A, ears)
    for e in a.eyes:
        cyl(m, (e.x, a.front - 0.08, e.z), 0.3, 0.12, (40, 36, 48), "H", "Button", axis="Y")
        for dx in (-0.08, 0.08):
            cyl(m, (e.x + dx, a.front - 0.15, e.z), 0.04, 0.04, (120, 110, 130), "H", "Button", axis="Y")
    for k in range(5):
        box(m, (0, a.bfront - 0.12, a.leg + 0.3 + k * 0.3), (0.3, 0.06, 0.06), (120, 80, 50), "B", "Stitch", studs=False)
    box(m, (-a.bw / 2 - 0.1, a.by + 0.4, a.bz), (0.08, 0.7, 0.7), (150, 200, 255), "B", "Patch", studs=False)
    from catparts import bow_tie
    bow_tie(m, A, (255, 90, 120), 1.2)


@cat("Slime Cat", shape="Loaf", fur="7ae860", second="b8ff9a", eyes="2b2733")
def _slime(m, A):
    a = G(A)
    for o in m.objects:
        for mt in o.data.materials:
            try:
                mt.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.75
                mt.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.05
            except Exception:
                pass
    for x, y in ((-0.9, -0.3), (0.8, 0.4), (0.0, 0.9)):
        box(m, (x, a.by + y, a.leg - 0.05), (0.5, 0.5, 0.25), (122, 232, 96), "B", "Drip", alpha=0.8)
    for x in (-0.6, 0.7):
        box(m, (x, a.front - 0.05, a.hb + 0.2), (0.25, 0.1, 0.5), (122, 232, 96), "H", "Drip", studs=False, alpha=0.8)
    ball(m, (0.3, a.by + 0.2, a.bz + 0.1), 0.3, (255, 230, 80), "B", "Inside", alpha=0.9)


@cat("Candy Monster Cat", shape="Fluffy", fur="ffb0d8", second="c8e8ff", eyes="5ab0ff", blush=True)
def _candymonster(m, A):
    a = G(A)
    marks(m, A, 10, 0.75, [(255, 180, 220), (180, 220, 255)], shape="ball", where=("top", "left", "right"), seed=6, head=4, off=0.2)
    for x in (-1, 1):
        cyl(m, (x * 0.8, a.hy, a.top + 0.5), 0.07, 1.0, WHITE, "H", "Stick")
        cyl(m, (x * 0.8, a.hy, a.top + 1.15), 0.4, 0.15, (255, 90, 160) if x < 0 else (90, 190, 255), "H", "Lolly", axis="Y")
        cyl(m, (x * 0.8, a.hy - 0.05, a.top + 1.15), 0.22, 0.16, WHITE, "H", "Lolly", axis="Y")


@cat("Clockwork Cat", shape="Loaf", fur="d8a848", second="f0d8a0", eyes="3c96ff")
def _clockwork(m, A):
    a = G(A)
    brass = (190, 150, 60)
    for s in (-1, 1):
        for (u, v, r) in ((-0.2, 0.1, 0.55), (0.25, -0.15, 0.4)):
            c = (s * (a.bw / 2 + 0.12), a.by + u * a.bl, a.bz + v * a.bh)
            cyl(m, c, r, 0.14, brass, "B", "Gear", axis="X")
            for k in range(8):
                box(m, (0, 0, r + 0.08), (0.14, 0.16, 0.18), brass, "B", "Gear", studs=False, fr=T(*c) @ R(k * 0.785, "X"))
    cyl(m, (0, a.bfront - 0.12, a.bz + 0.1), 0.5, 0.1, (255, 245, 220), "B", "Clock", axis="Y")
    box(m, (0, a.bfront - 0.19, a.bz + 0.25), (0.06, 0.04, 0.3), INK, "B", "Clock", studs=False)
    box(m, (0.12, a.bfront - 0.19, a.bz + 0.1), (0.25, 0.04, 0.06), INK, "B", "Clock", studs=False)
    c = (0, a.bback + 0.3, a.bz + 0.4)
    cyl(m, c, 0.1, 0.6, brass, "B", "Key", axis="Y")
    for x in (-1, 1):
        box(m, (x * 0.35, c[1] + 0.3, c[2]), (0.5, 0.1, 0.45), brass, "B", "Key", studs=False)


@cat("Steam Mech Cat", shape="Fluffy", fur="b8703a", second="e0b890", eyes="ffb020")
def _steammech(m, A):
    a = G(A)
    copper, iron = (190, 110, 60), (90, 90, 100)
    from catparts import goggles
    goggles(m, A, (110, 70, 40), (255, 200, 80), up=True)
    for x in (-0.6, 0.6):
        cyl(m, (x, a.bback - 0.2, a.btop + 0.7), 0.25, 1.4, iron, "B", "Chimney")
        cyl(m, (x, a.bback - 0.2, a.btop + 1.45), 0.32, 0.15, copper, "B", "Chimney")
    for s in (-1, 1):
        cyl(m, (s * (a.bw / 2 + 0.2), a.by, a.bz + 0.2), 0.15, a.bl * 0.9, copper, "B", "Pipe", axis="Y")
        for k in range(3):
            box(m, (s * (a.bw / 2 + 0.12), a.by - 0.7 + k * 0.7, a.bz - 0.3), (0.12, 0.2, 0.2), iron, "B", "Rivet", studs=False)


@cat("Pixel Glitch Cat", shape="Loaf", fur="9a5af0", second="d8c0ff", eyes="40ffe0")
def _glitch(m, A):
    a = G(A)
    rnd = random.Random(9)
    cols = [(60, 255, 230), (255, 70, 200), (154, 90, 240)]
    for k in range(10):
        f = k % 3
        if f == 0:
            c = (rnd.uniform(-0.45, 0.45) * a.bw, a.by + rnd.uniform(-0.1, 0.45) * a.bl, a.btop + 0.15)
        else:
            sx = -1 if f == 1 else 1
            c = (sx * (a.bw / 2 + 0.2), a.by + rnd.uniform(-0.45, 0.45) * a.bl, a.bz + rnd.uniform(-0.4, 0.4) * a.bh)
        box(m, c, (0.4, 0.4, 0.4), cols[k % 3], "B", "Pixel", studs=False, emit=1.5)
    box(m, (0.35, a.hy - 0.1, a.hz + 0.4), (a.hw * 0.5, a.hd * 0.6, 0.35), (60, 255, 230), "H", "Glitch", studs=False, emit=1.0, alpha=0.7)
    box(m, (-0.3, a.hy - 0.1, a.hz - 0.5), (a.hw * 0.6, a.hd * 0.5, 0.25), (255, 70, 200), "H", "Glitch", studs=False, emit=1.0, alpha=0.7)


@cat("Neon Cyber Cat", shape="Slim", fur="2b2733", second="3d3846", eyes="ff40c0")
def _neoncyber(m, A):
    a = G(A)
    pink, cyan = (255, 60, 200), (60, 230, 255)
    for s in (-1, 1):
        box(m, (s * (a.bw / 2 + 0.06), a.by, a.bz + 0.3), (0.06, a.bl * 0.9, 0.1), pink, "B", "Neon", studs=False, emit=3.0)
        box(m, (s * (a.bw / 2 + 0.06), a.by + 0.3, a.bz - 0.2), (0.06, a.bl * 0.6, 0.1), cyan, "B", "Neon", studs=False, emit=3.0)
    box(m, (0, a.by, a.btop + 0.06), (0.1, a.bl * 0.9, 0.06), pink, "B", "Neon", studs=False, emit=3.0)
    box(m, (0, a.front - 0.12, a.eyes[0].z), (a.hw * 0.9, 0.12, 0.45), (40, 20, 60), "H", "Visor", studs=False, rough=0.05, coat=1.0)
    box(m, (0, a.front - 0.19, a.eyes[0].z), (a.hw * 0.8, 0.06, 0.14), pink, "H", "Visor", studs=False, emit=3.0)
    for p in a.paws:
        box(m, (p.x, p.y - 0.06, 0.2), (1.08, 1.12, 0.12), cyan, "L", "Neon", studs=False, emit=2.0)


@cat("Bubble Cat", shape="Fluffy", fur="9fd0ff", second="ffffff", eyes="b06cff", blush=True)
def _bubble(m, A):
    a = G(A)
    ball(m, (0, a.by - 0.4, a.top / 2 + 0.2), (a.bw / 2 + 1.3, a.bl / 2 + 1.5, a.top / 2 + 0.9), (220, 240, 255), "Fx", "BigBubble",
         alpha=0.18, rough=0.02, coat=1.0, emit=0.1)
    marks(m, A, 6, 0.3, [(255, 180, 230), (180, 230, 255)], shape="ball", seed=4, head=2, off=0.15)


for _name, _entry in DESIGNS.items():
    blockcat.DESIGNS[_name] = _entry
