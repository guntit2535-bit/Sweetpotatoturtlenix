# Store item pictures from GPT -> 512 x 512 transparent PNGs for Creator Hub (passes / products).
# Reads art/source/gpt_items/*.webp|png, removes the background by a flood fill from the border (white, light
# grey and a painted checkerboard: light, low-saturation pixels; the dark navy outline stops the fill), crops,
# centres on a square with a small margin, and writes art/export/store_items/<Key>.png plus a review sheet.
# Needs Pillow:   python tools/gen/item_icons.py
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import sys

# default: the store items; `python item_icons.py ui` cuts the UI icons (P01-P12) instead
KIND = sys.argv[1] if len(sys.argv) > 1 else "items"
SRC = os.path.join(ROOT, "art", "source", "gpt_ui" if KIND == "ui" else "gpt_items")
OUT = os.path.join(ROOT, "art", "export", "ui_icons" if KIND == "ui" else "store_items")
SIZE = 512
MARGIN = 0.05


def is_bg(p):
    r, g, b, a = p
    if a < 16:
        return True
    lo, hi = min(r, g, b), max(r, g, b)
    # white / light grey (soft shadows), or the mid grey of a painted checkerboard
    return (lo >= 185 and hi - lo <= 28) or (lo >= 115 and hi - lo <= 12)


def cut(img):
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0))
        q.append((x, h - 1))
    for y in range(h):
        q.append((0, y))
        q.append((w - 1, y))
    while q:
        x, y = q.popleft()
        i = y * w + x
        if seen[i]:
            continue
        seen[i] = 1
        if not is_bg(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        if x > 0:
            q.append((x - 1, y))
        if x < w - 1:
            q.append((x + 1, y))
        if y > 0:
            q.append((x, y - 1))
        if y < h - 1:
            q.append((x, y + 1))
    return img


def square(img):
    box = img.getbbox()
    img = img.crop(box)
    w, h = img.size
    side = int(max(w, h) * (1 + 2 * MARGIN))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2), img)
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    done = []
    for name in sorted(os.listdir(SRC)):
        key, ext = os.path.splitext(name)
        if ext.lower() not in (".webp", ".png", ".jpg", ".jpeg"):
            continue
        if KIND == "ui" and not key.startswith("P"):
            continue  # the screen mockups are not icons
        icon = square(cut(Image.open(os.path.join(SRC, name))))
        icon.save(os.path.join(OUT, key + ".png"))
        done.append((key, icon))
    # review sheet: every icon on navy and on white
    cols = 5
    rows = (len(done) + cols - 1) // cols
    cell = 180
    sheet = Image.new("RGBA", (cols * cell, rows * cell * 2), (255, 255, 255, 255))
    for i, (_, icon) in enumerate(done):
        x, y = (i % cols) * cell, (i // cols) * cell * 2
        sheet.paste(Image.new("RGBA", (cell, cell), (27, 36, 64, 255)), (x, y))
        small = icon.resize((cell - 20, cell - 20), Image.LANCZOS)
        sheet.paste(small, (x + 10, y + 10), small)
        sheet.paste(small, (x + 10, y + cell + 10), small)
    sheet.save(os.path.join(OUT, "_review.png"))
    print(f"{len(done)} icons -> {OUT}")


if __name__ == "__main__":
    main()
