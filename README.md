# Godot Aseprite Wizard

Godot plugin to help import Aseprite animations to AnimationPlayers, AnimatedSprites and SpriteFrames.

<img align="center" src="./screenshots/comparison.png" />
<img align="center" src="./screenshots/animation_dock.gif" />

_Check the screenshots folder for more examples._

### Features

- Generate sprite sheet and import animations to AnimationPlayer, AnimatedSprite or SpriteFrames resource.
- Adds Inspector docks for easy import and re-import.
- Filters out layers you don't want in the final animation, using regex.
- Supports Aseprite animation direction (forward, reverse, ping-pong).
- Supports loopable and non-loopable animations.
- Separates each Aseprite Tag into animations. In case no tags are defined, imports everything as default animation.
- AnimatedSprite
  - Creates SpriteFrames with Atlas Texture to be used in AnimatedSprites.
  - Converts Aseprite frame duration (defined in milliseconds) to Godot's animation FPS. This way you can create your animation with the right timing in Aseprite, and it should work the same way in Godot.
  - Choose to export the Aseprite file as a single SpriteFrames resource, or separate each layer in different resources.
  - Adds Aseprite file importer to Godot (check limitations section).
- AnimationPlayer
  - Adds and removes animation tracks without removing other existing tracks.
  - You are free to import multiple files to the same AnimationPlayer or import each layer to their own Sprite and AnimationPlayer.

Aseprite Wizard is only required during development. If you decide to not use it anymore, you can remove the plugin and all animations previously imported should keep working as expected.


## Installation and Configuration

Follow Godot [ installing plugins guide ]( https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

If you are using Windows, a portable version or if the `aseprite` command is not in your PATH, you need to set the right path on `Editor -> Editor Settings -> Aseprite`.

| Configuration           | Description |
| ----------------------- | ----------- |
| General > Command Path | Path to the aseprite executable. Default: `aseprite` |

For project specific configurations check `Project -> Project Settings -> General > Aseprite`.

| Configuration           | Description |
| ----------------------- | ----------- |
| Animation > Layer > Exclusion Pattern | Exclude layers with names matching this pattern (regex). This is the default value for new nodes. It can be changed or removed during the import. Default: not set |
| Animation > Loop > Enabled | Enables animation loop by default. Default: `true` |
| Animation > Loop > Exception prefix | Animations with this prefix are imported with opposite loop configuration. For example, if your default configuration is Loop = true, animations starting with `_` would have Loop = false. The prefix is removed from the animation name on import (i.e  `_death` > `death`). Default: `_` |
| Import > Preset > Enable Custom Preset | Enable Custom preset properties (*requires plugin restart*). Default: `false`. |
| Import > Preset > Preset | Custom preset properties for texture files imported via this plugin. Default: same as Godot's defaults. |
| Import > Cleanup > Remove Json File | Remove temporary `*.json` files generated during import. Default: `true` |
| Import > Import Plugin > Enable Automatic Importer | Enable/Disable Aseprite automatic importer (*requires plugin restart*). Default: `false` |
| Wizard > History > Cache File Path | Path to file where history data is stored. Default: `res://.aseprite_wizard_history` |
| Wizard > History > Keep One Entry Per Source File | When true, history does not show duplicates. Default: `false` |

## How to use

_Check this video for usage examples:_ https://youtu.be/1W-CCbrzG_0

After activating the plugin, you can find a section called Aseprite in the inspector dock when selecting Sprite and AnimatedSprite nodes. Also, the importer will be enabled allowing Aseprite files to be used seamlessly. In addition to that, you can find the wizard screen on `Project -> Tools -> Aseprite Spritesheet Wizard` menu.

### AnimationPlayer

Animations can be imported to AnimationPlayers via the Inspector dock.

- First, Create a `Sprite` node in your scene.
- With the node selected, look for the "Aseprite" section in the bottom part of the Inspector.
- Fill up the fields and click import.


| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File: | (\*.aseprite or \*.ase) source file. |
| Animation Player: |AnimationPlayer node where animations should be added to.|
| Layer: | Aseprite layer to be used in the animation. By default, all layers are included. |
| Output folder: | Folder to save the sprite sheet (png) file. Default: same as scene |
| Output file name | Output file name for the sprite sheet. In case the Layer option is used, this is used as file prefix (e.g prefix_layer_name.res). If not set, the source file basename is used.|
| Exclude pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html) |
| Only visible layers | If selected, it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|


