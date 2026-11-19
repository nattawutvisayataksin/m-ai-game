# Crystal Bastion Blender Asset Pipeline

Starter pipeline for stylized low-poly assets.

## Target specifications

- Tower: 1.5k–4k tris
- Enemy: 800–2k tris
- Hero: 3k–5k tris
- Shared palette atlas: 256×256
- Scale: 1 Blender unit = 1 meter
- Origin: on the model base
- Blender forward: `-Y`
- Godot-facing direction after glTF import: `+Z`
- Export: glTF 2.0 `.glb`, `+Y Up`, Apply Modifiers

## Generate starter models

Open Blender 4.x and run:

```text
Scripting > Open > tools/blender/create_stylized_assets.py > Run Script
```

Or from a terminal:

```text
blender --background --python tools/blender/create_stylized_assets.py
```

The script exports:

- `assets/models/generated/archer_tower.glb`
- `assets/models/generated/enemy_basic.glb`
- `assets/models/generated/hero_basic.glb`

Generate the Level 01 pine scenery separately with `create_stylized_pine.py`.
It exports `assets/models/generated/stylized_pine.glb`, which Level 01 instances
around the field perimeter without adding physics collisions.

The generated meshes are intentionally simple blockout assets. Use them as a consistent base, then add topology and details while keeping the same palette materials.

## Blender checklist before export

1. Apply transforms: `Ctrl+A > Scale`.
2. Keep the origin at the base of each asset.
3. Make the front face point to Blender `-Y`.
4. Keep tower `Base` and `Turret` as separate objects.
5. Add small bevels around `0.02–0.05 m`.
6. Use Shade Auto Smooth / smooth-by-angle.
7. Name collision meshes with the `-col` suffix.
8. Name animation clips `Idle`, `Walk`, `Attack`, `Die`, `Hit`; looping clips use `-loop`.
9. Export glTF 2.0 Binary (`.glb`) with +Y Up and Apply Modifiers.
10. Keep emissive colors restricted to crystals, torches, and windows.

## Palette atlas

Use a single 256×256 image for the whole game. Assign UVs to solid color cells rather than painting unique textures per model. Suggested palette families:

- Stone: cool blue-grey
- Wood: warm brown
- Cloth: saturated faction colors
- Gold: warm yellow-orange
- Crystal: cyan-blue emission
- Enemy: red-magenta contrast
- Dark: deep purple-blue outline

## Concept prompt

Stylized low-poly fantasy archer tower, isometric view, hand-painted look, warm sunset lighting, vibrant saturated colors, stone base with wooden top, blue glowing crystal, clean silhouette, game asset, white background
