"""Pure-Python validation for Blender-exported Wavefront OBJ previews.

Kept free of bpy so the parser can be exercised by the normal CI test runner.
"""
from __future__ import annotations

import hashlib
import math
from pathlib import Path


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _resolve_index(raw: str, count: int, kind: str, path: Path, line_number: int) -> int:
    try:
        value = int(raw)
    except ValueError as error:
        raise RuntimeError(f"{path.name}:{line_number}: invalid {kind} index {raw!r}") from error
    if value == 0:
        raise RuntimeError(f"{path.name}:{line_number}: {kind} index cannot be zero")
    resolved = value - 1 if value > 0 else count + value
    if resolved < 0 or resolved >= count:
        raise RuntimeError(f"{path.name}:{line_number}: {kind} index out of range")
    return resolved


def validate_obj(path: Path) -> dict:
    vertex_count = 0
    uv_count = 0
    normal_count = 0
    face_count = 0
    uv_min = [float("inf"), float("inf")]
    uv_max = [float("-inf"), float("-inf")]
    uv_coordinates = []
    uv_face_area_total = 0.0
    degenerate_uv_faces = 0
    material_libraries = []
    material_uses = 0

    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("v "):
            values = [float(value) for value in line.split()[1:4]]
            if len(values) != 3 or not all(math.isfinite(value) for value in values):
                raise RuntimeError(f"{path.name}:{line_number}: invalid vertex")
            vertex_count += 1
        elif line.startswith("vt "):
            values = [float(value) for value in line.split()[1:3]]
            if len(values) != 2 or not all(math.isfinite(value) for value in values):
                raise RuntimeError(f"{path.name}:{line_number}: invalid UV coordinate")
            uv_count += 1
            uv_coordinates.append(values)
            for axis in range(2):
                uv_min[axis] = min(uv_min[axis], values[axis])
                uv_max[axis] = max(uv_max[axis], values[axis])
        elif line.startswith("vn "):
            values = [float(value) for value in line.split()[1:4]]
            if len(values) != 3 or not all(math.isfinite(value) for value in values):
                raise RuntimeError(f"{path.name}:{line_number}: invalid normal")
            normal_count += 1
        elif line.startswith("mtllib "):
            material_libraries.extend(line.split()[1:])
        elif line.startswith("usemtl "):
            material_uses += 1
        elif line.startswith("f "):
            face_count += 1
            tokens = line.split()[1:]
            if len(tokens) < 3:
                raise RuntimeError(f"{path.name}:{line_number}: face has fewer than 3 corners")
            face_uvs = []
            for token in tokens:
                parts = token.split("/")
                if len(parts) != 3 or not all(parts):
                    raise RuntimeError(f"{path.name}:{line_number}: face is missing vertex, UV or normal data")
                _resolve_index(parts[0], vertex_count, "vertex", path, line_number)
                uv_index = _resolve_index(parts[1], uv_count, "UV", path, line_number)
                _resolve_index(parts[2], normal_count, "normal", path, line_number)
                face_uvs.append(uv_coordinates[uv_index])

            # Shoelace area on the UV polygon. A zero-area face means at least
            # one triangle collapses to a line/point in texture space.
            twice_area = sum(
                face_uvs[index][0] * face_uvs[(index + 1) % len(face_uvs)][1]
                - face_uvs[(index + 1) % len(face_uvs)][0] * face_uvs[index][1]
                for index in range(len(face_uvs))
            )
            face_area = abs(twice_area) * 0.5
            if face_area <= 1e-10:
                degenerate_uv_faces += 1
            else:
                uv_face_area_total += face_area

    if not vertex_count or not uv_count or not normal_count or not face_count:
        raise RuntimeError(f"{path.name}: export is missing vertices, UVs, normals or faces")
    if min(uv_min) < -1e-5 or max(uv_max) > 1.00001:
        raise RuntimeError(f"{path.name}: exported UV atlas exceeds the 0-1 range")
    if degenerate_uv_faces:
        raise RuntimeError(f"{path.name}: {degenerate_uv_faces} face(s) have zero-area UVs")
    return {
        "vertices": vertex_count,
        "uv_coordinates": uv_count,
        "normals": normal_count,
        "faces": face_count,
        "uv_degenerate_faces": degenerate_uv_faces,
        "uv_face_area_total": uv_face_area_total,
        "uv_min": uv_min,
        "uv_max": uv_max,
        "material_libraries": material_libraries,
        "material_uses": material_uses,
        "sha256": sha256_file(path),
    }
