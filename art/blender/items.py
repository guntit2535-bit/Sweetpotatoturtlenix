"""Item models for Sweetpotatoturtlenix (task R5), built from the developer's GPT reference sheets in
art/source/gpt_models (M01-M20). Smooth glossy toy shapes from kit.py (no studs). 1 unit = 1 stud,
front = -Y, up = +Z.

Families x steps: every 25-level item is 5 families (looks) x 5 steps (more trim each step, a little bigger):
  level L -> family = (L - 1) // 5 + 1, step = (L - 1) % 5 + 1
Builders: treadmill(level), weights(level) (rack + pair), dumbbell(level) (one, held in a hand),
rod(level), bat(), crate(key), each returning a kit.Model.
"""
import math

from mathutils import Matrix, Vector

import kit
from kit import Model, R, T

PI = math.pi

# palettes per family: frame, accent, dark, glow (emissive), gem
TREAD = [
    dict(name="basic", frame=(236, 238, 244), accent=(126, 214, 60), dark=(70, 72, 82), glow=(126, 230, 70), gem=(126, 230, 70)),
    dict(name="sport", frame=(240, 242, 248), accent=(40, 120, 230), dark=(70, 72, 82), glow=(255, 150, 40), gem=(70, 200, 255)),
    dict(name="neon", frame=(70, 68, 104), accent=(40, 220, 240), dark=(52, 54, 70), glow=(255, 80, 220), gem=(40, 220, 240)),
    dict(name="gold", frame=(250, 196, 40), accent=(214, 40, 50), dark=(60, 56, 60), glow=(255, 220, 90), gem=(240, 50, 80)),
    dict(name="cosmic", frame=(120, 70, 200), accent=(255, 205, 60), dark=(48, 30, 100), glow=(255, 110, 230), gem=(255, 210, 70)),
]
WEIGHTS = [
    dict(name="rubber", plate=(232, 46, 52), rack=(246, 176, 56), bar=(110, 112, 124), glow=None, alpha=1.0),
    dict(name="chrome", plate=(200, 206, 218), rack=(196, 202, 214), bar=(40, 110, 230), glow=(80, 190, 255), alpha=1.0),
    dict(name="gold", plate=(250, 196, 40), rack=(170, 30, 40), bar=(190, 30, 40), glow=(255, 220, 90), alpha=1.0),
    dict(name="crystal", plate=(150, 220, 255), rack=(214, 230, 245), bar=(210, 220, 240), glow=(120, 220, 255), alpha=0.75),
    dict(name="cosmic", plate=(90, 50, 170), rack=(130, 110, 170), bar=(255, 100, 220), glow=(255, 110, 230), alpha=1.0),
]
RODS = [
    dict(name="wood", pole=(180, 110, 50), grip=(130, 80, 40), trim=(110, 66, 30), reel=(240, 196, 70), glow=None),
    dict(name="iron", pole=(140, 146, 160), grip=(40, 90, 200), trim=(50, 110, 220), reel=(196, 200, 212), glow=(80, 190, 255)),
    dict(name="gold", pole=(250, 196, 40), grip=(200, 40, 50), trim=(214, 40, 50), reel=(250, 196, 40), glow=(255, 220, 90)),
    dict(name="crystal", pole=(150, 220, 255), grip=(236, 238, 248), trim=(214, 222, 240), reel=(170, 230, 255), glow=(120, 220, 255)),
    dict(name="cosmic", pole=(70, 40, 150), grip=(150, 90, 220), trim=(250, 200, 60), reel=(120, 70, 200), glow=(255, 110, 230)),
]
CRATES = {
    "Paper": dict(body=(214, 170, 110), lid=(226, 186, 128), trim=(236, 214, 170), corner=None, alpha=1.0, glow=None),
    "Wood": dict(body=(196, 128, 64), lid=(206, 140, 72), trim=(150, 92, 40), corner=(120, 124, 136), alpha=1.0, glow=None),
    "Gold": dict(body=(250, 196, 40), lid=(255, 210, 70), trim=(230, 170, 30), corner=(220, 30, 50), alpha=1.0, glow=None),
    "Diamond": dict(body=(150, 210, 255), lid=(170, 220, 255), trim=(200, 236, 255), corner=(220, 245, 255), alpha=0.7, glow=(120, 200, 255)),
}
PINK = (255, 150, 190)
WHITE = (250, 250, 252)
INK = (40, 44, 70)


def fam_step(level):
    level = max(1, min(25, level))
    return (level - 1) // 5, (level - 1) % 5 + 1


def rbox(m, center, half, color, e=0.3, frame=Matrix(), **o):
    return m.blob(half, color, frame @ T(*center), e1=e, e2=e, **o)


