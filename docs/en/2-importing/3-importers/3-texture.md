<!--
headings_nav_max_level: 1
-->
# Texture

Import Aseprite file as `PortableCompressedTexture2D`. This image can be either the full spritesheet or just the first frame (useful for static art like backgrounds).

## Options

| Field                   | Description |
| ----------------------- | ----------- |
| First Frame Only        | Export first frame only. When not selected, the full spritesheet is exported. Default: true |
| Layer ||
| Exclude layers pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Only include visible layers | If selected it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Sheet ||
| Sheet type | Algorithm to create spritesheet. Options: columns, horizontal, vertical, packed. Default: columns|
| Sheet column | Only applied when sheet type is "columns". Defines the number of columns in the spritesheet. If "0", packed algorithm is used. Default: 12.|

