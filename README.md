# Godot Aseprite Wizard

Godot plugin to help importing Aseprite animations as SpriteFrames.

This plugin uses Aseprite CLI to generate the spritesheet, and then converts it to SpriteFrames, that can be used in AnimatedSprite node.

It also adds Aseprite importer to Godot, so you can use `*.ase` and `*.aseprite` files directly as resources.

<img align="center" src="./screenshots/import_dock.png" />

<img align="center" src="./screenshots/main_screen.png" />

<img align="center" src="./screenshots/aseprite_godot.png" />

### Features

- Adds Aseprite file importer to Godot.
- Creates SpriteFrames with Atlas Texture to be used in AnimatedSprites.
- Separate each Aseprite Tag as its own animation. In case no tags are defined, import everything as default animation.
- Converts Aseprite frame duration (defined in milliseconds) to Godot's animation FPS. This way you can create your animation with the right timing in Aseprite, and it should work the same way in Godot.
- Choose to export Aseprite file as single SpriteFrames resource, or separate each layer as its own resource.
- Filter out layers you don't want in the final animation, using regex.
- Supports Aseprite animation direction (forward, reverse, ping-pong)
- (Importer only) Suppports importing Aseprite files as SpriteFrames, Atlas Texture, Animated Texture and Texture strip.


## Instalation and Configuration

Follow Godot [ installing plugins guide ]( https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

This plugin requires Aseprite. It tries to use the `aseprite` command from your PATH. However, if you are using a portable version, the command is not in your PATH or you are running Aseprite on Windows, you can change the aseprite executable's path clicking on the configuration button, in the wizard screen.


## How to use

After activating the plugin, the importer will be enable allowing Aseprite files to be used seamlessly. In addition to that, you can find the wizard screen on `Project -> Tools -> Aseprite Spritesheet Wizard` menu.

### Importer flow

If you use the importer flow, any `*.ase` or `*.aseprite` file saved in the project will be automatically imported as a `SpriteFrames` resource, which can be used in `AnimatedSprite` nodes. You can change import settings for each file in the Import dock.

### Wizard flow

The wizard screen allows you to import files from outside your project root. This can be used in cases where you prefer to not include your Aseprite files to your project, or you don't want them to be imported automatically.

Check this video to see the wizard in action: https://www.youtube.com/watch?v=Yeqlce685E0

### Options

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File Location: | *.aseprite or *.ase source file containing animations. |
| Output folder:          | Folder to save the output `SpriteFrames` resource(s). |
| Output filename / prefix | Defines output filename. In case layers are split in multiple files, this is used as file prefix (e.g prefix_layer_name.res). If not set, source filename is used.|
| Exclude layers matching pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Split layers in multiple resource: | If selected, each layer will be exported as a separated resource (e.g my_layer_1.res, layer_name_2.res, ...). If not selected, all layers will be merged and exported as a single resource file with same base name as source.  |
| Only include visible layers | If selected it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Trim image | Removes padding from sprites/layers/cels before saving them. |

Importer-only options:

| Field                   | Description |
| ----------------------- | ----------- |
| Sprite filename pattern | Defines output filename. Default value: `{basename}.{layer}.{extension}` |
| Import texture strip | Creates image strip (png) per sprite/layer. Default value: `false` |
| Texture Strip Filename Pattern | Name for image strip file. Default value: `{basename}.{layer}.Strip.{extension}` |
| Import Texture Atlas | Creates AtlasTexture per animation, along with textures for each animation frame. Default value: false |
| Texture Atlas Filename Pattern | Name for AtlasTexture files. Default value: `{basename}.{layer}.Atlas.{extension}` |
| Texture Atlas Frame Filename Pattern | Name for AtlasTexture frames files. Default value: `{basename}.{layer}.{animation}.{frame}.Atlas.{extension}` |
| Import Animated Texture | Creates one AnimatedTexture for each animation. Default value: `false` |
| Animated Texture Filename Pattern | Name for Animated Texture files. Default value: `{basename}.{layer}.{animation}.Texture.{extension}` |
| Animated Texture Frame Filename Pattern | Name for Animated Texture frames files. Default value: `{basename}.{layer}.{animation}.{frame}.Texture.{extension}` |


## Limitations

### Non-looping animations

Aseprite does not have the concept of Loop / single run animations, as in Godot. Because of that, all animations are imported with Loop on. To disable it, you need to open the resource in the editor and uncheck the loop toggle (it won't work if you are using the importer flow).

Loops are useful for running, walking and idle cycles. Single run is useful for death, attack and engage animations.

### Import overwrite previous files

Currently, import overwrite previous imported files. Any modification in the previous file will be lost.

## Known Issues


### SpriteFrames dock showing outdated resource

Godot is using the cached resource. Open another SpriteFrame and then re-open the affected one. You should see the newest version.

This issue will only show outdated resources in the editor. When running the project you will always see the newest changes.


###  Spritesheet file not showing on File Sytem dock (wizard only)

Changing focus from Godot to another window, and then coming back, will trigger a re-import.


### Warnings in the output related with image file being imported (wizard only)

Those warnings are related on how I import the image file the first time. You'll probably see them when importing the same file twice. It does not affect the process.


