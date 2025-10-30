#!/usr/bin/env python3
"""
Utility script to convert legacy Tanky .ttp pattern files into 32x32 PNGs.

The converter expects:
  * An accompanying palette file (default: Paleta.pal with 256 RGB entries).
  * Pattern files encoded as 8-bit indexed images with a 10-byte header.

Usage:
    python tools/convert_ttp.py \
        --palette /home/jmn/OneDrive/Programación/Legado/Tanky Alberto/Paleta.pal \
        --output assets/tiles \
        "/home/jmn/OneDrive/Programación/Legado/Tanky Alberto/Patrones/Suelo terroso (relleno).ttp" \
        ...
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image

HEADER_SIZE = 10  # 5 * uint16_t
EXPECTED_PIXELS = 32 * 32


def load_palette(path: Path) -> Sequence[int]:
    data = path.read_bytes()
    if len(data) != 256 * 3:
        raise ValueError(f"{path} does not look like a 256-color RGB palette")
    return list(data)


def convert_pattern(pattern_path: Path, palette: Sequence[int], output_dir: Path) -> Path:
    raw = pattern_path.read_bytes()
    if len(raw) <= HEADER_SIZE:
        raise ValueError(f"{pattern_path} is too small to contain pixel data")
    pixel_data = raw[HEADER_SIZE:]
    if len(pixel_data) != EXPECTED_PIXELS:
        raise ValueError(
            f"{pattern_path} has {len(pixel_data)} bytes; only 32x32 patterns are supported"
        )

    img = Image.new("P", (32, 32))
    img.putpalette(palette)
    img.putdata(pixel_data)

    sanitized_name = pattern_path.stem.replace(" ", "_").lower()
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{sanitized_name}.png"
    img.save(output_path)
    return output_path


def main(argv: Iterable[str]) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--palette",
        type=Path,
        required=True,
        help="Path to the 256-color .pal file",
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Directory where converted PNGs will be written",
    )
    parser.add_argument("patterns", nargs="+", type=Path, help=".ttp files to convert")
    args = parser.parse_args(list(argv))

    palette = load_palette(args.palette)
    for pattern in args.patterns:
        output = convert_pattern(pattern, palette, args.output)
        print(f"Converted {pattern} -> {output}")


if __name__ == "__main__":
    main(os.sys.argv[1:])
