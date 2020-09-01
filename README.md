# Godot Aseprite Wizard

Godot plugin to help importing Aseprite animations as SpriteFrames.

This plugin uses Aseprite CLI to generate the spritesheet, and then converts it to SpriteFrames, that can be used in AnimatedSprite node.

<img align="center" src="./screenshots/main_screen.png" />

<img align="center" src="./screenshots/aseprite_godot.png" />
## Features

- Creates SpriteFrames with Atlas Texture to be used in AnimatedSprites.
- Separate each Aseprite Tag as its own animation. In case no tags are defined, import everything as default animation.
- Converts Aseprite frame duration (defined in milliseconds) to Godot's animation FPS. This way you can create your animation with the right timing in Aseprite, and it should work the same way in Godot.
- Choose to export Aseprite file as single SpriteFrames resource, or separate each layer as its own resource.
- Filter out layers you don't want in the final animation, using regex.
- Supports Aseprite animation direction (forward, reverse, ping-pong)

## How to use

After activating the plugin, you can find it on `Project -> Tools -> Aseprite Spritesheet Wizard` menu.

Options:

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File Location: | *.aseprite or *.ase source file containing animations. |
| Output folder:          | Folder to save the output `SpriteFrames` resource(s). |
| Output filename / prefix | Defines output filename. In case layers are split in multiple files, this is used as file prefix (e.g prefix_layer_name.res). If not set, source filename is used.|
| Exclude layers matching pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Split layers in multiple resource: | If selected, each layer will be exported as a separated resource (e.g my_layer_1.res, layer_name_2.res, ...). If not selected, all layers will be merged and exported as a single resource file with same base name as source.  |
| Only include visible layers | If selected it only includes in the image file the layers visible in Aseprite. If not selected, all layers are exported, regardless of visibility.|
| Trim image | Removes padding from sprites/layers/cels before savimg them. |


## Instalation and Configuration

Follow Godot [ installing plugins guide ]( https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

This plugin requires Aseprite. It tries to use the `aseprite` command from your PATH. However, if you are using a portable version, the command is not in your PATH or you are running Aseprite on Windows, you can change the aseprite executable's path clicking on the configuration button, in the wizard screen.

## Limitations

### Non-looping animations

Aseprite does not have the concept of Loop / single run animations, as in Godot. Because of that, all animations are imported with Loop on. To disable it, you need to open the resource in the editor and uncheck the loop toggle.

Loops are useful for running, walking and idle cycles. Single run is usefull for death, attack and engage animations.

### Import overwrite previous files

Currently, import overwrite previous imported files. Any modification in the previous file will be lost.

## Known Issues

You may see some weirdness related to Godot caching the resource in the editor. I've tried to workaround the cache the best I could, but you will still see some caching issues.

None of those issues affect the game. They are editor only, meaning, you should see the most updated resource when running the game.

###  Spritesheet file not showing on File Sytem dock.

Changing focus from Godot to another window, and then coming back, will trigger a re-import.|

### SpriteFrames dock showing outdated resource.

Godot is using the cached resource. Open another SpriteFrame and then re-open the affected one. You should see the newest version.

### Warnings in the output related with image file importing.

Those warnings are related on how I import the image file the first time. You'll probably see them when importing the same file twice. Bad news, there is nothing you can do. Good news, those warnings do not affect the process.


