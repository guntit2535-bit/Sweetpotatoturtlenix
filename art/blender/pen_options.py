# -*- coding: utf-8 -*-
# Run with the Pillow path and the output: python pen_options.py <pillow path> art/preview/pens/pen_options.png
# W7 (revision 3 item 15): top view of one pen in the lobby, to scale, with today's pen and 3 bigger options.
import math
import sys

sys.path.insert(0, sys.argv[1])
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

OUT = sys.argv[2]
S = 5.0  # px per stud
W, H = 1500, 980
FONT = ImageFont.truetype("C:/Windows/Fonts/tahomabd.ttf", 26)
SMALL = ImageFont.truetype("C:/Windows/Fonts/tahoma.ttf", 19)

LOBBY, PLAZA, ROAD_W = 150, 46, 16
# options: (label, front radius, depth, width, colour)
TODAY = ("ตอนนี้", 83, 34, 40)
OPTS = [
    ("A  ใหญ่ขึ้น x1.8", 83, 46, 42, (60, 150, 255)),
    ("B  ใหญ่ขึ้น x2.5 (แนะนำ)", 83, 56, 44, (40, 190, 80)),
    ("C  ใหญ่สุด x2.9", 83, 60, 46, (255, 140, 40)),
]


def area(d, w):
    return (w - 6) * (d - 16)  # the cats' walking area (PenService "Area")


def panel(ox, title, opt):
    im = Image.new("RGB", (W // 2 - 10, H // 2 - 10), (126, 204, 96))
    d = ImageDraw.Draw(im)
    cx, cy = im.width / 2, im.height - 40  # the pen's angle points up; map centre is below the panel

    def pt(r, a):  # radius, angle (deg) from the pen's centre line
        t = math.radians(a)
        return (cx + math.sin(t) * r * S, im.height - 12 - (math.cos(t) * r - 64) * S)

    # lobby edge, plaza, roads (at +-22.5 degrees)
    for r, col, wdt in ((LOBBY, (255, 220, 60), 6), (PLAZA, (220, 220, 230), 0)):
        pts = [pt(r, a) for a in range(-40, 41, 2)]
        if wdt:
            d.line(pts, fill=col, width=wdt)
        else:
            d.polygon(pts + [pt(0, 40), pt(0, -40)], fill=col)
    for side in (-1, 1):
        a = side * 22.5
        for r0 in range(PLAZA, LOBBY, 2):
            p0 = pt(r0, a)
            d.ellipse([p0[0] - ROAD_W / 2 * S, p0[1] - ROAD_W / 2 * S, p0[0] + ROAD_W / 2 * S, p0[1] + ROAD_W / 2 * S], fill=(236, 226, 205))

    def rect(front, depth, width, col, fill=None, w=4):
        x0, x1 = cx - width / 2 * S, cx + width / 2 * S
        y0, y1 = pt(front, 0)[1], pt(front + depth, 0)[1]
        d.rectangle([x0, y1, x1, y0], outline=col, fill=fill, width=w)
        return x0, x1, y0, y1

    # today's pen (grey dashed look) and the option
    lab, front, depth, width = TODAY
    if opt:
        name, f2, d2, w2, col = opt
        x0, x1, y0, y1 = rect(f2, d2, w2, col, fill=(170, 230, 140), w=5)
        # cat area and the house at the back
        d.rectangle([cx - (w2 - 6) / 2 * S, pt(f2 + 2, 0)[1] - (d2 - 16) * S, cx + (w2 - 6) / 2 * S, pt(f2 + 2, 0)[1]], outline=(255, 255, 255), width=2)
        hy = pt(f2 + d2 - 6, 0)[1]
        d.rectangle([cx - 6 * S, hy - 4 * S, cx + 6 * S, hy + 4 * S], fill=(250, 240, 220), outline=(90, 70, 60), width=2)
        rect(front, depth, width, (90, 90, 90), w=2)
    else:
        x0, x1, y0, y1 = rect(front, depth, width, (90, 90, 90), fill=(170, 230, 140), w=5)
        d.rectangle([cx - (width - 6) / 2 * S, pt(front + 2, 0)[1] - (depth - 16) * S, cx + (width - 6) / 2 * S, pt(front + 2, 0)[1]], outline=(255, 255, 255), width=2)
        hy = pt(front + depth - 6, 0)[1]
        d.rectangle([cx - 6 * S, hy - 4 * S, cx + 6 * S, hy + 4 * S], fill=(250, 240, 220), outline=(90, 70, 60), width=2)
    # gym in front: treadmill left, weights right
    for x, col in ((-12, (40, 50, 110)), (12, (230, 80, 120))):
        gy = pt(front - 8, 0)[1]
        d.rectangle([cx + x * S - 3 * S, gy - 4 * S, cx + x * S + 3 * S, gy + 4 * S], fill=col)
    # trees between the pens
    for side in (-1, 1):
        p0 = pt(136, side * 15)
        d.ellipse([p0[0] - 18, p0[1] - 18, p0[0] + 18, p0[1] + 18], fill=(46, 140, 60), outline=(30, 90, 40), width=2)
    d.text((14, 10), title, fill=(30, 30, 50), font=FONT)
    o = opt or (None, front, depth, width)
    a = area(o[2], o[3])
    d.text((14, 46), f"คอก {o[3]} x {o[2]} สตั๊ด · ที่แมวเดิน {a:,} ตร.สตั๊ด", fill=(30, 30, 50), font=SMALL)
    d.text((14, 72), f"= x{a / area(depth, width):.1f} ของตอนนี้ · 60 ตัว = {a / 60:.0f} ตร.สตั๊ด/ตัว", fill=(30, 30, 50), font=SMALL)
    return im


sheet = Image.new("RGB", (W, H), (40, 44, 70))
tiles = [panel(0, "ตอนนี้", None)] + [panel(0, o[0], o) for o in OPTS]
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % 2) * (W // 2) + 5, (i // 2) * (H // 2) + 5))
sheet.save(OUT)
print("wrote", OUT)
