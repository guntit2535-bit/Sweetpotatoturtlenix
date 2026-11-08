"""Block cats with LEGO studs (revision round 2). The developer approved the design table
(docs/Sweetpotato_Cats.xlsx, art/source/cat_designs.json: 50 unique designs per tier); this builds them.
Every cat is our own design; the client's pictures only gave the direction (chunky blocks, studs on every
face, stacked plates, block faces, glow on rare ones).

  base(m, look) -> A        the plain cat; A = the attach points (head, face, body, tail, paws ...)
  DESIGNS[name](m, A)       what makes a design special (clothes, props, wings, effects)
  build(name) -> kit.Model  one design from the table

Units: studs, front = -Y, up = +Z, feet on z = 0. In the game the same blocks become Roblox Parts with a tiled
studs texture, so a cat costs about as many parts as now.
"""
import math
import random

import bmesh
from mathutils import Matrix, Vector

import kit
from kit import Model, R, T

STUD = 0.42
STUD_R = 0.13
STUD_H = 0.07
INK = (34, 30, 44)
PINK = (255, 150, 182)
WHITE = (255, 255, 255)
GOLD = (255, 196, 46)
GOLD_DARK = (214, 150, 30)


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
            if lu < STUD * 0.8 or lv < STUD * 0.8:
                continue
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
    o.setdefault("rough", 0.32)
    o.setdefault("coat", 0.35)
    obj = m.add(bm, color, name, smooth=False, **o)
    if bevel:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        mod.limit_method = "ANGLE"
    return obj


def flat(m, center, size, color, frame=Matrix(), **o):
    """A plain block with no studs (faces, trims, small parts)."""
    return block(m, center, size, color, frame=frame, sides="none", bevel=0.02, **o)


def gem(m, center, r, color, emit=0.6):
    return m.blob((r, r, r * 1.3), color, T(*center), e1=2.0, e2=2.0, nu=4, nv=6, name="Gem", rough=0.05, coat=1.0,
                  emit=emit, smooth=False)


def sparkles(m, center, radius, n, color, seed=1, size=0.13, emit=4.0, zmin=0.5, zmax=4.5):
    rnd = random.Random(seed)
    for _ in range(n):
        a = rnd.uniform(0, 6.28)
        r = rnd.uniform(radius * 0.8, radius)
        c = (center[0] + math.cos(a) * r, center[1] + math.sin(a) * r, rnd.uniform(zmin, zmax))
        m.blob((size, size, size), color, T(*c) @ R(0.7, "Z") @ R(0.6, "X"), e1=0.2, e2=0.2, nu=8, nv=4, name="Sparkle",
               emit=emit)


# --------------------------------------------------------------------------------------------------
SHAPES = {
    "Loaf": dict(leg=0.9, bw=2.5, bl=3.0, bh=1.9, hw=2.9, hd=2.3, hh=2.5),
    "Slim": dict(leg=1.3, bw=2.0, bl=3.4, bh=1.6, hw=2.5, hd=2.1, hh=2.3),
    "Fluffy": dict(leg=0.8, bw=3.0, bl=3.1, bh=2.2, hw=3.2, hd=2.5, hh=2.7),
}


