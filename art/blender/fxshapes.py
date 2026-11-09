"""Smooth effect shapes for Mythical / Secret cats (V5j, developer 2026-11-09: "the effects look like plain
geometry, make them beautiful shapes in Blender, special, with an aura"). Style options for approval:

  A "charms"  smooth glowing items round the cat + twinkles + a soft glow on the ground
  B "magic"   A + a magic circle on the ground + two ribbons of light spiralling up round the cat
  C "aura"    A + a see-through flame-shaped aura round the whole cat + light motes rising

Everything is something Roblox can show: each item / ribbon / circle is one mesh (uploaded by the developer, Neon
so it glows), a glow = the same mesh a little bigger and half see-through, the aura = a see-through Neon mesh.
Object names start with "Fx" so the rig (catrig.py) puts them on the Fx bone.
"""
import math
import random

from mathutils import Matrix, Vector

from kit import R, T

TAU = 2 * math.pi


def C(c):
    return tuple(int(v) for v in c)


def lighter(c, k=0.5):
    return tuple(int(v + (255 - v) * k) for v in c)


# -- single items ----------------------------------------------------------------------------------------------
def star_outline(points, ro, ri, phase=math.pi / 2):
    out = []
    for k in range(points * 2):
        a = phase + k * math.pi / points
        r = ro if k % 2 == 0 else ri
        out.append((math.cos(a) * r, math.sin(a) * r))
    return out


def facing(c, center):
    """A frame at c whose local Z points away from the cat's middle (so flat items face the viewer round it)."""
    d = Vector((c[0] - center[0], c[1] - center[1], 0))
    if d.length < 1e-4:
        d = Vector((0, -1, 0))
    d.normalize()
    q = d.to_track_quat("Z", "Y")
    return Matrix.Translation(Vector(c)) @ q.to_matrix().to_4x4()


def item(m, kind, c, s, col, center, rnd, emit=3.0):
    col = C(col)
    hi = lighter(col, 0.55)
    f = facing(c, center)
    if kind == "flame":
        base = Vector(c) - Vector((0, 0, s * 0.45))
        ph = rnd.uniform(0, 6)
        m.flame(base, (0, 0, 1), s * 1.5, s * 0.42, col, wiggle=0.16, phase=ph, name="Fx_Flame", emit=emit, alpha=0.95)
        m.flame(base + Vector((0, 0, s * 0.05)), (0, 0, 1), s * 0.95, s * 0.24, (255, 245, 190), wiggle=0.12, phase=ph,
                name="Fx_FlameCore", emit=emit * 1.4)
        m.flame(base - Vector((0, 0, s * 0.1)), (0, 0, 1), s * 1.9, s * 0.62, col, wiggle=0.16, phase=ph, name="Fx_FlameGlow",
                emit=emit * 0.6, alpha=0.22)
    elif kind == "crystal":
        def shard(off, scale, tilt, spin, colr, alpha, name, e):
            h, r = s * 1.7 * scale, s * 0.3 * scale

            def prof(t):
                if t <= 0.0 or t >= 1.0:
                    return (t * h, 0.0)
                w = min(t / 0.15, 1.0) if t < 0.15 else (1 - t) / 0.85
                return (t * h, r * (w ** 0.6))
            fr = Matrix.Translation(Vector(c) + Vector(off)) @ R(spin, "Z") @ R(tilt, "X") @ R(-math.pi / 2, "Y")
            return m.lathe(prof, colr, fr @ T(-h * 0.35, 0, 0), n_t=8, n_a=6, name=name, smooth=False, rough=0.05, coat=1.0,
                           emit=e, alpha=alpha)
        spin = rnd.uniform(0, 6.28)
        shard((0, 0, -s * 0.5), 1.0, 0.0, spin, col, 0.92, "Fx_Crystal", emit * 0.55)
        shard((0, 0, -s * 0.5), 0.62, 0.0, spin, hi, 1.0, "Fx_CrystalCore", emit * 0.9)
        shard((s * 0.18, 0, -s * 0.55), 0.6, 0.55, spin, col, 0.92, "Fx_Crystal", emit * 0.55)
        shard((-s * 0.15, 0, -s * 0.55), 0.5, -0.6, spin + 1.2, col, 0.92, "Fx_Crystal", emit * 0.55)
        shard((0, 0, -s * 0.55), 1.35, 0.0, spin, col, 0.16, "Fx_CrystalGlow", emit * 0.5)
    elif kind == "star":
        out = star_outline(5, s * 0.62, s * 0.28)
        m.slab(out, s * 0.3, col, f, bevel=s * 0.12, name="Fx_Star", emit=emit, rough=0.2)
        m.slab(star_outline(5, s * 0.36, s * 0.16), s * 0.32, hi, f @ T(0, 0, s * 0.03), bevel=s * 0.08, name="Fx_StarCore",
               emit=emit * 1.3)
        m.slab(star_outline(5, s * 0.95, s * 0.45), s * 0.12, col, f @ T(0, 0, -s * 0.05), bevel=s * 0.05,
               name="Fx_StarGlow", emit=emit * 0.6, alpha=0.25)
    elif kind == "flake":
        fr = f
        for k in range(6):
            a = k * TAU / 6
            d = Vector((math.cos(a), math.sin(a), 0))
            p0 = fr @ Vector((0, 0, 0))
            tip = fr @ (d * s * 0.62)
            m.tube([p0, tip], s * 0.055, col, n=8, name="Fx_Flake", emit=emit)
            for side in (-1, 1):
                b0 = fr @ (d * s * 0.36)
                bd = Vector((math.cos(a + side * 0.75), math.sin(a + side * 0.75), 0))
                m.tube([b0, fr @ (d * s * 0.36 + bd * s * 0.2)], s * 0.04, col, n=6, name="Fx_Flake", emit=emit)
        m.ball(Vector(c), s * 0.11, hi, name="Fx_FlakeCore", emit=emit * 1.3)
        m.revolve([(s * 0.0, -0.01), (s * 0.72, -0.01), (s * 0.72, 0.01), (0.0, 0.01)], col, fr, n_a=24, name="Fx_FlakeGlow",
                  emit=emit * 0.5, alpha=0.18)
    elif kind == "twinkle":
        m.slab(star_outline(4, s * 0.5, s * 0.1), s * 0.06, (255, 255, 255), f, bevel=s * 0.02, name="Fx_Twinkle", emit=emit * 1.5)
        m.slab(star_outline(4, s * 0.8, s * 0.2), s * 0.03, col, f @ T(0, 0, -0.01), bevel=s * 0.01, name="Fx_TwinkleGlow",
               emit=emit * 0.8, alpha=0.35)
    elif kind == "orb":
        m.ball(Vector(c), s * 0.32, hi, name="Fx_Orb", emit=emit * 1.2)
        m.ball(Vector(c), s * 0.55, col, name="Fx_OrbGlow", emit=emit * 0.6, alpha=0.25)
    else:
        more(m, kind, c, s, col, hi, f, rnd, emit, center)


