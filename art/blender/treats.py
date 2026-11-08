"""Cat treats (M09) for the shop: treat(name) -> kit.Model, name = Config.Treats Name
(LuckyTreat, GoldenFish, Catnip). Front = -Y, standing on z = 0.
"""
import math

from mathutils import Matrix, Vector

import kit
from kit import Model, R, T
from items import paw, star

PI = math.pi
NAMES = ["LuckyTreat", "GoldenFish", "Catnip"]


def fish_outline(L=1.0, H=0.55):
    """Fish side view, counter-clockwise: an oval body (nose at -x) and a forked tail at +x."""
    cx, rx, ry = -0.1 * L, 0.45 * L, 0.5 * H
    pts = []
    n = 30
    for i in range(n + 1):
        a = 0.5 + i * (2 * PI - 1.0) / n
        pts.append((cx + rx * math.cos(a), ry * math.sin(a)))
    pts += [(0.68 * L, -0.5 * H), (0.6 * L, 0.0), (0.68 * L, 0.5 * H)]
    return pts


def treat(name):
    m = Model(name)
    if name == "LuckyTreat":
        out = fish_outline(1.6, 0.95)
        m.slab(out, 0.34, (140, 210, 80), T(0, 0, 0.55) @ kit.FRONT, bevel=0.13, name="Biscuit")
        # a lighter rim stripe and the gold clover on the front side
        for i, (dx, dy, rot) in enumerate(((0, 0.13, 0), (0.13, 0, -PI / 2), (0, -0.13, PI), (-0.13, 0, PI / 2))):
            heart = []
            for k in range(20):
                t = 2 * PI * k / 20
                x = 0.2 * math.sin(t) ** 3
                y = 0.16 * math.cos(t) - 0.06 * math.cos(2 * t) - 0.025 * math.cos(3 * t) + 0.04
                c, s = math.cos(rot), math.sin(rot)
                heart.append((x * c - y * s + dx - 0.25, x * s + y * c + dy))
            m.slab(heart[::-1], 0.06, (255, 205, 50), T(0, -0.17, 0.55) @ kit.FRONT, bevel=0.02, name="Clover")
        m.blob((0.09, 0.09, 0.04), (255, 190, 40), T(-0.25, -0.22, 0.55) @ kit.FRONT, name="CloverMid")
        m.tube([(-0.25, -0.18, 0.5), (-0.2, -0.18, 0.35)], 0.025, (255, 205, 50), n=6, name="Stem")
        m.ball((-0.62, -0.15, 0.72), 0.06, (40, 70, 30), name="Eye")
    elif name == "GoldenFish":
        gold = (255, 200, 40)
        body = m.blob((0.62, 0.3, 0.42), gold, T(0, 0, 0.6), e1=0.9, e2=0.9,
                      warp=lambda p: Vector((p.x, p.y * (1 - 0.35 * max(0, p.x) / 0.62), p.z * (1 - 0.3 * max(0, p.x) / 0.62))),
                      name="Body", rough=0.2, coat=0.8)
        tail = [(0.0, 0.0), (0.42, 0.34), (0.32, 0.0), (0.42, -0.34)]
        m.slab(tail[::-1], 0.12, gold, T(0.5, 0, 0.62) @ kit.FRONT, bevel=0.05, name="Tail", rough=0.2, coat=0.8)
        m.leaf((0.0, 0, 0.98), (0.6, 0, 0.5), 0.45, 0.25, (255, 180, 30), up=(0, -1, 0), name="Fin")
        for y in (-1, 1):
            m.leaf((0.05, y * 0.24, 0.45), (0.5, y * 0.4, -0.5), 0.3, 0.16, (255, 180, 30), name="Fin")
        tree = m.bvh(body)
        m.face(tree, (-0.35, -0.3, 0.68), (0, -1, 0), 0.16)
        for p, r in (((-0.75, -0.3, 1.15), 0.12), ((0.6, -0.3, 0.2), 0.09), ((0.75, -0.3, 1.05), 0.07)):
            star(m, p, r, (255, 230, 90), emit=1.5)
    elif name == "Catnip":
        pot = (214, 110, 60)
        m.lathe(kit.spline([(0, 0.0), (0, 0.36), (0.55, 0.42), (0.6, 0.5), (0.62, 0.55), (0.7, 0.0)]), pot,
                R(-PI / 2, "Y"), n_t=30, n_a=36, name="Pot")
        m.torus(0.5, 0.07, (226, 124, 70), T(0, 0, 0.6), name="Rim")
        m.blob((0.47, 0.47, 0.05), (110, 70, 40), T(0, 0, 0.64), name="Soil")
        m.torus(0.41, 0.05, (255, 130, 180), T(0, 0, 0.3), name="Ribbon")
        for x in (-1, 1):
            m.blob((0.16, 0.06, 0.1), (255, 130, 180), T(x * 0.15, -0.46, 0.3) @ R(x * 0.4, "Y"), e1=0.8, e2=0.8, name="Bow")
        m.blob((0.11, 0.05, 0.1), (255, 214, 90), T(0, -0.5, 0.31), e1=0.7, e2=0.8, name="Badge")
        paw(m, (0, -0.56, 0.3), (0, -1, 0), (0, 0, 1), 0.12, (255, 130, 180))
        import random
        rnd = random.Random(7)
        # catnip: short stems with broad round leaves, an outer ring leaning out and an inner ring standing up
        for ring, (count, tilt, ln, z) in enumerate(((9, 1.05, 0.42, 0.7), (7, 0.6, 0.4, 0.82), (4, 0.25, 0.34, 0.95))):
            for i in range(count):
                a = 2 * PI * (i + 0.5 * ring) / count + rnd.uniform(-0.15, 0.15)
                d = Vector((math.cos(a) * math.sin(tilt), math.sin(a) * math.sin(tilt), math.cos(tilt)))
                base = Vector((math.cos(a) * 0.08 * (3 - ring), math.sin(a) * 0.08 * (3 - ring), z))
                green = (70 + rnd.randint(0, 50), 180 + rnd.randint(0, 40), 60 + rnd.randint(0, 20))
                ln2 = ln + rnd.uniform(0, 0.08)
                side = d.cross(Vector((0, 0, 1)))
                side = side.normalized() if side.length > 1e-3 else Vector((1, 0, 0))
                nrm = side.cross(d).normalized()
                fr = Matrix.Translation(base + d * ln2 * 0.55) @ Matrix((d, side, nrm)).transposed().to_4x4()
                m.blob((ln2 * 0.5, ln2 * 0.38, 0.03), green, fr, e1=1.0, e2=0.85,
                       warp=lambda p, L=ln2: Vector((p.x, p.y * (1 - 0.35 * max(0.0, p.x) / (L * 0.5)), p.z + 0.25 * (p.x / L) ** 2 * L)),
                       name="Leaf")
                m.tube([base, base + d * ln2 * 0.25], 0.025, (70, 150, 60), n=6, name="Stem")
    return m
