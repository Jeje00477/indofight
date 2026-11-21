"""Bangun dan render properti skill dan ultimate di Blender (docs/decisions.md no. 23).

Dijalankan tanpa jendela:
  blender --background --factory-startup --python tools/blender/render_props.py -- <folder keluaran>

Tiap frame dirender dua kali pada 3x ukuran game: <nama>_<nomor>_c.png (warna) dan
_id.png (warna rata per bagian). tools/pack_props.py mengubahnya menjadi sprite sheet berpalet.

Satuan model adalah piksel game. Properti menghadap +X (kanan), lantai di z = 0.
"""
import math
import os
import sys

import bpy

SUPERSAMPLE = 3
_materials = {}
_id_colors = {}


def _linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _material(hex_color):
    if hex_color not in _materials:
        m = bpy.data.materials.new(hex_color)
        m.diffuse_color = tuple(_linear(int(hex_color[i:i + 2], 16) / 255) for i in (0, 2, 4)) + (1.0,)
        m.roughness = 1.0
        _materials[hex_color] = m
    return _materials[hex_color]


def _id_color(group):
    if group not in _id_colors:
        n = len(_id_colors) + 1
        _id_colors[group] = (((n * 37) % 16) / 15.0, ((n * 59) % 16) / 15.0, ((n * 83) % 16) / 15.0, 1.0)
    return _id_colors[group]


def joint(name, parent, loc=(0, 0, 0)):
    o = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(o)
    o.parent = parent
    o.location = loc
    return o


def _finish(parent, loc, color, group, scale=(1, 1, 1), rot=(0, 0, 0), smooth=True):
    o = bpy.context.active_object
    o.parent = parent
    o.location = loc
    o.scale = scale
    o.rotation_euler = [math.radians(a) for a in rot]
    o.data.materials.append(_material(color))
    if smooth:
        o.data.shade_smooth()
    o.color = _id_color(group)
    return o


def sphere(parent, loc, color, group, scale):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1.0, segments=20, ring_count=12)
    return _finish(parent, loc, color, group, scale)