Notes:
- The generated sprite sheet texture is set to the Sprite node and every tag in the Aseprite file will be inserted as an Animation into the selected AnimationPlayer.
- If the animation already exists in the AnimationPlayer, all existing tracks are kept. Only the required tracks for the Sprite animation will be changed (`Sprite:frame`).
- Loop configuration and animation length will be changed according to the Aseprite file.
- The plugin will never delete an Animation containing other tracks than the ones used by itself (`Sprite:frame`). In case the animation is removed from Aseprite, it will delete the track from the AnimationPlayer and only delete the animation in case there are no other tracks left.


### AnimatedSprite and SpriteFrames

There are a few different ways to import animations to be used in AnimatedSprites. All of them create a SpriteFrames resource with everything configured.


#### via Inspector dock

This is very similar to the AnimationPlayer option.

- First, select the AnimatedSprite in your scene.
- With the node selected, look for the "Aseprite" section in the bottom part of the Inspector.
- Fill up the fields and click import.

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File: | (\*.aseprite or \*.ase) source file. |
| Animation Player: |AnimationPlayer node where animations should be added to.|
| Layer: | Aseprite layer to be used in the animation. By default, all layers are included. |
| Output folder: | Folder to save the sprite sheet (png) file. Default: same as scene |
| Output file name | Output file name for the sprite sheet. In case the Layer option is used, this is used as the file prefix (e.g prefix_layer_name.res). If not set, the source file basename is used.|
| Exclude pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html) |
| Only visible layers | If selected, it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|


Notes:
- A SpriteFrames resource will be generated and assigned to the AnimatedSprite. This resource is embedded in the scene. It does not require any external dependency.
- As opposed to the AnimationPlayer flow, a new SpriteFrames resource is generated on every import. This means any manual change will be lost after re-import.


### Wizard (bottom dock)

The wizard screen allows you to import SpriteFrames resources without attaching them to a scene or node This can be used in cases where you would like to generate SpriteFrames independently and include them in different nodes manually or programmatically.


| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File Location: | \*.aseprite or \*.ase source file containing animations. |
| Output folder:          | Folder to save the output `SpriteFrames` resource(s). |
| Output filename / prefix | Defines output filename. In case layers are split into multiple files, this is used as the file prefix (e.g prefix_layer_name.res). If not set, the source file basename is used.|
| Exclude layers matching pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Split layers in multiple resources: | If selected, each layer will be exported as a separated resource (e.g my_layer_1.res, layer_name_2.res, ...). If not selected, all layers will be merged and exported as a single resource file with the same base name as the source. |
| Only include visible layers | If selected, it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Do not create resource file | Does not create SpriteFrames resource. Useful if you are only interested in the .json and .png output from Aseprite. |


Notes:
- Overwrites any manual change done to previously imported resources.


### Importer

__I intend to deprecate this feature in the next major release. It's too buggy and hacky compared to the other flows.__

If you use the importer flow, any `*.ase` or `*.aseprite` file saved in the project will be automatically imported as a `SpriteFrames` resource, which can be used in `AnimatedSprite` nodes. You can change import settings for each file in the Import dock.
This feature needs to be enabled via Aseprite Wizard Configuration screen.

Notes:
- The importer flow is kind o hacky and buggy. 
- Files generated through the automatic importer can be significantly larger than those generated via other methods.
- The importer does a bad job at refreshing Godot Editor cache. You might see resources outdated in the editor, but running the project will show the newest version.


### Options

| Field                   | Description |
| ----------------------- | ----------- |
| Output filename / prefix | Defines output filename. In case layers are split into multiple files, this is used as file prefix (e.g prefix_layer_name.res). If not set, the source filename is used.|
| Exclude layers matching pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Split layers in multiple resources: | If selected, each layer will be exported as a separated resource (e.g my_layer_1.res, layer_name_2.res, ...). If not selected, all layers will be merged and exported as a single resource file with the same base name as the source. |
| Only include visible layers | If selected it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Sprite filename pattern | Defines output filename. Default value: `{basename}.{layer}.{extension}` |
| Import texture strip | Creates image strip (png) per sprite/layer. Default value: `false` |
| Texture Strip Filename Pattern | Name for image strip file. Default value: `{basename}.{layer}.Strip.{extension}` |
| Import Texture Atlas | Creates AtlasTexture per animation, along with textures for each animation frame. Default value: false |
| Texture Atlas Filename Pattern | Name for AtlasTexture files. Default value: `{basename}.{layer}.Atlas.{extension}` |
| Texture Atlas Frame Filename Pattern | Name for AtlasTexture frames files. Default value: `{basename}.{layer}.{animation}.{frame}.Atlas.{extension}` |
| Import Animated Texture | Creates one AnimatedTexture for each animation. Default value: `false` |
| Animated Texture Filename Pattern | Name for Animated Texture files. Default value: `{basename}.{layer}.{animation}.Texture.{extension}` |
| Animated Texture Frame Filename Pattern | Name for Animated Texture frames files. Default value: `{basename}.{layer}.{animation}.{frame}.Texture.{extension}` |


