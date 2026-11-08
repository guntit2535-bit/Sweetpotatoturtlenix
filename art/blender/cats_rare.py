"""Rare tier (round 2): fashion. A plain cat (base look) plus clothes or an accessory, from the design table.
Registers each design into blockcat.DESIGNS (Cool Shades is in blockcat.py).
"""
import math

import blockcat
from blockcat import GOLD, INK, PINK, WHITE, shade
from catparts import (BLACK, BLUE, BROWN, GREEN, RED, SILVER, WOOD, C, G, about, ball, beanie, beret, bow, bow_tie,
                      box, boots, brim_hat, cap, collar, cone_hat, crown, cuffs, cyl, ears_out, flower, fx, glasses,
                      goggles, headband, headphones, hood, lei, mix, mustache, necklace, necktie, overall, plate,
                      red_nose, ring, scarf, shirt, skirt, stack, star, stick, top_hat, wedge, coat, belt, side_mark,
                      backpack, held, remove)
from kit import R, T

DESIGNS = {}


def cat(name, **look):
    def deco(fn):
        DESIGNS[name] = (fn, look)
        return fn
    return deco


@cat("Cap Cat", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff")
def _cap(m, A):
    cap(m, A, RED, back=True)


@cat("Bow Tie", shape="Loaf", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="patch", patternColor="b8bcc8")
def _bowtie(m, A):
    bow_tie(m, A, (225, 40, 55), 1.3)
    collar(m, A, WHITE, h=0.2)


@cat("Ribbon", shape="Fluffy", fur="ffffff", second="fff2f6", eyes="7ec8ff", cheeks=True)
def _ribbon(m, A):
    a = G(A)
    bow(m, (a.hw * 0.25, a.hy, a.top + 0.35), (255, 120, 170), 1.5)


@cat("Beanie", shape="Loaf", fur="9a6a44", second="fff0d8", eyes="52d273")
def _beanie(m, A):
    beanie(m, A, (60, 170, 90), band=(40, 130, 70), pom=WHITE)


@cat("Scarf", shape="Slim", fur="a8adb8", second="eef0f4", eyes="ffb020", pattern="tabby", patternColor="777c88")
def _scarf(m, A):
    scarf(m, A, [(230, 70, 70), WHITE, (60, 120, 230)])


@cat("Nerd", shape="Loaf", fur="ffe6bc", second="fffaf0", eyes="3c96ff", eyeStyle="big")
def _nerd(m, A):
    glasses(m, A, frame=INK, lens=WHITE, kind="round")
    necktie(m, A, (60, 110, 220), shirt=WHITE)


@cat("Top Hat", shape="Slim", fur="2e2a36", second="ffffff", eyes="7ed957", pattern="tuxedo")
def _tophat(m, A):
    ears_out(m, A)
    top_hat(m, A, BLACK, (200, 40, 50))
    stick(m, A, BLACK, h=2.4, top="ball", top_col=GOLD)


@cat("Flower Crown", shape="Fluffy", fur="ffffff", second="fff2f6", eyes="52d273", blush=True)
def _flowercrown(m, A):
    a = G(A)
    cols = [(255, 110, 150), (255, 210, 60), (160, 120, 255), (90, 200, 255), (255, 150, 60)]
    for k in range(7):
        x = -a.hw * 0.42 + k * a.hw * 0.14
        flower(m, (x, a.hy - a.hd * 0.35, a.top + 0.12), 0.55, cols[k % 5])
        box(m, (x, a.hy + 0.1, a.top + 0.05), (0.3, a.hd * 0.6, 0.1), (90, 180, 80), "H", "Leaf", studs=False)
    fx(m, A, "orbit", "petal", [(255, 150, 190), (255, 210, 230)], n=8, s=0.45, emit=0.3, z=(0.5, 3.5))


@cat("Headphones", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="tabby", patternColor="d9681f")
def _headphones(m, A):
    headphones(m, A, (60, 60, 75), (70, 180, 255))
    fx(m, A, "orbit", "note", [(80, 160, 255), (255, 120, 180)], n=5, s=0.55, emit=0.8, z=(2.5, 4.5))


@cat("Hoodie", shape="Loaf", fur="a8adb8", second="eef0f4", eyes="ffb020")
def _hoodie(m, A):
    hood(m, A, (150, 90, 220), inner=(255, 170, 200))
    shirt(m, A, (150, 90, 220), h=1.2)
    a = G(A)
    box(m, (0, a.bfront - 0.27, a.hb - 0.55), (0.9, 0.1, 0.45), (120, 70, 190), "B", "Pocket", studs=False)


@cat("Sweater", shape="Fluffy", fur="ffe6bc", second="fffaf0", eyes="52d273")
def _sweater(m, A):
    a = G(A)
    red, dark, cream = (200, 50, 60), (130, 30, 40), (255, 230, 200)
    shirt(m, A, red, h=a.bh * 0.85)
    for s in (-1, 1):
        x = s * (a.bw / 2 + 0.25)
        for u in (-0.3, 0.0, 0.3):
            box(m, (x, a.by + u * a.bl, a.btop - a.bh * 0.3), (0.06, 0.2, a.bh * 0.9), dark, "B", "Check", studs=False)
        for v in (-0.35, 0.25):
            box(m, (x * 1.01, a.by, a.btop - a.bh * 0.3 + v), (0.06, a.bl + 0.3, 0.16), cream, "B", "Check", studs=False)
    collar(m, A, red, h=0.4)


@cat("Raincoat", shape="Loaf", fur="ffffff", second="ffffff", eyes="3c96ff")
def _raincoat(m, A):
    y = (255, 210, 40)
    hood(m, A, y, ears=False)
    coat(m, A, y)
    boots(m, A, y, h=0.55, sole=(200, 150, 20))
    a = G(A)
    for z in (0.3, -0.3):
        box(m, (0, a.bfront - 0.27, a.bz + z), (0.22, 0.08, 0.22), (60, 120, 230), "B", "Button", studs=False)


@cat("Sailor", shape="Slim", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="patch", patternColor="d0d6e2")
def _sailor(m, A):
    a = G(A)
    ears_out(m, A)
    cyl(m, (0, a.hy, a.top + 0.2), a.hw * 0.42, 0.4, WHITE, "H", "Hat")
    cyl(m, (0, a.hy, a.top + 0.12), a.hw * 0.44, 0.2, (40, 90, 200), "H", "Band")
    box(m, (0, a.by + 0.4, a.btop + 0.08), (a.bw * 0.9, 1.2, 0.12), (40, 90, 200), "B", "Collar", studs=False)
    for x in (-1, 1):
        box(m, (x * 0.4, a.bback + 0.2, a.btop + 0.03), (0.1, 0.1, 0.1), WHITE, "B", "Collar", studs=False)
    bow(m, (0, a.front - 0.1, a.hb + 0.15), (220, 40, 50), 0.8)


@cat("Bandana", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="52d273")
def _bandana(m, A):
    a = G(A)
    ears_out(m, A)
    red = (220, 40, 50)
    box(m, (0, a.hy + 0.05, a.top + 0.12), (a.hw + 0.2, a.hd + 0.2, 0.3), red, "H", "Band")
    box(m, (0, a.hy + 0.05, a.top - 0.25), (a.hw + 0.22, a.hd + 0.22, 0.5), red, "H", "Band", studs=False)
    for x, y in ((-0.8, -0.5), (0.5, -0.8), (0.9, 0.4), (-0.3, 0.6), (0.0, -0.2)):
        box(m, (x, a.hy + y, a.top + 0.3), (0.2, 0.2, 0.06), WHITE, "H", "Dot", studs=False)
    for x in (-1, 1):
        box(m, (x * 0.25, a.hy + a.hd / 2 + 0.35, a.top - 0.4), (0.3, 0.6, 0.14), red, "H", "Knot", studs=False,
            fr=about((0, a.hy + a.hd / 2, a.top - 0.2), R(x * 0.4, "Z") @ R(0.6, "X")))


@cat("Party Hat", shape="Loaf", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="calico", patternColor="ffb066", third="5a5060")
def _partyhat(m, A):
    cone_hat(m, A, [(255, 90, 160), (70, 180, 255), (255, 210, 50), (120, 220, 120), (255, 90, 160)], h=1.8, w=1.2, tilt=0.18,
             pom=(255, 230, 90))
    fx(m, A, "orbit", "pixel", [(255, 90, 160), (70, 180, 255), (255, 210, 50), (120, 220, 120)], n=14, s=0.28, emit=0.2)


@cat("Beret", shape="Slim", fur="2b2733", second="3d3846", eyes="ffd23c")
def _beret(m, A):
    beret(m, A, (220, 50, 60))
    a = G(A)
    box(m, (0, a.hy, a.hb + 0.2), (a.hw + 0.1, a.hd + 0.1, 0.3), (240, 240, 240), "H", "Collar", studs=False)
    for z in (0.0,):
        box(m, (0, a.front - 0.1, a.hb + 0.2), (0.6, 0.08, 0.3), (40, 40, 50), "H", "Collar", studs=False)


@cat("Sunhat", shape="Fluffy", fur="ffe6bc", second="fffaf0", eyes="5ab0ff", blush=True)
def _sunhat(m, A):
    a = G(A)
    straw = (240, 205, 120)
    brim_hat(m, A, straw, band=(255, 120, 160), brim=1.6, h=0.6, cw=0.62)
    bow(m, (a.hw * 0.32, a.hy - a.hd * 0.3, a.top + 0.4), (255, 120, 160), 0.8)


@cat("Jersey", shape="Loaf", fur="ffffff", second="ffffff", eyes="52d273", pattern="masked", patternColor="5a5060")
def _jersey(m, A):
    navy = (40, 70, 170)
    shirt(m, A, navy, h=1.3)
    a = G(A)
    # number 1 on the side
    side_mark(m, A, WHITE, [(0.0, 0.05, 0.22, 0.8), (-0.12, 0.3, 0.2, 0.2), (0.0, -0.35, 0.5, 0.15)])
    box(m, (0, a.by, a.btop - 0.6), (a.bw + 0.5, a.bl + 0.5, 0.14), (230, 60, 70), "B", "Trim", studs=False)
    cap(m, A, navy, back=False, logo=WHITE)


@cat("Bucket Hat", shape="Loaf", fur="9a6a44", second="fff0d8", eyes="ffd23c", pattern="tabby", patternColor="6a4628")
def _bucket(m, A):
    a = G(A)
    ears_out(m, A)
    green = (160, 215, 120)
    for k, w in enumerate((1.25, 1.05)):
        box(m, (0, a.hy, a.top + 0.05 + k * 0.1), (a.hw * w, a.hd * w, 0.14), shade(green, 0.9 + k * 0.1), "H", "Brim", studs=False)
    box(m, (0, a.hy, a.top + 0.5), (a.hw * 0.8, a.hd * 0.8, 0.75), green, "H", "Hat")


@cat("Monocle", shape="Slim", fur="a8adb8", second="eef0f4", eyes="52d273")
def _monocle(m, A):
    a = G(A)
    ears_out(m, A)
    e = a.eyes[1]
    cyl(m, (e.x, a.front - 0.22, e.z - 0.02), 0.5, 0.1, GOLD, "H", "Monocle", axis="Y")
    cyl(m, (e.x, a.front - 0.25, e.z - 0.02), 0.38, 0.06, WHITE, "H", "Lens", axis="Y", alpha=0.5, rough=0.05, coat=1.0)
    box(m, (e.x + 0.4, a.front - 0.22, e.z - 0.8), (0.05, 0.05, 1.2), GOLD, "H", "Chain", studs=False)
    mustache(m, A, (60, 50, 60))
    top_hat(m, A, (60, 60, 70), GOLD, h=0.9, w=0.55)


@cat("Pearls", shape="Fluffy", fur="d9d3e6", second="fff6f8", eyes="5ab0ff", ears="small", cheeks=True)
def _pearls(m, A):
    necklace(m, A, (255, 250, 240), n=11, r=0.19, rows=3)
    a = G(A)
    for x in (-1, 1):
        ball(m, (x * (a.hw / 2 + 0.02), a.hy - 0.2, a.hz - 0.4), 0.14, (250, 245, 235), "H", "Bead")
    fx(m, A, "orbit", "spark", [(255, 255, 255), (255, 240, 200)], n=8, s=0.4, emit=2.5)


@cat("Heart Glasses", shape="Loaf", fur="ffb5cf", second="fff0f5", eyes="ff5a8a", blush=True)
def _heartglasses(m, A):
    glasses(m, A, frame=(220, 30, 70), lens=(255, 110, 150), kind="heart", emit=0.3)
    fx(m, A, "orbit", "heart", [(255, 90, 140), (255, 150, 190)], n=6, s=0.5, emit=1.0, z=(2.2, 4.4))


@cat("Star Glasses", shape="Slim", fur="b38cff", second="efe6ff", eyes="ffd23c")
def _starglasses(m, A):
    glasses(m, A, frame=(255, 205, 40), lens=(255, 240, 150), kind="star", emit=0.3)
    fx(m, A, "orbit", "star", [(255, 220, 80), (255, 255, 200)], n=6, s=0.45, emit=2.0)


@cat("Backpack", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="socks")
def _backpack(m, A):
    backpack(m, A, (60, 160, 240), flap=(40, 120, 200))
    b = held(m, A, -1)
    fr = T(b.x, b.y, 0.0) @ R(0.15, "Y")
    box(m, (0, 0, 1.0), (0.3, 0.3, 1.8), (255, 210, 50), "L", "Pencil", fr=fr, studs=False)
    wedge(m, (0, 0, 2.05), (0.3, 0.3, 0.3), (240, 200, 160), "L", "Pencil", fr=fr @ T(0, 0, 0) @ R(0, "Z"))
    box(m, (0, 0, 0.12), (0.32, 0.32, 0.22), (255, 150, 180), "L", "Pencil", fr=fr, studs=False)


@cat("Bowler Hat", shape="Slim", fur="ffe6bc", second="fffaf0", eyes="7ed957", pattern="dorsal", patternColor="e0c090")
def _bowler(m, A):
    a = G(A)
    ears_out(m, A)
    brown = (110, 70, 45)
    plate(m, (0, a.hy, a.top + 0.08), (a.hw * 1.0, a.hd * 1.0, 0.14), brown, "H", "Brim")
    stack(m, (0, a.hy, a.top + 0.14), a.hw * 0.68, a.hw * 0.4, 0.75, 3, brown, d0=a.hd * 0.68, d1=a.hd * 0.4)
    box(m, (0, a.hy, a.top + 0.25), (a.hw * 0.7, a.hd * 0.7, 0.18), INK, "H", "Band", studs=False)
    necktie(m, A, (200, 60, 60), shirt=WHITE, long=0.9)


@cat("Earmuffs", shape="Fluffy", fur="ffffff", second="ffffff", eyes="3c96ff", cheeks=True)
def _earmuffs(m, A):
    a = G(A)
    pink = (255, 150, 190)
    ears_out(m, A)
    box(m, (0, a.hy + 0.1, a.top + 0.15), (a.hw * 0.7, 0.3, 0.2), (240, 120, 160), "H", "Band", studs=False)
    for x in (-1, 1):
        box(m, (x * (a.hw / 2 + 0.06), a.hy + 0.1, a.top - 0.3), (0.2, 0.3, 0.8), (240, 120, 160), "H", "Band", studs=False)
        ball(m, (x * (a.hw / 2 + 0.3), a.hy + 0.05, a.hz + 0.1), 0.6, pink, "H", "Muff", rough=0.9, coat=0.0)
    scarf(m, A, [pink, WHITE], tail=False)


@cat("Tutu", shape="Slim", fur="ffffff", second="fff2f6", eyes="5ab0ff", blush=True)
def _tutu(m, A):
    pink = (255, 160, 200)
    skirt(m, A, pink, layers=3, wide=0.6, col2=(255, 200, 225))
    a = G(A)
    plate(m, (0, a.by, a.leg + 0.85), (a.bw + 0.44, a.bl + 0.44, 0.45), pink, "B", "Top")
    bow(m, (a.hw * 0.3, a.hy, a.top + 0.3), pink, 0.8)


@cat("Overalls", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="52d273", pattern="tabby", patternColor="d9681f")
def _overalls(m, A):
    overall(m, A, (70, 110, 180), strap=(60, 95, 160))
    a = G(A)
    shirt(m, A, (250, 230, 120), h=0.6)


@cat("Leather Jacket", shape="Slim", fur="a8adb8", second="eef0f4", eyes="ffb020", eyeStyle="big")
def _leather(m, A):
    a = G(A)
    jacket = (40, 38, 46)
    shirt(m, A, jacket, h=1.35, front=False)
    for x in (-1, 1):
        wedge(m, (x * 0.55, a.bfront - 0.28, a.hb - 0.05), (0.6, 0.14, 0.7), jacket, "B", "Lapel",
              fr=about((x * 0.55, a.bfront - 0.28, a.hb - 0.05), R(math.pi / 2, "X") @ R(math.pi, "Z")))
        box(m, (x * 0.3, a.bfront - 0.27, a.bz), (0.06, 0.08, a.bh * 0.7), SILVER, "B", "Zip", studs=False)
    box(m, (0, a.bfront - 0.25, a.bz + 0.1), (0.5, 0.08, 0.9), WHITE, "B", "Tee", studs=False)
    glasses(m, A, kind="square")


@cat("Hawaiian", shape="Loaf", fur="ffe6bc", second="fffaf0", eyes="3c96ff")
def _hawaiian(m, A):
    a = G(A)
    shirt(m, A, (60, 190, 210), h=1.25)
    for s in (-1, 1):
        for u, v, c in ((-0.3, 0.2, (255, 110, 150)), (0.15, -0.15, (255, 220, 70)), (0.35, 0.25, WHITE), (-0.05, 0.35, (255, 110, 150))):
            box(m, (s * (a.bw / 2 + 0.25), a.by + u * a.bl, a.btop - 0.6 + v), (0.06, 0.38, 0.38), c, "B", "Print", studs=False,
                fr=about((s * (a.bw / 2 + 0.25), a.by + u * a.bl, a.btop - 0.6 + v), R(0.785, "X")))
    lei(m, A, [(255, 110, 150), (255, 220, 70), (255, 150, 60), WHITE])


@cat("Pajamas", shape="Fluffy", fur="9fd2ff", second="e8f5ff", eyes="3c96ff", eyeStyle="sleepy")
def _pajamas(m, A):
    a = G(A)
    pj = (120, 140, 230)
    shirt(m, A, pj, h=1.7)
    for s in (-1, 1):
        for u, v in ((-0.3, 0.2), (0.1, -0.3), (0.3, 0.3)):
            c = (s * (a.bw / 2 + 0.27), a.by + u * a.bl, a.bz + v)
            star(m, (0, 0, 0), 0.4, (255, 230, 90), "B", emit=0.2, fr=T(*c) @ R(math.pi / 2, "Z"))
    tip = cone_hat(m, A, [pj, pj, (100, 120, 210), pj], h=1.6, w=1.3, tilt=0.6, n=4)
    ball(m, tip, 0.3, WHITE, "H", "Pom")
    box(m, (0, a.hy, a.top + 0.05), (a.hw * 0.5, a.hd * 0.5, 0.2), WHITE, "H", "Band", studs=False)
    fx(m, A, "above", "z", [WHITE, (200, 220, 255)], n=3, s=0.55, emit=0.8)


@cat("Office Tie", shape="Slim", fur="a8adb8", second="eef0f4", eyes="52d273", pattern="mackerel", patternColor="5a5e6a")
def _office(m, A):
    shirt(m, A, WHITE, h=1.3)
    necktie(m, A, (40, 70, 180), shirt=WHITE, long=1.0)
    a = G(A)
    b = held(m, A, -1)
    box(m, (b.x, b.y, 0.55), (0.3, 1.1, 0.8), (90, 60, 40), "L", "Case")
    box(m, (b.x, b.y, 1.05), (0.12, 0.45, 0.14), (60, 40, 30), "L", "Case", studs=False)


@cat("Sneakerhead", shape="Loaf", fur="ffffff", second="ffffff", eyes="ffb020", pattern="spots", patternColor="4a4652", seed=8)
def _sneaker(m, A):
    a = G(A)
    cols = [(255, 70, 90), (60, 160, 255), (255, 200, 40), (90, 210, 110)]
    for i, p in enumerate(a.paws):
        box(m, (p.x, p.y - 0.12, 0.28), (1.1, 1.3, 0.5), cols[i], "L", "Shoe")
        box(m, (p.x, p.y - 0.12, 0.05), (1.14, 1.34, 0.1), WHITE, "L", "Shoe", studs=False)
        box(m, (p.x, p.y - 0.78, 0.4), (0.7, 0.06, 0.2), WHITE, "L", "Lace", studs=False)
    cap(m, A, (255, 70, 90), back=True)


@cat("Cherry Clip", shape="Fluffy", fur="ffffff", second="fff2f6", eyes="7ed957", blush=True)
def _cherry(m, A):
    a = G(A)
    for x in (-0.35, 0.1):
        ball(m, (-a.hw / 2 + 0.2 + x, a.hy - 0.4, a.top + 0.25), 0.4, (220, 30, 50), "H", "Cherry", emit=0.1)
    box(m, (-a.hw / 2 + 0.1, a.hy - 0.4, a.top + 0.6), (0.6, 0.08, 0.08), (60, 140, 60), "H", "Stem", studs=False,
        fr=about((-a.hw / 2 + 0.1, a.hy - 0.4, a.top + 0.6), R(0.0, "Y")))
    for x in (-0.35, 0.1):
        box(m, (-a.hw / 2 + 0.2 + x, a.hy - 0.4, a.top + 0.42), (0.06, 0.06, 0.4), (60, 140, 60), "H", "Stem", studs=False)
    box(m, (-a.hw / 2 + 0.3, a.hy - 0.4, a.top + 0.7), (0.35, 0.08, 0.2), (90, 190, 80), "H", "Leaf", studs=False)


@cat("Tennis", shape="Slim", fur="ffffff", second="ffffff", eyes="52d273", pattern="bicolor")
def _tennis(m, A):
    green = (80, 200, 110)
    headband(m, A, green, knot=False, tails=False)
    cuffs(m, A, green)
    b = held(m, A, -1)
    fr = T(b.x, b.y, 0.0) @ R(0.2, "Y")
    box(m, (0, 0, 0.5), (0.16, 0.16, 1.0), (60, 60, 70), "L", "Racket", fr=fr, studs=False)
    for k in range(10):
        a = k * 0.628
        box(m, (0, 0, 0), (0.12, 0.12, 0.3), (230, 60, 70), "L", "Racket", studs=False,
            fr=fr @ T(0, 0, 1.55) @ R(a, "Y") @ T(0.5, 0, 0))
    box(m, (0, 0, 1.55), (0.85, 0.04, 0.85), (240, 240, 240), "L", "Racket", fr=fr, studs=False, alpha=0.6)
    ball(m, (b.x + 0.6, b.y - 0.6, 0.25), 0.25, (220, 240, 60), "L", "TBall")


@cat("Snow Goggles", shape="Fluffy", fur="ffffff", second="ffffff", eyes="3c96ff", cheeks=True)
def _goggles(m, A):
    goggles(m, A, (40, 44, 60), (255, 150, 40), up=True)
    scarf(m, A, [(255, 150, 40), (40, 44, 60)])


@cat("Gold Chain", shape="Loaf", fur="2b2733", second="3d3846", eyes="ffd23c", eyeStyle="big", glowEyes=True)
def _goldchain(m, A):
    a = G(A)
    for k in range(12):
        t = k / 11
        x = -a.hw * 0.4 + t * a.hw * 0.8
        z = a.hb - 0.05 - 0.4 * math.sin(math.pi * t)
        box(m, (x, a.front - 0.12, z), (0.3, 0.12, 0.22), GOLD, "H", "Chain", studs=False, rough=0.15,
            fr=about((x, a.front - 0.12, z), R(0.6 if k % 2 else -0.6, "Y")))
    box(m, (0, a.front - 0.15, a.hb - 0.75), (0.6, 0.14, 0.6), GOLD, "H", "Pendant", rough=0.15)
    box(m, (0, a.front - 0.24, a.hb - 0.75), (0.22, 0.06, 0.22), (255, 60, 90), "H", "Gem", studs=False, emit=0.5)
    glasses(m, A, kind="square")
    fx(m, A, "orbit", "spark", [GOLD, (255, 240, 170)], n=7, s=0.4, emit=2.5)


@cat("Graduate", shape="Slim", fur="2b2733", second="ffffff", eyes="7ed957", pattern="tuxedo")
def _graduate(m, A):
    a = G(A)
    ears_out(m, A)
    box(m, (0, a.hy, a.top + 0.25), (a.hw * 0.7, a.hd * 0.7, 0.5), BLACK, "H", "Hat")
    box(m, (0, a.hy, a.top + 0.55), (a.hw * 1.15, a.hw * 1.15, 0.12), BLACK, "H", "Board", studs=False)
    box(m, (0, a.hy, a.top + 0.65), (0.2, 0.2, 0.1), GOLD, "H", "Tassel", studs=False)
    box(m, (a.hw * 0.55, a.hy - 0.3, a.top + 0.2), (0.12, 0.12, 0.8), GOLD, "H", "Tassel", studs=False)
    b = held(m, A, -1)
    cyl(m, (b.x, b.y, 0.3), 0.22, 1.2, (250, 240, 215), "L", "Scroll", axis="X")
    cyl(m, (b.x, b.y, 0.3), 0.24, 0.2, (220, 40, 50), "L", "Scroll", axis="X")


@cat("Cheerleader", shape="Loaf", fur="ffffff", second="ffffff", eyes="3c96ff", pattern="patch", patternColor="ffb066", blush=True)
def _cheer(m, A):
    red = (225, 40, 55)
    shirt(m, A, red, h=1.0)
    skirt(m, A, red, layers=2, wide=0.25, col2=WHITE)
    a = G(A)
    for side in (-1, 1):
        b = held(m, A, side)
        for k in range(10):
            ang = k * 0.628
            bx, bz = b.x + side * 0.3, 1.3
            box(m, (bx + math.cos(ang) * 0.4, b.y + math.sin(ang) * 0.4, bz + (k % 3 - 1) * 0.25), (0.34, 0.34, 0.34),
                red if k % 2 == 0 else WHITE, "L", "Pompom", studs=False, fr=about((bx, b.y, bz), R(ang, "Z")))
    bow(m, (0, a.hy + a.hd / 2 + 0.1, a.top - 0.2), red, 0.9)


@cat("Bunny Ears", shape="Fluffy", fur="ffffff", second="ffffff", eyes="ff7aa8", blush=True, ears="small")
def _bunny(m, A):
    a = G(A)
    pink = (255, 160, 200)
    box(m, (0, a.hy + 0.1, a.top + 0.1), (a.hw * 0.75, 0.3, 0.2), pink, "H", "Band", studs=False)
    for x in (-1, 1):
        fr = about((x * 0.55, a.hy + 0.1, a.top + 0.2), R(x * 0.18, "Y"))
        box(m, (x * 0.55, a.hy + 0.1, a.top + 1.15), (0.6, 0.35, 1.9), WHITE, "H", "BunnyEar", fr=fr)
        box(m, (x * 0.55, a.hy - 0.09, a.top + 1.15), (0.34, 0.06, 1.5), pink, "H", "BunnyEar", fr=fr, studs=False)


@cat("Antlers", shape="Loaf", fur="9a6a44", second="fff0d8", eyes="3c96ff")
def _antlers(m, A):
    a = G(A)
    ant = (170, 120, 70)
    for x in (-1, 1):
        bx = x * (a.hw / 2 - 0.5)
        box(m, (bx, a.hy + 0.2, a.top + 0.6), (0.24, 0.24, 1.2), ant, "H", "Antler", studs=False)
        box(m, (bx + x * 0.3, a.hy + 0.2, a.top + 1.15), (0.6, 0.22, 0.22), ant, "H", "Antler", studs=False)
        box(m, (bx + x * 0.55, a.hy + 0.2, a.top + 1.45), (0.22, 0.22, 0.6), ant, "H", "Antler", studs=False)
        box(m, (bx - x * 0.2, a.hy + 0.2, a.top + 1.4), (0.22, 0.22, 0.5), ant, "H", "Antler", studs=False)
    red_nose(m, A)
    collar(m, A, (200, 40, 50), gem=GOLD)
    ball(m, (0, a.front - 0.25, a.hb + 0.05), 0.2, GOLD, "H", "Bell")


@cat("Santa Hat", shape="Fluffy", fur="ffffff", second="ffffff", eyes="52d273", cheeks=True)
def _santa(m, A):
    a = G(A)
    ears_out(m, A)
    red = (220, 40, 50)
    tip = cone_hat(m, A, [red, red, red, red], h=1.7, w=a.hw * 0.85, tilt=0.55, n=4)
    ball(m, tip, 0.35, WHITE, "H", "Pom")
    box(m, (0, a.hy, a.top + 0.1), (a.hw * 0.95, a.hd * 0.95, 0.38), WHITE, "H", "Fur")
    fx(m, A, "above", "flake", [WHITE, (220, 240, 255)], n=7, s=0.45, emit=0.6)


@cat("Spooky Hat", shape="Slim", fur="2b2733", second="3d3846", eyes="b06cff", eyeStyle="big", glowEyes=True)
def _spooky(m, A):
    purple = (130, 70, 200)
    cone_hat(m, A, [(60, 40, 90), (60, 40, 90), purple, (60, 40, 90), (60, 40, 90)], h=1.8, w=1.3, tilt=-0.25, brim=1.25)
    a = G(A)
    box(m, (0, a.hy, a.top + 0.3), (1.35, 1.35, 0.2), purple, "H", "Band", studs=False)


@cat("Leaf Hat", shape="Loaf", fur="9fd88a", second="f0fae8", eyes="7a4ad8")
def _leafhat(m, A):
    a = G(A)
    ears_out(m, A)
    leaf = (70, 170, 70)
    fr = about((0, a.hy, a.top), R(0.15, "X") @ R(-0.1, "Y"))
    plate(m, (0, a.hy, a.top + 0.15), (a.hw * 1.2, a.hd * 1.5, 0.14), leaf, "H", "Leaf", fr=fr)
    box(m, (0, a.hy, a.top + 0.25), (0.12, a.hd * 1.4, 0.08), (40, 120, 40), "H", "Vein", fr=fr, studs=False)
    for k in (-1, 0, 1):
        box(m, (0.35, a.hy + k * 0.6, a.top + 0.25), (0.7, 0.08, 0.06), (40, 120, 40), "H", "Vein", studs=False,
            fr=fr @ about((0, a.hy + k * 0.6, a.top + 0.25), R(0.5, "Z")))
    box(m, (0, a.hy + a.hd * 0.8, a.top + 0.3), (0.15, 0.5, 0.15), (90, 70, 40), "H", "Stem", fr=fr, studs=False)


@cat("Mushroom Hat", shape="Fluffy", fur="ffe6bc", second="fffaf0", eyes="52d273", blush=True)
def _mushroom(m, A):
    a = G(A)
    ears_out(m, A)
    red = (225, 50, 60)
    stack(m, (0, a.hy, a.top), a.hw * 1.15, a.hw * 0.55, 1.0, 3, red, d0=a.hd * 1.15, d1=a.hd * 0.55)
    for x, y, z in ((-0.9, -0.4, 0.2), (0.7, -0.6, 0.2), (0.0, -0.2, 0.9), (-0.5, -0.65, 0.55), (0.9, 0.3, 0.3), (0.45, -0.75, 0.55)):
        box(m, (x, a.hy + y * a.hd * 0.8, a.top + z), (0.32, 0.32, 0.32), WHITE, "H", "Dot", studs=False)


@cat("Fruit Hat", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="52d273")
def _fruithat(m, A):
    a = G(A)
    ears_out(m, A)
    straw = (220, 175, 100)
    box(m, (0, a.hy, a.top + 0.35), (a.hw * 0.85, a.hd * 0.85, 0.7), straw, "H", "Basket")
    for z in (0.15, 0.55):
        box(m, (0, a.hy, a.top + z), (a.hw * 0.87, a.hd * 0.87, 0.1), shade(straw, 0.8), "H", "Basket", studs=False)
    for c, p, r in (((230, 40, 50), (-0.5, -0.3), 0.38), ((255, 200, 40), (0.4, -0.2), 0.42), ((120, 60, 160), (0.0, 0.35), 0.36),
                    ((80, 190, 80), (-0.4, 0.4), 0.33), ((255, 140, 40), (0.6, 0.4), 0.36)):
        ball(m, (p[0], a.hy + p[1], a.top + 0.8 + r * 0.5), r, c, "H", "Fruit")
    box(m, (0.4, a.hy - 0.2, a.top + 1.45), (0.08, 0.08, 0.35), (90, 70, 40), "H", "Stem", studs=False)


@cat("Paper Crown", shape="Loaf", fur="ff9a3c", second="fff0d8", eyes="3c96ff", pattern="tabby", patternColor="d9681f")
def _papercrown(m, A):
    crown(m, A, (255, 215, 60), gems=((255, 90, 120), (70, 170, 255), (90, 200, 90)), w=0.8, h=0.5, tips=5)


@cat("Diamond Collar", shape="Slim", fur="e4e7ef", second="ffffff", eyes="7ec8ff", eyeStyle="big")
def _diamondcollar(m, A):
    a = G(A)
    collar(m, A, (180, 120, 255), h=0.3)
    for k in range(7):
        x = -a.hw * 0.39 + k * a.hw * 0.13
        box(m, (x, a.front - 0.1, a.hb + 0.18), (0.22, 0.14, 0.22), (200, 240, 255), "H", "Gem", studs=False, emit=0.7,
            fr=about((x, a.front - 0.1, a.hb + 0.18), R(0.785, "Y")))
    box(m, (0, a.front - 0.14, a.hb - 0.15), (0.42, 0.14, 0.42), (200, 240, 255), "H", "Gem", studs=False, emit=1.0,
        fr=about((0, a.front - 0.14, a.hb - 0.15), R(0.785, "Y")))
    fx(m, A, "orbit", "gem", [(200, 240, 255), (230, 200, 255)], n=6, s=0.4, emit=1.5)


@cat("Pigtails", shape="Fluffy", fur="ffe6bc", second="fffaf0", eyes="3c96ff", blush=True)
def _pigtails(m, A):
    a = G(A)
    remove(m, ("Ear", "EarIn"))
    hair = (120, 75, 45)
    box(m, (0, a.hy + 0.1, a.top + 0.12), (a.hw + 0.1, a.hd + 0.1, 0.3), hair, "H", "Hair")
    box(m, (0, a.hy + a.hd / 2 + 0.05, a.hz + 0.3), (a.hw + 0.1, 0.2, a.hh * 0.6), hair, "H", "Hair", studs=False)
    for x in (-1, 1):
        box(m, (x * a.hw * 0.24, a.front - 0.05, a.top - 0.2), (a.hw * 0.45, 0.14, 0.4), hair, "H", "Fringe", studs=False)
        hx = x * (a.hw / 2 + 0.45)
        box(m, (hx, a.hy + 0.2, a.hz + 0.2), (0.7, 0.8, 0.8), hair, "H", "Tail")
        box(m, (hx + x * 0.15, a.hy + 0.25, a.hz - 0.5), (0.6, 0.7, 0.8), hair, "H", "Tail")
        bow(m, (x * (a.hw / 2 + 0.25), a.hy - 0.25, a.hz + 0.55), (255, 110, 160), 0.6)


DESIGNS_ALL = DESIGNS
for _name, _entry in DESIGNS.items():
    blockcat.DESIGNS[_name] = _entry
