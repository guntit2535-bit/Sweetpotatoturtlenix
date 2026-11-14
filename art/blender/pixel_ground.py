"""X4 (map restyle, look B): the ground texture: 8 x 8 studs of pixel noise with a LEGO stud on every stud, grey so
the game tints it with each tile's colour (Texture.Color3 = the tile's checker colour), seamless when tiled.
Writes art/export/PixelGround.png (512 px, 64 px a stud). Run with any Python that has Pillow, e.g.
  "C:/Program Files/Blender Foundation/Blender 5.2/5.2/python/bin/python.exe" -I art/blender/pixel_ground.py <pylib>
"""
import os
import random
import sys

if len(sys.argv) > 1:
    sys.path.insert(0, sys.argv[1])

from PIL import Image, ImageDraw  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "export", "PixelGround.png")
STUDS = 8
PX = 64  # pixels per stud
SIZE = STUDS * PX

rng = random.Random(4)
img = Image.new("RGB", (SIZE, SIZE))
d = ImageDraw.Draw(img)


def grey(v):
    v = max(0, min(255, int(v)))
    return (v, v, v)


for sy in range(STUDS):
    for sx in range(STUDS):
        # the pixel: one of 3 shades (like look B's 3 greens), a stud wide
        base = rng.choice((255, 238, 222))
        x0, y0 = sx * PX, sy * PX
        d.rectangle([x0, y0, x0 + PX - 1, y0 + PX - 1], fill=grey(base))
        # a soft edge line between pixels so the grid reads
        d.line([x0, y0, x0 + PX - 1, y0], fill=grey(base - 18), width=2)
        d.line([x0, y0, x0, y0 + PX - 1], fill=grey(base - 18), width=2)
        # the LEGO stud: shadow down-right, the stud, a light rim up-left, a small shine
        cx, cy, r = x0 + PX / 2, y0 + PX / 2, PX * 0.3
        d.ellipse([cx - r + 3, cy - r + 4, cx + r + 3, cy + r + 4], fill=grey(base - 34))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=grey(base - 6))
        d.ellipse([cx - r * 0.45, cy - r * 0.55, cx - r * 0.05, cy - r * 0.2], fill=grey(min(255, base + 24)))

img.save(OUT)
print("written", OUT)