def cyl(m, a, b, r, color, e=0.18, **o):
    """Rounded cylinder from a to b."""
    a, b = Vector(a), Vector(b)
    d = b - a
    rot = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_matrix().to_4x4()
    mid = (a + b) / 2
    return m.blob((r, r, d.length / 2), color, Matrix.Translation(mid) @ rot, e1=e, e2=1.0, **o)


def ear(m, base, size, color, inner=PINK, facing=Vector((0, -1, 0)), tilt=0.0):
    """A cat ear standing on `base`: a tapered rounded pyramid, the pink inside towards `facing`."""

    def warp(p):
        k = 1 - (p.z + size) / (2 * size) * 0.82
        return Vector((p.x * k, p.y * k, p.z))

    fr = Matrix.Translation(Vector(base) + Vector((0, 0, size * 0.9))) @ R(tilt, "Y")
    m.blob((size * 0.75, size * 0.42, size), color, fr, e1=0.7, e2=0.6, warp=warp, name="Ear")
    f = Vector(facing).normalized()
    m.blob((size * 0.45, size * 0.12, size * 0.62), inner, Matrix.Translation(Vector(base) + Vector((0, 0, size * 0.75)) + f * size * 0.36) @ R(tilt, "Y"),
           e1=0.7, e2=0.6, warp=warp, name="EarIn")


def paw(m, center, normal, up, size, color):
    """A paw print lying on a surface facing `normal`."""
    n = Vector(normal).normalized()
    u = Vector(up).normalized()
    s = n.cross(u)
    c = Vector(center)
    flat = Matrix((s, u, n)).transposed().to_4x4()
    m.blob((size * 0.42, size * 0.34, size * 0.08), color, Matrix.Translation(c - u * size * 0.15) @ flat, e1=0.8, e2=1.0, name="Pad")
    for dx, dy in ((-0.42, 0.32), (-0.15, 0.5), (0.15, 0.5), (0.42, 0.32)):
        m.blob((size * 0.14, size * 0.17, size * 0.07), color, Matrix.Translation(c + s * dx * size + u * dy * size) @ flat, e1=0.8, e2=1.0, name="Toe")


