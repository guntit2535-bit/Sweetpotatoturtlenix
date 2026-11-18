"""Revision list 6 (client, 2026-11-18): hotbar pictures for the 50 rods, the shop button's gold coin, and a preview
of the new rods and the Galaxy crate.

  blender -b --factory-startup -P art/blender/rod_icons.py -- <pylib dir with Pillow> [first] [last]

Writes art/export/RodIcons/Rod<L>.png and RobuxCoin.png (256 x 256, transparent, a dark outline like the cat icons)
and art/preview/rev6_items.png (rods 26-50, the coin, the Galaxy crate). The rods come from items.rod (the same
builder the game's meshes are exported from), leaning 40 degrees so a long rod fills a square picture.
The coin is our own gold hexagon coin (a rim, an inner hexagon and a square in the middle), not a copied logo.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if args:
    sys.path.insert(0, args[0])
FIRST = int(args[1]) if len(args) > 1 else 1
LAST = int(args[2]) if len(args) > 2 else 50

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import crates_v2  # noqa: E402
import items  # noqa: E402
import kit  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "art", "export", "RodIcons")
PREVIEW = os.path.join(ROOT, "art", "preview", "rev6_items.png")
os.makedirs(OUT, exist_ok=True)
RES = 256
OUTLINE = (47, 53, 82)
OUTLINE_PX = 5


def scene():
    sc = kit.new_scene()
    g = bpy.data.objects.get("Ground")
    if g:
        bpy.data.objects.remove(g)
    for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
        try:
            sc.render.engine = engine
            break
        except Exception:
            pass
    sc.render.film_transparent = True
    try:
        sc.eevee.taa_render_samples = 24
    except Exception:
        pass
    return sc


def outline(path):
    from PIL import Image, ImageFilter
    im = Image.open(path).convert("RGBA")
    a = im.split()[3]
    grown = a.point(lambda v: 255 if v > 24 else 0).filter(ImageFilter.MaxFilter(OUTLINE_PX * 2 + 1))
    base = Image.new("RGBA", im.size, OUTLINE + (0,))
    base.putalpha(grown)
    base.alpha_composite(im)
    base.save(path)


def render(objs, path, direction, pad=1.08):
    kit.frame_camera(objs, path, direction=direction, lens=80, pad=pad, res=RES)
    outline(path)


def lean(objs, deg):
    turn = Matrix.Rotation(math.radians(deg), 4, "Y")
    for o in objs:
        o.matrix_world = turn @ o.matrix_world


def hexagon(r, n=6, rot=math.pi / 6):
    return [(r * math.cos(rot + k * 2 * math.pi / n), r * math.sin(rot + k * 2 * math.pi / n)) for k in range(n)]


def coin():
    m = kit.Model("RobuxCoin")
    gold, deep, shine = (255, 196, 40), (214, 138, 18), (255, 232, 130)
    face = Matrix.Rotation(math.radians(90), 4, "X")  # the coin stands up, facing -Y
    m.slab(hexagon(1.0), 0.32, gold, face, bevel=0.08, rough=0.25, coat=0.8)
    m.slab(hexagon(0.80), 0.06, deep, Matrix.Translation((0, -0.17, 0)) @ face, bevel=0.02, rough=0.3)
    m.slab(hexagon(0.66), 0.08, gold, Matrix.Translation((0, -0.19, 0)) @ face, bevel=0.03, rough=0.25, coat=0.8)
    sq = [(-0.24, -0.24), (0.24, -0.24), (0.24, 0.24), (-0.24, 0.24)]
    m.slab(sq, 0.06, (120, 70, 10), Matrix.Translation((0, -0.235, 0)) @ face, bevel=0.03, rough=0.4)
    m.blob((0.16, 0.03, 0.08), shine, Matrix.Translation((-0.42, -0.24, 0.5)) @ Matrix.Rotation(0.5, 4, "Y"), name="Shine", emit=0.6)
    return m


def main():
    done = []
    for L in range(FIRST, LAST + 1):
        scene()
        model = items.rod(L)
        lean(model.objects, -40)
        path = os.path.join(OUT, f"Rod{L}.png")
        render(model.objects, path, direction=(-0.15, -1.0, 0.25))
        done.append(path)
        print(f"[rods] Rod{L}", flush=True)
    scene()
    c = coin()
    coin_path = os.path.join(OUT, "RobuxCoin.png")
    render(c.objects, coin_path, direction=(-0.25, -1.0, 0.18), pad=1.05)
    scene()
    crate = crates_v2.crate("B", "Galaxy")
    crate_path = os.path.join(ROOT, "art", "preview", "_galaxy_crate.png")
    kit.frame_camera(crate.objects, crate_path, direction=(-0.8, -1.0, 0.6), res=RES, pad=1.05)
    # the preview: rods 26-50 (5 x 5), then the coin and the Galaxy crate
    from PIL import Image, ImageDraw
    cell = 150
    img = Image.new("RGBA", (6 * cell, 5 * cell), (110, 116, 128, 255))
    d = ImageDraw.Draw(img)
    for i, L in enumerate(range(26, 51)):
        p = os.path.join(OUT, f"Rod{L}.png")
        if not os.path.exists(p):
            continue
        x, y = (i % 5) * cell, (i // 5) * cell
        d.rectangle((x + 4, y + 4, x + cell - 4, y + cell - 4), fill=(90, 96, 108, 255))
        img.alpha_composite(Image.open(p).resize((cell - 12, cell - 12), Image.LANCZOS), (x + 6, y + 6))
        d.text((x + 10, y + 8), str(L), fill=(255, 255, 255, 255))
    for k, p in enumerate((coin_path, crate_path)):
        x, y = 5 * cell, k * 2 * cell + cell // 2
        d.rectangle((x + 4, y + 4, x + cell - 4, y + cell - 4), fill=(90, 96, 108, 255))
        img.alpha_composite(Image.open(p).convert("RGBA").resize((cell - 12, cell - 12), Image.LANCZOS), (x + 6, y + 6))
    img.save(PREVIEW)
    os.remove(crate_path)
    print("[rods] done", len(done), flush=True)


main()
