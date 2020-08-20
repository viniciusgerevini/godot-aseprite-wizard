# Godot Aseprite Wizard

Godot plugin to help importing Aseprite animations as SpriteFrames.

This plugin uses Aseprite CLI to generate spritesheet, and then converts it to SpriteFrames, that can be used in AnimatedSprite node.

This plugin makes it easier to use Aseprite as your animation's source of truth. In other words, you can create all your animations in Aseprite, and then import them directly to an AnimatedSprite, without extra work.

<img align="center" src="./screenshots/main_screen.png" />

<img align="center" src="./screenshots/aseprite_godot.png" />
## Features

- Creates SpriteFrames with Atlas Texture to be used in AnimatedSprites.
- Separate each Aseprite Tag as its own animation. In case no tags are defined, import everything as default animation.
- Converts Aseprite frame duration (defined in milliseconds) to Godot's animation FPS. This way you can create your animation with the right timing in Aseprite, and it should work the same way in Godot.
- Chose to export Aseprite file as single SpriteFrames resource, or separate each layer as its own resource.
- Filter out layers you don't want in the final animation, using regex.
- Supports Aseprite animation direction (forward, reverse, ping-pong)

## How to use

After activating the plugin, you can find it on `Project -> Tools -> Aseprite Spritesheet Wizard` menu.

Options:

| Field                   | Description |
| ----------------------- | ----------- |
| Aseprite File Location: | *.aseprite or *.ase source file containing animations.| |
| Output folder:          | Folder to save the output `SpriteFrames` resource(s). If exporting with grouped layers, output will be one file named `[source filename].res`. If exporting layers separated, output will be multiple files named `[layer_name].res`
| Exclude layers matching pattern: | Do not export layers that match the pattern defined. i.e `_draft$` excludes all layers ending with `_draft`. Uses Godot's [Regex implementation](https://docs.godotengine.org/en/stable/classes/class_regex.html)  |
| Group all layers in one Spritesheet: | If selected, all layers will be grouped and exported as a single resource file with same base name as source (e.g person.res). If not selected, each layer will be exported as a separated resource (e.g head.res, left_arm.res, legs.res)|


## Instalation and Configuration

Follow Godot [ installing plugins guide ]( https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

This plugin requires Aseprite. It tries to use the `aseprite` command from your PATH. However, if you are using a portable version, the command is not in your PATH or you are running Aseprite on Windows, you can change the aseprite executable's path clicking on the configuration button, in the wizard screen.

## Limitations

### Non-looping animations

Aseprite does not have the concept of Loop / single run animations, as in Godot. Because of that, all animations are imported with Loop on. To disable it, you need to open the resource in the editor and uncheck the loop button.

Loops are useful for running, walking and idle cycles. Single run is usefull for death, attack and engage animations.

I'll work on a way to define the loop when importing the file.

### Import overwrite previous files

Currently, import overwrite previous imported files. My first script implementation had a "diff" step, but I dropped it, because it was too complex. I intend to re-implement it, but for now any new import will overwrite the previous files.



## Known Issues

You may see some weirdness related to Godot caching the resource in the editor. I've tried to workaround the cache the best I could, but you will still see some caching issues.

None of those issues affect the game. They are editor only, meaning, you should see the most updated resource when running the game.

###  Spritesheet file not showing on File Sytem dock.

Changing focus from Godot to another window, and then coming back, will trigger a re-import.|

### SpriteFrames dock showing outdated resource.

Godot is using the cached resource. Open another SpriteFrame and then re-open the affected one. You should see the newest version.

### Warnings in the output related with image file importing.

Those warnings are related on how I import the file the first time. You'll probably see them when importing the same file twice, without loosing focus from Godot (not giving a chance to re-import first one). There is nothing you can do, but those warnings do not affect the process.


