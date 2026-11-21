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
from mathutils import Vector
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


def material(name, color, roughness=0.72, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    return mat


def make_palette():
    return {
        "fox_orange": material("fox_orange", (0.91, 0.36, 0.13), 0.82),
        "cream": material("cream", (0.98, 0.86, 0.66), 0.88),
        "ear_pink": material("ear_pink", (0.82, 0.39, 0.35), 0.9),
        "dark": material("dark", (0.08, 0.06, 0.05), 0.28),
        "white": material("white", (1.0, 0.98, 0.87), 0.22),
        "nose": material("nose", (0.12, 0.07, 0.06), 0.24),
        "expression": material("expression", (0.29, 0.12, 0.075), 0.58),
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


def leaf_mesh(name, center, width, height, depth, mat, facing=-1.0):
    """A softly pointed ear/tuft leaf with a rounded cross-section."""
    cx, cy, cz = center
    ring_count, sides = 9, 20
    verts, faces = [], []
    for row in range(ring_count):
        t = row / (ring_count - 1)
        y = cy + (t - 0.5) * height
        profile = max(0.035, math.sin(math.pi * (t ** 0.92)) ** 0.72)
        bend = 0.055 * math.sin(t * math.pi)
        for side in range(sides):
            angle = 2.0 * math.pi * side / sides
            x = cx + math.cos(angle) * width * profile * 0.5
            z = cz + facing * (math.sin(angle) * depth * profile * 0.5 + bend)
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


def create_fox(p):
    # Compact pear-shaped body, with the face consistently pointing toward -Z.
    ellipsoid("FoxBody", (0, 0.91, 0.05), (0.57, 0.63, 0.91), p["fox_orange"])
    ellipsoid("FoxBelly", (0, 0.91, -0.48), (0.43, 0.54, 0.31), p["cream"])

    # Head silhouette: broad forehead, soft cheeks and a shorter, friendlier muzzle.
    ellipsoid("FoxHead", (0, 1.73, -0.62), (0.62, 0.61, 0.56), p["fox_orange"], 40, 28)
    ellipsoid("FoxMuzzle", (0, 1.42, -1.055), (0.39, 0.25, 0.32), p["cream"])
    ellipsoid("CheekFluff_L", (-0.43, 1.48, -0.87), (0.22, 0.18, 0.19), p["cream"], 24, 16)
    ellipsoid("CheekFluff_R", (0.43, 1.48, -0.87), (0.22, 0.18, 0.19), p["cream"], 24, 16)
    ellipsoid("ForeheadTuft", (0, 2.22, -0.59), (0.16, 0.20, 0.18), p["fox_orange"], 24, 16)

    # Tall, gently outward-splayed ears with separate inset inner-ear pieces.
    leaf_mesh("FoxEarLeft", (-0.39, 2.20, -0.52), 0.46, 0.88, 0.30, p["fox_orange"])
    leaf_mesh("FoxEarRight", (0.39, 2.20, -0.52), 0.46, 0.88, 0.30, p["fox_orange"])
    leaf_mesh("FoxEarInner_L", (-0.39, 2.20, -0.695), 0.29, 0.60, 0.10, p["ear_pink"])
    leaf_mesh("FoxEarInner_R", (0.39, 2.20, -0.695), 0.29, 0.60, 0.10, p["ear_pink"])

    # Four independently animated, rounded paws with darker soft paw ends.
    for side, suffix in ((-1, "Left"), (1, "Right")):
        ellipsoid("FoxLegFront" + suffix, (side*0.34, 0.40, -0.55),
                 (0.22, 0.43, 0.25), p["fox_orange"])
        ellipsoid("FoxLegBack" + suffix, (side*0.34, 0.39, 0.57),
                 (0.25, 0.42, 0.31), p["fox_orange"])
        ellipsoid("PawFront" + suffix, (side*0.34, 0.12, -0.61),
                 (0.22, 0.13, 0.25), p["cream"], 24, 16)
        ellipsoid("PawBack" + suffix, (side*0.34, 0.12, 0.61),
                 (0.24, 0.13, 0.27), p["cream"], 24, 16)

    # Big plush tail sweeps up behind the body; cream tip remains separately riggable.
    curved_plume("FoxTail",
        [(0.15, 1.02, 0.68), (0.39, 1.10, 1.08), (0.43, 1.42, 1.55),
         (0.28, 1.76, 1.86), (0.12, 1.91, 1.99)],
        [0.24, 0.36, 0.49, 0.43, 0.26], p["fox_orange"])
    curved_plume("FoxTailTip",
        [(0.12, 1.91, 1.91), (0.06, 2.03, 2.02), (0.00, 2.12, 2.11)],
        [0.28, 0.22, 0.025], p["cream"])

    # Eyes sit on the front (-Z) plane; pupils and catchlights are readable at distance.
    for side, suffix in ((-1, "Left"), (1, "Right")):
        ellipsoid("EyeBase" + suffix, (side*0.255, 1.76, -1.105),
                 (0.145, 0.19, 0.075), p["cream"], 32, 20)
        ellipsoid("EyePupil" + suffix, (side*0.255, 1.765, -1.168),
                 (0.108, 0.145, 0.055), p["dark"], 32, 20)
        ellipsoid("EyeShine" + suffix, (side*0.255-0.035, 1.825, -1.216),
                 (0.038, 0.048, 0.018), p["white"], 20, 12)
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
        "FoxBelly": ["FoxBelly"],
        "FoxHead": ["FoxHead", "ForeheadTuft", "BrowLeft", "BrowRight"],
        "FoxMuzzle": ["FoxMuzzle", "CheekFluff_L", "CheekFluff_R", "Smile"],
        "FoxEarLeft": ["FoxEarLeft"],
        "FoxEarRight": ["FoxEarRight"],
        "FoxEarInnerLeft": ["FoxEarInner_L"],
        "FoxEarInnerRight": ["FoxEarInner_R"],
        "FoxLegFrontLeft": ["FoxLegFrontLeft", "PawFrontLeft"],
        "FoxLegFrontRight": ["FoxLegFrontRight", "PawFrontRight"],
        "FoxLegBackLeft": ["FoxLegBackLeft", "PawBackLeft"],
        "FoxLegBackRight": ["FoxLegBackRight", "PawBackRight"],
        "FoxTail": ["FoxTail"],
        "FoxTailTip": ["FoxTailTip"],
        "FoxEyes": ["EyeBaseLeft", "EyeBaseRight", "EyePupilLeft", "EyePupilRight"],
        "FoxEyeSparkles": ["EyeShineLeft", "EyeShineRight"],
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
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.55

    for name, offset, power, size in (
        ("Key", (1.8, 2.8, -2.0), 1200, 3.2),
        ("Fill", (-2.0, 1.0, -1.0), 650, 2.8),
        ("Rim", (0.0, 2.0, 2.8), 950, 2.4),
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
        camera.rotation_euler = (center-camera.location).to_track_quat("-Z", "Y").to_euler()
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
    scene.render.resolution_x = 1200
    scene.render.resolution_y = 1200
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(output / "fox_companion_hero_three_quarter.png")
    scene.view_settings.view_transform = "AgX"
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