def base(m, look):
    """The plain cat. Returns its attach points."""
    shape = look.get("shape", "Loaf")
    fur = hexrgb(look.get("fur"), (255, 170, 80))
    second = hexrgb(look.get("second"), (255, 240, 220))
    pat = hexrgb(look.get("patternColor"), shade(fur, 0.78))
    eye = hexrgb(look.get("eyes"), (70, 160, 255))
    pattern = look.get("pattern", "solid")
    P = SHAPES[shape]
    leg, bw, bl, bh = P["leg"], P["bw"], P["bl"], P["bh"]
    hw, hd, hh = P["hw"], P["hd"], P["hh"]
    bz, by = leg + bh / 2, 0.35
    sock = pattern in ("socks", "tuxedo")
    paws = []
    for x in (-1, 1):
        for y in (-1, 1):
            lc = (x * (bw / 2 - 0.45), by + y * (bl / 2 - 0.5), leg / 2 + 0.05)
            block(m, lc, (0.85, 0.85, leg + 0.1), fur, name="Leg")
            block(m, (lc[0], lc[1] - 0.06, 0.18), (0.95, 1.0, 0.36), second if sock else shade(fur, 0.9), name="Paw", sides="top")
            paws.append(Vector(lc))
    block(m, (0, by, bz), (bw, bl, bh), fur, name="Body")
    flat(m, (0, by - bl / 2 - 0.05, bz - 0.15), (bw * 0.62, 0.12, bh * 0.66), second, name="Chest")
    if pattern == "tabby":
        for k in (-1, 0, 1):
            block(m, (0, by + k * 0.85, bz + bh / 2 + 0.06), (bw * 0.9, 0.36, 0.14), pat, name="Stripe")
    tail = [(0, by + bl / 2 + 0.35, bz + 0.2), (0, by + bl / 2 + 0.8, bz + 0.85), (0, by + bl / 2 + 0.95, bz + 1.6)]
    for i, c in enumerate(tail):
        col = second if i == 2 and pattern != "solid" else (pat if pattern == "tabby" and i == 1 else fur)
        block(m, c, (0.6, 0.6, 0.85), col, name="Tail")
    hz = leg + bh + hh / 2 - 0.35
    hy = by - bl / 2 + 0.2
    block(m, (0, hy, hz), (hw, hd, hh), fur, name="Head")
    front = hy - hd / 2
    if pattern == "tabby":
        for x in (-0.45, 0, 0.45):
            flat(m, (x, hy - 0.2, hz + hh / 2 + 0.06), (0.26, hd * 0.6, 0.12), pat, name="Stripe")
        for x in (-1, 1):
            for k in (0, 1):
                flat(m, (x * (hw / 2 + 0.03), hy - 0.3 - k * 0.45, hz - 0.1), (0.08, 0.22, 0.5), pat, name="Cheek")
    ears = []
    for x in (-1, 1):
        ex = x * (hw / 2 - 0.55)
        block(m, (ex, hy + 0.15, hz + hh / 2 + 0.3), (0.95, 0.55, 0.6), fur, name="Ear")
        block(m, (ex + x * 0.08, hy + 0.15, hz + hh / 2 + 0.78), (0.55, 0.45, 0.45), fur, name="Ear")
        flat(m, (ex, hy - 0.16, hz + hh / 2 + 0.38), (0.5, 0.1, 0.42), PINK, name="EarIn")
        ears.append(Vector((ex, hy + 0.15, hz + hh / 2 + 0.3)))
    mz = hz - hh * 0.22
    block(m, (0, front - 0.22, mz), (1.3, 0.45, 0.75), second, name="Muzzle")
    flat(m, (0, front - 0.47, mz + 0.22), (0.36, 0.12, 0.2), PINK, name="Nose")
    flat(m, (0, front - 0.47, mz - 0.12), (0.5, 0.1, 0.07), INK, name="Mouth")
    eyes = []
    for x in (-1, 1):
        ex, ez = x * hw * 0.27, hz + hh * 0.08
        if not look.get("noEyes"):
            flat(m, (ex, front - 0.06, ez), (0.62, 0.14, 0.78), INK, name="Eye")
            flat(m, (ex, front - 0.13, ez - 0.17), (0.5, 0.08, 0.3), eye, name="Iris")
            flat(m, (ex - 0.12, front - 0.15, ez + 0.17), (0.2, 0.06, 0.2), WHITE, name="Shine", emit=0.5)
        flat(m, (x * hw * 0.42, front - 0.06, mz + 0.05), (0.4, 0.08, 0.18), (255, 175, 195), name="Blush")
        eyes.append(Vector((ex, front, ez)))
    return dict(shape=shape, fur=fur, second=second, pat=pat, eye=eye, leg=leg, bw=bw, bl=bl, bh=bh, bz=bz, by=by,
                hw=hw, hd=hd, hh=hh, hz=hz, hy=hy, front=front, mz=mz, eyes=eyes, ears=ears, paws=paws,
                head_top=hz + hh / 2, tail=[Vector(t) for t in tail], back=Vector((0, by, bz + bh / 2)))


# --------------------------------------------------------------------------------------------------
# Designs: one per tier for the first sheet (the rest follow the same way, from the table)

def d_ginger_tabby(m, A):  # Basic: a plain cat
    pass


def d_cool_shades(m, A):  # Rare: sunglasses
    f, ez = A["front"], A["eyes"][0].z
    flat(m, (0, f - 0.2, ez + 0.05), (A["hw"] * 0.95, 0.12, 0.16), INK, name="Frame")
    for e in A["eyes"]:
        flat(m, (e.x, f - 0.24, ez - 0.1), (0.85, 0.12, 0.62), (40, 44, 70), name="Lens", rough=0.05, coat=1.0)
        flat(m, (e.x - 0.18, f - 0.31, ez + 0.02), (0.22, 0.05, 0.12), (190, 225, 255), name="Glint", emit=0.6)
    for x in (-1, 1):
        flat(m, (x * (A["hw"] / 2 + 0.02), A["hy"] - 0.2, ez + 0.05), (0.1, A["hd"] * 0.7, 0.12), INK, name="Arm")


