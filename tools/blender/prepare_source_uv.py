#!/usr/bin/env python3
"""Prepare non-destructive Smart UV blockout exports for Giantback source meshes.

Run with Blender 4.2 LTS:
  blender --background --python tools/blender/prepare_source_uv.py -- \
    --input assets/source_models --output build/uv_preview

This creates preview OBJ/MTL files only. It never overwrites the editable sources.
Smart UV is a technical first pass, not final hand-authored UVs or painted textures.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

import bpy


ASSETS = (
    "fox_companion",
    "moth_companion",
    "home_cottage",
    "farm_bed",
    "bridge_segment",
    "home_island",
)
BLENDER_MIN = (4, 2, 0)
BLENDER_MAX = (4, 4, 0)
UV_MARGIN = 0.025
SMART_ANGLE_DEGREES = 66.0


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--assets", nargs="+", choices=ASSETS, default=list(ASSETS))
    parser.add_argument(
        "--overwrite-previews",
        action="store_true",
        help="replace existing files in the preview output directory",
    )
    return parser.parse_args(argv)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def import_source(path: Path) -> list:
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
    return objects


def unwrap_objects(objects: list) -> None:
    # Multi-object edit mode lets Blender pack all object islands into one shared
    # 0-1 atlas while preserving the separate named mesh objects for rigging.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(
        angle_limit=math.radians(SMART_ANGLE_DEGREES),
        island_margin=UV_MARGIN,
        area_weight=0.0,
        correct_aspect=True,
        scale_to_bounds=False,
    )
    bpy.ops.uv.pack_islands(rotate=True, margin=UV_MARGIN)
    bpy.ops.object.mode_set(mode="OBJECT")

    for obj in objects:
        if not obj.data.uv_layers:
            raise RuntimeError(f"UV unwrap failed for object {obj.name}")
        uv_values = [
            component
            for loop in obj.data.uv_layers.active.data
            for component in (loop.uv.x, loop.uv.y)
        ]
        if not uv_values or not all(math.isfinite(value) for value in uv_values):
            raise RuntimeError(f"Invalid UV coordinates on object {obj.name}")
        if min(uv_values) < -1e-5 or max(uv_values) > 1.00001:
            raise RuntimeError(f"UV coordinates outside 0-1 atlas on object {obj.name}")



def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def validate_export(path: Path) -> dict:
    vertex_count = 0
    uv_count = 0
    normal_count = 0
    face_count = 0
    uv_min = [float("inf"), float("inf")]
    uv_max = [float("-inf"), float("-inf")]

    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if line.startswith("v "):
            vertex_count += 1
        elif line.startswith("vt "):
            values = [float(value) for value in line.split()[1:3]]
            if len(values) != 2 or not all(math.isfinite(value) for value in values):
                raise RuntimeError(f"{path.name}:{line_number}: invalid UV coordinate")
            uv_count += 1
            for axis in range(2):
                uv_min[axis] = min(uv_min[axis], values[axis])
                uv_max[axis] = max(uv_max[axis], values[axis])
        elif line.startswith("vn "):
            normal_count += 1
        elif line.startswith("f "):
            face_count += 1
            tokens = line.split()[1:]
            if len(tokens) < 3:
                raise RuntimeError(f"{path.name}:{line_number}: face has fewer than 3 corners")
            for token in tokens:
                parts = token.split("/")
                if len(parts) != 3 or not parts[1] or not parts[2]:
                    raise RuntimeError(f"{path.name}:{line_number}: face is missing UV or normal data")
                vertex_index, uv_index, normal_index = int(parts[0]), int(parts[1]), int(parts[2])
                if vertex_index == 0 or abs(vertex_index) > vertex_count:
                    raise RuntimeError(f"{path.name}:{line_number}: vertex index out of range")
                if uv_index == 0 or abs(uv_index) > uv_count:
                    raise RuntimeError(f"{path.name}:{line_number}: UV index out of range")
                if normal_index == 0 or abs(normal_index) > normal_count:
                    raise RuntimeError(f"{path.name}:{line_number}: normal index out of range")

    if not vertex_count or not uv_count or not normal_count or not face_count:
        raise RuntimeError(f"{path.name}: export is missing vertices, UVs, normals or faces")
    if min(uv_min) < -1e-5 or max(uv_max) > 1.00001:
        raise RuntimeError(f"{path.name}: exported UV atlas exceeds the 0-1 range")
    return {
        "vertices": vertex_count,
        "uv_coordinates": uv_count,
        "normals": normal_count,
        "faces": face_count,
        "uv_min": uv_min,
        "uv_max": uv_max,
        "sha256": sha256_file(path),
    }


def export_preview(objects: list, destination: Path) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.wm.obj_export(
        filepath=str(destination),
        export_selected_objects=True,
        export_uv=True,
        export_normals=True,
        export_materials=True,
        export_object_groups=True,
        export_material_groups=True,
        forward_axis="NEGATIVE_Z",
        up_axis="Y",
        path_mode="COPY",
    )


def main() -> None:
    if bpy.app.version < BLENDER_MIN or bpy.app.version >= BLENDER_MAX:
        raise RuntimeError(
            f"Use Blender 4.2.x; detected {bpy.app.version_string}"
        )
    args = parse_args()
    input_dir = args.input.resolve()
    output_dir = args.output.resolve()
    if input_dir == output_dir:
        raise RuntimeError("Input and output directories must be different; source files are protected")
    if not input_dir.is_dir():
        raise FileNotFoundError(f"Input directory does not exist: {input_dir}")
    pending_outputs = [
        output_dir / f"{asset}.{extension}"
        for asset in args.assets
        for extension in ("obj", "mtl")
    ]
    manifest_path = output_dir / "uv_preview_manifest.json"
    existing = [path for path in pending_outputs + [manifest_path] if path.exists()]
    if existing and not args.overwrite_previews:
        raise FileExistsError(
            "Preview output already exists. Choose a new output directory or pass "
            "--overwrite-previews explicitly: " + ", ".join(str(path) for path in existing)
        )
    output_dir.mkdir(parents=True, exist_ok=True)
    report = {
        "kind": "smart_uv_preview",
        "blender_version": bpy.app.version_string,
        "smart_angle_degrees": SMART_ANGLE_DEGREES,
        "uv_margin": UV_MARGIN,
        "final_art_approved": False,
        "assets": [],
    }

    for asset in args.assets:
        source = input_dir / f"{asset}.obj"
        if not source.is_file():
            raise FileNotFoundError(source)
        reset_scene()
        objects = import_source(source)
        original_names = sorted(obj.name for obj in objects)
        unwrap_objects(objects)
        destination = output_dir / f"{asset}.obj"
        export_preview(objects, destination)
        export_stats = validate_export(destination)
        report["assets"].append(
            {
                "name": asset,
                "source": str(source),
                "source_sha256": sha256_file(source),
                "preview": str(destination),
                "export": export_stats,
                "mesh_objects": original_names,
                "uv_ready_for_visual_review": True,
                "texture_painted": False,
                "studio_accepted": False,
            }
        )

    (output_dir / "uv_preview_manifest.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )


if __name__ == "__main__":
    main()