## F.A.Q. and limitations

### What is the correct command to use in Aseprite Command Path

The plugin uses `aseprite` as the default command. In case your system uses a different location you can either add it to the PATH variable or provide the full path to the executable. Here are some common locations:

- Steam on Windows: `C:\\Steam\steamapps\common\Aseprite\aseprite.exe`. (This will vary depending on your Steam Library location).
- MacOS: `/Applications/Aseprite.app/Contents/MacOS/aseprite`.
- Ubuntu: `/usr/bin/aseprite`. (Note: usually your PATH already includes binaries from `/usr/bin`)

*Note: Adding Aseprite to the PATH on Windows does not always work, as reported by some users. In this case, it's better to stick to the full path.*

### Non-looping animations

Aseprite does not have the concept of loop / single run animations, as in Godot. Because of that, looping is handled via a configured convention.

By default, all animations are imported with loop = true. Any animation starting with `_` (the exception prefix), will be imported with loop = false.

Both the default configuration and the exception prefix can be changed in the configuration window.

### Import overwrite previous files

Currently, import overwrites previously imported files. Any manual modification in the previous resource file will be lost.


### Blurry images when importing through Wizard Screen

The wizard screen uses Godot's default image loader. To prevent blurry images, disable the filter flag for Textures in the Import dock and set it as the default preset.

For more info, check: https://docs.godotengine.org/en/3.2/getting_started/workflow/assets/import_process.html


### What is the gibberish in the node's "Editor Description"

If you are using the Sprite or AnimatedSprite Inspector dock flow, you may have noticed some "gibberish" text in the Editor Description field.

This is a base64 encoded config for the options you selected for that node. This is not required for the animation to work, however, it does improve the development flow, as you won't need to fill all information up again when re-importing your animations.

If I were to have the new fields persisted without using the "Editor Description", I'd have to create custom nodes extending the Sprite/AnimatedSprite nodes, which goes against my intention to keep this plugin a dev dependency only.

Another possible workaround would be saving temporary or support files, which would add complexity and flakiness to the plugin, and possibly pollute your repository.

The "Editor Description" was the best compromise from the options available. If it bothers you and you don't mind filling the fields up when re-importing, feel free to delete its content after importing.


## Known Issues


### SpriteFrames dock showing outdated resource

Godot is using the cached resource. Open another SpriteFrame and then re-open the affected one. You should see the newest version.

This issue will only show outdated resources in the editor. When running the project you will always see the newest changes.


### Files imported by the importer are bigger than the ones imported using the Wizard.

The sprite sheet file (png) used in the resource is created by Aseprite, outside Godot Editor. Because of that, the plugin needs to trigger a file system scan to import this file.

However, the scan operation is asynchronous and it can't be used in the importer. We implemented a fallback method but, unfortunately, it creates bigger resource files.

Until we find an alternative way, the importer will create bigger files. To prevent it from generating resources for Aseprite files saved in your project folder, leave it disabled in the configuration screen or add a `.gdignore` file to the folder containing the `*.aseprite` files.


### Big files issue (Image width cannot be greater than 16384px)

As per Godot's [docs](https://docs.godotengine.org/en/stable/classes/class_image.html):

> The maximum image size is 16384×16384 pixels due to graphics hardware limitations. Larger images may fail to import.

This plugin exports all animations as a single sprite sheet. If you are using a big canvas size in Aseprite with lots of frames, you may reach this limit.

Sprite sheets are generated using a `packing` algorithm, which should mitigate this issue, however, it won't solve it entirely.

I might implement an option to split big images in multiple files, however, this will only be possible for AnimatedSprites. In the current implementation, AnimationPlayers won't benefit from it.


## Contact

Thanks for the constant feedback and suggestions. If you are facing problems with the plugin or have suggestions/questions, please open an issue in this repo or send me a message via [Twitter](https://twitter.com/vini_gerevini) or e-mail.

If you like game dev related content and want to support me, consider subscribing to my [Youtube channel](http://youtube.com/c/ThisIsVini).
