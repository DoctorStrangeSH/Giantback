#!/usr/bin/env python3
"""Generate a crisp UV distortion checker PNG using only the Python standard library.

Example:
  python tools/blender/generate_uv_checker.py --output build/uv_checker.png
"""
from __future__ import annotations

import argparse
import struct
import zlib
from pathlib import Path


def _chunk(kind: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )


def build_checker(size: int = 1024, tiles: int = 8, subdivisions: int = 8) -> bytes:
    if size < 64 or size > 8192:
        raise ValueError("size must be between 64 and 8192 pixels")
    if tiles < 2 or tiles > 32 or size % tiles:
        raise ValueError("tiles must be 2..32 and divide size exactly")
    if subdivisions < 1 or subdivisions > 16:
        raise ValueError("subdivisions must be between 1 and 16")

    tile_size = size // tiles
    cell_size = tile_size // subdivisions
    if cell_size < 2:
        raise ValueError("checker cells must be at least 2 pixels wide")

    rows = bytearray()
    for y in range(size):
        rows.append(0)  # PNG filter: None
        for x in range(size):
            tile_x, tile_y = x // tile_size, y // tile_size
            cell_x, cell_y = (x % tile_size) // cell_size, (y % tile_size) // cell_size
            alternate = (tile_x + tile_y + cell_x + cell_y) % 2 == 0
            # Alternating high-contrast warm/cool squares reveal UV stretching.
            base = (238, 226, 194) if alternate else (49, 83, 112)
            local_x, local_y = x % tile_size, y % tile_size
            edge = min(local_x, local_y, tile_size - 1 - local_x, tile_size - 1 - local_y)
            if edge < max(1, size // 1024):
                pixel = (28, 35, 43)
            elif x % cell_size == 0 or y % cell_size == 0:
                pixel = (112, 142, 158)
            else:
                pixel = base
            rows.extend(pixel)

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", header)
        + _chunk(b"IDAT", zlib.compress(bytes(rows), level=9))
        + _chunk(b"IEND", b"")
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--size", type=int, default=1024)
    parser.add_argument("--tiles", type=int, default=8)
    parser.add_argument("--subdivisions", type=int, default=8)
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    destination = args.output.resolve()
    if destination.exists() and not args.overwrite:
        raise FileExistsError(f"Refusing to overwrite {destination}; pass --overwrite explicitly")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(build_checker(args.size, args.tiles, args.subdivisions))
    print(f"Created UV checker: {destination} ({args.size}x{args.size})")


if __name__ == "__main__":
    main()
