"""Create the broadleaf tree and rock spire scenery variants.

Run from the project root with:
    blender --background --python tools/blender/create_stylized_scenery.py

Coordinates are authored in Blender's Z-up space; the glTF exporter converts
them to Godot's Y-up space so each model's base sits at the origin.
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "assets" / "models" / "generated"


def make_material(name: str, color: tuple[float, float, float]) -> bpy.types.Material:
    material = bpy.data.materials.new(name=name)
    rgba = (*color, 1.0)
    material.diffuse_color = rgba
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    if principled:
        principled.inputs["Base Color"].default_value = rgba
        principled.inputs["Roughness"].default_value = 0.9
    return material


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.materials):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def finish(obj: bpy.types.Object, material: bpy.types.Material, scale: tuple[float, float, float] | None = None) -> bpy.types.Object:
    if scale is not None:
        obj.scale = scale
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.use_smooth = False
    return obj


def cylinder(name: str, location: tuple[float, float, float], radius: float, depth: float, material: bpy.types.Material, vertices: int = 8) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    return finish(obj, material)


def cone(name: str, location: tuple[float, float, float], radius1: float, radius2: float, depth: float, material: bpy.types.Material, vertices: int = 7, z_rotation: float = 0.0) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=location,
        rotation=(0.0, 0.0, math.radians(z_rotation)),
    )
    obj = bpy.context.object
    obj.name = name
    return finish(obj, material)


def ico(name: str, location: tuple[float, float, float], radius: float, material: bpy.types.Material, scale: tuple[float, float, float] | None = None) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    return finish(obj, material, scale)


def join_parts(parts: list[bpy.types.Object], name: str) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    joined = bpy.context.object
    joined.name = name
    return joined


def export_asset(name: str, obj: bpy.types.Object) -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(
        filepath=str(OUTPUT / f"{name}.glb"),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
    )
    print(f"Exported {OUTPUT / f'{name}.glb'}")


def make_broadleaf() -> None:
    clear_scene()
    bark = make_material("Bark - broadleaf", (0.26, 0.15, 0.08))
    deep = make_material("Leaves - deep", (0.08, 0.27, 0.14))
    forest = make_material("Leaves - forest", (0.14, 0.38, 0.18))
    sunlit = make_material("Leaves - sunlit", (0.26, 0.48, 0.22))

    trunk = cylinder("Broadleaf_Trunk", (0.0, 0.0, 1.3), 0.26, 2.6, bark, 8)
    parts = [
        trunk,
        ico("Broadleaf_Canopy_Main", (0.0, 0.0, 3.15), 1.5, forest, (1.15, 1.0, 0.95)),
        ico("Broadleaf_Canopy_Right", (0.95, 0.25, 2.55), 0.95, deep),
        ico("Broadleaf_Canopy_Left", (-0.85, -0.3, 2.7), 1.0, deep),
        ico("Broadleaf_Canopy_Top", (0.15, -0.85, 3.5), 0.8, sunlit),
    ]
    export_asset("stylized_broadleaf", join_parts(parts, "StylizedBroadleaf"))


def make_rock_spire() -> None:
    clear_scene()
    stone = make_material("Rock - deep", (0.16, 0.19, 0.23))
    stone_light = make_material("Rock - sunlit", (0.28, 0.32, 0.37))

    base = ico("RockSpire_Base", (0.0, 0.0, 0.55), 1.1, stone, (1.2, 1.0, 0.65))
    parts = [
        base,
        cone("RockSpire_Mid", (0.0, 0.0, 1.6), 0.85, 0.55, 1.8, stone_light, 7),
        cone("RockSpire_Tip", (0.0, 0.0, 2.9), 0.5, 0.0, 1.2, stone, 6, 18.0),
        ico("RockSpire_Chip", (0.85, -0.35, 0.35), 0.45, stone_light),
    ]
    export_asset("stylized_rock_spire", join_parts(parts, "StylizedRockSpire"))


def main() -> None:
    make_broadleaf()
    make_rock_spire()


if __name__ == "__main__":
    main()
