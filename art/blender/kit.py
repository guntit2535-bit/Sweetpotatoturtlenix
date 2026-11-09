"""Toy-model kit for SKY PUTT items (Blender as a Python module).

Every shape is a smooth surface built from math (lathe profiles, superellipsoids, tori, swept tubes),
so nothing looks like a plain block. 1 Blender unit = 1 stud. Front of a model = -Y, up = +Z.
"""
import math
import random

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

TAU = math.tau
RES = 1.0  # resolution factor: 1 = preview quality, ~0.5 = game (phones)


def res(n, low):
    return n if n <= low else max(low, int(round(n * RES)))


def srgb(c):
    def lin(v):
        v /= 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

    return (lin(c[0]), lin(c[1]), lin(c[2]), 1.0)


_mats = {}


def mat(rgb, rough=0.42, coat=0.0, emit=0.0, alpha=1.0):
    key = (tuple(rgb), rough, coat, emit, alpha)
    if key in _mats:
        return _mats[key]
    m = bpy.data.materials.new("M%d" % len(_mats))
    m.use_nodes = True
    p = m.node_tree.nodes["Principled BSDF"]
    p.inputs["Base Color"].default_value = srgb(rgb)
    p.inputs["Roughness"].default_value = rough
    p.inputs["Coat Weight"].default_value = coat
    if emit:
        p.inputs["Emission Color"].default_value = srgb(rgb)
        p.inputs["Emission Strength"].default_value = emit
    if alpha < 1:
        p.inputs["Alpha"].default_value = alpha
        p.inputs["Transmission Weight"].default_value = 0.6
    _mats[key] = m
    return m


def spow(x, e):
    return math.copysign(abs(x) ** e, x)


def spline(points):
    """Profile (t -> (x, r)) through points with Catmull-Rom smoothing; first/last r = 0 close it."""
    n = len(points) - 1

    def f(t):
        u = min(t * n, n - 1e-9)
        i = int(u)
        s = u - i
        p0, p1, p2, p3 = (points[max(i - 1, 0)], points[i], points[i + 1], points[min(i + 2, n)])
        out = []
        for k in range(2):
            a, b, c, d = p0[k], p1[k], p2[k], p3[k]
            out.append(0.5 * (2 * b + (c - a) * s + (2 * a - 5 * b + 4 * c - d) * s * s + (3 * b - a - 3 * c + d) * s ** 3))
        if t >= 1:
            out = list(points[-1])
        if t <= 0:
            out = list(points[0])
        return out[0], max(out[1], 0.0)

    return f


def smoothstep(a, b, x):
    t = min(max((x - a) / (b - a), 0), 1)
    return t * t * (3 - 2 * t)



