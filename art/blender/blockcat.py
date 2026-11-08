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
MARK_T = 0.14  # thickness of a colour patch laid on a face
MARK_O = 0.04  # how far its centre sits outside the face


def patch(m, box, face, uv, size, color, name="Mark", studs=True, lift=0.0):
    """A colour patch on one face of a box (box = (centre, size)). face: top / left / right / front / back;
    uv = where on that face (-0.5 .. 0.5 of its two sides), size = the patch's two sides. Clamped to the face.
    lift: a little extra height, so overlapping patches do not fight."""
    (cx, cy, cz), (sx, sy, sz) = box
    o = MARK_O + lift
    if face == "top":
        lu, lv = sx, sy
    elif face in ("left", "right"):
        lu, lv = sy, sz
    else:
        lu, lv = sx, sz
    su, sv = min(size[0], lu), min(size[1], lv)
    u = max(-(lu - su) / 2, min((lu - su) / 2, uv[0] * lu))
    v = max(-(lv - sv) / 2, min((lv - sv) / 2, uv[1] * lv))
    if face == "top":
        c, s = (cx + u, cy + v, cz + sz / 2 + o), (su, sv, MARK_T)
    elif face in ("left", "right"):
        k = -1 if face == "left" else 1
        c, s = (cx + k * (sx / 2 + o), cy + u, cz + v), (MARK_T, su, sv)
    else:
        k = -1 if face == "front" else 1
        c, s = (cx + u, cy + k * (sy / 2 + o), cz + v), (su, MARK_T, sv)
    if studs:
        return block(m, c, s, color, name=name)
    return flat(m, c, s, color, name=name)


def wrap(m, box, y, length, color, down=0.6, width=None, name="Mark", sides=(-1, 1), top=True):
    """A band across the top of a box at y (a stripe or a patch) that runs down its sides by `down` of the height."""
    (cx, cy, cz), (sx, sy, sz) = box
    u = (y - cy) / sy
    if top:
        patch(m, box, "top", (0, u), (width or sx, length), color, name=name)
    for k in sides:
        patch(m, box, "left" if k < 0 else "right", (u, 0.5 - down / 2), (length, sz * down), color, name=name)


