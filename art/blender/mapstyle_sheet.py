"""Renders the three map style looks (mapstyle.py) and the comparison sheet into art/preview/mapstyle/.
Run:  blender -b --factory-startup -P art/blender/mapstyle_sheet.py -- <pillow path> [looks, e.g. AC] [samples]
Writes style_A.png / style_B.png / style_C.png (1400 x 900) and, when all three exist, styles_sheet.png.
"""
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])
ONLY = args[1] if len(args) > 1 else "ABC"
SAMPLES = int(args[2]) if len(args) > 2 else 64

import bpy  # noqa: E402

import mapstyle  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "preview", "mapstyle"))
os.makedirs(OUT, exist_ok=True)
TITLES = {"A": "A  LEGO bricks", "B": "B  Pixel voxel", "C": "C  Cute toy blocks"}
W, H = 1400, 900

for look in ONLY:
    t = time.time()
    sc = mapstyle.setup(SAMPLES, W, H)
    mapstyle.build(look)
    mapstyle.camera()
    raw = os.path.join(OUT, f"_raw_{look}.png")
    sc.render.filepath = raw
    bpy.ops.render.render(write_still=True)
    print("rendered", look, "%.0f s" % (time.time() - t), len(bpy.data.objects), "objects")

from PIL import Image, ImageDraw, ImageFont  # noqa: E402


def sky(w, h):
    top, bot = (138, 200, 250), (228, 244, 255)
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
    return im.convert("RGBA")


for look in ONLY:
    raw = os.path.join(OUT, f"_raw_{look}.png")
    im = Image.alpha_composite(sky(W, H), Image.open(raw).convert("RGBA")).convert("RGB")
    im.save(os.path.join(OUT, f"style_{look}.png"))
    os.remove(raw)

paths = [os.path.join(OUT, f"style_{k}.png") for k in "ABC"]
if all(os.path.exists(p) for p in paths):
    cw, ch, gap, lab = 780, 501, 18, 64
    sheet = Image.new("RGB", (3 * cw + 4 * gap, lab + ch + gap), (236, 240, 247))
    d = ImageDraw.Draw(sheet)
    try:
        big = ImageFont.truetype("arialbd.ttf", 36)
        font = ImageFont.truetype("arialbd.ttf", 30)
    except OSError:
        big = font = ImageFont.load_default()
    for i, (k, p) in enumerate(zip("ABC", paths)):
        x0 = gap + i * (cw + gap)
        sheet.paste(Image.open(p).resize((cw, ch), Image.LANCZOS), (x0, lab))
        letter, name = TITLES[k].split("  ")
        d.text((x0 + 4, 14), letter, fill=(70, 90, 200), font=big)
        d.text((x0 + 40, 18), name, fill=(40, 44, 70), font=font)
    sheet.save(os.path.join(OUT, "styles_sheet.png"))
    print("sheet written")
