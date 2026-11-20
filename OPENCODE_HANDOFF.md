# Crystal Bastion — OpenCode Handoff

## Current state

- Project: Godot 4.7.2, GDScript, 3D tower defense.
- Branch: `main`, based on `cd7082b` (`Complete Crystal Bastion campaign finale`).
- The current workspace changes are intended to be committed together. They include existing local gameplay/UI work and the recent Codex improvements.

## Latest pass — environment identity

- Added three reusable, non-colliding scenery scenes: `CrystalCluster`, `RuinArch`, and `RockCluster` under `scenes/world/`.
- Dressed Levels 02–04 with a perimeter pine line plus level-specific crystal clusters, ruin arches, and rocks. Existing paths and BuildSpot positions are unchanged.
- Fixed a tower bug where every instance of a tower scene shared one `SphereShape3D` sub-resource, so upgrading one Archer widened the detection radius of every Archer. `Tower._ready()` now duplicates the shape before applying `attack_range`.
- Added `tools/_smoke_scenery.tscn`, which validates scenery clearance against lane samples and build spots, and asserts that Archer and Archer II keep independent detection ranges.

Validation: `godot --headless --path . res://tools/_smoke_scenery.tscn` reports 22 props per level, minimum lane clearance 4.0–6.0 m, minimum BuildSpot clearance 8.9–9.6 m, `range base=8.0 upgraded=9.0 shared=false`, and `failures=0`.

## Work in this handoff

- Replaced procedural placeholder sound effects with 13 imported WAV effects for tower shots, impacts, building, coins, waves, abilities, outcomes, and campaign completion. The music bed remains procedural.
- Added audio shutdown cleanup for pooled players.
- Added a Blender-generated low-poly pine model and 12 non-colliding perimeter instances to Level 01. Regenerate it with `blender --background --python tools/blender/create_stylized_pine.py`.
- Added camera control help to the opening tutorial and pause menu: WASD/screen edge to pan, Q/E to rotate, and mouse wheel to zoom.
- Included local gameplay improvements: automatic meteor target selection, clearer ability key labels and HUD anchoring, BuildSpot ring visibility, and ground-only tower notes.
- Added/updated smoke scenes and cleanup for the tests that manipulate temporary progression.

## Validation

- Godot imported the WAV and pine GLB assets; Level 01 loaded without parse or resource-load errors.
- All 12 existing smoke scenes reached their completion output during the validation pass. The HUD and tutorial smoke scenes were rerun after the camera-help change and also completed without script errors.
- Godot still reports ObjectDB/audio resource references at shutdown for some headless smoke runs. This is a test-process teardown warning and remains open for investigation.
- Save data was backed up and restored around smoke scenes that modify progression.

## Suggested next steps

1. Open Levels 01–04 in the Godot Editor and visually confirm the perimeter framing from the live gameplay camera.
2. Continue tracking down headless shutdown resource warnings if clean smoke output is required.
3. Consider replacing the shared pine GLB with a second authored tree/rock variant so perimeter lines read less repetitive.

## Run and smoke checks

- Main project scene: `res://scenes/ui/WorldMap.tscn`.
- Existing smoke scenes are under `tools/` and can be launched individually from the Godot Editor.
- Progression smoke scenes write to `user://save.json`; keep a backup when running them outside the guarded test workflow.
