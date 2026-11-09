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


def swirl(m, cx, cy, r, z0, z1, cols, emit=2.5, turns=1.4):
    for k, col in enumerate(cols[:2]):
        pts = []
        n = 48
        for i in range(n + 1):
            t = i / n
            a = k * math.pi + t * turns * TAU
            rr = r * (1.0 - 0.25 * t)
            pts.append(Vector((cx + math.cos(a) * rr, cy + math.sin(a) * rr, z0 + (z1 - z0) * t)))
        m.tube(pts, lambda t: 0.02 + 0.06 * math.sin(math.pi * t), lighter(C(col), 0.4), n=8, name="Fx_Swirl", emit=emit * 1.2)
        m.tube(pts, lambda t: 0.05 + 0.16 * math.sin(math.pi * t), C(col), n=10, name="Fx_SwirlGlow", emit=emit * 0.5, alpha=0.2)


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
