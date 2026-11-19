# pyright: reportMissingImports=false
"""Create Crystal Bastion's starter stylized low-poly assets in Blender.

Run in Blender 4.x with:
    blender --background --python tools/blender/create_stylized_assets.py

The script creates an archer tower, a basic enemy, and a hero, then exports
one GLB per asset to res://assets/models/generated/. It keeps materials simple
and palette-driven so the models can later be switched to a shared atlas.
"""

from __future__ import annotations

import math
import os
from typing import Iterable

import bpy
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUTPUT = os.path.join(ROOT, "assets", "models", "generated")

PALETTE = {
    "stone": (0.22, 0.27, 0.34, 1.0),
    "stone_light": (0.38, 0.45, 0.52, 1.0),
    "wood": (0.30, 0.13, 0.06, 1.0),
    "wood_light": (0.55, 0.27, 0.09, 1.0),
    "cloth": (0.08, 0.22, 0.52, 1.0),
    "skin": (0.72, 0.42, 0.25, 1.0),
    "gold": (0.95, 0.58, 0.10, 1.0),
    "crystal": (0.10, 0.72, 0.95, 1.0),
    "enemy": (0.60, 0.12, 0.18, 1.0),
    "dark": (0.035, 0.045, 0.07, 1.0),
}


def material(name: str, color: tuple[float, float, float, float], emission: bool = False) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.78
        if emission:
            bsdf.inputs["Emission Color"].default_value = color
            bsdf.inputs["Emission Strength"].default_value = 4.0
    return mat


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def apply_finish(obj: bpy.types.Object, bevel: float = 0.035) -> bpy.types.Object:
    if obj.type == "MESH":
        obj.data.materials.append(obj.get("_material"))
        bevel_mod = obj.modifiers.new("Bevel", "BEVEL")
        bevel_mod.width = bevel
        bevel_mod.segments = 2
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.shade_smooth_by_angle()
        obj.select_set(False)
    return obj


def cube(name: str, location: tuple[float, float, float], scale: tuple[float, float, float], mat: bpy.types.Material) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj["_material"] = mat
    return apply_finish(obj)


def cylinder(name: str, location: tuple[float, float, float], radius: float, depth: float, mat: bpy.types.Material, vertices: int = 8) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj["_material"] = mat
    return apply_finish(obj)


def ico(name: str, location: tuple[float, float, float], radius: float, mat: bpy.types.Material) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=radius, location=location)
    obj = bpy.context.object
    obj.name = name
    obj["_material"] = mat
    return apply_finish(obj, 0.02)


def parent_all(root: bpy.types.Object, objects: Iterable[bpy.types.Object]) -> None:
    for obj in objects:
        obj.parent = root


def make_root(name: str) -> bpy.types.Object:
    root = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    return root


def export_asset(name: str, root: bpy.types.Object) -> None:
    os.makedirs(OUTPUT, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for obj in root.children_recursive:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUTPUT, f"{name}.glb"),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_yup=True,
        export_animations=True,
    )


def make_archer_tower() -> None:
    clear_scene()
    stone = material("Palette_Stone", PALETTE["stone"])
    light = material("Palette_StoneLight", PALETTE["stone_light"])
    wood = material("Palette_Wood", PALETTE["wood"])
    wood_light = material("Palette_WoodLight", PALETTE["wood_light"])
    crystal = material("Palette_Crystal", PALETTE["crystal"], True)
    root = make_root("ArcherTower")
    base = cylinder("Base-col", (0, 0.45, 0), 1.25, 0.9, stone)
    upper = cylinder("Turret", (0, 1.35, 0), 0.9, 0.8, wood)
    roof = cylinder("Roof", (0, 1.9, 0), 1.05, 0.25, wood_light, 6)
    gem = ico("Crystal", (0, 2.15, 0), 0.25, crystal)
    parent_all(root, [base, upper, roof, gem])
    export_asset("archer_tower", root)


def make_enemy() -> None:
    clear_scene()
    red = material("Palette_Enemy", PALETTE["enemy"])
    dark = material("Palette_Dark", PALETTE["dark"])
    root = make_root("Enemy")
    body = ico("Body", (0, 0.9, 0), 0.65, red)
    head = ico("Head", (0, 1.65, 0), 0.42, red)
    eye = ico("Eye", (0, 1.7, -0.38), 0.08, dark)
    parent_all(root, [body, head, eye])
    export_asset("enemy_basic", root)


def make_hero() -> None:
    clear_scene()
    cloth = material("Palette_Cloth", PALETTE["cloth"])
    skin = material("Palette_Skin", PALETTE["skin"])
    gold = material("Palette_Gold", PALETTE["gold"])
    root = make_root("Hero")
    body = cylinder("Body", (0, 1.0, 0), 0.45, 1.1, cloth)
    head = ico("Head", (0, 1.85, 0), 0.35, skin)
    shoulder = cylinder("ShoulderGuard", (0, 1.35, 0), 0.62, 0.16, gold)
    parent_all(root, [body, head, shoulder])
    export_asset("hero_basic", root)


def main() -> None:
    make_archer_tower()
    make_enemy()
    make_hero()
    print(f"Exported Crystal Bastion assets to {OUTPUT}")


if __name__ == "__main__":
    main()
