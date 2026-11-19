# pyright: reportMissingImports=false
"""Create a 256x256 starter palette atlas for Crystal Bastion.

Run from Blender's Python console or with:
    blender --background --python tools/blender/create_palette_atlas.py
"""

from __future__ import annotations

import os

import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUTPUT = os.path.join(ROOT, "assets", "textures", "palette_atlas.png")

COLORS = [
    (0.22, 0.27, 0.34, 1.0),
    (0.38, 0.45, 0.52, 1.0),
    (0.30, 0.13, 0.06, 1.0),
    (0.55, 0.27, 0.09, 1.0),
    (0.08, 0.22, 0.52, 1.0),
    (0.72, 0.42, 0.25, 1.0),
    (0.95, 0.58, 0.10, 1.0),
    (0.10, 0.72, 0.95, 1.0),
    (0.60, 0.12, 0.18, 1.0),
    (0.035, 0.045, 0.07, 1.0),
]


def main() -> None:
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    image = bpy.data.images.new("CrystalBastionPalette", width=256, height=256, alpha=True)
    pixels = [0.0] * (256 * 256 * 4)
    cell_width = 256 // len(COLORS)
    for index, color in enumerate(COLORS):
        start_x = index * cell_width
        end_x = 256 if index == len(COLORS) - 1 else (index + 1) * cell_width
        for y in range(256):
            for x in range(start_x, end_x):
                offset = (y * 256 + x) * 4
                pixels[offset:offset + 4] = color
    image.pixels = pixels
    image.filepath_raw = OUTPUT
    image.file_format = "PNG"
    image.save()
    print(f"Saved palette atlas to {OUTPUT}")


if __name__ == "__main__":
    main()
