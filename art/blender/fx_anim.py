"""V5j animation preview of the approved effect looks (developer 2026-11-09):
  Mythical (A): the items orbit the cat, twinkles pulse in place.
  Secret (B): the same, and every 3 s two ribbons of light shoot up from the magic circle and fade.
Run: blender -b --factory-startup -P art/blender/fx_anim.py -- <pillow path> [cell px] [fps]
Writes art/preview/cats_v1/fx_anim.gif (3 s loop, the two cats side by side).
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
args = sys.argv[sys.argv.index("--") + 1:]
sys.path.insert(0, args[0])
CELL = int(args[1]) if len(args) > 1 else 420
FPS = int(args[2]) if len(args) > 2 else 12

import bpy  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

import blockcat  # noqa: E402
import catalog  # noqa: E402,F401
import cateffects  # noqa: E402
import catparts  # noqa: E402
import fxshapes  # noqa: E402
import kit  # noqa: E402

OUT = os.path.join(HERE, "..", "preview", "cats_v1")
CATS = [("Dragon Cat", "Mythical"), ("Star Emperor Cat", "Secret")]
SECONDS = 3.0
SPIN = math.pi / 2 / SECONDS  # a quarter turn a loop: the items line up again, so the loop has no jump
DIRECTION = Vector((-0.95, -0.85, 0.42)).normalized()
GROUND = ("Fx_GroundGlow", "Fx_GroundRing", "Fx_Circle", "Fx_Rune")
frames_all = []

for name, tier in CATS:
    sc = kit.new_scene()
    sc.cycles.samples = 14
    sc.render.resolution_x = sc.render.resolution_y = CELL
    m = blockcat.build(name)
    a = catparts.G(m.A)
    cx, cy = 0.0, a.by - 0.3
    base_r = max(a.bw, a.bl) / 2 + 1.5
    key = cateffects.KEY_OF[name]
    cols = [fxshapes.C(c) for c in cateffects.STYLE[key][0]["cols"]]
    for o in list(m.objects):
        if o.name.split(".")[0] in ("Fx_Swirl", "Fx_SwirlGlow"):
            m.objects.remove(o)
            bpy.data.objects.remove(o)
    spinning, twinkles = [], []
    for o in m.objects:
        n = o.name.split(".")[0]
        if not n.startswith("Fx") or n in GROUND:
            continue
        (twinkles if n.startswith("Fx_Twinkle") else spinning).append((o, o.matrix_world.copy()))
    center = Vector((0, cy, (a.top + 1.4) / 2))
    radius = math.hypot(base_r * 1.1, (a.top + 1.6) / 2) * 1.02
    cam = bpy.data.cameras.new("Cam")
    cam.lens = 50
    co = bpy.data.objects.new("Cam", cam)
    co.location = center + DIRECTION * (radius / math.sin(math.atan(18 / 50)))
    co.rotation_euler = (center - co.location).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(co)
    sc.camera = co
    piv = Matrix.Translation((cx, cy, 0))
    frames = []
    for f in range(int(SECONDS * FPS)):
        t = f / FPS
        spin = piv @ Matrix.Rotation(t * SPIN, 4, "Z") @ piv.inverted()
        for o, rest in spinning:
            o.matrix_world = spin @ rest
        for i, (o, rest) in enumerate(twinkles):
            c = rest.translation
            k = 0.65 + 0.35 * math.sin(t * 2 * math.pi + i * 1.7)  # one pulse a second
            o.matrix_world = Matrix.Translation(c) @ Matrix.Scale(k, 4) @ Matrix.Translation(-c) @ rest
        made = []
        if tier == "Secret":
            u = t / SECONDS
            head = min(1.0, u / 0.35) ** 0.8
            tail = max(0.0, min(1.0, (u - 0.18) / 0.4))
            fade = 1.0 if u < 0.45 else max(0.0, 1 - (u - 0.45) / 0.2)
            before = set(m.objects)
            fxshapes.swirl(m, cx, cy, base_r, 0.2, a.top + 1.0, cols if len(cols) > 1 else cols * 2, 2.5, tail=tail, head=head,
                           fade=fade)
            made = [o for o in m.objects if o not in before]
        p = os.path.join(OUT, f"_anim_{name.replace(' ', '')}_{f:03d}.png")
        sc.render.filepath = p
        bpy.ops.render.render(write_still=True)
        frames.append(p)
        for o in made:
            m.objects.remove(o)
            bpy.data.objects.remove(o)
        print("frame", name, f)
    frames_all.append((name, tier, frames))

from PIL import Image, ImageDraw, ImageFont  # noqa: E402

try:
    font = ImageFont.truetype("tahomabd.ttf", 20)
except OSError:
    font = ImageFont.load_default()
gif = []
for i in range(len(frames_all[0][2])):
    im = Image.new("RGB", (CELL * len(frames_all), CELL + 36), (212, 220, 234))
    dr = ImageDraw.Draw(im)
    for k, (name, tier, frames) in enumerate(frames_all):
        im.paste(Image.open(frames[i]).convert("RGB"), (k * CELL, 36))
        label = "Mythical: ของลอยหมุนรอบตัว" if tier == "Mythical" else "Secret: เกลียวแสงพุ่งขึ้นทุก 3 วินาที"
        dr.text((k * CELL + 12, 7), label, fill=(40, 44, 70), font=font)
    gif.append(im.convert("P", palette=Image.ADAPTIVE, colors=200))
out = os.path.join(OUT, "fx_anim.gif")
gif[0].save(out, save_all=True, append_images=gif[1:], duration=int(1000 / FPS), loop=0)
for _, _, frames in frames_all:
    for p in frames:
        os.remove(p)
print("wrote", out)