def halo(m, c, r, col, emit, name="Fx_Glow"):
    """A soft see-through ball round an item (only for things that glow)."""
    if emit > 0.4:
        m.ball(Vector(c), r, col, name=name, emit=emit * 0.5, alpha=0.18)


def more(m, kind, c, s, col, hi, f, rnd, emit, center):
    """The other item kinds of cateffects.STYLE, all smooth (V5j)."""
    v = Vector(c)
    e = emit
    if kind == "ball":
        m.ball(v, s * 0.4, col, name="Fx_Orb", emit=e)
        m.ball(v + Vector((-s * 0.1, -s * 0.12, s * 0.12)), s * 0.12, lighter(col, 0.7), name="Fx_OrbShine", emit=e * 1.3)
        halo(m, c, s * 0.62, col, e)
    elif kind == "bubble":
        m.ball(v, s * 0.5, lighter(col, 0.3), name="Fx_Bubble", emit=e * 0.5, alpha=0.3, rough=0.02, coat=1.0)
        m.ball(v + Vector((-s * 0.18, -s * 0.2, s * 0.2)), s * 0.09, (255, 255, 255), name="Fx_BubbleShine", emit=2.0)
        m.torus(s * 0.5, s * 0.02, lighter(col, 0.5), f, nu=32, nv=6, name="Fx_BubbleRim", emit=e, alpha=0.6)
    elif kind in ("cube", "pixel"):
        k = 0.5 if kind == "cube" else 0.35
        m.blob((s * 0.5, s * 0.5 * (1 if kind == "cube" else 0.4), s * 0.5), col, f @ R(rnd.uniform(0, 1.5), "Z") @ R(0.6, "X"),
               e1=k, e2=k, nu=12, nv=8, name="Fx_Chip", emit=e, smooth=True)
        halo(m, c, s * 0.75, col, e)
    elif kind == "spark":
        item(m, "twinkle", c, s * 1.2, col, center, rnd, e)
    elif kind == "heart":
        out = []
        for i in range(40):
            t = i / 40 * TAU
            x = 16 * math.sin(t) ** 3
            y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
            out.append((x * s * 0.034, y * s * 0.034))
        out.reverse()
        m.slab(out[::-1], s * 0.32, col, f, bevel=s * 0.13, name="Fx_Heart", emit=e, rough=0.2)
        if e > 0.4:
            m.slab([(x * 1.45, y * 1.45) for x, y in out[::-1]], s * 0.08, col, f @ T(0, 0, -s * 0.06), bevel=s * 0.03,
                   name="Fx_HeartGlow", emit=e * 0.5, alpha=0.22)
    elif kind == "note":
        head = f @ T(-s * 0.15, -s * 0.3, 0)
        m.blob((s * 0.2, s * 0.14, s * 0.1), col, head @ R(0.45, "Z"), name="Fx_Note", emit=e)
        top = f @ Vector((s * 0.03, s * 0.42, 0))
        m.tube([head @ Vector((s * 0.18, 0, 0)), top], s * 0.035, col, n=8, name="Fx_Note", emit=e)
        m.leaf(top, (f.to_3x3() @ Vector((0.6, -0.8, 0))), s * 0.38, s * 0.16, col, thick=s * 0.05, bend=0.2, name="Fx_Note",
               emit=e)
        halo(m, c, s * 0.55, col, e)
    elif kind == "flame":
        item(m, "flame", c, s, col, center, rnd, e)
    elif kind in ("leaf", "petal", "feather"):
        L, W = {"leaf": (s * 1.0, s * 0.5), "petal": (s * 0.6, s * 0.5), "feather": (s * 1.3, s * 0.34)}[kind]
        d = Vector((rnd.uniform(-0.4, 0.4), rnd.uniform(-0.4, 0.4), 1)).normalized()
        base = v - d * L * 0.5
        m.leaf(base, d, L, W, col, thick=W * 0.16, bend=0.25 if kind != "petal" else 0.4, roll=rnd.uniform(0, 3),
               fat=0.55 if kind == "leaf" else (0.4 if kind == "petal" else 0.75), name="Fx_" + kind.title(), emit=e)
        if kind != "petal":
            m.tube([base, base + d * L * 0.95], W * 0.05, lighter(col, 0.4) if kind == "feather" else C((90, 150, 60)), n=6,
                   name="Fx_" + kind.title(), emit=e * 0.5)
        halo(m, c, L * 0.55, col, e)
    elif kind == "gem":
        item(m, "crystal", c, s, col, center, rnd, e)
    elif kind == "coin":
        fr = f @ R(math.pi / 2, "X") @ R(rnd.uniform(-0.4, 0.4), "Y")
        r = s * 0.45
        m.revolve([(0, -s * 0.07), (r * 0.95, -s * 0.07), (r, -s * 0.03), (r, s * 0.03), (r * 0.95, s * 0.07), (r * 0.75, s * 0.07),
                   (r * 0.72, s * 0.04), (0, s * 0.04)], col, fr, n_a=32, name="Fx_Coin", emit=e * 0.6, rough=0.15, coat=0.8)
        m.slab(star_outline(5, r * 0.45, r * 0.2), s * 0.03, lighter(col, 0.4), fr @ T(0, 0, s * 0.05), bevel=s * 0.01,
               name="Fx_Coin", emit=e)
        halo(m, c, s * 0.6, col, e)
    elif kind == "ufo":
        fr = Matrix.Translation(v) @ R(rnd.uniform(-0.2, 0.2), "X")
        m.revolve([(0, -s * 0.1), (s * 0.35, -s * 0.12), (s * 0.62, -s * 0.02), (s * 0.62, s * 0.02), (s * 0.35, s * 0.08),
                   (0, s * 0.08)], (205, 215, 230), fr, n_a=36, name="Fx_Ufo", rough=0.2, coat=0.8)
        m.blob((s * 0.28, s * 0.28, s * 0.22), (150, 255, 190), fr @ T(0, 0, s * 0.1), name="Fx_UfoDome", emit=1.0, alpha=0.7)
        for k in range(6):
            a = k * TAU / 6
            m.ball(fr @ Vector((math.cos(a) * s * 0.48, math.sin(a) * s * 0.48, 0)), s * 0.06, col, name="Fx_UfoLight", emit=3.0)
    elif kind == "bat":
        out = [(0, 0.18), (0.2, 0.08), (0.45, 0.22), (0.62, 0.1), (0.55, -0.05), (0.42, -0.02), (0.32, -0.14), (0.2, -0.05),
               (0, -0.12), (-0.2, -0.05), (-0.32, -0.14), (-0.42, -0.02), (-0.55, -0.05), (-0.62, 0.1), (-0.45, 0.22), (-0.2, 0.08)]
        out = [(x * s * 1.4, y * s * 1.4) for x, y in out]
        m.slab(out[::-1], s * 0.08, col, f, bevel=s * 0.03, name="Fx_Bat")
        m.ball(f @ Vector((0, 0.02, s * 0.06)), s * 0.14, col, name="Fx_Bat")
        for x in (-1, 1):
            m.ball(f @ Vector((x * s * 0.05, s * 0.05, s * 0.18)), s * 0.03, (255, 220, 80), name="Fx_BatEye", emit=3.0)
    elif kind == "gear":
        fr = f
        m.revolve([(s * 0.16, -s * 0.08), (s * 0.4, -s * 0.08), (s * 0.4, s * 0.08), (s * 0.16, s * 0.08)], col, fr, n_a=64,
                  rmod=lambda a: 1.0 + 0.22 * (1 if math.cos(a * 8) > 0.2 else 0), name="Fx_Gear", rough=0.25, coat=0.6,
                  smooth=False, emit=e)
    elif kind == "candy":
        fr = f @ R(rnd.uniform(-0.6, 0.6), "Y")
        m.ball(v, s * 0.28, col, name="Fx_Candy", emit=e, rough=0.1, coat=1.0)
        m.torus(s * 0.2, s * 0.05, (255, 255, 255), fr @ R(0.6, "Y"), nu=24, nv=6, name="Fx_Candy", emit=e)
        for x in (-1, 1):
            m.drop(fr @ Vector((x * s * 0.62, 0, 0)), fr.to_3x3() @ Vector((-x, 0, 0)), s * 0.38, s * 0.2, lighter(col, 0.3),
                   name="Fx_Candy", emit=e)
    elif kind == "moon":
        out = []
        for i in range(25):
            a = -2.4 + 4.8 * i / 24
            out.append((math.cos(a) * s * 0.55, math.sin(a) * s * 0.55))
        for i in range(25):
            a = 2.0 - 4.0 * i / 24
            out.append((math.cos(a) * s * 0.42 + s * 0.2, math.sin(a) * s * 0.46))
        m.slab(out, s * 0.22, col, f @ R(0.4, "Z"), bevel=s * 0.09, name="Fx_Moon", emit=e)
        halo(m, c, s * 0.75, col, e)
    elif kind == "cloud":
        for dx, dz, r in ((-0.32, -0.05, 0.3), (0.0, 0.08, 0.4), (0.33, -0.04, 0.3), (0.12, -0.15, 0.28), (-0.15, -0.15, 0.27)):
            m.ball(f @ Vector((dx * s, dz * s, 0)), r * s, col, name="Fx_Cloud", emit=e * 0.6, rough=0.6)
    elif kind == "rock":
        def warp(p):
            k = 1 + 0.18 * math.sin(p.x * 7 + 1.3) * math.cos(p.y * 6) + 0.1 * math.sin(p.z * 9)
            return p * k
        m.blob((s * 0.42, s * 0.36, s * 0.32), col, f @ R(rnd.uniform(0, 3), "Z"), e1=0.8, e2=0.8, nu=14, nv=10, warp=warp,
               name="Fx_Rock", smooth=False, rough=0.8)
        m.blob((s * 0.3, s * 0.26, s * 0.08), C((110, 190, 90)), f @ T(0, 0, s * 0.28), nu=10, nv=6, name="Fx_RockMoss")
    elif kind == "drop":
        m.drop(v - Vector((0, 0, s * 0.25)), (0, 0, 1), s * 0.75, s * 0.3, col, tip=1.4, name="Fx_Drop", emit=e, alpha=0.85, rough=0.05,
               coat=1.0)
        m.ball(v + Vector((-s * 0.08, -s * 0.12, -s * 0.05)), s * 0.06, (255, 255, 255), name="Fx_DropShine", emit=2.0)
        halo(m, c, s * 0.5, col, e)
    elif kind == "lantern":
        fr = Matrix.Translation(v)
        m.revolve([(0.0, -s * 0.35), (s * 0.2, -s * 0.33), (s * 0.34, -s * 0.15), (s * 0.36, 0), (s * 0.34, s * 0.15), (s * 0.2, s * 0.33),
                   (0.0, s * 0.35)], col, fr, n_a=32, rmod=lambda a: 1 - 0.06 * abs(math.sin(a * 4)), name="Fx_Lantern", emit=e,
                  alpha=0.95)
        for z in (-1, 1):
            m.revolve([(0, -s * 0.04), (s * 0.18, -s * 0.04), (s * 0.18, s * 0.04), (0, s * 0.04)], C((140, 40, 30)),
                      fr @ T(0, 0, z * s * 0.36), n_a=20, name="Fx_LanternCap")
        halo(m, c, s * 0.6, col, e)
    elif kind == "z":
        out = [(-0.3, 0.3), (0.3, 0.3), (0.3, 0.18), (-0.1, -0.18), (0.3, -0.18), (0.3, -0.3), (-0.3, -0.3), (-0.3, -0.18),
               (0.1, 0.18), (-0.3, 0.18)]
        m.slab([(x * s, y * s) for x, y in out][::-1], s * 0.16, col, f, bevel=s * 0.05, name="Fx_Zzz", emit=e)
    elif kind == "bolt":
        out = [(0.05, 0.55), (-0.25, 0.0), (-0.02, 0.02), (-0.12, -0.55), (0.25, 0.08), (0.02, 0.06), (0.18, 0.55)]
        m.slab([(x * s, y * s) for x, y in out][::-1], s * 0.16, col, f, bevel=s * 0.05, name="Fx_Bolt", emit=e)
        if e > 0.4:
            m.slab([(x * s * 1.5, y * s * 1.3) for x, y in out][::-1], s * 0.05, col, f @ T(0, 0, -s * 0.06), bevel=s * 0.02,
                   name="Fx_BoltGlow", emit=e * 0.5, alpha=0.25)
    elif kind == "clock":
        fr = f
        m.revolve([(0, -s * 0.06), (s * 0.48, -s * 0.06), (s * 0.5, 0), (s * 0.48, s * 0.06), (0, s * 0.06)], col, fr, n_a=40,
                  name="Fx_Clock", emit=e * 0.6)
        m.torus(s * 0.48, s * 0.05, C((220, 170, 60)), fr, nu=40, nv=8, name="Fx_ClockRim", rough=0.2)
        o = fr @ Vector((0, 0, s * 0.08))
        m.tube([o, fr @ Vector((0, s * 0.3, s * 0.08))], s * 0.03, C((60, 50, 70)), n=6, name="Fx_ClockHand")
        m.tube([o, fr @ Vector((s * 0.2, -s * 0.05, s * 0.08))], s * 0.03, C((60, 50, 70)), n=6, name="Fx_ClockHand")
    elif kind == "portal":
        fr = f
        m.torus(s * 0.5, s * 0.08, col, fr, nu=48, nv=10, name="Fx_Portal", emit=e)
        m.revolve([(0, -0.01), (s * 0.48, -0.01), (s * 0.48, 0.01), (0, 0.01)], lighter(col, 0.3), fr, n_a=40, name="Fx_PortalCore",
                  emit=e * 0.6, alpha=0.4)
        pts = [fr @ Vector((math.cos(t * 9) * s * 0.45 * t, math.sin(t * 9) * s * 0.45 * t, 0.02)) for t in [i / 30 for i in range(1, 31)]]
        m.tube(pts, s * 0.025, lighter(col, 0.6), n=6, name="Fx_PortalSwirl", emit=e * 1.2)
    elif kind == "sweetpotato":
        def warp(p):
            return Vector((p.x, p.y, p.z + 0.12 * s * math.sin(p.x / s * 3)))
        fr = Matrix.Translation(v) @ R(rnd.uniform(0.3, 0.8), "Y")
        m.blob((s * 0.55, s * 0.3, s * 0.28), C((175, 85, 170)), fr, nu=20, nv=12, warp=warp, name="Fx_Potato", emit=e * 0.3)
        m.leaf(fr @ Vector((s * 0.5, 0, s * 0.1)), (fr.to_3x3() @ Vector((1, 0, 0.8))), s * 0.5, s * 0.25, C((110, 200, 80)),
               name="Fx_PotatoLeaf")
        halo(m, c, s * 0.7, col, e)
    elif kind == "flower":
        fr = Matrix.Translation(v)
        for k in range(5):
            a = k * TAU / 5
            d = Vector((math.cos(a), math.sin(a), 0.35)).normalized()
            m.leaf(v, d, s * 0.55, s * 0.36, col, thick=s * 0.06, bend=0.35, fat=0.4, name="Fx_Flower", emit=e)
        m.ball(v + Vector((0, 0, s * 0.06)), s * 0.14, C((255, 225, 90)), name="Fx_FlowerCore", emit=e * 1.2)
    elif kind == "fish":
        fr = f @ R(math.pi / 2, "Y")
        m.blob((s * 0.38, s * 0.12, s * 0.22), col, f, nu=18, nv=10, name="Fx_Fish", emit=e * 0.5)
        m.leaf(f @ Vector((-s * 0.3, 0, 0)), f.to_3x3() @ Vector((-1, 0, 0)), s * 0.3, s * 0.3, col, thick=s * 0.04, fat=0.3,
               name="Fx_Fish", emit=e * 0.5)
    elif kind == "twinkle":
        item(m, "twinkle", c, s, col, center, rnd, e)
    else:
        raise ValueError(kind)


