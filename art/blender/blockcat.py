"""Block cats with LEGO studs (revision round 2, V1 second try). Direction from the client's pictures (another
game: only the direction is used): creatures made of big chunky blocks, every face covered in round studs,
fur as stacked angled plates, simple block faces, and for rarer ones crystals, gold armour, wings and glow.
Every cat here is our own design.

  cat(look, tier) -> kit.Model      look = the game's cat data (shape, fur, second, pattern, patternColor, eyes)
Units: studs, front = -Y, up = +Z, feet on z = 0. In the game the same blocks are Roblox Parts and the studs are
a tiled studs texture (one small image), so it costs no extra parts.
"""
import math

import bmesh
from mathutils import Matrix, Vector

import kit
from kit import Model, R, T

STUD = 0.42  # stud spacing
STUD_R = 0.13
STUD_H = 0.07
INK = (34, 30, 44)
PINK = (255, 150, 182)
WHITE = (255, 255, 255)
GOLD = (255, 196, 46)


def hexrgb(h, default):
    if not h:
        return default
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def block(m, center, size, color, frame=Matrix(), studs=True, bevel=0.035, name="Block", sides="all", **o):
    """A box (size = full sizes) with studs on its faces (sides: "all", "top" or "none")."""
    bm = bmesh.new()
    r = bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=r["verts"])
    if studs and sides != "none":
        hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
        faces = [((0, 0, 1), (1, 0, 0), (0, 1, 0), hz, (size[0], size[1]))]
        if sides == "all":
            faces += [((0, 0, -1), (1, 0, 0), (0, 1, 0), hz, (size[0], size[1])),
                      ((0, -1, 0), (1, 0, 0), (0, 0, 1), hy, (size[0], size[2])),
                      ((0, 1, 0), (1, 0, 0), (0, 0, 1), hy, (size[0], size[2])),
                      ((-1, 0, 0), (0, 1, 0), (0, 0, 1), hx, (size[1], size[2])),
                      ((1, 0, 0), (0, 1, 0), (0, 0, 1), hx, (size[1], size[2]))]
        for n, u, v, off, (lu, lv) in faces:
            n, u, v = Vector(n), Vector(u), Vector(v)
            nu, nv = max(1, int(lu / STUD)), max(1, int(lv / STUD))
            su, sv = lu / nu, lv / nv
            rot = n.to_track_quat("Z", "Y").to_matrix().to_4x4()
            for i in range(nu):
                for j in range(nv):
                    p = n * (off + STUD_H / 2) + u * (-lu / 2 + su * (i + 0.5)) + v * (-lv / 2 + sv * (j + 0.5))
                    c = bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=STUD_R, radius2=STUD_R, depth=STUD_H)
                    bmesh.ops.transform(bm, matrix=Matrix.Translation(p) @ rot, verts=c["verts"])
    bmesh.ops.transform(bm, matrix=frame @ T(*center), verts=bm.verts[:])
    obj = m.add(bm, color, name, smooth=False, rough=0.32, coat=0.35, **o)
    if bevel:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        mod.limit_method = "ANGLE"
    return obj


