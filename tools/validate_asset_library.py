#!/usr/bin/env python3
"""Validate the tracked Giantback source-asset library without Blender or Roblox Studio."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "assets" / "source_models"
REQUIRED_PAIRS = (
    "bridge_segment",
    "farm_bed",
    "fox_companion",
    "home_cottage",
    "home_island",
    "moth_companion",
)


def validate() -> list[str]:
    errors: list[str] = []
    for stem in REQUIRED_PAIRS:
        obj_path = SOURCE_DIR / f"{stem}.obj"
        mtl_path = SOURCE_DIR / f"{stem}.mtl"
        if not obj_path.is_file() or obj_path.stat().st_size == 0:
            errors.append(f"Missing or empty source mesh: {obj_path.relative_to(ROOT)}")
            continue
        if not mtl_path.is_file() or mtl_path.stat().st_size == 0:
            errors.append(f"Missing or empty material library: {mtl_path.relative_to(ROOT)}")
            continue

        vertices = faces = 0
        referenced_materials: set[str] = set()
        for line_number, raw in enumerate(obj_path.read_text(encoding="utf-8").splitlines(), 1):
            line = raw.strip()
            if line.startswith("v "):
                vertices += 1
            elif line.startswith("f "):
                if len(line.split()) < 4:
                    errors.append(f"{obj_path.name}:{line_number}: face has fewer than 3 vertices")
            elif line.startswith("mtllib "):
                referenced_materials.update(line.split()[1:])
            if line.startswith("f "):
                faces += 1
        if vertices < 3 or faces < 1:
            errors.append(f"{obj_path.name}: expected non-empty geometry, got {vertices} vertices / {faces} faces")
        if not referenced_materials:
            errors.append(f"{obj_path.name}: no mtllib declaration")
        for material_name in referenced_materials:
            if not (SOURCE_DIR / material_name).is_file():
                errors.append(f"{obj_path.name}: referenced material file is missing: {material_name}")

    manifest = SOURCE_DIR / "ASSET_MANIFEST.md"
    if not manifest.is_file():
        errors.append("Missing assets/source_models/ASSET_MANIFEST.md")
    else:
        manifest_text = manifest.read_text(encoding="utf-8")
        for stem in REQUIRED_PAIRS:
            if f"{stem}.obj" not in manifest_text:
                errors.append(f"Asset manifest does not mention {stem}.obj")

    return errors


if __name__ == "__main__":
    problems = validate()
    if problems:
        raise SystemExit("\n".join(problems))
    print(f"Validated {len(REQUIRED_PAIRS)} original OBJ/MTL source pairs and the asset manifest.")
