#!/usr/bin/env python3
"""Render a disposable, checker-textured turntable-style still for a UV preview OBJ.

Run after prepare_source_uv.py and generate_uv_checker.py:
  blender --background --python tools/blender/render_uv_preview.py -- \
    --input build/uv_preview/fox_companion.obj \
    --checker build/uv_checker.png \
    --output build/uv_review/fox_companion_uv.png

The script only reads the OBJ/checker and writes a PNG plus a .blend review scene.
It never edits source OBJ/MTL files.
"""
from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


BLENDER_MIN = (4, 2, 0)
BLENDER_MAX = (4, 4, 0)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--checker", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--resolution", type=int, default=1024)
    parser.add_argument("--overwrite", action="store_true")
    return parser.parse_args(argv)


def import_preview(path: Path) -> list:
    bpy.ops.wm.obj_import(
        filepath=str(path),
        forward_axis="NEGATIVE_Z",
        up_axis="Y",
        use_split_objects=True,
        use_split_groups=True,
        validate_meshes=True,
    )
    objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not objects:
        raise RuntimeError(f"No mesh objects imported from {path.name}")
    for obj in objects:
        if not obj.data.uv_layers:
            raise RuntimeError(f"Imported preview has no UV layer: {obj.name}")
    return objects


def assign_checker(objects: list, checker_path: Path) -> None:
    image = bpy.data.images.load(str(checker_path), check_existing=True)
    image.filepath = str(checker_path)
    material = bpy.data.materials.new(name="TEMP_UV_DIAGNOSTIC_CHECKER")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()

    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    texture.interpolation = "Closest"
    texture.extension = "REPEAT"
    texture.label = "Diagnostic only — remove before final texture authoring"
    links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])

    for obj in objects:
        obj.data.materials.clear()
        obj.data.materials.append(material)


def bounds(objects: list) -> tuple[Vector, float]:
    corners = [
        obj.matrix_world @ Vector(corner)
        for obj in objects
        for corner in obj.bound_box
    ]
    minimum = Vector(tuple(min(point[axis] for point in corners) for axis in range(3)))
    maximum = Vector(tuple(max(point[axis] for point in corners) for axis in range(3)))
    center = (minimum + maximum) * 0.5
    radius = max((maximum - minimum).length * 0.5, 0.5)
    return center, radius


def setup_camera_and_lights(center: Vector, radius: float) -> None:
    scene = bpy.context.scene
    camera_data = bpy.data.cameras.new("UVReviewCamera")
    camera = bpy.data.objects.new("UVReviewCamera", camera_data)
    scene.collection.objects.link(camera)
    direction = Vector((1.55, -2.2, 1.45)).normalized()
    camera.location = center + direction * radius * 3.8
    camera.rotation_euler = (center - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = radius * 2.9
    scene.camera = camera

    for name, offset, energy, size in (
        ("Key", Vector((1.8, -2.0, 2.8)), 1500, radius * 1.8),
        ("Fill", Vector((-2.0, -0.8, 1.2)), 850, radius * 1.5),
        ("Rim", Vector((0.2, 2.0, 2.2)), 1200, radius * 1.2),
    ):
        data = bpy.data.lights.new(name, type="AREA")
        data.energy = energy
        data.shape = "DISK"
        data.size = size
        light = bpy.data.objects.new(name, data)
        scene.collection.objects.link(light)
        light.location = center + offset * radius
        light.rotation_euler = (center - light.location).to_track_quat("-Z", "Y").to_euler()

    world = bpy.data.worlds.new("UVReviewWorld") if not bpy.data.worlds else bpy.data.worlds[0]
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.16, 0.19, 0.24, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.45


def main() -> None:
    if bpy.app.version < BLENDER_MIN or bpy.app.version >= BLENDER_MAX:
        raise RuntimeError(f"Use Blender 4.2.x; detected {bpy.app.version_string}")
    args = parse_args()
    input_path = args.input.resolve()
    checker_path = args.checker.resolve()
    output_path = args.output.resolve()
    blend_path = output_path.with_suffix(".blend")

    if not input_path.is_file():
        raise FileNotFoundError(input_path)
    if not checker_path.is_file():
        raise FileNotFoundError(checker_path)
    if input_path in (checker_path, output_path, blend_path):
        raise RuntimeError("Input, checker and output paths must be distinct")
    if args.resolution < 256 or args.resolution > 4096:
        raise ValueError("--resolution must be between 256 and 4096")
    existing = [path for path in (output_path, blend_path) if path.exists()]
    if existing and not args.overwrite:
        raise FileExistsError(
            "Review output already exists; pass --overwrite explicitly: "
            + ", ".join(str(path) for path in existing)
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    objects = import_preview(input_path)
    assign_checker(objects, checker_path)
    center, radius = bounds(objects)
    setup_camera_and_lights(center, radius)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = args.resolution
    scene.render.resolution_y = args.resolution
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"
    scene.render.filepath = str(output_path)
    scene.render.image_settings.color_mode = "RGBA"

    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.render.render(write_still=True)
    print(f"UV diagnostic render: {output_path}")
    print(f"Review scene: {blend_path}")
    print("Diagnostic checker material is temporary; it is not production art.")


if __name__ == "__main__":
    main()
