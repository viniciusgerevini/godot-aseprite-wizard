<!--
headings_nav_max_level: 1
-->
# Tileset Texture

Aseprite 1.3 added [Tilemap support](https://www.aseprite.org/docs/tilemap/). You can create special layers which can then be exported as tilesets. The tileset importer will generate an image with the tiles from the aseprite file, which can be added to the Tileset editor in Godot.

## Options

| Field                   | Description |
| ----------------------- | ----------- |
| Layer ||
| Exclude layers pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Only include visible layers | If selected it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Sheet ||
| Sheet type | Algorithm to create spritesheet. Options: columns, horizontal, vertical, packed. Default: columns|
| Sheet column | Only applied when sheet type is "columns". Defines the number of columns in the spritesheet. If "0", packed algorithm is used. Default: 12.