def d_pirate(m, A):  # Epic: tricorn hat, eye patch, striped shirt, wooden cutlass
    top, hy, hw = A["head_top"], A["hy"], A["hw"]
    black, gold, red = (40, 36, 48), GOLD, (220, 50, 60)
    block(m, (0, hy, top + 0.25), (hw * 1.15, A["hd"] * 1.05, 0.3), black, name="HatBrim")
    block(m, (0, hy + 0.05, top + 0.75), (hw * 0.75, A["hd"] * 0.7, 0.75), black, name="HatTop")
    for x, y in ((-1, -1), (1, -1), (0, 1)):
        block(m, (x * hw * 0.5, hy + y * A["hd"] * 0.45, top + 0.55), (0.7, 0.7, 0.4), black, name="HatCorner")
    flat(m, (0, hy - A["hd"] * 0.53, top + 0.3), (hw * 1.1, 0.06, 0.1), gold, name="Trim")
    # a white paw badge on the hat
    flat(m, (0, hy - A["hd"] * 0.36, top + 0.8), (0.42, 0.06, 0.32), WHITE, name="Badge")
    for k in (-1, 0, 1):
        flat(m, (k * 0.17, hy - A["hd"] * 0.37, top + 1.02), (0.11, 0.06, 0.12), WHITE, name="Toe")
    # eye patch over the right eye with a strap
    e = A["eyes"][1]
    flat(m, (e.x, A["front"] - 0.2, e.z), (0.8, 0.12, 0.85), black, name="Patch")
    flat(m, (0, A["front"] - 0.14, e.z + 0.42), (hw * 1.02, 0.08, 0.1), black, name="Strap")
    # red and white striped shirt round the body
    bw, bl, bz, by = A["bw"], A["bl"], A["bz"], A["by"]
    for k in range(4):
        z = bz - A["bh"] / 2 + 0.25 + k * 0.45
        col = red if k % 2 == 0 else WHITE
        flat(m, (0, by, z), (bw + 0.1, bl + 0.1, 0.22), col, name="Shirt")
    # a wooden cutlass held by the front right paw
    p = A["paws"][0]
    blade = T(p.x - 0.75, p.y - 1.0, A["leg"] + 0.3) @ R(0.35, "Y") @ R(-0.5, "X")
    flat(m, (0, 0, 0.2), (0.25, 0.25, 0.5), (130, 80, 40), frame=blade, name="Hilt")
    flat(m, (0, 0, 0.5), (0.7, 0.3, 0.12), gold, frame=blade, name="Guard")
    flat(m, (0, 0, 1.4), (0.2, 0.38, 1.6), (225, 230, 240), frame=blade, name="Blade", rough=0.15)
    # a gold earring
    m.torus(0.16, 0.05, gold, T(A["ears"][0].x - 0.45, A["hy"], A["hz"] + 0.2) @ R(math.pi / 2, "Y"), name="Earring")


def d_strawberry(m, A):  # Legendary: the cat is a strawberry
    top, hy, hw, hd = A["head_top"], A["hy"], A["hw"], A["hd"]
    leaf, leaf2 = (70, 180, 70), (110, 210, 90)
    # seeds on the head and body
    rnd = random.Random(3)
    for _ in range(30):
        if rnd.random() < 0.35:
            side = rnd.choice((-1, 1))
            y, z = rnd.uniform(hy - hd / 2 + 0.3, hy + hd / 2 - 0.3), rnd.uniform(A["hz"] - A["hh"] / 2 + 0.3, top - 0.3)
            flat(m, (side * (hw / 2 + 0.03), y, z), (0.06, 0.16, 0.22), (255, 225, 90), name="Seed")
        else:
            side = rnd.choice((-1, 1))
            y, z = rnd.uniform(A["by"] - A["bl"] / 2 + 0.4, A["by"] + A["bl"] / 2 - 0.3), rnd.uniform(A["bz"] - 0.5, A["bz"] + 0.6)
            flat(m, (side * (A["bw"] / 2 + 0.03), y, z), (0.06, 0.16, 0.22), (255, 225, 90), name="Seed")
    # the leafy crown and the stem
    for k in range(7):
        a = k * 2 * math.pi / 7 + 0.3
        fr = T(math.cos(a) * 0.9, hy + math.sin(a) * 0.8, top + 0.12) @ R(a, "Z") @ R(-0.35, "Y")
        block(m, (0.55, 0, 0), (1.7, 0.7, 0.16), leaf if k % 2 == 0 else leaf2, frame=fr, name="Leaf")
    block(m, (0, hy, top + 0.75), (0.36, 0.36, 1.0), (60, 140, 60), name="Stem")
    block(m, (0.25, hy, top + 1.25), (0.7, 0.3, 0.3), (60, 140, 60), name="Stem")
    # a cream dollop on the back and floating hearts
    block(m, (0, A["by"] + 0.4, A["bz"] + A["bh"] / 2 + 0.2), (1.2, 1.0, 0.35), (255, 245, 235), name="Cream")
    for c in ((1.8, -1.0, 3.9), (-1.9, -0.6, 3.3), (2.1, 0.6, 2.4)):
        for dx in (-0.14, 0.14):
            flat(m, (c[0] + dx, c[1], c[2] + 0.1), (0.24, 0.12, 0.24), (255, 110, 150), name="Heart", emit=1.2)
        flat(m, (c[0], c[1], c[2] - 0.08), (0.28, 0.12, 0.24), (255, 110, 150), name="Heart", emit=1.2)


