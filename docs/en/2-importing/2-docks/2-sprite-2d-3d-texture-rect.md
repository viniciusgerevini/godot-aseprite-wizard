# Sprites and TextureRect

When working with `Sprite2D`, `Sprite3D` and `TextureRect` nodes, you have the option to import the file as a static image or load its animations to an `AnimationPlayer` node.

1. Create your node (`Sprite2D`, `Sprite3D`, `TextureRect`).
2. With the node selected, look for the "Aseprite" section on the bottom part of the Inspector dock.
3. Fill up the fields and click import.


## Animation mode options

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File | (\*.aseprite or \*.ase) source file. |
| Animation Player |AnimationPlayer node where animations should be added to.|
| Layers ||
| Layer | Aseprite layer(s) to be used in the animation. By default, all layers are included. |
| Exclude pattern | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html) |
| Only visible layers | If selected, it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Slices ||
| Slice | Aseprite Slice to be used in the animation. By default, the whole file is used. |
| Animation ||
| Keep manual animation length | When this is active the animation length won't be adjusted if other properties were added and the resulting imported animation is shorter. Default: false. |
| Hide when unused| If active, this node will be set as hidden in every existing animation it is not part of. Default: false.|
| Output ||
| Embed Texture: | Embed sprite sheet texture in the scene, instead of generating an external file. Default: enabled |
| Output folder: | (When Embed Texture is off) Folder to save the sprite sheet (png) file. Default: same as scene |
| Output file name | (When Embed Texture is off) Output file name for the sprite sheet. In case the Layer option is used with a single layer, this is used as the file prefix (e.g prefix_layer_name.res). If not set, the source file basename is used.|

Notes:

- The generated sprite sheet texture is set to the Sprite node and every tag in the Aseprite file will be inserted as an Animation into the selected AnimationPlayer.
- If the animation already exists in the AnimationPlayer, all existing tracks are kept. Only the required tracks for the Sprite animation will be changed.
- Loop configuration and animation length will be changed according to the Aseprite file. If you wish to keep a manually configured animation length, set the `Keep manual animation length` option.
- The plugin will never delete an Animation containing other tracks besides the ones used by itself. In case the animation is removed from Aseprite, it will delete the track from the AnimationPlayer and only delete the animation in case there are no other tracks left.
- Animations are added to the global animation library by default. To define a library name, use the `library_name/animation_name` pattern on your Aseprite tags.


## Image mode options

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File | (\*.aseprite or \*.ase) source file. |
| Layers ||
| Layer | Aseprite layer to be used in the animation. By default, all layers are included. |
| Exclude pattern | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html) |
| Only visible layers | If selected, it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Slices ||
| Slice | Aseprite Slice to be used in the animation. By default, the whole file is used. |
| Output ||
| Output folder | Folder to save the sprite sheet (png) file. Default: same as scene |
| Output file name | Output file name for the sprite sheet. In case the Layer option is used with a single layer, this is used as file prefix (e.g prefix_layer_name.res). If not set, the source file basename is used.|