def box(parent, loc, size, color, group, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    return _finish(parent, loc, color, group, size, rot, smooth=False)


def wheel_disc(parent, loc, radius, width, color, group):
    """Silinder dengan sumbu ke arah kamera (sumbu Y), untuk roda."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=radius, depth=width)
    return _finish(parent, loc, color, group, rot=(90, 0, 0))


def tube(parent, a, b, radius, color, group):
    """Batang lurus dari titik a ke titik b."""
    dx, dy, dz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    length = math.sqrt(dx * dx + dy * dy + dz * dz)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius, depth=length)
    o = _finish(parent, ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2), color, group)
    o.rotation_euler = (0, math.atan2(math.sqrt(dx * dx + dy * dy), dz), math.atan2(dy, dx))
    return o


# --- Properti -------------------------------------------------------------------

def _wheel(root, x, radius, tire, hub, group):
    """Roda dengan jeruji, supaya putarannya terlihat."""
    w = joint("wheel", root, (x, 0, radius))
    wheel_disc(w, (0, 0, 0), radius, 5.0, tire, group)
    wheel_disc(w, (0, 0, 0), radius * 0.56, 5.6, hub, group)
    box(w, (0, 0, 0), (radius * 1.5, 6.0, 1.6), tire, group)
    box(w, (0, 0, 0), (1.6, 6.0, radius * 1.5), tire, group)
    return w


def build_bekal():
    """Kotak bekal plastik merah bertutup terang, dilempar berputar seperti bumerang."""
    red, red_dark, lid, clip = "e8504a", "b3222b", "d8d8da", "f08a24"
    root = joint("root", None)
    spin = joint("spin", root, (0, 0, 8))
    # Dimiringkan ke arah kamera supaya tutupnya terlihat dari samping.
    tilt = joint("tilt", spin)
    tilt.rotation_euler = (math.radians(22), 0, 0)
    turn = joint("turn", tilt)
    box(turn, (0, 0, -1.5), (20, 13, 7), red, "body")
    box(turn, (0, 0, -5.4), (17, 10.5, 1.6), red_dark, "body")
    box(turn, (0, 0, 2.6), (22, 15, 2.4), lid, "lid")
    box(turn, (0, 0, 4.2), (13, 7, 1.4), lid, "lid")
    box(turn, (11.2, 0, 1.0), (1.8, 5.5, 3.6), clip, "clip")
    box(turn, (-11.2, 0, 1.0), (1.8, 5.5, 3.6), clip, "clip")
    frames = 8

    def pose(i):
        turn.rotation_euler = (0, 0, math.radians(i * 180.0 / frames))
    return {"size": (32, 24), "floor": 22, "frames": frames, "pose": pose, "yaw": 0.0}


def build_scooter():
    """Motor matic merah Emak-Emak (GDD 6.4): tameng depan, dek kaki, jok, dan lampu sein."""
    red, red_dark, red_light = "e8504a", "b3222b", "ffcf4a"
    tire, metal, lamp, sein_off, sein_on = "4f4f52", "d8d8da", "ffcf4a", "f08a24", "ffcf4a"
    root = joint("root", None)
    wheels = [_wheel(root, -26, 10, tire, metal, "wheel_b"), _wheel(root, 28, 10, tire, metal, "wheel_f")]
    # Badan belakang, jok, dan dek kaki.
    sphere(root, (-20, 0, 24), red, "body", (18, 7.5, 9))
    box(root, (-27, 0, 16), (18, 9, 8), red_dark, "body")
    box(root, (-19, 0, 33.5), (26, 9, 4), tire, "seat")
    box(root, (2, 0, 13), (26, 10, 4), red_dark, "deck")
    sphere(root, (-37, 0, 26), red_light, "tail", (3.2, 5, 3.2))
    # Tameng depan dan setang.
    box(root, (20, 0, 27), (7, 13, 30), red, "shield", rot=(0, -14, 0))
    tube(root, (22, 0, 12), (29, 0, 10), 1.8, metal, "fork")
    tube(root, (18, 0, 40), (14, 0, 50), 1.6, tire, "bar")
    tube(root, (14, -8, 50), (14, 8, 50), 1.5, tire, "bar")
    sphere(root, (26, 0, 41), lamp, "lamp", (3.4, 4.6, 3.8))
    box(root, (30, 0, 22), (9, 9, 2.2), red_dark, "fender", rot=(0, -8, 0))
    seins = [sphere(root, (24, -7, 36), sein_off, "sein", (2.2, 2.0, 2.2)),
             sphere(root, (-36, -6, 31), sein_off, "sein", (2.0, 1.8, 2.0))]
    frames = 4

    def pose(i):
        for w in wheels:
            w.rotation_euler = (0, math.radians(i * 22.5), 0)
        color = sein_on if i % 2 == 0 else sein_off
        for s in seins:
            s.data.materials[0] = _material(color)
    return {"size": (96, 64), "floor": 62, "frames": frames, "pose": pose, "yaw": 20.0}


def build_motor():
    """Motor bebek Abang Ojol (GDD 6.7): rangka rendah, sayap depan hijau, jok panjang."""
    green, green_dark, black, grey, light, lamp = "41a740", "207d23", "313131", "9d9b99", "d3cfcc", "e6e7e6"
    root = joint("root", None)
    wheels = [_wheel(root, -29, 11, black, grey, "wheel_b"), _wheel(root, 29, 11, black, grey, "wheel_f")]
    sphere(root, (-6, 0, 17), grey, "engine", (9, 6, 6.5))
    box(root, (-12, 0, 26), (40, 7.5, 7), green, "body", rot=(0, 6, 0))
    box(root, (-28, 0, 31), (18, 7, 5), green_dark, "body", rot=(0, -12, 0))
    box(root, (-13, 0, 33.5), (30, 8, 3.6), black, "seat")
    box(root, (10, 0, 26), (5, 13, 22), green, "shield", rot=(0, -20, 0))
    tube(root, (16, 0, 34), (28, 0, 12), 1.9, light, "fork")
    tube(root, (15, 0, 38), (12, 0, 47), 1.6, black, "bar")
    tube(root, (12, -8, 47), (12, 8, 47), 1.5, black, "bar")
    sphere(root, (19, 0, 40), lamp, "lamp", (3.6, 4.6, 3.8))
    box(root, (29, 0, 24), (10, 8, 2.2), green_dark, "fender", rot=(0, -10, 0))
    box(root, (-36, 0, 24), (12, 7, 2.0), green_dark, "fender", rot=(0, 16, 0))
    tube(root, (-10, -5, 13), (-38, -5, 17), 2.0, grey, "exhaust")
    frames = 4

    def pose(i):
        for w in wheels:
            w.rotation_euler = (0, math.radians(i * 22.5), 0)
    return {"size": (96, 64), "floor": 62, "frames": frames, "pose": pose, "yaw": 20.0}


BUILDERS = {"bekal": build_bekal, "scooter": build_scooter, "motor": build_motor}


# --- Render ---------------------------------------------------------------------

def setup_scene(size, floor_row, yaw):
    """Atur kamera dan render untuk model yang baru dibangun."""
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = size[0] * SUPERSAMPLE
    scene.render.resolution_y = size[1] * SUPERSAMPLE
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    # Tanpa dither: derau dither merusak render ID dan menjadi bintik setelah dipaskan ke palet.
    scene.render.dither_intensity = 0.0
    cam_data = bpy.data.cameras.new("cam")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = max(size)
    cam = bpy.data.objects.new("cam", cam_data)
    scene.collection.objects.link(cam)
    pitch = math.radians(8.0)
    # Baris lantai: z = 0 jatuh tepat di bawah baris `floor_row`.
    center_z = floor_row + 1 - size[1] / 2
    rig = joint("cam_rig", None, (0, 0, center_z))
    rig.rotation_euler = (0, 0, math.radians(yaw))
    cam.parent = rig
    cam.location = (0, -400 * math.cos(pitch), 400 * math.sin(pitch))
    cam.rotation_euler = (math.radians(90) - pitch, 0, 0)
    scene.camera = cam
    return scene


def shading_color(scene):
    s = scene.display.shading
    s.light = "STUDIO"
    s.color_type = "MATERIAL"
    s.show_shadows = False
    # Cavity "WORLD" menghasilkan derau yang menjadi bintik setelah dipaskan ke palet.
    s.show_cavity = False
    s.show_object_outline = False
    s.show_specular_highlight = False
    # Lampu "paint" paling terang dan rata; lampu bawaan membuat warna jauh lebih gelap dari palet.
    s.use_world_space_lighting = False
    s.studio_light = "paint.sl"
    scene.display.render_aa = "8"


def shading_id(scene):
    s = scene.display.shading
    s.light = "FLAT"
    s.color_type = "OBJECT"
    s.show_cavity = False
    scene.display.render_aa = "OFF"


def main():
    argv = sys.argv[sys.argv.index("--") + 1:]
    out_dir = argv[0]
    only = argv[1].split(",") if len(argv) > 1 and argv[1] else None
    os.makedirs(out_dir, exist_ok=True)
    for name, builder in BUILDERS.items():
        if only and name not in only:
            continue
        scene = bpy.context.scene
        for o in list(scene.objects):
            bpy.data.objects.remove(o, do_unlink=True)
        _id_colors.clear()
        spec = builder()
        keep = list(scene.objects)
        scene = setup_scene(spec["size"], spec["floor"], spec["yaw"])
        for i in range(spec["frames"]):
            spec["pose"](i)
            for suffix, setup in (("c", shading_color), ("id", shading_id)):
                setup(scene)
                scene.render.filepath = os.path.join(out_dir, "%s_%02d_%s.png" % (name, i, suffix))
                bpy.ops.render.render(write_still=True)
        print("RENDER SELESAI: %s, %d frame, %d objek" % (name, spec["frames"], len(keep)))


main()