def cat_face(m, frame, r, color):
    """A glowing cat head (round face with two ears) on a screen; `frame` points local +Y out of the screen."""
    pts = []
    n = 28
    for i in range(n):
        a = -PI / 2 + i * 2 * PI / n
        x, y = r * math.cos(a), r * 0.85 * math.sin(a)
        pts.append((x, y))
    # ears: replace the top arc points with two peaks
    out = []
    for x, y in pts:
        if y > r * 0.45:
            continue
        out.append((x, y))
    # insert ears between the right and left halves (outline runs counter-clockwise from the bottom)
    right = [p for p in out if p[0] >= 0]
    left = [p for p in out if p[0] < 0]
    right.sort(key=lambda p: p[1])
    left.sort(key=lambda p: -p[1])
    ears = [(r * 0.85, r * 0.45), (r * 0.75, r * 1.1), (r * 0.3, r * 0.62), (-r * 0.3, r * 0.62), (-r * 0.75, r * 1.1), (-r * 0.85, r * 0.45)]
    outline = right + ears + left
    flip = Matrix(((-1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))  # local Z -> +Y, keeps X / up
    m.slab(outline, 0.05, color, frame @ flip, name="CatFace", emit=1.2)


def star(m, center, r, color, frame=Matrix(), emit=0.0):
    pts = []
    for i in range(10):
        a = PI / 2 + i * PI / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((rr * math.cos(a), rr * math.sin(a)))
    return m.slab(pts, r * 0.35, color, frame @ T(*center) @ kit.FRONT, name="Star", emit=emit)


# --------------------------------------------------------------------------------------------------
# Treadmill (M16-M20): 5 families, steps 1-5 add console ears (3+), front pillars with gems (4+), a ring (5)
def treadmill(level):
    f, step = fam_step(level)
    P = TREAD[f]
    m = Model(f"Treadmill{level}")
    k = 1 + 0.02 * (level - 1)
    fr = Matrix.Scale(k, 4)
    glow_emit = 2.5 if P["name"] in ("neon", "cosmic") else 0.0
    # deck, belt, side rails, feet
    rbox(m, (0, 0, 0.5), (1.2, 2.1, 0.32), P["frame"], e=0.28, frame=fr)
    rbox(m, (0, 0.1, 0.84), (0.86, 1.95, 0.06), P["dark"] if P["name"] != "cosmic" else (60, 36, 130), e=0.2, frame=fr)
    for x in (-1, 1):
        rbox(m, (x * 1.02, 0.05, 0.82), (0.2, 2.0, 0.1), P["accent"], e=0.3, frame=fr)
        for y in (-1.8, 1.8):
            rbox(m, (x * 0.95, y, 0.12), (0.22, 0.22, 0.12), P["dark"], e=0.4, frame=fr)
        if step >= 2:
            rbox(m, (x * 1.23, 0.3, 0.5), (0.04, 1.4, 0.06), P["glow"], e=0.4, frame=fr, emit=glow_emit or 1.2)
    # uprights, handlebars, console
    for x in (-1, 1):
        cyl(m, fr @ Vector((x * 0.95, -1.8, 0.7)), fr @ Vector((x * 0.82, -2.05, 3.0)), 0.15 * k, P["frame"])
        cyl(m, fr @ Vector((x * 0.85, -1.95, 2.55)), fr @ Vector((x * 0.95, -0.9, 2.62)), 0.12 * k, P["dark"])
        cyl(m, fr @ Vector((x * 0.94, -1.05, 2.62)), fr @ Vector((x * 0.95, -0.75, 2.62)), 0.13 * k, P["accent"])
    # the runner stands on the belt facing -Y, so the screen faces +Y (back at the runner), tilted up
    tilt = R(0.32, "X")
    cons = fr @ T(0, -2.1, 3.25) @ tilt
    rbox(m, (0, 0, 0), (0.95, 0.24, 0.62), P["frame"], e=0.35, frame=cons)
    rbox(m, (0, 0.2, 0.12), (0.7, 0.06, 0.4), (30, 90, 200), e=0.25, frame=cons, emit=0.5)
    cat_face(m, cons @ T(0, 0.27, 0.12), 0.3, (150, 230, 255))
    for x, col in ((-0.2, (90, 220, 90)), (0.2, (240, 70, 80))):
        rbox(m, (x, 0.22, -0.43), (0.13, 0.05, 0.07), col, e=0.4, frame=cons, emit=0.4)
    if step >= 3:
        for x in (-1, 1):
            ear(m, cons @ Vector((x * 0.55, 0, 0.5)), 0.32 * k, P["frame"], inner=PINK if P["name"] != "neon" else (255, 120, 230))
    if step >= 4:
        for x in (-1, 1):
            cyl(m, fr @ Vector((x * 1.3, -1.6, 0.6)), fr @ Vector((x * 1.3, -1.6, 2.0)), 0.18 * k, P["accent"])
            m.ball(fr @ Vector((x * 1.3, -1.6, 2.35)), 0.3 * k, P["gem"], emit=1.0)
    if step >= 5:
        m.torus(1.25 * k, 0.07 * k, P["glow"], cons @ R(-PI / 2 + 0.25, "X"), emit=2.0)
        for i in range(3):
            a = 0.5 + i * 2.1
            star(m, cons @ Vector((1.25 * math.cos(a), 1.25 * math.sin(a) * 0.25, 1.25 * math.sin(a) * 0.95)), 0.25 * k, (255, 210, 60), emit=1.0)
        # a winged star on the front of the deck
        star(m, fr @ Vector((0, -2.15, 0.55)), 0.42, (255, 210, 60), emit=0.6)
    return m


# --------------------------------------------------------------------------------------------------
# Dumbbells (M11-M15): one dumbbell, and the rack with a pair for the pen
def _dumbbell(m, center, level, scale=1.0):
    f, step = fam_step(level)
    P = WEIGHTS[f]
    k = scale * (1 + 0.06 * (level - 1))
    c = Vector(center)
    ax = Vector((1, 0, 0))
    cyl(m, c - ax * 0.75 * k, c + ax * 0.75 * k, 0.11 * k, P["bar"])
    plates = 1 + (step - 1) // 2
    pr = (0.36 + 0.03 * step) * k
    for side in (-1, 1):
        for i in range(plates):
            x = side * (0.5 + i * 0.16) * k
            cyl(m, c + ax * (x - 0.07 * k), c + ax * (x + 0.07 * k), pr * (1 - i * 0.06), P["plate"], e=0.35, alpha=P["alpha"])
        outer = c + ax * side * (0.5 + plates * 0.16) * k
        paw(m, outer + ax * side * 0.01, ax * side, Vector((0, 0, 1)), pr * 0.9, WHITE if f != 3 else (230, 250, 255))
        if step >= 3:
            ear(m, c + ax * side * (0.5 + (plates - 1) * 0.08) * k + Vector((0, 0, pr * 0.85)), 0.14 * k, P["plate"], facing=Vector((0, -1, 0)))
        if step >= 5 and P["glow"]:
            m.torus(pr * 1.15, 0.03 * k, P["glow"], Matrix.Translation(c + ax * side * 0.55 * k) @ R(PI / 2, "Y"), emit=2.0)
    return m


def dumbbell(level):
    m = Model(f"Dumbbell{level}")
    return _dumbbell(m, (0, 0, 0), level)


def weights(level):
    f, step = fam_step(level)
    P = WEIGHTS[f]
    m = Model(f"Weights{level}")
    k = 1 + 0.06 * (level - 1)
    w, h = 1.15 * k, 1.9 * k
    for x in (-1, 1):
        cyl(m, (x * w, -0.45, 0.1), (x * w * 0.95, 0, h), 0.1 * k, P["rack"])
        cyl(m, (x * w, 0.45, 0.1), (x * w * 0.95, 0, h), 0.1 * k, P["rack"])
        rbox(m, (x * w, 0, 0.1), (0.16 * k, 0.6, 0.1), P["rack"], e=0.4)
    for z in (0.75 * h, h * 1.02):
        rbox(m, (0, 0, z - 0.32 * k), (w, 0.16 * k, 0.07), P["rack"], e=0.4)
    rbox(m, (0, 0, 0.25), (w * 0.9, 0.5, 0.1), P["rack"], e=0.4)
    if step >= 3:
        star(m, (0, -0.55, 0.3), 0.22 * k, (255, 210, 60), emit=0.5)
    _dumbbell(m, (0, 0, 0.75 * h - 0.32 * k + 0.45 * k), level, 0.95)
    _dumbbell(m, (0, 0, 1.02 * h - 0.32 * k + 0.45 * k), level, 0.95)
    return m


# --------------------------------------------------------------------------------------------------
# Rods (M01-M05): 5 materials x 5 tiers
def rod(level):
    f, step = fam_step(level)
    P = RODS[f]
    m = Model(f"Rod{level}")
    L = 4.6 + 0.04 * level
    # chunky toy pole bending forward (-Y) near the tip; the hand holds the grip at the origin
    pts = [(0, -0.9 * (t / 14) ** 2.2, t / 14 * L) for t in range(15)]
    m.tube(pts, lambda t: 0.2 * (1 - 0.45 * t), P["pole"], n=16, name="Pole")
    m.tube([(0, 0, -0.35), (0, 0, 1.1)], 0.27, P["grip"], n=16, name="Grip")
    m.torus(0.27, 0.07, P["trim"], T(0, 0, 1.12))
    m.blob((0.3, 0.3, 0.14), P["trim"], T(0, 0, -0.38), e1=0.5, e2=1.0, name="ButtCap")
    rings = 1 + step
    for i in range(rings):
        t = 0.35 + 0.55 * i / max(1, rings - 1)
        j = min(13, int(round(t * 14)))
        p = Vector(pts[j])
        d = (Vector(pts[j + 1]) - Vector(pts[j - 1])).normalized()
        rot = Vector((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4()
        m.torus(0.2 * (1 - 0.45 * t) + 0.02, 0.055, P["trim"], Matrix.Translation(p) @ rot)
    # tip ring the line hangs from
    tip = Vector(pts[-1])
    m.ball(tip, 0.13, P["trim"])
    # reel on the left side (-X), the paw facing out
    rc = Vector((-0.42, 0, 1.45))
    cyl(m, rc + Vector((0.22, 0, 0)), Vector((0, 0, 1.45)), 0.09, P["trim"])
    cyl(m, rc - Vector((0.16, 0, 0)), rc + Vector((0.16, 0, 0)), 0.38, P["reel"], e=0.3)
    paw(m, rc - Vector((0.17, 0, 0)), (-1, 0, 0), (0, 0, 1), 0.42, WHITE)
    cyl(m, rc + Vector((-0.17, 0.0, -0.1)), rc + Vector((-0.3, 0.32, -0.42)), 0.06, P["trim"])
    cyl(m, rc + Vector((-0.3, 0.32, -0.42)), rc + Vector((-0.55, 0.32, -0.42)), 0.1, P["grip"])
    if step >= 3:
        for y in (-1, 1):
            ear(m, rc + Vector((0, y * 0.18, 0.3)), 0.15, P["reel"])
    # line, float, hook
    m.tube([tip, tip + Vector((0, 0, -1.5))], 0.025, WHITE, n=6, caps=False, name="Line")
    fl = tip + Vector((0, 0, -1.45))
    m.ball(fl + Vector((0, 0, 0.1)), 0.25, (230, 50, 50))
    m.ball(fl + Vector((0, 0, -0.05)), 0.24, WHITE)
    m.tube([fl + Vector((0, 0, -0.25)), fl + Vector((0, 0, -0.5))], 0.025, WHITE, n=6, caps=False, name="Line2")
    m.torus(0.14, 0.04, (200, 204, 214), Matrix.Translation(fl + Vector((0, 0, -0.64))) @ R(PI / 2, "X"))
    if step >= 4 and P["glow"]:
        m.torus(0.33, 0.035, P["glow"], T(0, 0, 0.5), emit=1.5)
    if step >= 5:
        # a cat head charm on the butt of the grip with a bow (M01 / M03 tier 5)
        head_col = (240, 176, 70) if f == 0 else P["reel"]
        hc = Vector((0, -0.05, -0.62))
        m.blob((0.36, 0.32, 0.3), head_col, Matrix.Translation(hc), e1=0.6, e2=0.6, name="CatHead")
        for x in (-1, 1):
            ear(m, hc + Vector((x * 0.2, 0, 0.18)), 0.13, head_col)
            m.ball(hc + Vector((x * 0.12, -0.3, 0.05)), 0.045, INK)
        bow_col = (110, 200, 70) if f == 0 else P["trim"]
        for x in (-1, 1):
            m.blob((0.2, 0.08, 0.13), bow_col, T(x * 0.2, -0.22, -0.2) @ R(x * 0.4, "Y"), e1=0.8, e2=0.8, name="Bow")
        m.ball((0, -0.25, -0.2), 0.09, bow_col)
    return m


# --------------------------------------------------------------------------------------------------
def bat():
    m = Model("Bat")

    def prof(t):
        x = -0.35 + t * 4.4
        if t < 0.28:
            r = 0.22
        else:
            u = (t - 0.28) / 0.72
            r = 0.22 + 0.36 * math.sin(min(1.0, u * 1.15) * PI / 2) ** 1.4
        if t > 0.93:
            r *= math.sqrt(max(0.0, 1 - ((t - 0.93) / 0.07) ** 2))
        return x, r

    m.lathe(prof, (240, 176, 76), R(-PI / 2, "Y"), n_t=44, n_a=32, name="Barrel")
    # red wrapped grip with a gold collar and a cat-ear knob (M06)
    m.lathe(lambda t: (t * 1.2, 0.27 + 0.025 * math.sin(t * PI * 9)), (220, 50, 60), R(-PI / 2, "Y"), n_t=36, n_a=24, name="Grip")
    m.torus(0.29, 0.08, (250, 200, 60), T(0, 0, 1.25))
    m.blob((0.36, 0.36, 0.2), (250, 200, 60), T(0, 0, -0.12), e1=0.6, e2=1.0, name="Knob")
    for x in (-1, 1):
        ear(m, (x * 0.2, 0, -0.08), 0.15, (250, 200, 60))
    paw(m, (0, -0.57, 3.1), (0, -1, 0), (0, 0, 1), 0.62, WHITE)
    return m


def crate(key, lid_open=0.0):
    P = CRATES[key]
    m = Model(f"Crate{key}")
    rbox(m, (0, 0, 0.9), (1.0, 1.0, 0.9), P["body"], e=0.22, alpha=P["alpha"], emit=0.4 if P["glow"] else 0.0)
    lid = T(0, 0, 1.92) @ (T(0, 1.0, 0) @ R(-lid_open, "X") @ T(0, -1.0, 0))
    rbox(m, (0, 0, 0), (1.08, 1.08, 0.2), P["lid"], e=0.25, frame=lid, alpha=P["alpha"])
    for x in (-1, 1):
        ear(m, lid @ Vector((x * 0.55, 0, 0.12)), 0.3, P["lid"])
    paw(m, (0, -1.01, 0.9), (0, -1, 0), (0, 0, 1), 0.85, (90, 56, 30) if key in ("Paper", "Wood") else (120, 70, 20) if key == "Gold" else (40, 110, 200))
    if key == "Paper":
        rbox(m, (0, 0, 1.6), (0.25, 1.02, 0.3), P["trim"], e=0.2)
    if key == "Wood":
        for z in (0.45, 1.35):
            rbox(m, (0, -1.0, z), (0.95, 0.03, 0.04), P["trim"], e=0.4)
    if P["corner"]:
        for x in (-1, 1):
            for z in (0.15, 1.65):
                if key == "Wood":
                    m.ball((x * 0.96, -0.96, z), 0.16, P["corner"])
                else:
                    m.blob((0.2, 0.2, 0.2), P["corner"], T(x * 0.96, -0.96, z) @ R(PI / 4, "Z"), e1=1.0, e2=1.0, name="Gem", emit=0.4)
    return m