# -- aura pieces -------------------------------------------------------------------------------------------------
def ground_glow(m, cx, cy, r, col, emit=2.0):
    fr = T(cx, cy, 0.04)
    # soft: three see-through discs, fainter outwards, and one thin bright ring
    for k, (rr, al) in enumerate(((r * 0.55, 0.16), (r * 0.8, 0.1), (r, 0.07))):
        m.revolve([(0.0, -0.004), (rr, -0.004), (rr, 0.004), (0.0, 0.004)], lighter(col, 0.35), fr @ T(0, 0, k * 0.004), n_a=64,
                  name="Fx_GroundGlow", emit=emit * 0.5, alpha=al)
    m.torus(r, 0.035, lighter(col, 0.5), fr, nu=96, nv=8, name="Fx_GroundRing", emit=emit * 1.2)


def magic_circle(m, cx, cy, r, col, emit=2.5):
    fr = T(cx, cy, 0.05)
    hi = lighter(col, 0.4)
    m.torus(r, 0.07, hi, fr, nu=96, nv=8, name="Fx_Circle", emit=emit)
    m.torus(r * 0.82, 0.045, col, fr, nu=96, nv=8, name="Fx_Circle", emit=emit)
    # a star drawn inside, point to point
    pts = [Vector((math.cos(math.pi / 2 + k * 4 * math.pi / 5) * r * 0.8, math.sin(math.pi / 2 + k * 4 * math.pi / 5) * r * 0.8,
                   0)) for k in range(6)]
    for a, b in zip(pts, pts[1:]):
        m.tube([fr @ a, fr @ b], 0.035, col, n=6, caps=True, name="Fx_Circle", emit=emit)
    # little runes (diamonds) between the two rings
    for k in range(12):
        a = k * TAU / 12
        p = fr @ Vector((math.cos(a) * r * 0.91, math.sin(a) * r * 0.91, 0))
        m.slab([(0, 0.13), (-0.07, 0), (0, -0.13), (0.07, 0)], 0.03, hi, Matrix.Translation(p) @ R(a, "Z"), bevel=0.01,
               name="Fx_Rune", emit=emit)
    m.revolve([(0.0, -0.005), (r, -0.005), (r, 0.005), (0.0, 0.005)], col, fr @ T(0, 0, -0.01), n_a=64, name="Fx_GroundGlow",
              emit=emit * 0.4, alpha=0.18)