def cat(look, tier=1, name="BlockCat"):
    m = Model(name)
    shape = look.get("shape", "Loaf")
    fur = hexrgb(look.get("fur"), (255, 170, 80))
    second = hexrgb(look.get("second"), (255, 240, 220))
    pat = hexrgb(look.get("patternColor"), shade(fur, 0.78))
    eye = hexrgb(look.get("eyes"), (70, 160, 255))
    pattern = look.get("pattern", "solid")
    # proportions per base shape (leg h, body w / len / h, head w / d / h)
    P = {
        "Loaf": dict(leg=0.9, bw=2.5, bl=3.0, bh=1.9, hw=2.9, hd=2.3, hh=2.5),
        "Slim": dict(leg=1.3, bw=2.0, bl=3.4, bh=1.6, hw=2.5, hd=2.1, hh=2.3),
        "Fluffy": dict(leg=0.8, bw=3.0, bl=3.1, bh=2.2, hw=3.2, hd=2.5, hh=2.7),
    }[shape]
    leg, bw, bl, bh = P["leg"], P["bw"], P["bl"], P["bh"]
    hw, hd, hh = P["hw"], P["hd"], P["hh"]
    bz = leg + bh / 2
    by = 0.35
    # legs and paws
    for x in (-1, 1):
        for y in (-1, 1):
            lc = (x * (bw / 2 - 0.45), by + y * (bl / 2 - 0.5), leg / 2 + 0.05)
            sock = pattern in ("socks", "tuxedo")
            block(m, lc, (0.85, 0.85, leg + 0.1), fur, name="Leg")
            block(m, (lc[0], lc[1] - 0.06, 0.18), (0.95, 1.0, 0.36), second if sock else shade(fur, 0.9), name="Paw", sides="top")
    # body, chest plate, back stripes
    block(m, (0, by, bz), (bw, bl, bh), fur, name="Body")
    block(m, (0, by - bl / 2 - 0.05, bz - 0.15), (bw * 0.62, 0.12, bh * 0.66), second, name="Chest", sides="none")
    if pattern == "tabby":
        for k in (-1, 0, 1):
            block(m, (0, by + k * 0.85, bz + bh / 2 + 0.06), (bw * 0.9, 0.36, 0.14), pat, name="Stripe")
    if pattern == "patches":
        block(m, (bw * 0.18, by + 0.4, bz + bh / 2 + 0.06), (bw * 0.5, 1.2, 0.14), pat, name="Patch")
    if pattern == "spots":
        for sx, sy in ((-0.5, -0.6), (0.6, 0.3), (-0.3, 0.9)):
            block(m, (sx, by + sy, bz + bh / 2 + 0.06), (0.55, 0.55, 0.14), pat, name="Spot", sides="none")
    # layered fur plates on the cheeks / chest (Fluffy) and the back (higher tiers)
    if shape == "Fluffy":
        for k in range(3):
            fr = T(0, by - bl / 2 - 0.2 - k * 0.05, bz - 0.2 - k * 0.35) @ R(-0.35, "X")
            block(m, (0, 0, 0), (bw * (0.8 - k * 0.15), 0.25, 0.7), shade(second, 1 - k * 0.04), frame=fr, name="FurPlate")
    # tail: three blocks curving up
    tail = [((0, by + bl / 2 + 0.35, bz + 0.2), 0.3), ((0, by + bl / 2 + 0.8, bz + 0.85), 0.6), ((0, by + bl / 2 + 0.95, bz + 1.6), 1.1)]
    for i, (c, a) in enumerate(tail):
        col = second if i == 2 and pattern != "solid" else (pat if pattern == "tabby" and i == 1 else fur)
        block(m, c, (0.6, 0.6, 0.85), col, frame=Matrix(), name="Tail")
    # head
    hz = leg + bh + hh / 2 - 0.35
    hy = by - bl / 2 + 0.2
    block(m, (0, hy, hz), (hw, hd, hh), fur, name="Head")
    front = hy - hd / 2
    if pattern == "tabby":
        for x in (-0.45, 0, 0.45):
            block(m, (x, hy - 0.2, hz + hh / 2 + 0.06), (0.26, hd * 0.6, 0.12), pat, name="Stripe", sides="none")
    if pattern == "tuxedo":
        block(m, (0, front - 0.03, hz - hh * 0.28), (hw * 0.45, 0.1, hh * 0.4), second, name="Blaze", sides="none")
    # ears: stepped blocks with a pink inside
    for x in (-1, 1):
        ex = x * (hw / 2 - 0.55)
        block(m, (ex, hy + 0.15, hz + hh / 2 + 0.3), (0.95, 0.55, 0.6), fur, name="Ear")
        block(m, (ex + x * 0.08, hy + 0.15, hz + hh / 2 + 0.78), (0.55, 0.45, 0.45), fur, name="Ear")
        block(m, (ex, hy - 0.16, hz + hh / 2 + 0.38), (0.5, 0.1, 0.42), PINK, name="EarIn", sides="none")
    # face: muzzle block, nose, eyes with shines, mouth
    mz = hz - hh * 0.22
    block(m, (0, front - 0.22, mz), (1.3, 0.45, 0.75), second, name="Muzzle")
    block(m, (0, front - 0.47, mz + 0.22), (0.36, 0.12, 0.2), PINK, name="Nose", sides="none")
    block(m, (0, front - 0.47, mz - 0.12), (0.5, 0.1, 0.07), INK, name="Mouth", sides="none", bevel=0)
    glow = tier >= 4
    for x in (-1, 1):
        ex = x * hw * 0.27
        ez = hz + hh * 0.08
        block(m, (ex, front - 0.06, ez), (0.62, 0.14, 0.78), INK if not glow else shade(eye, 0.6), name="Eye", sides="none", bevel=0.02)
        block(m, (ex, front - 0.13, ez - 0.17), (0.5, 0.08, 0.3), eye, name="Iris", sides="none", bevel=0, emit=1.5 if glow else 0.0)
        block(m, (ex - 0.12, front - 0.15, ez + 0.17), (0.2, 0.06, 0.2), WHITE, name="Shine", sides="none", bevel=0, emit=0.5)
        block(m, (x * hw * 0.42, front - 0.06, mz + 0.05), (0.4, 0.08, 0.18), (255, 175, 195), name="Blush", sides="none", bevel=0)
    # tier extras
    if tier >= 2:  # a collar with a gem
        cz = hz - hh / 2 + 0.12
        block(m, (0, hy, cz), (hw * 0.9, hd + 0.14, 0.32), (225, 55, 80), name="Collar", sides="none")
        block(m, (0, front - 0.2, cz - 0.3), (0.48, 0.36, 0.48), (255, 215, 80), name="Bell", emit=0.3)
    if tier >= 3:  # crystal spikes along the back
        for k in range(4):
            y = by - 0.9 + k * 0.75
            h = 0.9 + 0.35 * math.sin(k * 1.7 + 1)
            m.blob((0.22, 0.22, h / 2), (140, 220, 255), T(0, y, bz + bh / 2 + h / 2 - 0.05) @ R(0.25, "X"), e1=2.0, e2=2.0,
                   nu=4, nv=6, name="Crystal", alpha=0.85, emit=0.8, smooth=False)
    if tier >= 4:  # gold armour plates on the shoulders and a crown
        for x in (-1, 1):
            block(m, (x * (bw / 2 + 0.06), by - 0.6, bz + 0.3), (0.2, 1.2, 1.0), GOLD, name="Armour")
        for k in range(5):
            a = -0.6 + k * 0.3
            block(m, (math.sin(a) * 0.7, hy + 0.1, hz + hh / 2 + 0.3 + (0.25 if k % 2 == 0 else 0.1)), (0.28, 0.28, 0.5 if k % 2 == 0 else 0.3), GOLD, name="Crown", sides="none")
    if tier >= 4:  # glowing sparkle cubes floating round it
        import random
        rnd = random.Random(4)
        for _ in range(9):
            a = rnd.uniform(0, 6.28)
            r = rnd.uniform(2.2, 3.0)
            c = (math.cos(a) * r, by + math.sin(a) * r, rnd.uniform(0.8, 4.5))
            m.blob((0.12, 0.12, 0.12), (255, 240, 150), T(*c) @ R(0.7, "Z") @ R(0.6, "X"), e1=0.2, e2=0.2, nu=8, nv=4, name="Sparkle", emit=4.0)
    if tier >= 5:  # layered wings
        for x in (-1, 1):
            for k in range(4):
                fr = T(x * (bw / 2 + 0.3 + k * 0.35), by + 0.3, bz + bh / 2 + 0.4 + k * 0.15) @ R(x * (0.5 + k * 0.12), "Y")
                block(m, (0, 0, 0), (0.25, 1.6 - k * 0.25, 0.5 + k * 0.35), (255, 245, 210) if k % 2 == 0 else (255, 220, 120),
                      frame=fr, name="Feather", emit=0.25)
    return m