def d_dragon(m, A):  # Mythical: wings, horns, back spikes, belly plates, a little fire
    gold, horn = GOLD, (250, 240, 210)
    hy, top, hw = A["hy"], A["head_top"], A["hw"]
    for x in (-1, 1):
        for k in range(3):
            block(m, (x * (hw / 2 - 0.35 - k * 0.04), hy + 0.45 + k * 0.42, top + 0.35 + k * 0.42), (0.55 - k * 0.12, 0.6, 0.5), gold, name="Horn")
    # belly plates
    for k in range(4):
        flat(m, (0, A["by"] - A["bl"] / 2 + 0.6 + k * 0.6, A["leg"] + 0.08), (A["bw"] * 0.6, 0.45, 0.14), gold, name="Belly")
    # back spikes and tail spikes
    for k in range(4):
        y = A["by"] - 0.9 + k * 0.7
        s = 0.85 - abs(k - 1.5) * 0.15
        block(m, (0, y, A["bz"] + A["bh"] / 2 + s * 0.6), (0.3, s, s), gold, frame=T(0, y, A["bz"] + A["bh"] / 2 + s * 0.4) @ R(0.785, "X") @ T(0, -y, -(A["bz"] + A["bh"] / 2 + s * 0.4)), name="Spike")
    for t in A["tail"]:
        block(m, (0, t.y + 0.25, t.z + 0.1), (0.2, 0.4, 0.4), gold, frame=T(0, t.y + 0.25, t.z + 0.1) @ R(0.785, "X") @ T(0, -(t.y + 0.25), -(t.z + 0.1)), name="TailSpike")
    # layered wings
    bone, skin = shade(A["fur"], 0.55), (150, 235, 150)
    for x in (-1, 1):
        root = T(x * (A["bw"] / 2 + 0.1), A["by"] + 0.1, A["bz"] + A["bh"] / 2 + 0.2)
        for k in range(4):
            fr = root @ R(-x * (0.35 + k * 0.32), "Y") @ T(x * 1.4, 0, 0)
            block(m, (0, 0, 0), (2.8, 0.2, 0.18), bone, frame=fr, name="WingBone")
            if k < 3:
                fr2 = root @ R(-x * (0.5 + k * 0.32), "Y") @ T(x * 1.3, 0.02, 0)
                block(m, (0, 0, 0), (2.5, 0.12, 0.75), skin, frame=fr2, name="WingSkin", sides="top")
    # its effect (round 2): soft flames floating round the body
    rnd = random.Random(5)
    for k in range(8):
        ang = k * math.pi / 4 + rnd.uniform(-0.2, 0.2)
        r = rnd.uniform(2.1, 2.6)
        c = (math.cos(ang) * r, A["by"] + math.sin(ang) * r, rnd.uniform(0.6, 3.0))
        m.blob((0.18, 0.18, 0.42), (255, 150, 50), T(*c), e1=0.8, e2=1.0, nu=8, nv=6, name="FxFlame", emit=3.0, alpha=0.85)
        m.blob((0.1, 0.1, 0.24), (255, 230, 120), T(c[0], c[1], c[2] - 0.08), e1=0.8, e2=1.0, nu=8, nv=6, name="FxFlame", emit=4.0)
    # a puff of fire from the mouth
    for k, (s, c) in enumerate(((0.32, (255, 210, 80)), (0.24, (255, 140, 40)), (0.18, (255, 90, 40)))):
        m.blob((s, s, s), c, T(0.1 * k, A["front"] - 0.7 - k * 0.35, A["mz"] - 0.05 + k * 0.12) @ R(0.7, "Z") @ R(0.5, "X"),
               e1=0.3, e2=0.3, nu=8, nv=4, name="Fire", emit=3.0)