def swirl(m, cx, cy, r, z0, z1, cols, emit=2.5, turns=1.4, tail=0.0, head=1.0, fade=1.0):
    """Two ribbons of light spiralling up. tail..head (0..1 of the full spiral) and fade (1 = full, 0 = gone) show one
    moment of the Secret burst (in game every 3 s: the head shoots up from the ground, the tail follows, it fades)."""
    if head - tail < 0.02 or fade <= 0.02:
        return
    for k, col in enumerate(cols[:2]):
        pts = []
        n = max(4, int(48 * (head - tail)))
        for i in range(n + 1):
            t = tail + (head - tail) * i / n
            a = k * math.pi + t * turns * TAU
            rr = r * (1.0 - 0.25 * t)
            pts.append(Vector((cx + math.cos(a) * rr, cy + math.sin(a) * rr, z0 + (z1 - z0) * t)))
        m.tube(pts, lambda t: (0.03 + 0.07 * math.sin(math.pi * t)) * (0.4 + 0.6 * fade), lighter(C(col), 0.15), n=8,
               name="Fx_Swirl", emit=emit * 1.2, alpha=min(1.0, 0.25 + 0.75 * fade))
        m.tube(pts, lambda t: 0.05 + 0.16 * math.sin(math.pi * t), C(col), n=10, name="Fx_SwirlGlow", emit=emit * 0.5,
               alpha=0.2 * fade)


