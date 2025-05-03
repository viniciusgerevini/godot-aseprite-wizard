<!--
headings-nav-max-level: 1
-->
# SpriteFrames (Split by layer)

You can generate one `SpriteFrames` resource for each layer by using the `SpriteFrames (Split by Layer)` importer. This importer will generate one `.ase_layer` file for each layer, which will be recognised as `SpriteFrames` and can be used directly. 

## Options

This importer has the same properties as the regular `SpriteFrames` importer with one extra:

| Field                   | Description |
| ----------------------- | ----------- |
| Layer Resources Folder | The folder where the layer resources should be created. Default: Same as source aseprite file|

This importer will keep track of the generated resources and remove them if the layer is removed in Aseprite.
