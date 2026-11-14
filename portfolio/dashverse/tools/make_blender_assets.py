"""Build editable, low-poly Dashverse meshes in Blender 5.3."""

import json
import math
from pathlib import Path
import sys

import bpy


destination = Path(sys.argv[sys.argv.index("--") + 1]).resolve()
destination.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.unit_settings.system = "METRIC"


def material(name, hex_color, metal=0, glow=0):
    raw = bytes.fromhex(hex_color)
    linear = tuple(
        value / 3294.6 if value < 11 else ((value / 255 + 0.055) / 1.055) ** 2.4
        for value in raw
    ) + (1,)
    result = bpy.data.materials.new(name)
    result.diffuse_color = linear
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = linear
    shader.inputs["Roughness"].default_value = 0.61
    shader.inputs["Metallic"].default_value = metal
    if glow:
        shader.inputs["Emission Color"].default_value = linear
        shader.inputs["Emission Strength"].default_value = glow
    return result


ink = material("Blue graphite", "20243D", 0.22)
cream = material("Porcelain", "FFF0D8")
white = material("Eye reflection", "FFFFFF")
mint = material("Mint signal", "64FFD1", 0.12, 0.45)
violet = material("Amethyst signal", "BE88FF", 0.04, 0.5)
bronze = material("Valley cedar", "C18E64")
roof = material("Valley sage", "437D75", 0.2)
asphalt = material("Skyline indigo", "42496A", 0.36)
records = []


def group(name):
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def move_to_group(obj, collection):
    for parent in list(obj.users_collection):
        parent.objects.unlink(obj)
    collection.objects.link(obj)


def finish_object(collection, name, dimensions, mat, rotation):
    obj = bpy.context.object
    obj.name = name
    obj.rotation_euler = rotation
    obj.scale = dimensions
    obj.data.materials.append(mat)
    move_to_group(obj, collection)
    return obj


def sphere(collection, name, p, size, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1, location=p)
    return finish_object(collection, name, size, mat, rotation)


def block(collection, name, p, size, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=p)
    return finish_object(collection, name, size, mat, rotation)


def cone(collection, name, p, size, mat, rotation=(0, 0, 0), sides=5, tip=0):
    bpy.ops.mesh.primitive_cone_add(vertices=sides, radius1=1, radius2=tip, depth=2, location=p)
    return finish_object(collection, name, size, mat, rotation)


def pet(name, style, hex_color, pale):
    collection = group(name)
    primary = material(name + " base", hex_color)
    lighter = material(name + " accents", pale)
    sphere(collection, "Body", (0, 0.10, 0.33), (0.33, 0.40, 0.26), primary)
    sphere(collection, "Head", (0, -0.17, 0.49), (0.32, 0.29, 0.28), primary)
    sphere(collection, "Muzzle", (0, -0.40, 0.41), (0.19, 0.08, 0.10), cream)
    sphere(collection, "Nose", (0, -0.475, 0.47), (0.058, 0.039, 0.037), ink)
    for side in (-1, 1):
        x = side * 0.13
        sphere(collection, "Eye", (x, -0.419, 0.53), (0.064, 0.048, 0.080), ink)
        sphere(collection, "Eye glint", (x + 0.022, -0.461, 0.56), (0.020, 0.014, 0.023), white)
        sphere(collection, "Foot", (side * 0.23, -0.08, 0.115), (0.105, 0.14, 0.10), lighter)
        if style == "fox":
            cone(collection, "Ear", (side * 0.219, -0.145, 0.765), (0.122, 0.085, 0.20), primary, (0, side * 0.29, 0), 4)
            cone(collection, "Ear accent", (side * 0.228, -0.207, 0.769), (0.074, 0.031, 0.132), lighter, (0, side * 0.29, 0), 4)
        elif style in {"cub", "bunny"}:
            h = 0.22 if style == "bunny" else 0.105
            z = 0.76 if style == "cub" else 0.86
            sphere(collection, "Ear", (side * 0.19, -0.135, z), (0.115, 0.077, h), primary, (0, side * 0.16, 0))
            sphere(collection, "Ear inset", (side * 0.19, -0.20, z), (0.075, 0.025, h * 0.72), lighter)
        elif style in {"owl", "wisp"}:
            sphere(collection, "Wing", (side * 0.36, 0.05, 0.36), (0.13, 0.27, 0.14), lighter, (0, side * 0.42, side * 0.29))
        else:
            cone(collection, "Fin", (side * 0.33, 0.23, 0.35), (0.12, 0.094, 0.15), lighter, (0, side * 0.7, 0), 4)
    if style in {"fox", "gecko"}:
        sphere(collection, "Tail", (0.18, 0.43, 0.43), (0.136, 0.31, 0.12), primary, (0.28, 0.15, -0.44))
        sphere(collection, "Tail tip", (0.28, 0.64, 0.50), (0.096, 0.14, 0.085), lighter, (0.27, 0, -0.41))
    elif style in {"cub", "meteor", "wisp"}:
        cone(collection, "Energy crystal", (0, 0.03, 0.89), (0.112, 0.11, 0.17), lighter, (0.21, 0.27, 0), 5)
    return collection


