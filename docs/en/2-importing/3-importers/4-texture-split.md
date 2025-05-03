<!--
headings-nav-max-level: 1
-->
# Texture (split by layer)

You can generate one image resource for each layer in Aseprite by using the `Texture (Split by Layer)` importer. This importer will generate one `.ase_layer_tex` file for each layer, which will be recognised as `PortableCompressedTexture2D` and can be used directly. 


## Options

This importer has the same properties as the regular `Texture` importer with some extra:

| Field                   | Description |
| ----------------------- | ----------- |
| Layer Resources Folder | The folder where the layer resources should be created. Default: Same as source aseprite file|
| Trim Cels | Trim empty space from spritesheet frames |
| Merge duplicated Layers | If selected, only unique layers will be imported. If two layers output the same texture, only the last one will be imported |

This importer will keep track of the generated resources and remove them if the layer is removed in Aseprite.