def aura_shell(m, cx, cy, r, height, col, emit=1.6, rnd=None):
    """A ring of tall see-through flame tongues round the cat (a power-up aura), brighter at their roots."""
    rnd = rnd or random.Random(1)
    tongues = 14
    for k in range(tongues):
        a = k * TAU / tongues + rnd.uniform(-0.1, 0.1)
        base = Vector((cx + math.cos(a) * r, cy + math.sin(a) * r, 0.05))
        tall = height * rnd.uniform(0.55, 1.0)
        side = (-math.sin(a), math.cos(a), 0)
        m.flame(base, (math.cos(a) * 0.12, math.sin(a) * 0.12, 1), tall, 0.42, col, wiggle=0.1, phase=rnd.uniform(0, 6),
                side=side, name="Fx_Aura", emit=emit, alpha=0.2)
        m.flame(base, (math.cos(a) * 0.1, math.sin(a) * 0.1, 1), tall * 0.45, 0.2, lighter(col, 0.5), wiggle=0.1,
                phase=rnd.uniform(0, 6), side=side, name="Fx_AuraCore", emit=emit * 1.5, alpha=0.45)


def motes(m, cx, cy, r, z0, z1, col, n, rnd, emit=3.0):
    for k in range(n):
        a = rnd.uniform(0, TAU)
        rr = r * rnd.uniform(0.4, 1.0)
        p = Vector((cx + math.cos(a) * rr, cy + math.sin(a) * rr, rnd.uniform(z0, z1)))
        sz = rnd.uniform(0.06, 0.12)
        m.ball(p, sz, lighter(C(col), 0.6), name="Fx_Mote", emit=emit * 1.4)
        m.tube([p - Vector((0, 0, sz * 6)), p], lambda t: sz * 0.6 * t, C(col), n=6, caps=False, name="Fx_MoteTrail", emit=emit,
               alpha=0.35)