def base(m, look):
    """The plain cat with its breed traits (all from `look`). Returns its attach points.
    look: shape, fur, second, patternColor, third, eyes, eyes2, nose, pattern, ears, tail, eyeStyle, seed, and the
    flags big, kitten, chubby, loafy, shortLegs, cheeks, flatFace, ruff, hairless, curly, cloud, yawn, blush,
    bigNose, pinkPaws, glowEyes."""
    shape = look.get("shape", "Loaf")
    P = dict(SHAPES[shape])
    if look.get("big"):
        P = {k: v * 1.12 for k, v in P.items()}
    if look.get("kitten"):
        P.update(leg=P["leg"] * 0.7, bw=P["bw"] * 0.8, bl=P["bl"] * 0.7, bh=P["bh"] * 0.8, hw=P["hw"] * 1.04,
                 hd=P["hd"] * 1.02, hh=P["hh"] * 1.04)
    if look.get("chubby"):
        P.update(bw=P["bw"] + 0.8, bh=P["bh"] + 0.45, bl=P["bl"] + 0.2, leg=P["leg"] * 0.75)
    if look.get("loafy"):
        P.update(leg=0.42, bw=P["bw"] + 0.35, bh=P["bh"] + 0.25)
    if look.get("shortLegs"):
        P.update(leg=0.45, bl=P["bl"] + 0.9)
    fur = hexrgb(look.get("fur"), (255, 170, 80))
    second = hexrgb(look.get("second"), (255, 240, 220))
    pat = hexrgb(look.get("patternColor"), shade(fur, 0.78))
    third = hexrgb(look.get("third"), (58, 52, 64))
    eye = hexrgb(look.get("eyes"), (70, 160, 255))
    eye2 = hexrgb(look.get("eyes2"), eye)
    nose = hexrgb(look.get("nose"), PINK)
    pattern = look.get("pattern", "solid")
    rnd = random.Random(look.get("seed", 7))
    leg, bw, bl, bh = P["leg"], P["bw"], P["bl"], P["bh"]
    hw, hd, hh = P["hw"], P["hd"], P["hh"]
    bz, by = leg + bh / 2, 0.35
    top_z = leg + bh

    # colours of each part, set by the pattern
    sock = {"socks": second, "tuxedo": second, "blackpaws": pat, "mitted": second}.get(pattern)
    sock_legs = [0, 1, 2, 3]
    if pattern == "mittens":
        sock, sock_legs = second, [0, 2]
    leg_c = pat if pattern in ("points", "mitted") else fur
    ear_c = [fur, fur]
    tail_c = fur
    muzzle_c = second
    if pattern in ("points", "mitted"):
        ear_c, tail_c, muzzle_c = [pat, pat], pat, pat
    elif pattern == "calico":
        ear_c = [pat, third]
    elif pattern == "masked":
        ear_c = [pat, pat]

    # legs and paws (order: (-x, front), (-x, back), (+x, front), (+x, back))
    paws = []
    for x in (-1, 1):
        for y in (-1, 1):
            i = len(paws)
            lc = (x * (bw / 2 - 0.45), by + y * (bl / 2 - 0.5), leg / 2 + 0.05)
            block(m, lc, (0.85, 0.85, leg + 0.1), leg_c, name="Leg")
            paw_c = shade(leg_c, 0.9)
            if sock and i in sock_legs:
                h = max(0.36, leg * 0.6)
                block(m, (lc[0], lc[1] - 0.02, h / 2 + 0.02), (1.03, 1.04, h), sock, name="Sock")
                paw_c = sock
            if look.get("pinkPaws"):
                paw_c = (255, 160, 190)
            block(m, (lc[0], lc[1] - 0.06, 0.18), (1.05, 1.08, 0.36), paw_c, name="Paw", sides="top")
            paws.append(Vector(lc))

    # body: one block, or layers from the bottom up
    layers = [(1.0, fur)]
    if pattern == "tuxedo":
        layers = [(0.42, second), (0.58, fur)]
    elif pattern in ("bicolor", "mitted"):
        layers = [(0.45, second), (0.55, fur)]
    elif pattern == "smoke":
        layers = [(0.34, shade(fur, 1.55)), (0.33, shade(fur, 1.25)), (0.33, fur)]
    elif look.get("loafy"):
        layers = [(0.72, fur), (0.28, pat)]
    z0 = leg
    for k, (f, col) in enumerate(layers):
        block(m, (0, by, z0 + bh * f / 2), (bw, bl, bh * f + (0.002 if k else 0)), col, name="Body")
        z0 += bh * f
    BODY = ((0, by, bz), (bw, bl, bh))
    chest, chest_z = (bw * 0.62, 0.12, bh * 0.66), bz - 0.15
    if pattern == "bib":
        chest, chest_z = (bw * 0.8, 0.12, bh * 0.85), bz - bh * 0.075 + 0.05
    flat(m, (0, by - bl / 2 - 0.05, chest_z), chest, second, name="Chest")
    if look.get("chubby"):
        block(m, (0, by - 0.1, leg - 0.02), (bw * 0.72, bl * 0.62, 0.42), second, name="Belly")

    # body patterns
    if pattern == "tabby":
        for k in (-1, 0, 1):
            block(m, (0, by + k * 0.85, bz + bh / 2 + 0.06), (bw * 0.9, 0.36, 0.14), pat, name="Stripe")
    elif pattern == "mackerel":
        n = 6
        for k in range(n):
            y = by - bl / 2 + 0.45 + k * (bl - 0.7) / (n - 1)
            wrap(m, BODY, y, 0.22, pat, down=0.7, name="Stripe")
        patch(m, BODY, "top", (0, 0), (0.3, bl - 0.3), pat, name="Stripe")
    elif pattern == "tiger":
        for k in range(4):
            y = by - bl / 2 + 0.55 + k * (bl - 0.9) / 3
            wrap(m, BODY, y, 0.42, pat, down=0.55, name="Stripe")
            for s in ("left", "right"):
                patch(m, BODY, s, ((y - by) / bl + 0.06, -0.18), (0.3, bh * 0.35), pat, name="Stripe")
    elif pattern == "classic":
        for k in (-1, 0, 1):
            patch(m, BODY, "top", (k * 0.3, 0), (0.32, bl * 0.85), pat, name="Stripe")
        for s in ("left", "right"):
            # the bullseye swirl on each side
            for u, v, w, h in ((0.12, 0.25, 1.3, 0.24), (0.12, -0.22, 1.3, 0.24), (-0.12, 0.02, 0.24, 0.9), (0.36, 0.02, 0.24, 0.9)):
                patch(m, BODY, s, (u, v), (w, h), pat, name="Stripe", studs=False)
            patch(m, BODY, s, (0.12, 0.02), (0.36, 0.3), pat, name="Stripe", studs=False)
    elif pattern == "calico":
        wrap(m, BODY, by - bl * 0.18, 1.2, pat, down=0.75, width=bw * 0.55, sides=(-1,), top=False)
        patch(m, BODY, "top", (-0.22, -0.18), (bw * 0.55, 1.2), pat)
        wrap(m, BODY, by + bl * 0.25, 1.1, third, down=0.7, sides=(1,), top=False)
        patch(m, BODY, "top", (0.22, 0.25), (bw * 0.55, 1.1), third)
        patch(m, BODY, "top", (-0.2, 0.42), (0.9, 0.6), third)
    elif pattern == "tortie":
        for k in range(16):
            face = rnd.choice(("top", "top", "left", "right"))
            patch(m, BODY, face, (rnd.uniform(-0.45, 0.45), rnd.uniform(-0.45, 0.45)),
                  (rnd.uniform(0.45, 0.9), rnd.uniform(0.45, 0.9)), pat if rnd.random() < 0.7 else shade(pat, 1.2), lift=k * 0.012)
    elif pattern in ("spots", "rosettes", "leopard"):
        n = {"spots": 10, "rosettes": 12, "leopard": 22}[pattern]
        sz = {"spots": 0.75, "rosettes": 0.62, "leopard": 0.34}[pattern]
        cells = [(f, i, j) for f in ("top", "left", "right") for i in range(4) for j in range(3)]
        rnd.shuffle(cells)
        for f, i, j in cells[:n]:
            uv = (-0.38 + i * 0.25 + rnd.uniform(-0.05, 0.05), -0.32 + j * 0.32 + rnd.uniform(-0.05, 0.05))
            o = patch(m, BODY, f, uv, (sz, sz), pat, studs=pattern == "spots")
            if pattern == "rosettes":
                cx, cy, cz = [sum(v.co[a] for v in o.data.vertices) / len(o.data.vertices) for a in range(3)]
                out = {"top": (0, 0, 0.05), "left": (-0.05, 0, 0), "right": (0.05, 0, 0)}[f]
                s2 = {"top": (0.3, 0.3, 0.06), "left": (0.06, 0.3, 0.3), "right": (0.06, 0.3, 0.3)}[f]
                flat(m, (cx + out[0], cy + out[1], cz + out[2]), s2, tuple((a + b) // 2 for a, b in zip(fur, pat)), name="Mark")
    elif pattern == "patch":
        wrap(m, BODY, by + bl * 0.08, bl * 0.5, pat, down=0.55, width=bw)
    elif pattern == "ribs":
        for s in ("left", "right"):
            for u in (-0.3, -0.1, 0.1, 0.3):
                patch(m, BODY, s, (u, 0), (0.16, bh * 0.85), pat, studs=False, name="Rib")
        for u in (-0.2, 0.2):
            patch(m, BODY, "top", (u, 0), (0.16, bl * 0.9), pat, studs=False, name="Rib")
    elif pattern == "dorsal":
        patch(m, BODY, "top", (0, 0), (0.7, bl * 0.95), pat, name="Stripe")
    if look.get("hairless"):
        for s in ("left", "right"):
            for v in (0.1, -0.12):
                patch(m, BODY, s, (-0.15, v), (bl * 0.4, 0.07), shade(fur, 0.82), studs=False, name="Wrinkle")
    curl_c = hexrgb(look.get("patternColor"), shade(fur, 0.9))
    if look.get("curly"):
        for i in range(4):
            for j in range(3):
                patch(m, BODY, "top", (-0.36 + i * 0.24 + (j % 2) * 0.1, -0.33 + j * 0.33), (0.42, 0.42), curl_c, name="Curl")
        for s in ("left", "right"):
            for i in range(4):
                patch(m, BODY, s, (-0.36 + i * 0.24, 0.2 - (i % 2) * 0.3), (0.42, 0.42), curl_c, name="Curl")
    if look.get("cloud"):
        puff = hexrgb(look.get("patternColor"), (225, 232, 245))
        for x, y, z, s in ((-1, -0.25, 0.35, 1.1), (1, 0.15, 0.3, 1.2), (-1, 0.35, -0.1, 0.9), (1, -0.35, -0.15, 0.85)):
            block(m, (x * (bw / 2 + 0.1), by + y * bl, bz + z * bh), (s * 0.7, s, s * 0.85), puff if s < 1 else WHITE, name="Puff")
        block(m, (0.3, by + 0.3, top_z + 0.25), (1.3, 1.2, 0.6), WHITE, name="Puff")
        block(m, (-0.4, by + 0.9, top_z + 0.15), (0.9, 0.8, 0.45), puff, name="Puff")
    if look.get("ruff"):
        block(m, (0, by - bl / 2 - 0.25, top_z - 0.55), (bw * 0.85, 0.6, 1.0), second, name="Ruff")
        block(m, (0, by - bl / 2 - 0.4, top_z - 1.2), (bw * 0.55, 0.45, 0.7), second, name="Ruff")

    # tail
    style = look.get("tail", "normal")
    t0 = by + bl / 2
    if style == "long":
        tail = [(0, t0 + 0.35, bz + 0.2), (0, t0 + 0.85, bz + 0.75), (0, t0 + 1.2, bz + 1.45), (0, t0 + 1.35, bz + 2.2),
                (0, t0 + 1.15, bz + 2.85)]
        sizes = [(0.55, 0.55, 0.85)] * 4 + [(0.55, 0.95, 0.55)]
    elif style == "bob":
        tail = [(0, t0 + 0.4, bz + 0.45), (0, t0 + 0.4, bz + 0.45)]
        sizes = [(1.0, 0.8, 0.9), None]
    elif style == "fluffy":
        tail = [(0, t0 + 0.45, bz + 0.25), (0, t0 + 0.9, bz + 0.95), (0, t0 + 1.05, bz + 1.8)]
        sizes = [(0.85, 0.85, 0.95), (1.0, 1.0, 1.0), (1.05, 1.05, 1.0)]
    elif style == "thin":
        tail = [(0, t0 + 0.3, bz + 0.2), (0, t0 + 0.75, bz + 0.85), (0, t0 + 0.95, bz + 1.6)]
        sizes = [(0.38, 0.38, 0.85)] * 3
    else:
        tail = [(0, t0 + 0.35, bz + 0.2), (0, t0 + 0.8, bz + 0.85), (0, t0 + 0.95, bz + 1.6)]
        sizes = [(0.6, 0.6, 0.85)] * 3
    for i, (c, s) in enumerate(zip(tail, sizes)):
        if not s:
            continue
        last = i == len(tail) - 1
        col = tail_c
        if last and pattern in ("tabby", "socks", "tuxedo", "calico", "bicolor", "mitted", "patch", "mittens"):
            col = second
        if last and pattern in ("blackpaws", "masked", "tips", "spots"):
            col = pat
        if last and pattern == "smoke":
            col = shade(fur, 1.25)
        if pattern == "tabby" and i == 1:
            col = pat
        if pattern in ("mackerel", "tiger", "classic", "leopard", "rosettes") and i % 2 == 1:
            col = pat
        block(m, c, s, col, name="Tail")

    # head
    hz = top_z + hh / 2 - 0.35
    hy = by - bl / 2 + 0.2
    block(m, (0, hy, hz), (hw, hd, hh), fur, name="Head")
    HEAD = ((0, hy, hz), (hw, hd, hh))
    front = hy - hd / 2
    if pattern in ("tabby", "mackerel", "tiger", "classic"):
        w = 0.4 if pattern == "tiger" else 0.26
        for x in (-0.45, 0, 0.45):
            flat(m, (x * (1.15 if pattern == "tiger" else 1), hy - 0.2, hz + hh / 2 + 0.06), (w, hd * 0.6, 0.12), pat, name="HeadStripe")
        for x in (-1, 1):
            for k in (0, 1):
                flat(m, (x * (hw / 2 + 0.03), hy - 0.3 - k * 0.45, hz - 0.1), (0.08, 0.22 if pattern != "tiger" else 0.3, 0.5), pat, name="Cheek")
        if pattern in ("tiger", "mackerel"):
            for x in (-0.3, 0, 0.3):
                flat(m, (x, front - 0.03, hz + hh * 0.36), (0.16, 0.08, 0.42 if x == 0 else 0.3), pat, name="HeadStripe")
    elif pattern in ("points", "mitted"):
        flat(m, (0, front - 0.03, hz - hh * 0.08), (hw * 0.66, 0.08, hh * 0.66), pat, name="Mask")
    elif pattern == "masked":
        flat(m, (0, front - 0.03, hz + hh * 0.08), (hw * 0.96, 0.08, 1.05), pat, name="Mask")
    elif pattern == "calico":
        patch(m, HEAD, "top", (-0.25, 0), (hw * 0.5, hd), pat, name="HeadMark")
        patch(m, HEAD, "left", (0, 0.2), (hd, hh * 0.6), pat, name="HeadMark")
        flat(m, (-hw * 0.3, front - 0.03, hz + hh * 0.22), (hw * 0.38, 0.08, hh * 0.5), pat, name="HeadMark")
    elif pattern == "tortie":
        for k, face in enumerate(("top", "right")):
            patch(m, HEAD, face, (rnd.uniform(-0.3, 0.3), rnd.uniform(0.0, 0.3)), (0.9, 0.7), pat, name="HeadMark", lift=k * 0.012)
        flat(m, (hw * 0.25, front - 0.03, hz + hh * 0.3), (0.7, 0.08, 0.5), pat, name="HeadMark")
    elif pattern in ("spots", "leopard", "rosettes"):
        for u, v in ((-0.3, -0.2), (0.25, 0.25)):
            patch(m, HEAD, "top", (u, v), (0.45, 0.45) if pattern == "spots" else (0.3, 0.3), pat, name="HeadMark", studs=False)
        if pattern == "spots":
            flat(m, (hw * 0.3, front - 0.03, hz + hh * 0.3), (0.6, 0.08, 0.55), pat, name="HeadMark")
    elif pattern == "patch":
        flat(m, (hw * 0.27, front - 0.03, hz + hh * 0.12), (hw * 0.42, 0.08, hh * 0.55), pat, name="HeadMark")
        patch(m, HEAD, "top", (0.25, 0), (hw * 0.45, hd), pat, name="HeadMark")
    elif pattern == "bicolor":
        flat(m, (0, front - 0.03, hz - hh * 0.2), (hw * 0.6, 0.08, hh * 0.5), second, name="HeadMark")
        flat(m, (0, front - 0.03, hz + hh * 0.18), (0.4, 0.08, hh * 0.5), second, name="HeadMark")
    elif pattern == "tuxedo":
        flat(m, (0, front - 0.03, hz - hh * 0.25), (hw * 0.5, 0.08, hh * 0.4), second, name="HeadMark")
    elif pattern == "dorsal":
        patch(m, HEAD, "top", (0, 0.1), (0.6, hd * 0.8), pat, name="HeadStripe")
    elif pattern == "smoke":
        patch(m, HEAD, "top", (0, 0), (hw, hd), shade(fur, 0.8), name="HeadMark")
    if look.get("hairless"):
        for k in range(3):
            flat(m, (0, front - 0.03, hz + hh * 0.3 + k * 0.17), (0.9 - k * 0.15, 0.07, 0.06), shade(fur, 0.82), name="HeadWrinkle")
    if look.get("curly"):
        for x in (-0.25, 0.25):
            patch(m, HEAD, "top", (x, 0.1), (0.5, 0.5), curl_c, name="HeadCurl")
    if look.get("cheeks"):
        for x in (-1, 1):
            block(m, (x * (hw / 2 + 0.18), hy - 0.15, hz - hh * 0.22), (0.55, hd * 0.65, hh * 0.42),
                  second if pattern in ("bicolor", "tuxedo") else fur, name="Fluff")

    # ears
    ears = []
    ear = look.get("ears", "normal")
    for i, x in enumerate((-1, 1)):
        ec = ear_c[i]
        if ear == "fold":
            ex = x * (hw / 2 - 0.6)
            fr = T(ex, hy - 0.05, hz + hh / 2 + 0.12) @ R(0.55, "X")
            block(m, (0, -0.15, 0), (1.0, 0.85, 0.32), ec, frame=fr, name="Ear")
            ears.append(Vector((ex, hy, hz + hh / 2 + 0.2)))
            continue
        k = {"big": 1.25, "small": 0.72}.get(ear, 1.0)
        ex = x * (hw / 2 - 0.55 * min(k, 1.0))
        z1 = hz + hh / 2 + 0.3 * k
        block(m, (ex, hy + 0.15, z1), (0.95 * k, 0.55, 0.6 * k), ec, name="Ear")
        z2 = z1 + 0.48 * k
        block(m, (ex + x * 0.08 * k, hy + 0.15, z2), (0.55 * k, 0.45, 0.45 * k), pat if pattern == "tips" else ec, name="Ear")
        flat(m, (ex, hy - 0.16, z1 + 0.08 * k), (0.5 * k, 0.1, 0.42 * k), PINK, name="EarIn")
        if ear == "tufts":
            block(m, (ex + x * 0.14, hy + 0.15, z2 + 0.45), (0.22, 0.22, 0.55), shade(pat, 0.75), name="Ear")
        ears.append(Vector((ex, hy + 0.15, z1)))

    # face
    mz = hz - hh * 0.22
    if look.get("flatFace"):
        block(m, (0, front - 0.1, mz), (1.15, 0.2, 0.6), muzzle_c, name="Muzzle", sides="none")
        nf = front - 0.24
    else:
        block(m, (0, front - 0.22, mz), (1.3, 0.45, 0.75), muzzle_c, name="Muzzle")
        nf = front - 0.47
    big_nose = look.get("bigNose")
    flat(m, (0, nf, mz + 0.22), (0.5 if big_nose else 0.36, 0.12, 0.28 if big_nose else 0.2), nose, name="Nose")
    if look.get("yawn"):
        flat(m, (0, nf, mz - 0.14), (0.5, 0.1, 0.36), (90, 30, 50), name="Mouth")
        flat(m, (0, nf - 0.02, mz - 0.24), (0.34, 0.08, 0.14), (255, 130, 150), name="Mouth")
    else:
        flat(m, (0, nf, mz - 0.12), (0.5, 0.1, 0.07), INK, name="Mouth")
    estyle = look.get("eyeStyle", "normal")
    eyes = []
    for i, x in enumerate((-1, 1)):
        ex, ez = x * hw * 0.27, hz + hh * 0.08
        iris = eye if i == 0 else eye2
        if estyle == "sleepy":
            flat(m, (ex, front - 0.06, ez - 0.12), (0.62, 0.14, 0.4), INK, name="Eye")
            flat(m, (ex, front - 0.13, ez - 0.2), (0.5, 0.08, 0.18), iris, name="Iris")
            flat(m, (ex, front - 0.09, ez + 0.1), (0.7, 0.14, 0.12), shade(fur, 0.8), name="Lid")
        elif estyle == "big":
            flat(m, (ex, front - 0.06, ez), (0.76, 0.14, 0.95), INK, name="Eye")
            flat(m, (ex, front - 0.13, ez - 0.17), (0.62, 0.08, 0.42), iris, name="Iris", emit=0.35 if look.get("glowEyes") else 0.0)
            flat(m, (ex - 0.15, front - 0.15, ez + 0.2), (0.26, 0.06, 0.26), WHITE, name="Shine", emit=0.5)
            flat(m, (ex + 0.17, front - 0.15, ez - 0.28), (0.12, 0.06, 0.12), WHITE, name="Shine", emit=0.5)
        else:
            flat(m, (ex, front - 0.06, ez), (0.62, 0.14, 0.78), INK, name="Eye")
            flat(m, (ex, front - 0.13, ez - 0.17), (0.5, 0.08, 0.3), iris, name="Iris")
            flat(m, (ex - 0.12, front - 0.15, ez + 0.17), (0.2, 0.06, 0.2), WHITE, name="Shine", emit=0.5)
        if look.get("blush"):
            flat(m, (x * hw * 0.42, front - 0.06, mz + 0.05), (0.56, 0.08, 0.28), (255, 130, 160), name="Blush")
        else:
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



# --------------------------------------------------------------------------------------------------
# Basic tier (round 2): plain cats with no clothes. Each design is its own breed, colours, pattern and shape.
def d_plain(m, A):  # Basic: nothing on top of the cat itself
    pass


BASIC_LOOKS = {
    "Ginger Tabby": dict(shape="Loaf", fur="ffa04a", second="fff0d8", pattern="tabby", patternColor="d9681f", eyes="3c96ff"),
    "Tuxedo": dict(shape="Slim", fur="2e2a36", second="ffffff", pattern="tuxedo", eyes="7ed957", nose="ff9ab8"),
    "Calico": dict(shape="Loaf", fur="ffffff", second="ffffff", pattern="calico", patternColor="ff9a3c", third="3a3440", eyes="ffb020"),
    "Snowball": dict(shape="Fluffy", fur="ffffff", second="f2f5ff", eyes="3c96ff", cheeks=True, ruff=True, tail="fluffy"),
    "Midnight": dict(shape="Slim", fur="2b2733", second="3d3846", eyes="ffd23c", eyeStyle="big", glowEyes=True, ears="big", nose="5a4c60"),
    "Grey Tabby": dict(shape="Loaf", fur="aab0bc", second="f2f3f6", pattern="tabby", patternColor="6a7080", eyes="7ed957", seed=2),
    "Cream Puff": dict(shape="Fluffy", fur="ffe6bc", second="fffaf0", eyes="5ab0ff", cheeks=True, tail="fluffy", blush=True, ears="small"),
    "Tortie": dict(shape="Loaf", fur="3a3440", second="ffb070", pattern="tortie", patternColor="ff8a2a", eyes="ffd23c", seed=4),
    "Siamese": dict(shape="Slim", fur="fff0d8", second="fff0d8", pattern="points", patternColor="5a3a2a", eyes="3ca0ff", ears="big"),
    "Russian Blue": dict(shape="Slim", fur="8797b2", second="a3b0c6", eyes="52d273", ears="big", nose="8a90a8", tail="thin"),
    "Bengal": dict(shape="Slim", fur="f0a640", second="fff0d0", pattern="rosettes", patternColor="5a3a20", eyes="7ed957", seed=3),
    "Persian": dict(shape="Fluffy", fur="fff3e2", second="ffffff", flatFace=True, ears="small", cheeks=True, tail="fluffy",
                    eyes="ff9a2a", eyeStyle="big"),
    "Maine Coon": dict(shape="Fluffy", big=True, fur="a8784a", second="f0e0c8", pattern="tabby", patternColor="6a4628", ears="tufts",
                       ruff=True, tail="fluffy", eyes="ffc040"),
    "Sphynx": dict(shape="Slim", fur="f6c4be", second="f6c4be", hairless=True, ears="big", tail="thin", eyes="70d6a0", eyeStyle="big"),
    "Scottish Fold": dict(shape="Loaf", fur="b9b4ae", second="f0ece6", ears="fold", eyeStyle="big", eyes="ffb020", cheeks=True),
    "Ragdoll": dict(shape="Fluffy", fur="fbf6ee", second="ffffff", pattern="mitted", patternColor="8a6248", eyes="3ca0ff", tail="fluffy",
                    ruff=True),
    "Munchkin": dict(shape="Loaf", shortLegs=True, fur="ffb066", second="ffffff", pattern="bicolor", eyes="3c96ff"),
    "British Shorthair": dict(shape="Loaf", fur="8c95a8", second="a4adbd", cheeks=True, ears="small", eyes="ff9a20", eyeStyle="big",
                              nose="7a8296"),
    "Sock Cat": dict(shape="Loaf", fur="9a6a44", second="fff4e8", pattern="socks", eyes="7ed957"),
    "Spotty": dict(shape="Slim", fur="ffffff", second="ffffff", pattern="spots", patternColor="2f2a36", eyes="3c96ff", seed=5),
    "Orange Loaf": dict(shape="Loaf", loafy=True, fur="ff9a3c", second="fff0d8", patternColor="cc6a1e", eyes="52d273"),
    "Smoky": dict(shape="Fluffy", fur="545866", second="c8ccd6", pattern="smoke", eyes="ffb020", tail="fluffy"),
    "Chocolate": dict(shape="Slim", fur="6a4030", second="8a5a44", eyes="ffd23c", nose="9a5a48"),
    "Lilac": dict(shape="Slim", fur="c4aecb", second="e6daea", eyes="ffb050", nose="dc9ab8", ears="big"),
    "Cinnamon": dict(shape="Loaf", fur="c0663a", second="ffe8cc", pattern="bib", eyes="ffb020"),
    "Mackerel": dict(shape="Slim", fur="a4a8b2", second="e8eaee", pattern="mackerel", patternColor="34353e", eyes="7ed957"),
    "Masked": dict(shape="Loaf", fur="ffffff", second="ffffff", pattern="masked", patternColor="3a3542", eyes="ffd23c"),
    "Patchy": dict(shape="Loaf", fur="ffffff", second="ffffff", pattern="patch", patternColor="8e94a2", eyes="3c96ff"),
    "Ginger Fluff": dict(shape="Fluffy", fur="ff9440", second="fff0d8", tail="fluffy", ruff=True, eyes="52d273", cheeks=True),
    "Black Paws": dict(shape="Slim", fur="ffffff", second="ffffff", pattern="blackpaws", patternColor="2f2a36", eyes="3c96ff"),
    "Golden Eyes": dict(shape="Loaf", fur="d6b48a", second="f6e8d4", eyeStyle="big", glowEyes=True, eyes="ffc21e"),
    "Odd Eyes": dict(shape="Fluffy", fur="ffffff", second="ffffff", eyeStyle="big", eyes="3c96ff", eyes2="ffd23c", ears="big"),
    "Sleepy": dict(shape="Loaf", fur="ffc890", second="fff4e8", eyeStyle="sleepy", yawn=True, eyes="9a6a3a"),
    "Chubby": dict(shape="Fluffy", chubby=True, fur="d8cfc0", second="fffaf2", eyes="52d273", cheeks=True, ears="small"),
    "Kitten": dict(shape="Loaf", kitten=True, fur="ffb066", second="ffffff", pattern="bib", eyeStyle="big", eyes="3c96ff", blush=True),
    "Long Tail": dict(shape="Slim", fur="c8ccd4", second="f0f2f6", tail="long", eyes="3cb0ff"),
    "Bobtail": dict(shape="Loaf", fur="ffffff", second="ffffff", pattern="patch", patternColor="ff9a3c", tail="bob", eyes="52d273"),
    "Curly Rex": dict(shape="Slim", fur="f2e0bc", second="fff6e6", curly=True, patternColor="dcc08c", ears="big", eyes="7ed957"),
    "Leopard Spot": dict(shape="Slim", fur="f2c040", second="fff2cc", pattern="leopard", patternColor="2f2a26", eyes="52d273", seed=6),
    "Silver Tabby": dict(shape="Loaf", fur="d4d8de", second="ffffff", pattern="classic", patternColor="2f3038", eyes="52d273"),
    "Peach": dict(shape="Loaf", fur="ffb894", second="fff0e8", blush=True, eyes="3c96ff", nose="ff7a9a"),
    "Coal": dict(shape="Slim", fur="25222b", second="34303b", eyes="7ed957", nose="ff8fb0", bigNose=True, pinkPaws=True),
    "Milk Tea": dict(shape="Fluffy", fur="c8a07a", second="ffffff", pattern="bib", tail="fluffy", eyes="3c96ff"),
    "Biscuit": dict(shape="Loaf", fur="d89a4a", second="fff0d0", pattern="bicolor", eyes="52d273"),
    "Mitten": dict(shape="Loaf", fur="9aa0ac", second="ffffff", pattern="mittens", eyes="ffd23c"),
    "Tiger Stripe": dict(shape="Slim", fur="ff8a2a", second="fff0d8", pattern="tiger", patternColor="2a2228", eyes="52d273"),
    "Pumpkin": dict(shape="Loaf", fur="e8661a", second="ffd8a8", pattern="ribs", patternColor="c04e10", eyes="52d273"),
    "Cloud": dict(shape="Fluffy", fur="dfe7f2", second="ffffff", cloud=True, patternColor="f4f7fc", eyes="5ab0ff", tail="fluffy"),
    "Shadow": dict(shape="Slim", fur="4a4652", second="5e5a66", pattern="dorsal", patternColor="2a2730", eyes="8ad8ff", eyeStyle="big"),
    "Honey": dict(shape="Loaf", fur="ffbf3a", second="fff0c0", pattern="tips", patternColor="d98a10", eyes="d98a10"),
}
for _name, _look in BASIC_LOOKS.items():
    DESIGNS.setdefault(_name, (d_plain, _look))


def build(name):
    fn, look = DESIGNS[name]
    m = Model(name.replace(" ", ""))
    A = base(m, look)
    fn(m, A)
    return m