for spec in [
    ("Spark Fox", "fox", "FF9A53", "FFCF88"), ("Neon Gecko", "gecko", "64F9AE", "B1FFD6"),
    ("Crystal Cub", "cub", "BE88FF", "E1D0FF"), ("Cloud Bunny", "bunny", "EEE7FF", "FFBEDA"),
    ("Thunder Owl", "owl", "FFD76D", "FFF0AE"), ("Mini Meteor", "meteor", "FF9258", "FFCB87"),
    ("Lava Turtle", "turtle", "E9798E", "FFB99A"), ("Galaxy Wisp", "wisp", "B187FF", "E6BAFF"),
]:
    pet(*spec)

valley = group("Valley Cabin")
block(valley, "Cedar walls", (0, 0, 0.91), (3.9, 2.8, 1.82), bronze)
for side in (-1, 1):
    block(valley, "Pitched roof", (side * 0.99, 0, 2.02), (2.3, 3.25, 0.14), roof, (0, side * 0.40, 0))
    block(valley, "Window frame", (side * 1.12, -1.45, 1.04), (0.74, 0.11, 0.72), cream)
    block(valley, "Window light", (side * 1.12, -1.53, 1.04), (0.58, 0.10, 0.52), mint)
block(valley, "Sage front door", (0, -1.45, 0.56), (0.68, 0.10, 1.12), roof)
block(valley, "Doorstep", (0, -1.65, 0.04), (1.14, 0.55, 0.11), ink)

neon = group("Skyline Tower")
block(neon, "Foundation", (0, 0, 0.22), (3.4, 2.8, 0.44), ink)
block(neon, "Main tower", (0, 0, 3.38), (2.95, 2.5, 6.42), asphalt)
block(neon, "Upper tower", (-0.38, 0.02, 6.98), (1.9, 2.03, 1.3), ink)
block(neon, "Crown stripe", (-0.38, 0.02, 7.62), (2.05, 2.15, 0.13), mint)
for level in range(8):
    block(neon, "Window band", (0.12, -1.27, 0.77 + level * 0.70), (2.36, 0.075, 0.13), violet if level % 3 == 0 else mint)
block(neon, "Signal mast", (-0.44, 0, 8.03), (0.11, 0.12, 0.8), mint)

canyon = group("Amethyst Outcrop")
cone(canyon, "Basalt foundation", (0, 0, 0.1), (0.86, 0.65, 0.16), ink, sides=7, tip=0.85)
for i, scale in enumerate((0.48, 0.83, 0.57)):
    x = (i - 1) * 0.45
    cone(canyon, "Crystal shaft", (x, 0, scale * 0.54), (0.19, 0.20, scale * 0.46), violet, (0, (i - 1) * 0.29, i), sides=5, tip=0.84)
    cone(canyon, "Crystal tip", (x * 1.32, 0, scale * 1.11), (0.167, 0.179, 0.16), violet, (0, (i - 1) * 0.29, i), sides=5)

display = group("Veltrix Display")
cone(display, "Platform", (0, 0, 0.16), (0.75, 0.75, 0.16), ink, sides=8, tip=0.90)
cone(display, "Signal ring", (0, 0, 0.35), (0.63, 0.63, 0.07), mint, sides=8, tip=0.94)
cone(display, "Pedestal", (0, 0, 0.57), (0.40, 0.40, 0.21), asphalt, sides=8, tip=0.92)
block(display, "Floating energy", (0, 0, 1.02), (0.30, 0.30, 0.30), mint, (0.71, 0.55, 0.66))

collections = list(bpy.context.scene.collection.children)
for index, collection in enumerate(collections):
    for obj in bpy.context.scene.objects:
        obj.select_set(False)
    triangle_count = 0
    largest_mesh = 0
    for obj in collection.objects:
        obj.select_set(True)
        obj.data.calc_loop_triangles()
        triangles = len(obj.data.loop_triangles)
        triangle_count += triangles
        largest_mesh = max(largest_mesh, triangles)
    filename = collection.name.lower().replace(" ", "_") + ".glb"
    bpy.ops.export_scene.gltf(
        filepath=str(destination / filename),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_texcoords=False,
        export_tangents=False,
    )
    records.append(
        {"file": filename, "meshes": len(collection.objects), "triangles": triangle_count, "largestMesh": largest_mesh}
    )
    # Spread the editable source collections so they are easy to inspect together.
    for obj in collection.objects:
        obj.location.x += (index % 4) * 5
        obj.location.y += (index // 4) * 4.5

bpy.ops.wm.save_as_mainfile(filepath=str(destination / "Dashverse-Assets.blend"))
(destination / "mesh_manifest.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
