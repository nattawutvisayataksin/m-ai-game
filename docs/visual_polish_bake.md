# Visual polish and LightmapGI bake

## Renderer

The project is configured for Godot Forward+ in `project.godot`. Use Forward+ for glow, SSAO, SSIL, volumetric fog, and lightmap preview.

## Level scene

Use `scenes/levels/VisualPolishLevel.tscn` as the visual-polish root or copy its nodes into a gameplay level. It contains:

- `WorldEnvironment`: AgX tonemap, exposure 1.0, glow, SSAO, SSIL, warm fog, saturation and contrast adjustments.
- Warm procedural sky with an orange horizon.
- Warm DirectionalLight3D with shadows and 80 m shadow distance.
- `LightmapGI`.
- GPUParticles3D starter presets: arrow trail, magic sparks, cannon explosion, frost burst, coin pickup, tower build dust.

## Bake static lighting

1. Open the level scene in Godot 4.4+.
2. Mark static environment meshes as **Global Illumination > Static**.
3. Ensure static props have valid UV2 lightmap coordinates.
4. Select the `LightmapGI` node.
5. Set the desired quality and texel scale in the Inspector.
6. Click **Bake Lightmaps** in the LightmapGI toolbar.
7. Save the generated lightmap data with the level scene.
8. Re-bake after moving static geometry, changing materials, or changing light direction.

Dynamic enemies, towers, projectiles, and hero should not be included as static lightmap geometry; they continue using the realtime DirectionalLight3D.

## Shader

`assets/shaders/stylized.gdshader` provides a two-step light ramp, rim light, hit flash, and dissolve parameters. `assets/shaders/outline.gdshader` can be assigned as a material `next_pass` for an inverted-hull outline.

For the outline to read cleanly, use smooth normals or a Weighted Normal modifier on the source model.
