"""Create a procedural mountain road diorama from a short design profile."""
import argparse
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def material(name, color, roughness=0.85, emission=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    if emission:
        shader.inputs["Emission Color"].default_value = (*color, 1)
        shader.inputs["Emission Strength"].default_value = emission
    return mat


def create_mesh(name, vertices, faces, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def block(name, location, size, mat, bevel=0.06):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        modifier = obj.modifiers.new("Edge radius", "BEVEL")
        modifier.width, modifier.segments = bevel, 2
    return obj


def sample_route(knots):
    points = []
    for i in range(len(knots) - 1):
        a, b = knots[i], knots[i + 1]
        prev = knots[max(i - 1, 0)]
        following = knots[min(i + 2, len(knots) - 1)]
        for j in range(16):
            t = j / 16
            point = (2 * a + t * (-prev + b) + t**2 * (2 * prev - 5 * a + 4 * b - following)
                     + t**3 * (-prev + 3 * a - 3 * b + following)) / 2
            points.append(point)
    return [*points, knots[-1]]


def lateral(point, neighbor):
    dx, dy = neighbor.x - point.x, neighbor.y - point.y
    return Vector((-dy, dx, 0)).normalized()


def ribbon(name, points, width, mat, offset=0.0, lift=0.0):
    verts = []
    for i, point in enumerate(points):
        right = lateral(points[max(0, i - 1)], points[min(len(points) - 1, i + 1)])
        for sign in (-1, 1):
            verts.append(point + right * (offset + sign * width / 2) + Vector((0, 0, lift)))
    return create_mesh(name, verts, [(2*i, 2*i+1, 2*i+3, 2*i+2) for i in range(len(points)-1)], mat)


def terrain(route, mats):
    def closest(x, y):
        candidate = min(route, key=lambda p: (p.x-x)**2+(p.y-y)**2)
        return math.hypot(candidate.x-x, candidate.y-y), candidate.z

    def height(x, y):
        dist, on_road = closest(x, y)
        mountain = 0.014 * (y+20)**2 + 2.1 * math.sin(0.16*x+0.32)*math.sin(0.19*y)
        ridge = 2.4 * math.exp(-((x-12)/9)**2-((y-9)/12)**2)
        mix = max(0, min(1, (dist-2.5)/8))
        return (on_road-0.12) * (1-mix) + (mountain+ridge) * mix

    n = 81
    coords = [(x*0.65-26, y*0.58-23) for y in range(n) for x in range(n)]
    verts = [(x, y, height(x, y)) for x, y in coords]
    faces = [(i, i+1, i+1+n, i+n) for i in range(n*(n-1)) if i % n < n-1]
    obj = create_mesh("Carved mountain surface", verts, faces, mats[0])
    for mat in mats[1:]:
        obj.data.materials.append(mat)
    for face in obj.data.polygons:
        x, y, z = face.center
        dist, _ = closest(x, y)
        face.material_index = 1 if dist < 3.6 else (2 if math.sin(x*0.72+y*0.48) + math.cos(y*0.7) > 0.58 else 0)
        face.use_smooth = False
    return height, closest


def forest(height, closest, bark, needles, rock, seed):
    rng = random.Random(seed)
    for i in range(135):
        x, y = rng.uniform(-24, 24), rng.uniform(-21, 21)
        dist, _ = closest(x, y)
        if dist < 4.8:
            continue
        ground = height(x, y)
        h = rng.uniform(0.8, 3.3)
        if i % 7 == 0:
            bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.5, location=(x, y, ground+0.1))
            boulder = bpy.context.object
            boulder.name = "Granite boulder"
            boulder.scale = (h / 2, h / 3, h / 3.7)
            boulder.data.materials.append(rock)
            continue
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=h*0.066, radius2=h*0.044, depth=h,
                                        location=(x, y, ground+h*0.5))
        bpy.context.object.name = "Pine trunk"
        bpy.context.object.data.materials.append(bark)
        for tier in range(3):
            bpy.ops.mesh.primitive_cone_add(vertices=7, radius1=h*(0.28-tier*0.049), depth=h*0.53,
                                            location=(x, y, ground+h*(0.56+0.19*tier)))
            tree = bpy.context.object
            tree.name = "Pine crown"
            tree.rotation_euler.z = i*0.61+tier*0.17
            tree.data.materials.append(needles[tier])