# -- the whole effect ------------------------------------------------------------------------------------------
def effect(m, a, style, kind, cols, n=8, s=0.55, emit=3.0, seed=3):
    """a = catparts.G(A). style: "charms" | "magic" | "aura"."""
    rnd = random.Random(seed)
    cols = [C(c) for c in cols]
    cx, cy = 0.0, a.by - 0.3
    r = max(a.bw, a.bl) / 2 + 1.5
    top = a.top
    center = (cx, cy)
    # the items: an even ring, heights in a gentle wave (designed, not random)
    for k in range(n):
        ang = k * TAU / n + 0.3
        zz = 1.0 + (top - 1.2) * (0.5 + 0.45 * math.sin(k * TAU / n * 2 + 0.6))
        c = (cx + math.cos(ang) * r, cy + math.sin(ang) * r, zz)
        item(m, kind, c, s * (1.0 if k % 2 == 0 else 0.8), cols[k % len(cols)], center, rnd, emit)
    # twinkles between them
    for k in range(5):
        ang = rnd.uniform(0, TAU)
        rr = r * rnd.uniform(0.75, 1.15)
        item(m, "twinkle", (cx + math.cos(ang) * rr, cy + math.sin(ang) * rr, rnd.uniform(0.8, top + 0.6)), rnd.uniform(0.35, 0.55),
             cols[0], center, rnd, emit)
    if style == "charms":
        ground_glow(m, cx, cy, r * 0.95, cols[0], emit)
    elif style == "magic":
        magic_circle(m, cx, cy, r * 1.05, cols[0], emit)
        swirl(m, cx, cy, r * 1.0, 0.2, top + 1.0, cols if len(cols) > 1 else cols * 2, emit)
    elif style == "aura":
        aura_shell(m, cx, cy, max(a.bw, a.bl) / 2 + 0.7, top + 1.2, cols[0], emit * 0.8, rnd)
        ground_glow(m, cx, cy, r * 0.75, cols[0], emit)
        motes(m, cx, cy, r * 0.9, 0.3, top + 1.5, cols[-1], 12, rnd, emit)
    else:
        raise ValueError(style)


