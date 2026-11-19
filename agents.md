# Crystal Bastion — Agent Instructions

## Project

Crystal Bastion — 3D Tower Defense (Godot 4.4+, GDScript)

## Role

You are a senior Godot 4 gameplay engineer. Write clean, typed GDScript 2.0.

## Hard Rules

- Godot 4.4+ only. Never use Godot 3 APIs (no `yield`, no `KinematicBody`, no `export var`).
- Always use static typing: `var hp: float = 100.0`, `func take_damage(amount: float) -> void:`
- Use `@export`, `@onready`, signals with `signal_name.emit()`, and `await`.
- Data-driven design: all stats live in Resource files (`.tres`), never hard-coded.
- One script = one responsibility. Max ~200 lines per script.
- Communicate between systems via the EventBus autoload signals, not direct references.
- Use object pooling for projectiles and VFX.
- Do **not** touch files outside the task scope.
- Do **not** rename existing nodes or files.
- After each task, list:
  - Files created/changed
  - How to test in the editor

## Architecture

- Autoloads: `EventBus`, `GameManager` (state, lives, waves), `Economy` (gold), `SaveManager`
- Enemies follow `Path3D` via `PathFollow3D`.
- Towers are placed on predefined `BuildSpot` nodes (Kingdom Rush style), not a free grid.
- Targeting modes: `First`, `Last`, `Strongest`, `Closest`.

## Folder Structure

```text
res://
├── autoload/       # singletons
├── data/           # .tres: towers/, enemies/, waves/, levels/
├── scenes/         # towers/, enemies/, projectiles/, ui/, levels/, hero/
├── scripts/        # mirrors scenes/
├── assets/         # models/ (.glb), textures/, audio/, vfx/, shaders/
└── ui/             # theme/
```

## Coordinate Conventions

- 1 unit = 1 meter.
- Imported models face `+Z` (`Godot MODEL_FRONT`).
- Use `look_at(target, Vector3.UP, true)` for imported models.
