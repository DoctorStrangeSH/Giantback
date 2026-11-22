#!/usr/bin/env python3
"""Build the first sculpted-form Fox Companion hero mesh for Giantback.

Run with Blender 4.2.x:
  blender --background --python tools/blender/build_fox_companion.py -- --output-dir build/fox_hero

The generator creates a separate review asset; it never overwrites fox_companion.obj.
This is a polished stylized blockout (silhouette/material pass), not final painted fur.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
import bmesh
from mathutils import Matrix, Vector
from fox_rig_contract import validate_rig_payload

BLENDER_MIN = (4, 2, 0)
BLENDER_MAX = (4, 4, 0)
GROUPS = (
    "FoxBody", "FoxBelly", "FoxHead", "FoxMuzzle",
    "FoxEarLeft", "FoxEarRight", "FoxEarInnerLeft", "FoxEarInnerRight",
    "FoxLegFrontLeft", "FoxLegFrontRight",
    "FoxLegBackLeft", "FoxLegBackRight",
    "FoxTail", "FoxTailTip", "FoxEyes", "FoxEyeSparkles", "FoxNose",
)


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args(argv)


def material(name, color, roughness=0.72, metallic=0.0, soft_fur=False):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    shader = nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    if soft_fur:
        # Soft fabric-like sheen keeps the companion readable under warm island light.
        # Guard optional sockets so the material remains compatible with Blender 4.2.
        if "Sheen Weight" in shader.inputs:
            shader.inputs["Sheen Weight"].default_value = 0.08
        if "Sheen Roughness" in shader.inputs:
            shader.inputs["Sheen Roughness"].default_value = 0.72
        mat["giantback_surface_profile"] = "soft_fur"
        # Restrained procedural micro-relief: broad enough to read as groomed fur,
        # not noisy scales. Keep bump subtle so the low-poly silhouette stays clean.
        noise = nodes.new("ShaderNodeTexNoise")
        noise.name = name + "_SoftFurNoise"
        noise.inputs["Scale"].default_value = 10.0
        noise.inputs["Detail"].default_value = 1.0
        noise.inputs["Roughness"].default_value = 0.62
        bump = nodes.new("ShaderNodeBump")
        bump.name = name + "_SoftFurBump"
        bump.inputs["Strength"].default_value = 0.002
        bump.inputs["Distance"].default_value = 0.001
        links.new(noise.outputs["Fac"], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    else:
        mat["giantback_surface_profile"] = "smooth"
    return mat


def make_palette():
    return {
        # Richer storybook orange and warm ivory: the old values rendered too muted
        # under neutral preview lighting. Keep the Fox brief's warm, restrained palette.
        "fox_orange": material("fox_orange", (0.90, 0.065, 0.001), 0.90, soft_fur=True),
        "cream": material("cream", (0.92, 0.72, 0.48), 0.92, soft_fur=True),
        "ear_pink": material("ear_pink", (0.66, 0.19, 0.16), 0.88),
        "dark": material("dark", (0.08, 0.06, 0.05), 0.28),
        "white": material("white", (1.0, 0.98, 0.87), 0.22),
        "nose": material("nose", (0.12, 0.07, 0.06), 0.24),
        "expression": material("expression", (0.29, 0.12, 0.075), 0.58),
        "paw_detail": material("paw_detail", (0.78, 0.43, 0.25), 0.82),
    }


def smooth(obj, mat, name):
    obj.name = name
    obj.data.name = name + "Mesh"
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def ellipsoid(name, center, scale, mat, segments=32, rings=20):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments, ring_count=rings, radius=1.0, location=center
    )
    obj = bpy.context.object
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return smooth(obj, mat, name)



def sculpted_head(name, center, scale, mat, segments=64, rings=40):
    """Build an organic fox head shell with true single-vertex poles and clean topology."""
    cx, cy, cz = center
    sx, sy, sz = scale
    verts, faces = [(cx, cy + sy, cz)], []
    # Interior latitude rings exclude both poles so no duplicate coincident vertices exist.
    for row in range(1, rings):
        theta = math.pi * row / rings
        vertical = math.cos(theta)
        radial = math.sin(theta)
        for side in range(segments):
            phi = 2.0 * math.pi * side / segments
            x = math.cos(phi) * radial
            z = math.sin(phi) * radial
            cheek = 1.0 + 0.16 * math.exp(-((vertical + 0.24) / 0.30) ** 2)
            jaw_taper = 1.0 - 0.20 * max(0.0, -vertical - 0.42)
            brow_width = 1.0 + 0.055 * max(0.0, vertical)
            px = x * sx * cheek * jaw_taper * brow_width
            py = vertical * sy
            pz = z * sz * (1.0 + 0.045 * max(0.0, vertical))
            verts.append((cx + px, cy + py, cz + pz))
    bottom = len(verts)
    verts.append((cx, cy - sy, cz))
    first_ring = 1
    last_ring = rings - 2
    for side in range(segments):
        nxt = (side + 1) % segments
        faces.append((0, first_ring + side, first_ring + nxt))
    for row in range(rings - 2):
        ring_a = 1 + row * segments
        ring_b = ring_a + segments
        for side in range(segments):
            nxt = (side + 1) % segments
            a, b = ring_a + side, ring_a + nxt
            faces.append((a, b, b + segments, a + segments))
    last_start = 1 + last_ring * segments
    for side in range(segments):
        nxt = (side + 1) % segments
        faces.append((last_start + side, bottom, last_start + nxt))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return smooth(obj, mat, name)


def organic_torso(name, center, profile, mat, sides=64):
    """Organic Y-axis body loft with broad ribcage and tapered shoulder/hip transitions."""
    cx, cy, cz = center
    verts, faces = [], []
    for y_offset, radius_x, radius_z, z_shift in profile:
        for side in range(sides):
            angle = 2.0 * math.pi * side / sides
            x = math.cos(angle) * radius_x
            z = math.sin(angle) * radius_z
            front_fullness = 1.0 + 0.055 * max(0.0, -math.sin(angle))
            verts.append((cx + x * front_fullness, cy + y_offset,
                          cz + z * front_fullness + z_shift))
    for row in range(len(profile) - 1):
        for side in range(sides):
            a = row * sides + side
            b = row * sides + (side + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    faces.append(tuple(range(sides - 1, -1, -1)))
    faces.append(tuple((len(profile) - 1) * sides + side for side in range(sides)))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return smooth(obj, mat, name)


def lofted_muzzle(name, profiles, mat, sides=48):
    """Create a tapered muzzle from hand-shaped elliptical cross sections along Z."""
    verts, faces = [], []
    for z, center_y, radius_x, radius_y in profiles:
        for side in range(sides):
            angle = 2.0 * math.pi * side / sides
            verts.append((
                math.cos(angle) * radius_x,
                center_y + math.sin(angle) * radius_y,
                z,
            ))
    for row in range(len(profiles) - 1):
        for side in range(sides):
            a = row * sides + side
            b = row * sides + (side + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    faces.append(tuple(range(sides - 1, -1, -1)))
    faces.append(tuple((len(profiles) - 1) * sides + side for side in range(sides)))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return smooth(obj, mat, name)


def leaf_mesh(name, center, width, height, depth, mat, facing=-1.0):
    """Create a sculpted ear shell with a curved centerline, tapered tip and convex front."""
    cx, cy, cz = center
    ring_count, sides = 25, 32
    verts, faces = [], []
    for row in range(ring_count):
        t = row / (ring_count - 1)
        # Broad lower ear, gently pinched upper third and a rounded pointed tip.
        profile = max(0.018, math.sin(math.pi * (t ** 0.82)) ** 0.78)
        profile *= 1.0 - 0.12 * t
        center_x = cx + (t ** 1.55) * width * 0.075 * (1 if cx > 0 else -1)
        center_z = cz + 0.045 * math.sin(math.pi * t)
        for side in range(sides):
            angle = 2.0 * math.pi * side / sides
            across = math.cos(angle)
            front_back = math.sin(angle)
            x = center_x + across * width * profile * 0.5
            y = cy + (t - 0.5) * height
            # Front surface is softly convex; rear remains fuller near the base.
            bulge = depth * profile * 0.5 * front_back
            z = center_z + facing * (bulge + 0.035 * math.sin(math.pi * t))
            verts.append((x, y, z))
    for row in range(ring_count - 1):
        for side in range(sides):
            a = row * sides + side
            b = row * sides + (side + 1) % sides
            faces.append((a, b, b + sides, a + sides))
    faces.append(tuple(range(sides - 1, -1, -1)))
    faces.append(tuple((ring_count - 1) * sides + side for side in range(sides)))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return smooth(obj, mat, name)

def curved_plume(name, points, radii, mat, sides=24, steps_per_segment=6):
    """Smooth tapered tube following a Catmull-Rom centerline."""
    samples = []
    for segment in range(len(points) - 1):
        p0 = Vector(points[max(0, segment - 1)])
        p1 = Vector(points[segment])
        p2 = Vector(points[segment + 1])
        p3 = Vector(points[min(len(points) - 1, segment + 2)])
        for step in range(steps_per_segment):
            t = step / steps_per_segment
            t2, t3 = t * t, t * t * t
            pos = 0.5 * (
                (2 * p1) + (-p0 + p2) * t
                + (2*p0 - 5*p1 + 4*p2 - p3) * t2
                + (-p0 + 3*p1 - 3*p2 + p3) * t3
            )
            radius = radii[segment] * (1-t) + radii[segment+1] * t
            samples.append((pos, radius))
    samples.append((Vector(points[-1]), radii[-1]))
    verts, faces = [], []
    previous_normal = Vector((1, 0, 0))
    for index, (point, radius) in enumerate(samples):
        tangent = (
            (samples[min(index + 1, len(samples)-1)][0]
             - samples[max(index - 1, 0)][0]).normalized()
        )
        normal = tangent.cross(Vector((0, 1, 0)))
        if normal.length < 1e-5:
            normal = previous_normal
        else:
            normal.normalize()
        binormal = tangent.cross(normal).normalized()
        previous_normal = normal
        for side in range(sides):
            angle = 2 * math.pi * side / sides
            offset = (normal * math.cos(angle) + binormal * math.sin(angle)) * radius
            verts.append(tuple(point + offset))
    for row in range(len(samples)-1):
        for side in range(sides):
            a = row*sides + side
            b = row*sides + (side+1) % sides
            faces.append((a, b, b+sides, a+sides))
    faces.append(tuple(range(sides-1, -1, -1)))
    faces.append(tuple((len(samples)-1)*sides + side for side in range(sides)))
    mesh = bpy.data.meshes.new(name + "Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return smooth(obj, mat, name)



def plush_tail(name, points, widths, depths, mat, sides=48, steps_per_segment=8):
    """Elliptical swept tail with a broad plush cross-section and tapered ends."""
    samples = []
    for segment in range(len(points) - 1):
        p0 = Vector(points[max(0, segment - 1)])
        p1 = Vector(points[segment])
        p2 = Vector(points[segment + 1])
        p3 = Vector(points[min(len(points) - 1, segment + 2)])
        for step in range(steps_per_segment):
            t = step / steps_per_segment
            t2, t3 = t*t, t*t*t
            pos = 0.5 * ((2*p1) + (-p0+p2)*t
                + (2*p0-5*p1+4*p2-p3)*t2
                + (-p0+3*p1-3*p2+p3)*t3)
            width = widths[segment]*(1-t) + widths[segment+1]*t
            depth = depths[segment]*(1-t) + depths[segment+1]*t
            samples.append((pos, width, depth))
    samples.append((Vector(points[-1]), widths[-1], depths[-1]))
    verts, faces = [], []
    previous_normal = Vector((1, 0, 0))
    for index, (point, width, depth) in enumerate(samples):
        tangent = (samples[min(index+1, len(samples)-1)][0]
                   - samples[max(index-1, 0)][0]).normalized()
        normal = tangent.cross(Vector((0, 1, 0)))
        if normal.length < 1e-5:
            normal = previous_normal
        else:
            normal.normalize()
        binormal = tangent.cross(normal).normalized()
        previous_normal = normal
        for side in range(sides):
            angle = 2*math.pi*side/sides
            offset = normal*(math.cos(angle)*width) + binormal*(math.sin(angle)*depth)
            verts.append(tuple(point + offset))
    for row in range(len(samples)-1):
        for side in range(sides):
            a = row*sides+side
            b = row*sides+(side+1)%sides
            faces.append((a,b,b+sides,a+sides))
    faces.append(tuple(range(sides-1,-1,-1)))
    faces.append(tuple((len(samples)-1)*sides+side for side in range(sides)))
    mesh = bpy.data.meshes.new(name+"Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return smooth(obj, mat, name)


def create_fox(p):
    # Compact pear-shaped body, with the face consistently pointing toward -Z.
    organic_torso("FoxBody", (0, 0.91, 0.05), [
        (-0.62, 0.12, 0.20, 0.02), (-0.53, 0.34, 0.48, 0.02),
        (-0.30, 0.49, 0.72, 0.00), (0.02, 0.57, 0.91, 0.00),
        (0.29, 0.54, 0.82, 0.02), (0.50, 0.40, 0.57, 0.04),
        (0.62, 0.12, 0.20, 0.05),
    ], p["fox_orange"])
    organic_torso("FoxBelly", (0, 0.92, -0.36), [
        (-0.48, 0.08, 0.08, 0.00), (-0.38, 0.25, 0.10, 0.00),
        (-0.18, 0.36, 0.12, 0.00), (0.08, 0.37, 0.12, 0.00),
        (0.31, 0.27, 0.10, 0.00), (0.40, 0.08, 0.07, 0.00),
    ], p["cream"])
    # Layered chest ruff gives the neck-to-body transition a softer fox-like silhouette.
    curved_plume("ChestRuffCenter",
        [(-0.10, 1.42, -0.69), (-0.06, 1.30, -0.82),
         (0.00, 1.16, -0.86), (0.045, 1.08, -0.81)],
        [0.012, 0.105, 0.082, 0.006], p["cream"], sides=18, steps_per_segment=6)
    curved_plume("ChestRuffLeft",
        [(-0.19, 1.43, -0.66), (-0.25, 1.32, -0.77),
         (-0.28, 1.20, -0.78)],
        [0.008, 0.075, 0.004], p["cream"], sides=16, steps_per_segment=5)
    curved_plume("ChestRuffRight",
        [(0.12, 1.43, -0.68), (0.20, 1.32, -0.77),
         (0.25, 1.20, -0.78)],
        [0.008, 0.075, 0.004], p["cream"], sides=16, steps_per_segment=5)

    # Head silhouette: broad forehead, soft cheeks and a shorter, friendlier muzzle.
    sculpted_head("FoxHead", (0, 1.73, -0.62), (0.62, 0.61, 0.56), p["fox_orange"], 64, 40)
    lofted_muzzle("FoxMuzzle", [(-1.385, 1.42, 0.075, 0.065), (-1.33, 1.42, 0.20, 0.13), (-1.23, 1.43, 0.31, 0.19), (-1.11, 1.44, 0.36, 0.215), (-1.015, 1.45, 0.29, 0.17), (-0.985, 1.45, 0.18, 0.11)], p["cream"])
    # Rounded cream cheek pads blend into the muzzle instead of forming pointed whisker tufts.
    ellipsoid("CheekFluff_L", (-0.255, 1.435, -1.035), (0.042, 0.026, 0.010), p["cream"], 24, 16)
    ellipsoid("CheekFluff_R", (0.255, 1.435, -1.035), (0.042, 0.026, 0.010), p["cream"], 24, 16)
    # Layered swept forelock tufts break the smooth cap silhouette.
    curved_plume("ForeheadTuft",
        [(-0.13, 2.16, -0.93), (-0.09, 2.27, -0.91),
         (0.00, 2.34, -0.84), (0.035, 2.42, -0.76)],
        [0.025, 0.105, 0.085, 0.006], p["fox_orange"], sides=20, steps_per_segment=7)
    curved_plume("ForeheadTuft_L",
        [(-0.28, 2.12, -0.88), (-0.31, 2.22, -0.86),
         (-0.27, 2.29, -0.79)],
        [0.012, 0.072, 0.004], p["fox_orange"], sides=16, steps_per_segment=6)
    curved_plume("ForeheadTuft_R",
        [(0.17, 2.14, -0.89), (0.22, 2.23, -0.85),
         (0.31, 2.27, -0.77)],
        [0.012, 0.068, 0.004], p["fox_orange"], sides=16, steps_per_segment=6)

    # Tall, gently outward-splayed ears with separate inset inner-ear pieces.
    leaf_mesh("FoxEarLeft", (-0.39, 2.20, -0.52), 0.46, 0.88, 0.30, p["fox_orange"])
    leaf_mesh("FoxEarRight", (0.39, 2.20, -0.52), 0.46, 0.88, 0.30, p["fox_orange"])
    leaf_mesh("FoxEarInner_L", (-0.39, 2.20, -0.695), 0.29, 0.60, 0.10, p["ear_pink"])
    leaf_mesh("FoxEarInner_R", (0.39, 2.20, -0.695), 0.29, 0.60, 0.10, p["ear_pink"])

    # Four independently animated, rounded paws with darker soft paw ends.
    for side, suffix in ((-1, "Left"), (1, "Right")):
        organic_torso("FoxLegFront" + suffix, (side*0.34, 0.40, -0.55), [
            (-0.42, 0.12, 0.13, 0.00), (-0.32, 0.17, 0.18, 0.00),
            (-0.12, 0.19, 0.20, 0.00), (0.12, 0.17, 0.18, 0.00),
            (0.32, 0.14, 0.15, 0.00), (0.42, 0.10, 0.12, 0.00),
        ], p["fox_orange"], sides=40)
        organic_torso("FoxLegBack" + suffix, (side*0.34, 0.39, 0.57), [
            (-0.41, 0.14, 0.15, 0.00), (-0.30, 0.20, 0.22, 0.00),
            (-0.10, 0.22, 0.25, 0.00), (0.12, 0.21, 0.24, 0.00),
            (0.31, 0.17, 0.19, 0.00), (0.41, 0.11, 0.13, 0.00),
        ], p["fox_orange"], sides=40)
        ellipsoid("PawFront" + suffix, (side*0.34, 0.13, -0.61),
                 (0.205, 0.115, 0.225), p["fox_orange"], 32, 20)
        ellipsoid("PawBack" + suffix, (side*0.34, 0.13, 0.61),
                 (0.22, 0.115, 0.24), p["fox_orange"], 32, 20)
        # Three shallow toe separators add a readable paw silhouette without claws.
        for toe, offset in enumerate((-0.085, 0.0, 0.085)):
            curved_plume("PawToeFront" + suffix + str(toe),
                [(side*0.34 + offset - 0.018, 0.145, -0.842),
                 (side*0.34 + offset, 0.175, -0.858),
                 (side*0.34 + offset + 0.018, 0.145, -0.842)],
                [0.002, 0.005, 0.002], p["paw_detail"],
                sides=8, steps_per_segment=4)
            curved_plume("PawToeBack" + suffix + str(toe),
                [(side*0.34 + offset - 0.018, 0.145, 0.842),
                 (side*0.34 + offset, 0.175, 0.858),
                 (side*0.34 + offset + 0.018, 0.145, 0.842)],
                [0.002, 0.005, 0.002], p["paw_detail"],
                sides=8, steps_per_segment=4)

    # Big plush tail sweeps up behind the body; cream tip remains separately riggable.
    plush_tail("FoxTail",
        [(0.15, 1.02, 0.68), (0.39, 1.10, 1.08), (0.43, 1.42, 1.55),
         (0.28, 1.76, 1.86), (0.12, 1.91, 1.99)],
        [0.18, 0.29, 0.40, 0.37, 0.27],
        [0.15, 0.25, 0.34, 0.32, 0.23], p["fox_orange"])
    # Match the orange tail's final center/radii exactly, then taper the cream tip gradually.
    plush_tail("FoxTailTip",
        [(0.12, 1.91, 1.99), (0.10, 1.96, 2.04), (0.06, 2.03, 2.10),
         (0.025, 2.09, 2.16), (0.00, 2.15, 2.20)],
        [0.27, 0.255, 0.205, 0.115, 0.012],
        [0.23, 0.215, 0.175, 0.095, 0.010], p["cream"])

    # Eyes sit on the front (-Z) plane; pupils and catchlights are readable at distance.
    for side, suffix in ((-1, "Left"), (1, "Right")):
        ellipsoid("EyeBase" + suffix, (side*0.255, 1.76, -1.105),
                 (0.145, 0.19, 0.075), p["cream"], 32, 20)
        ellipsoid("EyePupil" + suffix, (side*0.255, 1.765, -1.168),
                 (0.108, 0.145, 0.055), p["dark"], 32, 20)
        ellipsoid("EyeShine" + suffix, (side*0.255-0.035, 1.825, -1.216),
                 (0.038, 0.048, 0.018), p["white"], 20, 12)
        # Soft upper/lower eyelid rims frame the eyes and make expressions readable.
        curved_plume("EyeLidUpper" + suffix,
            [(side*0.255-0.145, 1.79, -1.145),
             (side*0.255-0.105, 1.91, -1.158),
             (side*0.255, 1.955, -1.165),
             (side*0.255+0.105, 1.91, -1.158),
             (side*0.255+0.145, 1.79, -1.145)],
            [0.012, 0.020, 0.023, 0.020, 0.012],
            p["expression"], sides=12, steps_per_segment=4)
        ellipsoid("EyeShineSmall" + suffix,
                 (side*0.255+0.018, 1.795, -1.218),
                 (0.016, 0.020, 0.010), p["white"], 16, 10)
    ellipsoid("FoxNose", (0, 1.47, -1.365), (0.105, 0.075, 0.065), p["nose"], 24, 16)

    # Soft brows and a tiny curved smile add readable emotion without extra rig groups.
    curved_plume("BrowLeft",
        [(-0.39, 1.99, -1.075), (-0.29, 2.035, -1.105), (-0.17, 2.015, -1.105)],
        [0.018, 0.027, 0.014], p["expression"], sides=12, steps_per_segment=5)
    curved_plume("BrowRight",
        [(0.17, 2.015, -1.105), (0.29, 2.035, -1.105), (0.39, 1.99, -1.075)],
        [0.014, 0.027, 0.018], p["expression"], sides=12, steps_per_segment=5)
    curved_plume("Smile",
        [(-0.12, 1.345, -1.31), (0.0, 1.315, -1.345), (0.12, 1.345, -1.31)],
        [0.012, 0.016, 0.012], p["expression"], sides=10, steps_per_segment=5)

    # Recreate exactly the rig-facing group names; detailed subforms stay in their group.
    grouped = {
        "FoxBody": ["FoxBody"],
        "FoxBelly": ["FoxBelly", "ChestRuffCenter", "ChestRuffLeft", "ChestRuffRight"],
        "FoxHead": ["FoxHead", "ForeheadTuft", "ForeheadTuft_L", "ForeheadTuft_R", "BrowLeft", "BrowRight"],
        "FoxMuzzle": ["FoxMuzzle", "CheekFluff_L", "CheekFluff_R", "Smile"],
        "FoxEarLeft": ["FoxEarLeft"],
        "FoxEarRight": ["FoxEarRight"],
        "FoxEarInnerLeft": ["FoxEarInner_L"],
        "FoxEarInnerRight": ["FoxEarInner_R"],
        "FoxLegFrontLeft": ["FoxLegFrontLeft", "PawFrontLeft", "PawToeFrontLeft0", "PawToeFrontLeft1", "PawToeFrontLeft2"],
        "FoxLegFrontRight": ["FoxLegFrontRight", "PawFrontRight", "PawToeFrontRight0", "PawToeFrontRight1", "PawToeFrontRight2"],
        "FoxLegBackLeft": ["FoxLegBackLeft", "PawBackLeft", "PawToeBackLeft0", "PawToeBackLeft1", "PawToeBackLeft2"],
        "FoxLegBackRight": ["FoxLegBackRight", "PawBackRight", "PawToeBackRight0", "PawToeBackRight1", "PawToeBackRight2"],
        "FoxTail": ["FoxTail"],
        "FoxTailTip": ["FoxTailTip"],
        "FoxEyes": ["EyeBaseLeft", "EyeBaseRight", "EyePupilLeft", "EyePupilRight", "EyeLidUpperLeft", "EyeLidUpperRight"],
        "FoxEyeSparkles": ["EyeShineLeft", "EyeShineRight", "EyeShineSmallLeft", "EyeShineSmallRight"],
        "FoxNose": ["FoxNose"],
    }
    for group_name, names in grouped.items():
        parts = [bpy.data.objects[name] for name in names]
        bpy.ops.object.select_all(action="DESELECT")
        for part in parts:
            part.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        if len(parts) > 1:
            bpy.ops.object.join()
        merged = bpy.context.object
        merged.name = group_name
        merged.data.name = group_name + "Mesh"
    return [bpy.data.objects[name] for name in GROUPS]


def unwrap_and_pack(objects):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(
        angle_limit=math.radians(58.0),
        island_margin=0.012,
        area_weight=0.0,
        correct_aspect=True,
        scale_to_bounds=False,
    )
    bpy.ops.uv.pack_islands(rotate=True, margin=0.012)
    bpy.ops.object.mode_set(mode="OBJECT")
    for obj in objects:
        if not obj.data.uv_layers:
            raise RuntimeError("UV generation failed for " + obj.name)


def add_review_camera(objects):
    corners = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    low = Vector(tuple(min(point[i] for point in corners) for i in range(3)))
    high = Vector(tuple(max(point[i] for point in corners) for i in range(3)))
    center = (low + high) * 0.5
    radius = max((high-low).length * 0.5, 1.0)

    camera_data = bpy.data.cameras.new("FoxHeroReviewCamera")
    camera = bpy.data.objects.new("FoxHeroReviewCamera", camera_data)
    bpy.context.scene.collection.objects.link(camera)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = radius * 2.55
    bpy.context.scene.camera = camera

    # Neutral warm studio floor gives the paws a readable contact shadow.
    floor_mat = material("ReviewFloor", (0.19, 0.22, 0.25), 0.94)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(center.x, -0.035, center.z))
    floor = bpy.context.object
    floor.name = "REVIEW_ONLY_Ground"
    # Blender planes are created in XY (normal +Z); the character uses Y-up.
    # Rotate the floor into XZ so paws actually rest on a horizontal surface.
    floor.rotation_euler.x = math.radians(90.0)
    floor.data.materials.append(floor_mat)

    world = bpy.data.worlds.new("FoxHeroReviewWorld") if not bpy.data.worlds else bpy.data.worlds[0]
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.16, 0.19, 0.23, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.22

    for name, offset, power, size in (
        ("Key", (1.8, 2.8, -2.0), 95, 3.2),
        ("Fill", (-2.0, 1.0, -1.0), 42, 2.8),
        ("Rim", (0.0, 2.0, 2.8), 72, 2.4),
    ):
        data = bpy.data.lights.new(name, "AREA")
        data.energy = power
        data.shape = "DISK"
        data.size = size
        data.use_shadow = True
        light = bpy.data.objects.new(name, data)
        bpy.context.scene.collection.objects.link(light)
        light.location = center + Vector(offset)
        light.rotation_euler = (center-light.location).to_track_quat("-Z", "Y").to_euler()

    return camera, center, radius


def render_review_views(camera, center, radius, output):
    # One consistent orthographic scale makes silhouette comparisons meaningful.
    distance = radius * 4.2
    views = {
        "three_quarter": Vector((1.5, 0.65, -2.5)).normalized(),
        "front": Vector((0.0, 0.15, -1.0)),
        "side": Vector((1.0, 0.12, 0.0)),
        "back": Vector((0.0, 0.15, 1.0)),
    }
    for view_name, direction in views.items():
        camera.location = center + direction * distance
        # The character is Y-up. Build an explicit camera basis so horizontal
        # side/back views cannot inherit a 90-degree roll from track_quat.
        forward = (center - camera.location).normalized()
        world_up = Vector((0.0, 1.0, 0.0))
        right = forward.cross(world_up).normalized()
        camera_up = right.cross(forward).normalized()
        back = -forward
        camera.rotation_euler = Matrix((right, camera_up, back)).transposed().to_quaternion().to_euler()
        bpy.context.scene.render.filepath = str(output / f"fox_companion_hero_{view_name}.png")
        bpy.ops.render.render(write_still=True)



# Source-space pivots for the hero OBJ. OBJ itself does not preserve object origins,
# so this sidecar is the authoritative hand-off for Roblox pivot placement.
RIG_PARTS = {
    "FoxBody": {"runtime_name": "Body", "pivot": [0.0, 0.91, 0.05], "animated": False},
    "FoxBelly": {"runtime_name": "Chest bib", "pivot": [0.0, 0.91, -0.48], "animated": False},
    "FoxHead": {"runtime_name": "Head", "pivot": [0.0, 1.73, -0.62], "animated": True},
    "FoxMuzzle": {"runtime_name": "Muzzle", "pivot": [0.0, 1.42, -1.055], "animated": True},
    "FoxEarLeft": {"runtime_name": "Ear", "pivot": [-0.39, 1.78, -0.52], "animated": True},
    "FoxEarRight": {"runtime_name": "Ear", "pivot": [0.39, 1.78, -0.52], "animated": True},
    "FoxEarInnerLeft": {"runtime_name": "Inner ear", "pivot": [-0.39, 1.78, -0.52], "animated": True, "attach_to": "FoxEarLeft"},
    "FoxEarInnerRight": {"runtime_name": "Inner ear", "pivot": [0.39, 1.78, -0.52], "animated": True, "attach_to": "FoxEarRight"},
    "FoxLegFrontLeft": {"runtime_name": "Paw", "pivot": [-0.34, 0.78, -0.55], "animated": True},
    "FoxLegFrontRight": {"runtime_name": "Paw", "pivot": [0.34, 0.78, -0.55], "animated": True},
    "FoxLegBackLeft": {"runtime_name": "Paw", "pivot": [-0.34, 0.78, 0.57], "animated": True},
    "FoxLegBackRight": {"runtime_name": "Paw", "pivot": [0.34, 0.78, 0.57], "animated": True},
    "FoxTail": {"runtime_name": "Tail", "pivot": [0.15, 1.02, 0.68], "animated": True},
    "FoxTailTip": {"runtime_name": "Tail tip", "pivot": [0.12, 1.91, 1.91], "animated": True, "attach_to": "FoxTail"},
    "FoxEyes": {"runtime_name": "Eye", "pivot": [0.0, 1.76, -1.105], "animated": False},
    "FoxEyeSparkles": {"runtime_name": "Eye shine", "pivot": [0.0, 1.825, -1.216], "animated": False},
    "FoxNose": {"runtime_name": "Nose", "pivot": [0.0, 1.47, -1.365], "animated": False},
}


def write_rig_metadata(output, objects):
    payload = {
        "asset": "fox_companion_hero",
        "coordinate_system": "Y-up; character faces -Z",
        "units": "source model units",
        "obj_note": "OBJ does not preserve object origins; use these source-space pivots when creating Roblox MeshParts and animation attachments.",
        "parts": RIG_PARTS,
    }
    object_names = {obj.name for obj in objects}
    if object_names != set(GROUPS):
        raise RuntimeError("Fox hero object groups do not match the rig contract")
    validate_rig_payload(payload, expected_groups=GROUPS)
    path = output / "fox_companion_hero_rig.json"
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path



def write_mesh_quality_report(output, objects):
    """Write measurable mesh/UV/material facts for human art review."""
    parts = {}
    for obj in objects:
        if obj.type != "MESH" or len(obj.data.vertices) == 0 or len(obj.data.polygons) == 0:
            raise RuntimeError(f"{obj.name}: expected a non-empty mesh")
        if not obj.data.uv_layers:
            raise RuntimeError(f"{obj.name}: missing UV layer")
        if not obj.data.materials or any(mat is None for mat in obj.data.materials):
            raise RuntimeError(f"{obj.name}: missing material assignment")
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        zero_area_faces = sum(1 for face in bm.faces if face.calc_area() <= 1e-10)
        non_manifold_edges = sum(1 for edge in bm.edges if not edge.is_manifold)
        if zero_area_faces:
            bm.free()
            raise RuntimeError(f"{obj.name}: {zero_area_faces} zero-area faces")
        if non_manifold_edges:
            bm.free()
            raise RuntimeError(f"{obj.name}: {non_manifold_edges} non-manifold edges")
        bm.to_mesh(obj.data)
        bm.free()
        bounds = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        minimum = [min(point[i] for point in bounds) for i in range(3)]
        maximum = [max(point[i] for point in bounds) for i in range(3)]
        parts[obj.name] = {
            "vertices": len(obj.data.vertices),
            "faces": len(obj.data.polygons),
            "zero_area_faces": 0,
            "non_manifold_edges": 0,
            "normals": "recalculated_outward",
            "uv_layers": len(obj.data.uv_layers),
            "materials": [mat.name for mat in obj.data.materials],
            "material_profiles": {
                mat.name: mat.get("giantback_surface_profile", "unspecified")
                for mat in obj.data.materials
            },
            "bounds": {"min": minimum, "max": maximum},
        }
    payload = {
        "asset": "fox_companion_hero",
        "coordinate_system": "Y-up; character faces -Z",
        "part_count": len(parts),
        "parts": parts,
    }
    path = output / "fox_companion_hero_mesh_report.json"
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path


def export_obj(objects, path):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.wm.obj_export(
        filepath=str(path), export_selected_objects=True,
        export_uv=True, export_normals=True, export_materials=True,
        export_object_groups=True, export_material_groups=True,
        forward_axis="NEGATIVE_Z", up_axis="Y", path_mode="COPY",
    )


def main():
    if bpy.app.version < BLENDER_MIN or bpy.app.version >= BLENDER_MAX:
        raise RuntimeError("Use Blender 4.2.x; detected " + bpy.app.version_string)
    args = parse_args()
    output = args.output_dir.resolve()
    if output.exists() and any(output.iterdir()) and not args.overwrite:
        raise FileExistsError("Output folder is not empty; use a fresh folder or --overwrite")
    output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    palette = make_palette()
    objects = create_fox(palette)
    unwrap_and_pack(objects)
    camera, center, radius = add_review_camera(objects)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    # CI uses a fast review resolution; final artist-approved renders can be made at 1200+.
    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.eevee.taa_render_samples = 16
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(output / "fox_companion_hero_three_quarter.png")
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    blend_path = output / "fox_companion_hero.blend"
    obj_path = output / "fox_companion_hero.obj"
    rig_path = write_rig_metadata(output, objects)
    mesh_report_path = write_mesh_quality_report(output, objects)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    export_obj(objects, obj_path)
    render_review_views(camera, center, radius, output)
    print("Fox hero preview OBJ:", obj_path)
    print("Fox hero review blend:", blend_path)
    print("Fox hero rig metadata:", rig_path)
    print("Fox hero mesh quality report:", mesh_report_path)
    print("Fox hero review renders: three_quarter, front, side, back")
    print("NOTE: stylized mesh blockout only; painted fur and Studio acceptance remain open.")


if __name__ == "__main__":
    main()
