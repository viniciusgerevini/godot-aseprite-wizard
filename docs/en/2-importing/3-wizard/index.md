# Wizard Dock

The wizard screen allows you to import `SpriteFrames` resources without attaching them to a scene or node. This can be used in cases where you would like to generate `SpriteFrames` independently and include them in different nodes manually or programmatically.

This dock also allows you to create the raw aseprite export files (png, json) without creating any resource at all.

To open the dock go to `Project -> Tools -> Aseprite Wizard -> SpriteFrames Wizard...`.

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File Location: | \*.aseprite or \*.ase source file containing animations. |
| Output folder:          | Folder to save the output `SpriteFrames` resource(s). |
| Output filename / prefix | Defines output filename. In case layers are split into multiple files, this is used as the file prefix (e.g prefix_layer_name.res). If not set, the source file basename is used.|
| Exclude layers matching pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Split layers in multiple resources: | If selected, each layer will be exported as a separated resource (e.g my_layer_1.res, layer_name_2.res, ...). If not selected, all layers will be merged and exported as a single resource file with the same base name as the source. |
| Round FPS | Rounds Animation FPS to next integer. Default: true |
| Only include visible layers | If selected, it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Do not create resource file | Does not create SpriteFrames resource. Useful if you are only interested in the .json and .png output from Aseprite. |

Notes:
- Overwrites any manual change done to previously imported resources.

In this dock you also find tabs to list all `SpriteFrames` imported through it and a local history of previous imports.