def T(x, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def R(angle, axis):
    return Matrix.Rotation(angle, 4, axis)


def S(k):
    return Matrix.Scale(k, 4)


FRONT = R(math.pi / 2, "X")  # local Z -> -Y (a flat thing facing the viewer)


def prim(obj, kind, frame, size, **extra):
    """Remember what simple shape an object is (for exporters that turn it into a Roblox part): kind, the frame
    of its centre (in the object's local space, before matrix_world) and its full sizes along that frame."""
    obj["prim"] = kind
    obj["frame"] = [v for row in frame for v in row]
    obj["size"] = [float(v) for v in size]
    for k, v in extra.items():
        obj[k] = v


class Model:
    """A list of smooth parts that together make one item."""

    def __init__(self, name):
        self.name = name
        self.objects = []
        self.coll = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(self.coll)

    # -- core: rows of vertices -> object ------------------------------------------------------
    def surface(self, rows, color, closed_u=True, closed_v=False, pole_a=None, pole_b=None, name="Part", **mopts):
        bm = bmesh.new()
        grid = [[bm.verts.new(p) for p in row] for row in rows]
        nu = len(rows[0])
        span_u = nu if closed_u else nu - 1
        nrows = len(grid)
        span_v = nrows if closed_v else nrows - 1
        for j in range(span_v):
            a, b = grid[j], grid[(j + 1) % nrows]
            for i in range(span_u):
                k = (i + 1) % nu
                try:
                    bm.faces.new((a[i], a[k], b[k], b[i]))
                except ValueError:
                    pass
        if pole_a is not None:
            v = bm.verts.new(pole_a)
            for i in range(span_u):
                bm.faces.new((v, grid[0][(i + 1) % nu], grid[0][i]))
        if pole_b is not None:
            v = bm.verts.new(pole_b)
            for i in range(span_u):
                bm.faces.new((v, grid[-1][i], grid[-1][(i + 1) % nu]))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        return self.add(bm, color, name, **mopts)

    def add(self, bm, color, name="Part", smooth=True, solidify=0.0, **mopts):
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        for poly in mesh.polygons:
            poly.use_smooth = smooth
        obj = bpy.data.objects.new(name, mesh)
        obj.data.materials.append(mat(color, **mopts))
        obj["rgb"] = list(color)
        if solidify:
            mod = obj.modifiers.new("Solid", "SOLIDIFY")
            mod.thickness = solidify
            mod.offset = -1
        self.coll.objects.link(obj)
        self.objects.append(obj)
        return obj

    # -- shapes ----------------------------------------------------------------------------------
    def lathe(self, profile, color, frame=Matrix(), n_t=40, n_a=36, rmod=None, name="Lathe", **o):
        """Surface of revolution around local X. profile(t) -> (x, r), t in 0..1; ends with r ~ 0
        become poles. rmod(t, angle) multiplies the radius (grooves, bumps, waves)."""
        n_t, n_a = res(n_t, 4), res(n_a, 8)
        rows, pa, pb = [], None, None
        for j in range(n_t + 1):
            t = j / n_t
            x, r = profile(t)
            if r < 1e-4:
                p = frame @ Vector((x, 0, 0))
                if j == 0:
                    pa = p
                else:
                    pb = p
                continue
            row = []
            for i in range(n_a):
                a = TAU * i / n_a
                rr = r * (rmod(t, a) if rmod else 1)
                row.append(frame @ Vector((x, rr * math.cos(a), rr * math.sin(a))))
            rows.append(row)
        return self.surface(rows, color, pole_a=pa, pole_b=pb, name=name, **o)

    def blob(self, size, color, frame=Matrix(), e1=1.0, e2=1.0, nu=36, nv=20, warp=None, name="Blob", **o):
        """Superellipsoid with half-sizes size=(x, y, z): e=1 round, e<1 boxier (rounded box /
        rounded cylinder). warp(Vector) -> Vector deforms it in local space before `frame`."""
        sx, sy, sz = size
        nu, nv = res(nu, 8), res(nv, 5)
        rows = []
        for j in range(1, nv):
            th = -math.pi / 2 + math.pi * j / nv
            row = []
            for i in range(nu):
                ph = TAU * i / nu
                p = Vector((
                    sx * spow(math.cos(th), e1) * spow(math.cos(ph), e2),
                    sy * spow(math.cos(th), e1) * spow(math.sin(ph), e2),
                    sz * spow(math.sin(th), e1),
                ))
                row.append(frame @ (warp(p) if warp else p))
            rows.append(row)
        pa, pb = Vector((0, 0, -sz)), Vector((0, 0, sz))
        if warp:
            pa, pb = warp(pa), warp(pb)
        obj = self.surface(rows, color, pole_a=frame @ pa, pole_b=frame @ pb, name=name, **o)
        if not warp:
            prim(obj, "Blob", frame, (2 * sx, 2 * sy, 2 * sz), e=[float(e1), float(e2)])
        return obj

    def ball(self, center, radius, color, nu=24, nv=14, **o):
        return self.blob((radius,) * 3, color, Matrix.Translation(center), nu=nu, nv=nv, **o)

    def torus(self, R, r, color, frame=Matrix(), nu=72, nv=28, rfun=None, name="Torus", **o):
        """Torus around local Z. rfun(phi, psi) -> minor radius (psi 0 = outer equator, pi/2 = top)."""
        nu, nv = res(nu, 10), res(nv, 6)
        rows = []
        for j in range(nv):
            psi = TAU * j / nv
            row = []
            for i in range(nu):
                phi = TAU * i / nu
                rr = rfun(phi, psi) if rfun else r
                d = R + rr * math.cos(psi)
                row.append(frame @ Vector((d * math.cos(phi), d * math.sin(phi), rr * math.sin(psi))))
            rows.append(row)
        obj = self.surface(rows, color, closed_v=True, name=name, **o)
        if not rfun:
            prim(obj, "Torus", frame, (2 * (R + r), 2 * (R + r), 2 * r), R=float(R), r=float(r))
        return obj

    def tube(self, points, radius, color, n=12, caps=True, name="Tube", **o):
        """Tube along a polyline. radius: number or f(t)."""
        rf = radius if callable(radius) else (lambda t: radius)
        n = res(n, 6)
        pts = [Vector(p) for p in points]
        if RES < 1 and len(pts) > 4:
            keep = max(4, int(math.ceil(len(pts) * max(RES, 0.5))))
            pts = [pts[round(k * (len(pts) - 1) / (keep - 1))] for k in range(keep)]
        tang = []
        for k in range(len(pts)):
            a, b = pts[max(k - 1, 0)], pts[min(k + 1, len(pts) - 1)]
            tang.append((b - a).normalized())
        ref = Vector((0, 0, 1)) if abs(tang[0].z) < 0.9 else Vector((1, 0, 0))
        nrm = tang[0].cross(ref).normalized()
        rows = []
        for k, p in enumerate(pts):
            if k:
                nrm = (nrm - tang[k] * nrm.dot(tang[k])).normalized()
            bin_ = tang[k].cross(nrm)
            r = rf(k / (len(pts) - 1))
            rows.append([p + (nrm * math.cos(TAU * i / n) + bin_ * math.sin(TAU * i / n)) * r for i in range(n)])
        pa = pb = None
        if caps:
            # round caps: two extra rings + pole at each end
            ra, rb = rf(0), rf(1)
            t0, t1 = tang[0], tang[-1]
            ring_a = [pts[0] + (v - pts[0]) * 0.7 - t0 * ra * 0.7 for v in rows[0]]
            ring_b = [pts[-1] + (v - pts[-1]) * 0.7 + t1 * rb * 0.7 for v in rows[-1]]
            rows = [ring_a] + rows + [ring_b]
            pa, pb = pts[0] - t0 * ra, pts[-1] + t1 * rb
        return self.surface(rows, color, pole_a=pa, pole_b=pb, name=name, **o)

    def revolve(self, section, color, frame=Matrix(), n_a=48, rmod=None, name="Ring", **o):
        """Closed 2D section [(r, z), ...] revolved around local Z (rings, nuts, saucers, wheels).
        rmod(angle) multiplies the radius (hexagons, gear teeth, scallops)."""
        n_a = res(n_a, 10)
        rows = []
        for (r, z) in section:
            row = []
            for i in range(n_a):
                a = TAU * i / n_a
                k = rmod(a) if rmod else 1
                row.append(frame @ Vector((r * k * math.cos(a), r * k * math.sin(a), z)))
            rows.append(row)
        return self.surface(rows, color, closed_v=True, name=name, **o)

    def leaf(self, base, direction, length, width, color, thick=None, bend=0.0, up=(0, 0, 1), roll=0.0,
             fat=0.7, name="Leaf", **o):
        """Flat leaf / petal / feather / flame from `base` toward `direction`: widest at `fat` of the
        way, pointed tip, bent by `bend` toward its up side."""
        d = Vector(direction).normalized()
        u = Vector(up)
        if abs(d.dot(u.normalized())) > 0.98:
            u = Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 1, 0))
        side = d.cross(u).normalized()
        u = side.cross(d).normalized()
        rot = Matrix((d, side, u)).transposed().to_4x4() @ Matrix.Rotation(roll, 4, "X")
        frame = Matrix.Translation(Vector(base)) @ rot
        t_ = thick if thick is not None else width * 0.18

        def warp(p):
            x = (p.x / length + 0.5)  # 0 base .. 1 tip
            w = math.sin(math.pi * min(max(x, 0), 1) ** fat) ** 0.9
            return Vector((x * length, p.y * w, p.z * (0.35 + 0.65 * w) + bend * length * x * x))

        return self.blob((length / 2, width / 2, t_ / 2), color, frame, nu=24, nv=12, warp=warp, name=name, **o)

    def drop(self, base, direction, length, radius, color, tip=1.6, name="Drop", **o):
        """Teardrop (flame, drip, beak): round at `base`, pointed toward `direction`."""
        d = Vector(direction).normalized()
        frame = Matrix.Translation(Vector(base)) @ d.to_track_quat("X", "Z").to_matrix().to_4x4()

        def prof(t):
            if t >= 1:
                return length, 0.0
            if t < 0.25:
                r = radius * math.sqrt(max(0.0, 1 - ((0.25 - t) / 0.25) ** 2))
            else:
                r = radius * (1 - ((t - 0.25) / 0.75)) ** (1 / tip)
            return t * length, r

        return self.lathe(prof, color, frame, n_t=20, n_a=20, name=name, **o)

    def flame(self, base, direction, length, radius, color, wiggle=0.12, phase=0.0, side=(0, -1, 0), name="Flame", **o):
        """Cartoon flame tongue: round bottom, curvy pointed tip."""
        d = Vector(direction).normalized()
        sd = Vector(side).cross(d).normalized()
        pts = []
        for i in range(17):
            t = i / 16
            pts.append(Vector(base) + d * length * t + sd * wiggle * length * math.sin(phase + t * 5.5) * t)
        return self.tube(pts, lambda t: radius * (math.sin(math.pi * min(1, 0.3 + 0.7 * t)) ** 0.9 if t > 0 else 1) *
                         (1 - t) ** 0.35 if t < 1 else radius * 0.02, color, n=16, name=name, **o)

    def slab(self, outline, thick, color, frame=Matrix(), bevel=None, name="Slab", **o):
        """Flat shape from a 2D outline [(x, y), ...] (local XY, counter-clockwise), `thick` deep along local Z,
        with rounded edges."""
        bm = bmesh.new()
        verts = [bm.verts.new((x, y, -thick / 2)) for x, y in outline]
        face = bm.faces.new(verts)
        ext = bmesh.ops.extrude_face_region(bm, geom=[face])
        moved = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
        bmesh.ops.translate(bm, verts=moved, vec=(0, 0, thick))
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
        bmesh.ops.transform(bm, matrix=frame, verts=bm.verts[:])
        obj = self.add(bm, color, name, **o)
        mod = obj.modifiers.new("Round", "BEVEL")
        mod.width = bevel if bevel is not None else thick * 0.45
        mod.segments = max(2, res(4, 2))
        mod.limit_method = "NONE"
        mod.harden_normals = True
        tri = obj.modifiers.new("Tri", "TRIANGULATE")
        return obj

    # -- placing details on a surface -------------------------------------------------------------
    def bvh(self, obj):
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        tree = BVHTree.FromBMesh(bm)
        bm.free()
        return tree

    @staticmethod
    def hit(tree, point, direction):
        """Project `point` onto the surface along -direction (cast from outside)."""
        d = Vector(direction).normalized()
        loc, nor, _, _ = tree.ray_cast(Vector(point) + d * 5, -d)
        return loc, nor

    def stuck(self, tree, point, direction, size, color, sink=0.35, spin=0.0, name="Dot", **o):
        """An ellipsoid (size = half-sizes x, y along the surface, z out of it) stuck on the surface."""
        loc, nor = self.hit(tree, point, direction)
        if loc is None:
            return None
        z = nor.normalized()
        ref = Vector((0, 0, 1)) if abs(z.z) < 0.95 else Vector((0, 1, 0))
        x = ref.cross(z).normalized()
        y = z.cross(x)
        rot = Matrix((x, y, z)).transposed().to_4x4() @ Matrix.Rotation(spin, 4, "Z")
        frame = Matrix.Translation(loc + z * size[2] * (1 - 2 * sink)) @ rot
        return self.blob(size, color, frame, nu=16, nv=10, name=name, **o)

    def face(self, tree, center, out, s, up=(0, 0, 1), gap=1.5, cheeks=True, smile=True):
        """Cartoon face: eyes (with shine), cheeks, smile. out = direction the face looks."""
        out = Vector(out).normalized()
        upv = Vector(up)
        right = upv.cross(out).normalized() * -1  # viewer's right
        upv = out.cross(right).normalized() * -1
        c, _ = self.hit(tree, center, out)
        black, white, pink = (40, 32, 45), (255, 255, 255), (255, 140, 165)
        for side in (-1, 1):
            p = c + right * side * gap * s / 2 + upv * s * 0.15
            eye = self.stuck(tree, p, out, (s * 0.36, s * 0.48, s * 0.2), black, sink=0.3, rough=0.25, name="Eye")
            if eye:
                self.stuck(tree, p + upv * s * 0.2 - right * s * 0.1, out, (s * 0.13,) * 2 + (s * 0.08,), white,
                           sink=-0.9, rough=0.2, name="Shine")
            if cheeks:
                self.stuck(tree, c + right * side * (gap * s / 2 + s * 0.55) - upv * s * 0.5, out,
                           (s * 0.34, s * 0.2, s * 0.06), pink, sink=0.2, name="Cheek")
        if smile:
            pts = []
            for k in range(9):
                a = math.pi * (0.2 + 0.6 * k / 8)
                p = c + right * math.cos(a) * s * 0.42 - upv * (s * 0.35 + math.sin(a) * s * 0.28)
                loc, nor = self.hit(tree, p, out)
                pts.append(loc + nor * s * 0.02)
            self.tube(pts, s * 0.07, black, n=8, rough=0.3, name="Smile")

    def triangles(self):
        n = 0
        for o in self.objects:
            n += sum(len(p.vertices) - 2 for p in o.data.polygons) * (2 if o.modifiers else 1)
        return n