def aim(camera, target):
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", type=int, default=482)
    parser.add_argument("--render", type=Path)
    args = parser.parse_args(sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else [])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    asphalt = material("Blue-gray asphalt", (0.042, 0.065, 0.072))
    ochre = material("Ochre edge paint", (0.72, 0.40, 0.12))
    ivory = material("Chalk center paint", (0.70, 0.78, 0.66))
    moss = material("Dry alpine ground", (0.13, 0.20, 0.124))
    shoulder = material("Weathered gravel", (0.22, 0.183, 0.126))
    granite = material("Granite faces", (0.22, 0.25, 0.23))
    bark = material("Pine bark", (0.084, 0.052, 0.031))
    needles = [material(f"Pine layer {i+1}", tint) for i, tint in enumerate(
        [(0.063,0.15,0.102), (0.072,0.192,0.121), (0.095,0.227,0.14)])]
    black = material("Cut diorama base", (0.05, 0.076, 0.071))
    steel = material("Galvanized barrier", (0.31, 0.38, 0.39), 0.55)

    route = sample_route([Vector(p) for p in [(-24,-18,1.3), (-12,-17,1.9), (6,-15,3.1),
        (19,-9,4.2), (16,-3,5.4), (-3,0,6.6), (-16,3,7.7), (-18,8,8.6),
        (-10,12,9.4), (6,13,10.9), (20,18,12.6), (24,23,13.9)]])
    ground, closest = terrain(route, [moss, shoulder, granite])
    block("Diorama plinth", (0, 0.2, -1.0), (52.3, 47, 2.6), black, 0.22)
    ribbon("Two-lane switchback", route, 4.65, asphalt, lift=0.12)
    for side in (-1, 1):
        ribbon("Shoulder paint", route, .09, ochre, offset=side*2.15, lift=0.145)
    for i in range(4, len(route)-3, 7):
        ribbon("Center dash", route[i:i+4], .11, ivory, lift=0.151)
    for start, end, side in [(33, 73, -1), (77, 132, 1), (139, 168, -1)]:
        section = route[start:end]
        ribbon("Reflective barrier top", [p + Vector((0,0,0.58)) for p in section], .22, steel, side*2.6)
        for i in range(0,len(section)-1,4):
            point = section[i] + lateral(section[i], section[i+1])*side*2.6
            block("Barrier support", point + Vector((0,0,0.36)), (0.105,0.105,0.72), steel, 0.025)
    forest(ground, closest, bark, needles, granite, args.seed)
    world = bpy.data.worlds.new("High cloud environment")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.23, 0.34, 0.42, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.55
    scene = bpy.context.scene
    scene.world = world
    bpy.ops.object.light_add(type="SUN", location=(0,0,20))
    sun = bpy.context.object
    sun.name = "Late-afternoon sun"
    sun.rotation_euler = (math.radians(34), math.radians(-28), math.radians(-32))
    sun.data.energy, sun.data.angle = 2.25, math.radians(8)
    bpy.ops.object.camera_add(location=(52,-64,52))
    camera = bpy.context.object
    camera.name = "Diorama overview"
    camera.data.type, camera.data.ortho_scale = "ORTHO", 87
    aim(camera, (0,1.7,7.5))
    camera.location.z += 2.5
    scene.camera = camera
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 20
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1152, 864
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "AgX"
    args.output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), compress=True)
    if args.render:
        scene.render.filepath = str(args.render.resolve())
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    main()
