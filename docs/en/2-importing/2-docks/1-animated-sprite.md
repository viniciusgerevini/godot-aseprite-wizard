# AnimatedSprite

To import animations via the Import Dock:

1. Create an `AnimatedSprite2D` or `AnimatedSprite3D` node and select it in your scene.
1. With the node selected, look for the "Aseprite" section in the bottom part of the Inspector dock.
1. Fill up the fields and click import.

## Options

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File: | (\*.aseprite or \*.ase) source file. |
| Layers ||
| Layer: | Aseprite layer(s) to be used in the animation. By default, all layers are included. |
| Exclude pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html) |
| Only visible layers | If selected, it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Slices ||
| Slice | Aseprite Slice to be used in the animation. By default, the whole file is used. |
| Animation ||
| Round FPS | Rounds Animation FPS to next integer. Default: true |
| Output  ||
| Embed Texture: | Embed sprite sheet texture in the scene, instead of generating an external file. Default: enabled |
| Output folder: | (When Embed Texture is off) Folder to save the sprite sheet (png) file. Default: same as scene |
| Output file name | (When Embed Texture is off) Output file name for the sprite sheet. In case the Layer option is used with a single layer, this is used as the file prefix (e.g prefix_layer_name.res). If not set, the source file basename is used.|

## Notes

- A `SpriteFrames` resource will be generated and assigned to the AnimatedSprite. This resource is embedded in the scene and the spritesheet can be either embedded (Embed Texture option enabled) or a file will be created in the output folder.
- As opposed to the `AnimationPlayer` flow, a new `SpriteFrames` resource is generated on every import. This means any manual change will be lost after re-import.