def d_cat_god(m, A):  # Secret: crown, halo, golden wings, sash, floating gems, light
    hy, top, hw = A["hy"], A["head_top"], A["hw"]
    # crown with gems
    block(m, (0, hy, top + 0.2), (hw * 0.95, A["hd"] * 0.85, 0.32), GOLD, name="Crown")
    for k in range(5):
        x = -hw * 0.38 + k * hw * 0.19
        h = 0.65 if k % 2 == 0 else 0.42
        block(m, (x, hy - A["hd"] * 0.38, top + 0.35 + h / 2), (0.32, 0.22, h), GOLD, name="CrownTip")
    gem(m, (0, hy - A["hd"] * 0.47, top + 0.32), 0.17, (90, 200, 255))
    for x in (-1, 1):
        gem(m, (x * hw * 0.3, hy - A["hd"] * 0.47, top + 0.28), 0.12, (255, 80, 120))
    # halo behind the head
    m.torus(1.15, 0.12, (255, 230, 120), T(0, hy + A["hd"] / 2 + 0.35, top + 0.9) @ R(math.pi / 2, "X"), name="Halo", emit=3.0)
    # a golden sash and a big gem on the chest
    flat(m, (0, A["by"], A["bz"] + 0.1), (A["bw"] + 0.1, 0.5, 0.2), GOLD, frame=T(0, A["by"], A["bz"]) @ R(0.6, "Y") @ T(0, -A["by"], -A["bz"]), name="Sash")
    gem(m, (0, A["by"] - A["bl"] / 2 - 0.15, A["bz"] + 0.2), 0.26, (120, 220, 255), emit=1.5)
    for x in (-1, 1):
        block(m, (x * (A["bw"] / 2 + 0.08), A["by"] - 0.4, A["bz"] + 0.25), (0.22, 1.5, 1.2), GOLD, name="Armour")
    for p in A["paws"]:
        flat(m, (p.x, p.y - 0.06, 0.5), (1.0, 1.05, 0.2), GOLD, name="Anklet")
    m.torus(2.6, 0.12, (255, 225, 110), T(0, A["by"], 0.08), name="Aura", emit=3.0)
    # big layered wings, white and gold
    for x in (-1, 1):
        for k in range(5):
            fr = T(x * (A["bw"] / 2 + 0.3 + k * 0.45), A["by"] + 0.35, A["bz"] + A["bh"] / 2 + 0.4 + k * 0.32) @ R(x * (0.45 + k * 0.13), "Y")
            block(m, (0, 0, 0), (0.24, 2.4 - k * 0.25, 0.8 + k * 0.5), (255, 248, 225) if k % 2 == 0 else GOLD, frame=fr, name="Wing", emit=0.15)
    # glowing eyes, light, floating gems and sparkles
    for e in A["eyes"]:
        flat(m, (e.x, A["front"] - 0.16, e.z - 0.17), (0.5, 0.06, 0.3), (120, 230, 255), name="Glow", emit=3.0)
    for k in range(4):
        a = k * math.pi / 2 + 0.4
        gem(m, (math.cos(a) * 2.8, A["by"] + math.sin(a) * 2.6, 1.6 + (k % 2) * 1.4), 0.2, (255, 215, 90), emit=1.5)
    sparkles(m, (0, A["by"]), 3.2, 12, (255, 245, 170), seed=9)


DESIGNS = {
    "Ginger Tabby": (d_ginger_tabby, dict(shape="Loaf", fur="ffa04a", second="fff0d8", pattern="tabby", patternColor="d9681f", eyes="3c96ff")),
    "Cool Shades": (d_cool_shades, dict(shape="Slim", fur="9aa3b5", second="ffffff", pattern="solid", eyes="3c96ff")),
    "Pirate": (d_pirate, dict(shape="Loaf", fur="ff9a3c", second="fff0d8", pattern="solid", eyes="3c96ff")),
    "Strawberry Cat": (d_strawberry, dict(shape="Loaf", fur="ff4b5c", second="fff3ea", pattern="solid", eyes="3c96ff")),
    "Dragon Cat": (d_dragon, dict(shape="Slim", fur="4fbf5a", second="fff2c4", pattern="solid", eyes="ffb020")),
    "Cat God": (d_cat_god, dict(shape="Fluffy", fur="ffe08a", second="fffaf0", pattern="solid", eyes="5ec4ff")),
}


def build(name):
    fn, look = DESIGNS[name]
    m = Model(name.replace(" ", ""))
    A = base(m, look)
    fn(m, A)
    return m
