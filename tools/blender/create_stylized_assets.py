# pyright: reportMissingImports=false
"""Create Crystal Bastion's starter stylized low-poly assets in Blender.

Run in Blender 4.x or newer with:
    blender --background --python tools/blender/create_stylized_assets.py

All coordinates are authored in Blender's Z-up space. The glTF exporter converts
them to Godot's Y-up space, so each model's base stays at the origin.

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


def cone(name: str, location: tuple[float, float, float], radius1: float, radius2: float, depth: float, mat: bpy.types.Material, vertices: int = 6) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius1, radius2=radius2, depth=depth, location=location)
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


def add_action(root: bpy.types.Object, name: str, frames: list[tuple[int, tuple[float, float, float], tuple[float, float, float]]]) -> None:
    """Add a small root transform animation exported as a named GLB clip."""
    action = bpy.data.actions.new(name)
    root.animation_data_create()
    root.animation_data.action = action
    for frame, location, rotation in frames:
        root.location = location
        root.rotation_euler = rotation
        root.keyframe_insert(data_path="location", frame=frame, group=name)
        root.keyframe_insert(data_path="rotation_euler", frame=frame, group=name)
    # Blender 5.x stores action curves through layered action slots; the
    # default keyframe interpolation is suitable for these small clips.
    track = root.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, 1, action)
    strip.frame_end = max(float(frames[-1][0]), 1.0)
    root.animation_data.action = None


def add_character_actions(root: bpy.types.Object, is_hero: bool = False) -> None:
    if is_hero:
        add_action(root, "Idle", [(1, (0, 0, 0), (0, 0, 0)), (20, (0, 0.035, 0), (0, 0, 0)), (40, (0, 0, 0), (0, 0, 0))])
        add_action(root, "Walk", [(1, (0, 0, 0), (0, 0, -0.035)), (8, (0, 0.05, 0), (0, 0, 0.035)), (16, (0, 0, 0), (0, 0, -0.035))])
        add_action(root, "Attack", [(1, (0, 0, 0), (0, 0, 0)), (5, (0, 0.02, -0.04), (0.0, 0.0, -0.12)), (12, (0, 0, 0), (0, 0, 0))])
        add_action(root, "Die", [(1, (0, 0, 0), (0, 0, 0)), (18, (0, 0.15, 0), (0, 0, -0.3))])
    else:
        add_action(root, "Idle", [(1, (0, 0, 0), (0, 0, 0)), (16, (0, 0.04, 0), (0, 0, 0)), (32, (0, 0, 0), (0, 0, 0))])
        add_action(root, "Walk", [(1, (0, 0, 0), (0, 0, -0.08)), (8, (0, 0.08, 0), (0, 0, 0.08)), (16, (0, 0, 0), (0, 0, -0.08))])
        add_action(root, "Attack", [(1, (0, 0, 0), (0, 0, 0)), (5, (0, -0.05, -0.05), (0.0, 0.0, 0.15)), (12, (0, 0, 0), (0, 0, 0))])
        add_action(root, "Die", [(1, (0, 0, 0), (0, 0, 0)), (18, (0, 0.1, 0), (0.0, 0.0, 0.35))])


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


def make_tower_variant(name: str, base_color: tuple[float, float, float, float], accent_color: tuple[float, float, float, float], shape: str) -> None:
    clear_scene()
    stone = material("Palette_Stone", PALETTE["stone"])
    base = material("Palette_Base", base_color)
    accent = material("Palette_Accent", accent_color, True)
    root = make_root(name)
    parts: list[bpy.types.Object] = [cylinder("Base", (0, 0, 0.45), 1.25, 0.9, stone)]
    if shape == "barracks":
        parts += [cube("Keep", (0, 0, 1.35), (0.72, 0.75, 0.72), base), cube("Flag", (0, -0.76, 2.25), (0.42, 0.5, 0.05), accent)]
    elif shape == "cannon":
        parts += [cylinder("ArmoredBody", (0, 0, 1.15), 0.85, 0.9, base), cylinder("Barrel", (0, 0, 1.65), 0.28, 1.6, accent, 10)]
    else:
        parts += [cylinder("ArcaneBody", (0, 0, 1.25), 0.72, 1.0, base), cone("CrystalSpire", (0, 0, 2.15), 0.48, 0.0, 1.35, accent, 6)]
    parent_all(root, parts)
    export_asset(name.lower(), root)


def make_archer_tower() -> None:
    make_tower_variant("ArcherTower", PALETTE["wood"], PALETTE["crystal"], "archer")


def make_specialized_towers() -> None:
    make_tower_variant("BarracksTower", (0.18, 0.34, 0.58, 1.0), (0.95, 0.55, 0.1, 1.0), "barracks")
    make_tower_variant("CannonTower", (0.2, 0.21, 0.26, 1.0), (0.72, 0.25, 0.1, 1.0), "cannon")
    make_tower_variant("MageTower", (0.24, 0.12, 0.42, 1.0), (0.55, 0.25, 1.0, 1.0), "mage")


def make_enemy() -> None:
    clear_scene()
    red = material("Palette_Enemy", PALETTE["enemy"])
    red_light = material("Palette_EnemyLight", (0.85, 0.25, 0.16, 1.0))
    bone = material("Palette_Bone", (0.72, 0.62, 0.38, 1.0))
    dark = material("Palette_Dark", PALETTE["dark"])
    root = make_root("Enemy")
    body = ico("Body", (0, 0, 0.9), 0.65, red)
    head = ico("Head", (0, 0, 1.65), 0.42, red_light)
    eye_left = ico("EyeLeft", (-0.16, -0.38, 1.72), 0.08, dark)
    eye_right = ico("EyeRight", (0.16, -0.38, 1.72), 0.08, dark)
    horn_left = cone("HornLeft", (-0.28, 0, 2.05), 0.16, 0.0, 0.5, bone, 5)
    horn_right = cone("HornRight", (0.28, 0, 2.05), 0.16, 0.0, 0.5, bone, 5)
    shoulder = cylinder("ShoulderArmor", (0, 0, 1.1), 0.78, 0.16, bone, 8)
    parent_all(root, [body, head, eye_left, eye_right, horn_left, horn_right, shoulder])
    add_character_actions(root)
    export_asset("enemy_basic", root)


def make_enemy_variant(name: str, body_color: tuple[float, float, float, float], armor_color: tuple[float, float, float, float], size: float) -> None:
    clear_scene()
    body_mat = material(f"{name}_Body", body_color)
    armor_mat = material(f"{name}_Armor", armor_color)
    root = make_root(name)
    body = ico("Body", (0, 0, 0.9 * size), 0.65 * size, body_mat)
    armor = cylinder("Armor", (0, 0, 1.18 * size), 0.78 * size, 0.18 * size, armor_mat)
    parent_all(root, [body, armor])
    add_character_actions(root)
    export_asset("%s_enemy" % name.lower(), root)


def make_enemy_variants() -> None:
    make_enemy_variant("Runner", (0.95, 0.48, 0.08, 1.0), (0.35, 0.16, 0.04, 1.0), 0.8)
    make_enemy_variant("Brute", (0.28, 0.32, 0.42, 1.0), (0.12, 0.14, 0.18, 1.0), 1.45)


def make_hero() -> None:
    clear_scene()
    cloth = material("Palette_Cloth", PALETTE["cloth"])
    skin = material("Palette_Skin", PALETTE["skin"])
    gold = material("Palette_Gold", PALETTE["gold"])
    steel = material("Palette_Steel", (0.5, 0.65, 0.78, 1.0))
    root = make_root("Hero")
    body = cylinder("Body", (0, 0, 1.0), 0.45, 1.1, cloth)
    head = ico("Head", (0, 0, 1.85), 0.35, skin)
    shoulder = cylinder("ShoulderGuard", (0, 0, 1.35), 0.62, 0.16, gold)
    cape = cube("Cape", (0, 0.34, 1.15), (0.42, 0.58, 0.08), cloth)
    sword = cube("Sword", (0.58, -0.05, 1.15), (0.07, 0.55, 0.07), steel)
    hilt = cube("SwordHilt", (0.58, -0.05, 0.62), (0.2, 0.06, 0.08), gold)
    shield = ico("Shield", (-0.55, -0.18, 1.1), 0.38, steel)
    parent_all(root, [body, head, shoulder, cape, sword, hilt, shield])
    add_character_actions(root, True)
    export_asset("hero_basic", root)


def main() -> None:
    make_archer_tower()
    make_specialized_towers()
    make_enemy()
    make_enemy_variants()
    make_hero()
    print(f"Exported Crystal Bastion assets to {OUTPUT}")


if __name__ == "__main__":
    main()