# -- scene / render --------------------------------------------------------------------------------
def new_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _mats.clear()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.render.resolution_x = sc.render.resolution_y = 900
    world = bpy.data.worlds.new("Sky")
    world.use_nodes = True
    nt = world.node_tree
    bg = nt.nodes["Background"]
    grad = nt.nodes.new("ShaderNodeTexGradient")
    coord = nt.nodes.new("ShaderNodeTexCoord")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    sep = nt.nodes.new("ShaderNodeSeparateXYZ")
    nt.links.new(coord.outputs["Generated"], sep.inputs[0])
    nt.links.new(sep.outputs["Z"], ramp.inputs[0])
    ramp.color_ramp.elements[0].position = 0.5
    ramp.color_ramp.elements[0].color = srgb((215, 238, 255))
    ramp.color_ramp.elements[1].color = srgb((120, 185, 250))
    nt.links.new(ramp.outputs[0], bg.inputs[0])
    bg.inputs[1].default_value = 1.0
    sc.world = world
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.2
    sun.angle = math.radians(8)
    so = bpy.data.objects.new("Sun", sun)
    so.rotation_euler = (math.radians(40), math.radians(-25), math.radians(-30))
    sc.collection.objects.link(so)
    # grass ground
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=60)
    me = bpy.data.meshes.new("Ground")
    bm.to_mesh(me)
    bm.free()
    g = bpy.data.objects.new("Ground", me)
    g.data.materials.append(mat((150, 205, 120), rough=0.9))
    sc.collection.objects.link(g)
    return sc


def frame_camera(objs, out, direction=(-0.55, -1.0, 0.42), lens=50, pad=1.12, res=900, below=None):
    """below: frame only the vertices lower than this height (a club's head)."""
    sc = bpy.context.scene
    sc.render.resolution_x = sc.render.resolution_y = res
    pts = []
    for o in objs:
        for v in o.data.vertices:
            pts.append(o.matrix_world @ v.co)
    if below is not None:
        pts = [p for p in pts if p.z < below] or pts
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    center = (lo + hi) / 2
    radius = max((p - center).length for p in pts)
    cam = bpy.data.cameras.new("Cam")
    cam.lens = lens
    fov = 2 * math.atan(18 / lens)
    dist = radius / math.sin(fov / 2) * pad
    d = Vector(direction).normalized()
    co = bpy.data.objects.new("Cam", cam)
    co.location = center + d * dist
    look = (center - co.location).normalized()
    co.rotation_euler = look.to_track_quat("-Z", "Y").to_euler()
    sc.collection.objects.link(co)
    sc.camera = co
    sc.render.filepath = out
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(co)


def drop_to_ground(model):
    zmin = min((o.matrix_world @ v.co).z for o in model.objects for v in o.data.vertices)
    for o in model.objects:
        o.location.z -= zmin