# -- the game's effects: cateffects.STYLE specs in the approved looks ------------------------------------------
# developer 2026-11-09: Mythical = A (items + twinkles + soft ground glow; in game the items orbit the cat),
# Secret = B (items + twinkles + magic circle + light ribbons; in game the ribbons shoot up from the ground and fade,
# every 3 s).
KIND = {"star": "star", "flame": "flame", "gem": "crystal", "flake": "flake", "spark": "twinkle", "ball": "ball"}


def ring_arcs(m, cx, cy, r, z, cols, emit):
    """A smooth glowing ring, one arc per colour."""
    n = len(cols)
    for k, col in enumerate(cols):
        a0, a1 = k * TAU / n, (k + 1) * TAU / n + 0.02
        pts = [Vector((cx + math.cos(a0 + (a1 - a0) * i / 16) * r, cy + math.sin(a0 + (a1 - a0) * i / 16) * r, z)) for i in range(17)]
        m.tube(pts, 0.07, lighter(C(col), 0.25), n=8, caps=False, name="Fx_Ring", emit=emit)
        m.tube(pts, 0.2, C(col), n=8, caps=False, name="Fx_RingGlow", emit=emit * 0.5, alpha=0.18)


def back_wheel(m, a, r, cols, n, emit):
    """A radiant wheel behind the cat (sun, wings of light, zodiac, eclipse): rays, a ring and a soft disc."""
    c = Vector((0, a.bback + 0.6, a.btop + 1.2))
    fr = Matrix.Translation(c) @ R(math.pi / 2, "X")
    cols = [C(x) for x in cols]
    m.revolve([(0, -0.01), (r * 0.62, -0.01), (r * 0.62, 0.01), (0, 0.01)], cols[0], fr, n_a=48, name="Fx_WheelDisc",
              emit=emit * 0.4, alpha=0.25)
    m.torus(r * 0.62, 0.08, lighter(cols[0], 0.3), fr, nu=64, nv=8, name="Fx_Wheel", emit=emit)
    for k in range(n):
        ang = k * TAU / n
        d = Vector((math.cos(ang), math.sin(ang), 0))
        p0, p1 = fr @ (d * r * 0.7), fr @ (d * (r + (0.35 if k % 2 == 0 else 0.0)))
        m.tube([p0, p1], lambda t: 0.16 * (1 - t) + 0.02, cols[k % len(cols)], n=8, name="Fx_WheelRay", emit=emit)


def log(m, what, **data):
    """What the game needs to rebuild the effect from the mesh library (cats_export.py writes it per cat)."""
    if not hasattr(m, "fx_log"):
        m.fx_log = []
    data["what"] = what
    m.fx_log.append(data)


