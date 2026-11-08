"""Shoes (M07 / M08): one right shoe per pair; the game mirrors it for the left foot.
Toe = -Y, up = +Z, the sole's bottom at z = 0, origin under the middle of the foot.
shoe(key) -> kit.Model, key = Config.Shoes key (Sneakers ... CometKicks).
"""
import math

from mathutils import Matrix, Vector

import kit
from kit import Model, R, T
from items import paw, star, ear

PI = math.pi
LEN, WID = 0.68, 0.38  # footprint half-length / half-width (studs)
INK = (40, 44, 70)

KEYS = ["Sneakers", "SportShoes", "RunningShoes", "BouncyBoots", "RocketShoes", "CloudSteppers", "LightningBoots", "CometKicks"]


def footprint(k=1.0, n=40):
    pts = []
    for i in range(n):
        a = 2 * PI * i / n
        c, s = math.cos(a), math.sin(a)
        x = WID * k * math.copysign(abs(c) ** 0.8, c)
        y = LEN * k * math.copysign(abs(s) ** 0.8, s)
        if y > 0:
            x *= 1 - 0.2 * y / LEN  # narrower heel
        pts.append((x, y))
    return pts


def sole(m, z0, h, color, k=1.0, **o):
    return m.slab(footprint(k), h, color, T(0, 0, z0 + h / 2), bevel=min(0.07, h * 0.4), name="Sole", **o)


def upper(m, z0, color, high=0.0, **o):
    """The shoe body over the sole: low at the toe, higher at the heel; `high` adds a boot shaft."""
    def warp(p):
        s = kit.smoothstep(-0.05, -0.62, p.y)  # 0 at the middle, 1 at the toe
        h = kit.smoothstep(0.05, 0.6, p.y)  # the heel stands higher
        z = p.z
        if z < 0:
            z *= 0.25  # flat bottom on the sole
        else:
            z *= 1 - 0.58 * s + 0.18 * h
        return Vector((p.x, p.y, z))

    body = m.blob((WID * 0.95, LEN * 0.95, 0.42), color, T(0, 0.02, z0 + 0.08), e1=0.55, e2=0.75, warp=warp, nu=40, nv=24,
                  name="Upper", **o)
    shaft = None
    if high:
        shaft = m.blob((WID * 0.8, 0.32, high / 2 + 0.12), color, T(0, 0.26, z0 + 0.3 + high / 2), e1=0.5, e2=0.8, name="Shaft", **o)
    return body, shaft


def collar(m, tree, y=0.3, rx=0.24, ry=0.2, color=(64, 60, 78)):
    """The dark opening on top, placed on the surface found by a ray from above."""
    loc, _ = Model.hit(tree, (0, y, 0), (0, 0, 1))
    z = loc.z - 0.015 if loc else 0.5
    m.blob((rx, ry, 0.05), color, T(0, y, z), e1=0.6, e2=1.0, name="Collar", rough=0.8)


def pawon(m, loc, nor, up, size, color):
    n = Vector(nor).normalized()
    u = Vector(up)
    u = (u - n * u.dot(n)).normalized()
    paw(m, loc, n, u, size, color)


def laces(m, tree, color, n=3, y0=-0.34, step=0.12, w=0.17, tongue=None):
    """Flat laces across the instep and, if a colour is given, a tongue rising behind them."""
    for i in range(n):
        y = y0 + i * step
        m.stuck(tree, (0, y, 0.0), (0, -0.3, 1), (w, 0.045, 0.05), color, sink=0.0, name="Lace")
    if tongue:
        loc, _ = Model.hit(tree, (0, 0.02, 0), (0, 0, 1))
        if loc:
            m.blob((0.16, 0.05, 0.15), tongue, T(*(loc + Vector((0, 0.0, 0.06)))) @ R(-0.45, "X"), e1=0.6, e2=0.8, name="Tongue")


def side_point(tree, y, z, sx=1):
    loc, nor = Model.hit(tree, Vector((0, y, z)) + Vector((3 * sx, 0, 0)), Vector((sx, 0, 0)))
    return loc, nor


