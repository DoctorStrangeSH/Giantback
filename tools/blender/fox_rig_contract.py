"""Pure-Python validation for the Fox Hero rig sidecar.

Kept outside Blender so CI can validate the generated hand-off contract without
installing or launching Blender.
"""
from __future__ import annotations

import math
from typing import Iterable, Mapping, Any


def validate_rig_payload(payload: Mapping[str, Any], expected_groups: Iterable[str] | None = None) -> dict:
    if payload.get("asset") != "fox_companion_hero":
        raise ValueError("rig metadata asset must be fox_companion_hero")
    if payload.get("coordinate_system") != "Y-up; character faces -Z":
        raise ValueError("unsupported rig metadata coordinate system")
    if payload.get("units") != "source model units":
        raise ValueError("rig metadata units must be source model units")

    parts = payload.get("parts")
    if not isinstance(parts, dict) or not parts:
        raise ValueError("rig metadata parts must be a non-empty object")

    names = set(parts)
    if expected_groups is not None:
        expected = set(expected_groups)
        if names != expected:
            missing = sorted(expected - names)
            extra = sorted(names - expected)
            raise ValueError(f"rig metadata group mismatch; missing={missing}, extra={extra}")

    for source_name, item in parts.items():
        if not isinstance(item, dict):
            raise ValueError(f"{source_name}: metadata must be an object")
        runtime_name = item.get("runtime_name")
        if not isinstance(runtime_name, str) or not runtime_name.strip():
            raise ValueError(f"{source_name}: runtime_name is required")
        pivot = item.get("pivot")
        if (
            not isinstance(pivot, list)
            or len(pivot) != 3
            or any(isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) for value in pivot)
        ):
            raise ValueError(f"{source_name}: pivot must contain three finite numbers")
        if not isinstance(item.get("animated"), bool):
            raise ValueError(f"{source_name}: animated must be boolean")
        parent = item.get("attach_to")
        if parent is not None:
            if parent not in names:
                raise ValueError(f"{source_name}: attach_to references unknown group {parent!r}")
            if parent == source_name:
                raise ValueError(f"{source_name}: cannot attach a group to itself")
            if not parts[parent].get("animated"):
                raise ValueError(f"{source_name}: attachment parent {parent!r} must be animated")

    return {
        "asset": payload["asset"],
        "part_count": len(parts),
        "animated_count": sum(1 for item in parts.values() if item["animated"]),
        "attachment_count": sum(1 for item in parts.values() if item.get("attach_to")),
    }