def from_style(m, a, specs, tier, seed=3):
    """All the effect specs of one effectKey (cateffects.STYLE[key]) in the tier's look."""
    rnd = random.Random(seed)
    cx, cy = 0.0, a.by - 0.3
    top = a.top
    center = (cx, cy)
    base_r = max(a.bw, a.bl) / 2 + 1.5
    first = [C(x) for x in specs[0]["cols"]]
    # grey / dark effects (rocks, bats, gears) get the tier's colour on the ground
    import colorsys
    hsv = colorsys.rgb_to_hsv(*[v / 255 for v in first[0]])
    if hsv[1] < 0.25 or hsv[2] < 0.4:
        if hsv[2] > 0.8 and hsv[1] > 0.05:
            # pale but tinted (ice, snow, clouds): the same hue, stronger, so the glow shows
            r, g, b = colorsys.hsv_to_rgb(hsv[0], 0.55, 1.0)
            first = [(int(r * 255), int(g * 255), int(b * 255))] + first[1:]
        else:
            first = [(255, 95, 162)] if tier == "Mythical" else [(24, 201, 185), (120, 240, 230)]
    for st in specs:
        cols = [C(x) for x in st["cols"]]
        kind = KIND.get(st["kind"], st["kind"])
        n, sz, e, z = st["n"], max(0.32, st["s"] * 1.6), max(st["emit"], 0.0), st["z"]
        r = st["r"] or base_r
        lay = st["layout"]
        if lay in ("orbit", "rise", "ground", "above"):
            for k in range(n):
                ang = k * TAU / n + 0.3 + rnd.uniform(-0.08, 0.08)
                if lay == "orbit":
                    z0, z1 = (z[0], z[1]) if len(z) > 1 else (z[0], z[0])
                    zz = z0 + (z1 - z0) * (0.5 + 0.45 * math.sin(k * TAU / n * 2 + 0.6))
                    p = (cx + math.cos(ang) * r, cy + math.sin(ang) * r, zz)
                elif lay == "rise":
                    z0, z1 = z[0], z[-1]
                    p = (cx + math.cos(ang * 1.5) * r * 0.9, cy + math.sin(ang * 1.5) * r * 0.9, z0 + (z1 - z0) * k / max(1, n - 1))
                elif lay == "ground":
                    p = (cx + math.cos(ang) * r, cy + math.sin(ang) * r, sz * 0.5 + 0.1)
                else:
                    p = (rnd.uniform(-1.6, 1.6), a.hy + rnd.uniform(-1.0, 1.4), top + 1.0 + rnd.uniform(0, 1.4))
                size = sz * (1.0 if k % 2 == 0 else 0.85)
                log(m, "item", kind=kind, at=p, s=size, col=cols[k % len(cols)], center=center, emit=e)
                item(m, kind, p, size, cols[k % len(cols)], center, rnd, e)
        elif lay == "ring":
            log(m, "ring", at=(cx, cy, z[0]), r=r, cols=cols)
            ring_arcs(m, cx, cy, r, z[0], cols, max(e, 1.5))
        elif lay == "back":
            log(m, "wheel", at=(0, a.bback + 0.6, a.btop + 1.2), r=r, n=n, cols=cols)
            back_wheel(m, a, r, cols, n, max(e, 1.5))
        else:
            raise ValueError(lay)
    # twinkles round every effect
    for k in range(4 if tier == "Mythical" else 6):
        ang = rnd.uniform(0, TAU)
        rr = base_r * rnd.uniform(0.8, 1.15)
        p, size = (cx + math.cos(ang) * rr, cy + math.sin(ang) * rr, rnd.uniform(0.8, top + 0.8)), rnd.uniform(0.35, 0.5)
        log(m, "item", kind="twinkle", at=p, s=size, col=first[0], center=center, emit=3.0)
        item(m, "twinkle", p, size, first[0], center, rnd, 3.0)
    if tier == "Mythical":
        log(m, "ground", at=(cx, cy, 0), r=base_r * 0.95, cols=[first[0]])
        ground_glow(m, cx, cy, base_r * 0.95, first[0], 2.5)
    else:
        log(m, "circle", at=(cx, cy, 0), r=base_r * 1.05, cols=[first[0]])
        magic_circle(m, cx, cy, base_r * 1.05, first[0], 2.5)
        # the sheets show one moment of the burst (mid-flight); the game plays it every 3 s
        ribbon = first if len(first) > 1 else first * 2
        log(m, "burst", at=(cx, cy, 0.2), r=base_r, top=top + 1.0, cols=ribbon[:2])
        swirl(m, cx, cy, base_r, 0.2, top + 1.0, ribbon, 2.5, tail=0.3, head=0.8)
