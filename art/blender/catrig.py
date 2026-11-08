"""Bones and animation for the block cats (round 2). Every block of a cat belongs to one bone with the same
names as the game's cat rig (shared/CatModel: Body > Head, Tail1 > Tail2, LegFL / LegFR / LegBL / LegBR,
WingL / WingR) plus "Fx" for the effect around the body, so the game's cat animation code moves them.

  rig(model, A) -> Rig       sorts the blocks into bones and finds each bone's pivot
  Rig.pose(t, kind)          poses the cat at time t (seconds): kind "walk" or "idle"
"""
import math

from mathutils import Matrix, Vector

from kit import R

HEAD_NAMES = {"Head", "Ear", "EarIn", "Muzzle", "Nose", "Mouth", "Eye", "Iris", "Shine", "Blush", "Cheek", "Frame", "Lens",
              "Glint", "Arm", "HatBrim", "HatTop", "HatCorner", "Trim", "Badge", "Toe", "Patch", "Strap", "Earring", "Horn",
              "Crown", "CrownTip", "Halo", "Glow", "Fire", "Stem", "Leaf"}
FX_NAMES = {"Sparkle", "FxFlame", "Aura", "Heart"}
WING_NAMES = {"Wing", "WingBone", "WingSkin", "Feather"}
LEG_NAMES = {"Leg", "Paw", "Anklet", "Hilt", "Guard", "Blade"}
CHILDREN = ["Head", "Tail1", "LegFL", "LegFR", "LegBL", "LegBR", "WingL", "WingR"]


def base_name(obj):
    return obj.name.split(".")[0]


class Rig:
    def __init__(self, model, A):
        self.A = A
        self.bones = {}
        self.rest = {o: o.matrix_world.copy() for o in model.objects}
        by, bz, leg, bh = A["by"], A["bz"], A["leg"], A["bh"]
        paws = A["paws"]  # order: (-x, front), (-x, back), (+x, front), (+x, back)
        self.pivot = {
            "Body": Vector((0, by, bz)),
            "Head": Vector((0, A["hy"] + A["hd"] * 0.25, leg + bh)),
            "Tail1": Vector((0, by + A["bl"] / 2, bz + 0.1)),
            "Tail2": A["tail"][1] - Vector((0, 0, 0.4)),
            "LegFL": Vector((paws[0].x, paws[0].y, leg)),
            "LegBL": Vector((paws[1].x, paws[1].y, leg)),
            "LegFR": Vector((paws[2].x, paws[2].y, leg)),
            "LegBR": Vector((paws[3].x, paws[3].y, leg)),
            "WingL": Vector((-A["bw"] / 2, by + 0.1, bz + bh / 2)),
            "WingR": Vector((A["bw"] / 2, by + 0.1, bz + bh / 2)),
            "Fx": Vector((0, by, 0)),
        }
        for o in model.objects:
            self.bones.setdefault(self.classify(o), []).append(o)

    def classify(self, o):
        A = self.A
        n = base_name(o)
        c = o.matrix_world.translation if not o.data.vertices else sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
        flat_dist = math.hypot(c.x, c.y - A["by"])
        if n in FX_NAMES or (n == "Gem" and flat_dist > A["bw"] / 2 + 1.2):
            return "Fx"
        if n in WING_NAMES:
            return "WingL" if c.x < 0 else "WingR"
        if n in LEG_NAMES:
            front = c.y < A["by"]
            return ("LegF" if front else "LegB") + ("L" if c.x < 0 else "R")
        if n in ("Tail", "TailSpike"):
            return "Tail1" if c.z < A["bz"] + 0.5 else "Tail2"
        if n in HEAD_NAMES or (c.z > A["leg"] + A["bh"] - 0.05 and c.y < A["hy"] + A["hd"] / 2 + 1.2):
            return "Head"
        return "Body"

    def _about(self, bone, rot):
        p = self.pivot[bone]
        return Matrix.Translation(p) @ rot @ Matrix.Translation(-p)

    def pose(self, t, kind="walk"):
        ph = 2 * math.pi * t
        walk = kind == "walk"
        body = Matrix.Translation((0, 0, 0.1 * math.sin(2 * ph) if walk else 0.04 * math.sin(ph))) @ self._about("Body", R(0.03 * math.sin(ph), "Y"))
        legs = 0.45 * math.sin(ph) if walk else 0.0
        local = {
            "Body": Matrix(),
            "Head": self._about("Head", R(0.07 * math.sin(2 * ph), "X") @ R(0.1 * math.sin(ph * 0.5), "Z")),
            "Tail1": self._about("Tail1", R(0.25 * math.sin(ph), "Y")),
            "LegFL": self._about("LegFL", R(legs, "X")),
            "LegBR": self._about("LegBR", R(legs, "X")),
            "LegFR": self._about("LegFR", R(-legs, "X")),
            "LegBL": self._about("LegBL", R(-legs, "X")),
            "WingL": self._about("WingL", R(-0.35 * math.sin(2 * ph), "Y")),
            "WingR": self._about("WingR", R(0.35 * math.sin(2 * ph), "Y")),
        }
        tail2 = self._about("Tail2", R(0.35 * math.sin(ph - 0.7), "Y"))
        for bone, objs in self.bones.items():
            if bone == "Fx":
                m = Matrix()
            elif bone == "Tail2":
                m = body @ local["Tail1"] @ tail2
            else:
                m = body @ local.get(bone, Matrix())
            for i, o in enumerate(objs):
                rest = self.rest[o]
                if bone == "Fx":
                    # effects: orbit round the cat, flames flicker
                    orbit = self._about("Fx", R(ph * 0.5, "Z"))
                    c = rest.translation
                    k = 1 + 0.3 * math.sin(4 * ph + i * 1.7)
                    flick = Matrix.Translation(c) @ Matrix.Scale(k, 4) @ Matrix.Translation(-c)
                    o.matrix_world = orbit @ flick @ rest
                else:
                    o.matrix_world = m @ rest


def rig(model, A):
    return Rig(model, A)
