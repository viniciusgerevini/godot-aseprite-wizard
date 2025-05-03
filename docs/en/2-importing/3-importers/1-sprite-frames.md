<!--
headings-nav-max-level: 1
-->
# SpriteFrames importer

Aseprite files are imported as `SpriteFrames` resources and can be loaded to `AnimatedSprite` nodes directly or programatically.

## Options

| Field                   | Description |
| ----------------------- | ----------- |
| Layer ||
| Exclude layers matching pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Only include visible layers | If selected it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Sheet ||
| Sheet type | Algorithm to create spritesheet. Options: columns, horizontal, vertical, packed. Default: Packed|
| Sheet column | Only applied when sheet type is "columns". Defines the number of columns in the spritesheet. If "0", packed algorithm is used. Default: 12.
| Animation ||
| Animation / Round FPS | When selected, animation FPS is rounded to next integer. Default: true.|