def shoe(key):
    m = Model(key)
    if key == "Sneakers":
        sole(m, 0, 0.08, (60, 130, 230))
        sole(m, 0.08, 0.12, (250, 250, 252))
        up, _ = upper(m, 0.2, (250, 250, 252))
        tree = m.bvh(up)
        collar(m, tree)
        laces(m, tree, (60, 140, 240), tongue=(236, 240, 250))
        m.stuck(tree, (0, -0.55, 2), (0, -0.4, 1), (0.28, 0.16, 0.05), (220, 232, 250), sink=0.5, name="ToeCap")
    elif key == "SportShoes":
        sole(m, 0, 0.18, (250, 250, 252))
        up, _ = upper(m, 0.18, (90, 196, 70))
        tree = m.bvh(up)
        collar(m, tree)
        laces(m, tree, (250, 250, 252), tongue=(110, 210, 90))
        for sx in (-1, 1):
            for i in range(3):
                loc, nor = side_point(tree, -0.05 + i * 0.12, 0.36, sx)
                if loc:
                    n = nor.normalized()
                    t = Vector((0, 0.5, 1))
                    t = (t - n * t.dot(n)).normalized()
                    fr = Matrix.Translation(loc) @ Matrix((n.cross(t) * -1, t, n)).transposed().to_4x4()
                    m.blob((0.04, 0.16, 0.03), (250, 250, 252), fr, e1=0.5, e2=0.5, name="Stripe")
    elif key == "RunningShoes":
        # thick bouncy sole with a wavy yellow layer
        sole(m, 0, 0.1, (110, 70, 40))
        sole(m, 0.1, 0.12, (255, 210, 60), k=1.02)
        sole(m, 0.22, 0.08, (250, 250, 252))
        up, _ = upper(m, 0.28, (250, 130, 30))
        tree = m.bvh(up)
        collar(m, tree)
        laces(m, tree, (255, 214, 70), tongue=(255, 150, 50))
        loc, nor = side_point(tree, 0.1, 0.5)
        if loc:
            pawon(m, loc + nor * 0.02, nor, (0, 0, 1), 0.24, (250, 250, 252))
        m.blob((0.12, 0.08, 0.2), (255, 200, 60), T(0, 0.62, 0.72) @ R(-0.3, "X"), e1=0.6, e2=0.8, name="HeelTab")
    elif key == "BouncyBoots":
        # platform, blue spring, then the boot on a pink sole
        sole(m, 0, 0.12, (255, 120, 180))
        sole(m, 0.12, 0.05, (250, 250, 252), k=1.01)
        coil = []
        for i in range(121):
            t = i / 120
            a = t * 2 * PI * 4
            coil.append((0.2 * math.cos(a), 0.05 + 0.2 * math.sin(a), 0.17 + 0.3 * t))
        m.tube(coil, 0.035, (70, 170, 255), n=8, name="Spring", emit=0.3)
        sole(m, 0.47, 0.12, (255, 120, 180))
        up, sh = upper(m, 0.59, (255, 110, 175), high=0.55)
        tree = m.bvh(sh)
        collar(m, tree, y=0.26, rx=0.22, ry=0.24)
        loc, nor = Model.hit(tree, (0, 0.0, 1.15), (0, -1, 0.2))
        if loc:
            m.blob((0.26, 0.04, 0.12), (250, 250, 252), T(*(loc + nor * 0.03)), e1=0.4, e2=0.6, name="Strap")
            pawon(m, loc + nor * 0.08, nor, (0, 0, 1), 0.17, (255, 120, 180))
        for x in (-1, 1):
            ear(m, (x * 0.16, 0.36, 1.48), 0.13, (255, 110, 175))
    elif key == "RocketShoes":
        sole(m, 0, 0.16, (255, 205, 50))
        up, _ = upper(m, 0.16, (226, 40, 46))
        tree = m.bvh(up)
        collar(m, tree)
        m.stuck(tree, (0, -0.22, 2), (0, -0.2, 1), (0.22, 0.17, 0.05), (250, 250, 252), sink=0.4, name="Flap")
        loc, nor = Model.hit(tree, (0, -0.22, 2), (0, -0.2, 1))
        if loc:
            pawon(m, loc + nor * 0.06, nor, (0, -1, 0), 0.16, (226, 40, 46))
        for x in (-1, 1):
            base = Vector((x * 0.2, 0.72, 0.4))
            kit_c = Matrix.Translation(base) @ Vector((0, 0, 1)).rotation_difference(Vector((0, 0.35, 1))).to_matrix().to_4x4()
            m.blob((0.11, 0.11, 0.24), (220, 224, 234), kit_c, e1=0.9, e2=1.0, name="Rocket")
            m.drop(kit_c @ Vector((0, 0, 0.18)), kit_c.to_3x3() @ Vector((0, 0, 1)), 0.22, 0.1, (226, 40, 46), name="Nose")
            m.flame(kit_c @ Vector((0, 0, -0.2)), kit_c.to_3x3() @ Vector((0, 0, -1)), 0.35, 0.09, (255, 150, 40), emit=2.0)
            m.flame(kit_c @ Vector((0, 0, -0.22)), kit_c.to_3x3() @ Vector((0, 0, -1)), 0.22, 0.05, (255, 230, 90), emit=2.5)
        for x in (-1, 1):
            m.leaf((x * 0.33, 0.45, 0.7), (x * 0.6, 0.6, 0.5), 0.34, 0.16, (255, 205, 50), up=(0, 0, 1), name="Wing")
    elif key == "CloudSteppers":
        sole(m, 0, 0.14, (140, 210, 255))
        for x, y, z, r in ((0, -0.45, 0.32, 0.22), (0.12, -0.2, 0.36, 0.26), (-0.14, -0.15, 0.36, 0.25), (0.15, 0.15, 0.42, 0.26),
                           (-0.15, 0.2, 0.42, 0.26), (0, 0.42, 0.48, 0.26), (0, 0.0, 0.5, 0.24), (0.2, 0.45, 0.32, 0.18),
                           (-0.2, 0.45, 0.32, 0.18), (0.22, -0.35, 0.25, 0.15), (-0.22, -0.35, 0.25, 0.15)):
            m.ball((x, y, z), r, (250, 252, 255), name="Puff")
        m.blob((0.22, 0.05, 0.08), (140, 210, 255), T(0, -0.12, 0.72) @ R(-0.4, "X"), e1=0.4, e2=0.6, name="Strap")
        pawon(m, Vector((0, -0.17, 0.75)), (0, -0.4, 1), (0, 1, 0), 0.12, (250, 250, 252))
        for x in (-1, 1):
            for i, (ln, up) in enumerate(((0.42, 0.25), (0.34, 0.12), (0.26, 0.0))):
                m.leaf((x * 0.32, 0.35, 0.55 + up * 0.4), (x * 0.5, 0.7, 0.6 - i * 0.3), ln, 0.14, (250, 252, 255),
                       up=(0, 0, 1), name="Feather")
    elif key == "LightningBoots":
        sole(m, 0, 0.16, (255, 214, 40), emit=1.2)
        up, sh = upper(m, 0.16, (40, 46, 84), high=0.42)
        tree = m.bvh(sh)
        m.blob((WID * 0.82, LEN * 0.42, 0.14), (255, 205, 40), T(0, -0.32, 0.32), e1=0.6, e2=0.8, name="ToeCap")
        collar(m, tree, y=0.26, rx=0.22, ry=0.24)
        m.blob((0.33, 0.04, 0.09), (255, 205, 40), T(0, -0.02, 0.72), e1=0.4, e2=0.6, name="Strap")
        bolt = [(-0.05, 0.3), (0.12, 0.3), (0.03, 0.06), (0.14, 0.06), (-0.1, -0.3), (-0.02, -0.04), (-0.13, -0.04)]
        for x in (-1, 1):
            loc, nor = side_point(tree, 0.25, 0.75, x)
            fr = Matrix.Translation(loc + nor * 0.03) @ Vector((0, 0, 1)).rotation_difference(nor).to_matrix().to_4x4()
            fr = fr @ R(PI / 2 * (1 if x > 0 else -1), "Z")
            m.slab(bolt, 0.05, (255, 214, 40), fr, bevel=0.015, name="Bolt", emit=0.8)
    elif key == "CometKicks":
        sole(m, 0, 0.16, (255, 120, 220), emit=1.0)
        up, _ = upper(m, 0.16, (110, 60, 200))
        tree = m.bvh(up)
        collar(m, tree)
        m.blob((0.3, 0.05, 0.08), (250, 205, 60), T(0, -0.15, 0.54) @ R(-0.35, "X"), e1=0.4, e2=0.6, name="Strap")
        for (y, z, r) in ((-0.3, 0.32, 0.09), (0.1, 0.42, 0.11), (0.35, 0.3, 0.07)):
            loc, nor = side_point(tree, y, z)
            if loc:
                fr = Matrix.Translation(loc + nor * 0.02) @ Vector((0, 0, 1)).rotation_difference(nor).to_matrix().to_4x4()
                star(m, (0, 0, 0), r, (255, 214, 60), frame=fr @ R(-PI / 2, "X"), emit=0.6)
        # comet tail streaming back from the heel
        m.flame((0, 0.6, 0.5), (0, 1, 0.35), 0.75, 0.2, (180, 90, 255), wiggle=0.08, side=(1, 0, 0), emit=2.0, name="Tail")
        m.flame((0, 0.62, 0.5), (0, 1, 0.3), 0.55, 0.12, (255, 140, 230), wiggle=0.06, side=(1, 0, 0), emit=2.5, name="Tail2")
        star(m, (0, 0.62, 0.5), 0.15, (255, 230, 120), frame=Matrix(), emit=2.0)
    return m
