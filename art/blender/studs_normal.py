"""The LEGO studs normal map for the block cats (V5h, Config.Cats.Studs = "variant").
Run: <blender python> -I art/blender/studs_normal.py <pillow path>
Writes art/export/CatStuds_Normal.png: one stud per tile (256 px), tangent-space normals (OpenGL, +Y up), the
same stud as blockcat.py (radius 0.13 on a 0.42 grid). The developer uploads it to the group and puts its id
into the MaterialVariants (docs/DEVELOPER_TODO.md).
"""
import math
import os
import sys

sys.path.insert(0, sys.argv[1])
from PIL import Image  # noqa: E402

N = 256
R = 0.13 / 0.42  # stud radius in tiles
EDGE = 0.045  # the rounded rim
img = Image.new("RGB", (N, N))
px = img.load()
for j in range(N):
    for i in range(N):
        x = (i + 0.5) / N - 0.5
        y = 0.5 - (j + 0.5) / N
        d = math.hypot(x, y)
        nx = ny = 0.0
        if R - EDGE < d < R + EDGE:
            # the rim: normals lean outwards (a soft bump round the stud)
            t = (d - (R - EDGE)) / (2 * EDGE)
            k = math.sin(t * math.pi) * 0.85
            nx, ny = x / d * k, y / d * k
        elif d >= R + EDGE and d < R + EDGE * 2.2:
            # a small shadow ring on the plate
            t = (d - R - EDGE) / (EDGE * 1.2)
            k = -math.sin(min(1, t) * math.pi) * 0.25
            nx, ny = x / d * k, y / d * k
        nz = math.sqrt(max(0.0, 1 - nx * nx - ny * ny))
        px[i, j] = (int((nx * 0.5 + 0.5) * 255), int((ny * 0.5 + 0.5) * 255), int((nz * 0.5 + 0.5) * 255))
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "export", "CatStuds_Normal.png")
img.save(out)
print("wrote", out)
