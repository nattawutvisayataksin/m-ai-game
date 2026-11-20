"""Create the low-poly pine used to frame the first campaign level.

Run from the project root with:
    blender --background --python tools/blender/create_stylized_pine.py

Coordinates are authored in Blender's Z-up space; the glTF exporter converts
them to Godot's Y-up space so the trunk base sits at the origin.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "models" / "generated" / "stylized_pine.glb"


def make_material(name: str, color: tuple[float, float, float]) -> bpy.types.Material:
    material = bpy.data.materials.new(name=name)
    rgba = (*color, 1.0)
    material.diffuse_color = rgba
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled:
        principled.inputs["Base Color"].default_value = rgba
        principled.inputs["Roughness"].default_value = 0.88
    return material


def main() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    bark = make_material("Bark • warm cedar", (0.28, 0.13, 0.07))
    deep = make_material("Needles • deep pine", (0.075, 0.24, 0.16))
    forest = make_material("Needles • forest green", (0.11, 0.34, 0.20))
    sunlit = make_material("Needles • sunlit tips", (0.20, 0.43, 0.25))

    bpy.ops.mesh.primitive_cylinder_add(
        vertices=9, radius=0.24, depth=2.15, location=(0.0, 0.0, 1.075)
    )
    trunk = bpy.context.object
    trunk.name = "Pine_Trunk"
    trunk.data.materials.append(bark)
    parts = [trunk]

    crowns = ((2.45, 1.55, 1.95), (2.3, 1.27, 2.95), (2.05, 0.95, 3.82))
    for index, (height, radius, center_z) in enumerate(crowns):
        bpy.ops.mesh.primitive_cone_add(
            vertices=9,
            radius1=radius,
            radius2=0.0,
            depth=height,
            location=(0.0, 0.0, center_z),
            rotation=(0.0, 0.0, math.radians(index * 11)),
        )
        crown = bpy.context.object
        crown.name = f"Pine_Crown_{index + 1}"
        crown.data.materials.append((deep, forest, sunlit)[index])
        parts.append(crown)

    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = trunk
    bpy.ops.object.join()
    trunk.name = "StylizedPine"
    for polygon in trunk.data.polygons:
        polygon.use_smooth = False

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT),
        export_format="GLB",
        export_apply=True,
        export_yup=True,
    )
    print(f"Exported {OUTPUT}")


if __name__ == "__main__":
    main()
