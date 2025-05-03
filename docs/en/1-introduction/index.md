# Getting started

## Features

- This plugin adds a set of tools to help importing animations from Aseprite to Godot.
- Automatic importers to quickly import Aseprite files as different types (SpriteFrames, Static image, spritesheet texture, Tileset texture, etc)
- Inspector dock section to manually import animations directly to nodes (AnimatedSprite, Sprite2D, Sprite3D, TextureRect).
- Supports Aseprite animation directions (forward, reverse, ping-pong, ping-pong reverse).
- Supports loopable and non-loopable animations via Aseprite repeat or tags.
- Separate each Aseprite Tag into animations. In case no tags are defined, imports everything as default animation.
- Filter layers you don't want in the final animation using regex.
- Supports slices. Import only a region from your file.
- For AnimatedSprite
  - Creates SpriteFrames with Atlas Texture to be used in AnimatedSprites.
  - Converts Aseprite frame duration (defined in milliseconds) to Godot's animation FPS. This way you can create your animation with the right timing in Aseprite and it should work the same way in Godot.
  - Choose to export the Aseprite file as a single SpriteFrames resource or separate each layer in different resources.
- AnimationPlayer
  - Adds and removes animation tracks without removing other existing tracks.
  - You are free to import multiple files to the same AnimationPlayer or import each layer to their own Sprite/TextureRect and AnimationPlayer.
  - Supports animation libraries.

## Instalation

Follow Godot [ installing plugins guide ]( https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

Alternatively, you can download a specific version from [the releases page](https://github.com/viniciusgerevini/godot-aseprite-wizard/releases) and manually extract it to the addons folder.

## Configuration

_If you don't see the options bellow after installing the plugin, make sure it's enabled on Project > ProjectSettings > Plugins_

After installing the plugin, you need to make sure it's using the right Aseprite command. You can test the command by going to `Project > Tools > Aseprite Wizard > Config...`. If you get "command not found" instead of the Aseprite's version, you need to change the path to the Aseprite executable.

You can change the command path via editor settings: `Editor -> Editor Settings -> Aseprite`.

| Configuration           | Description |
| ----------------------- | ----------- |
| General > Command Path | Path to the aseprite executable. Default: `aseprite` |


## Project settings

For project specific configurations check `Project -> Project Settings -> General > Aseprite`.

| Configuration           | Description |
| ----------------------- | ----------- |
| Animation > Layer > Exclusion Pattern | Exclude layers with names matching this pattern (regex). This is the default value for new nodes. It can be changed or removed during the import. Default: not set |
| Animation > Layer > Only Include Visible Layers By Default | Default configuration for "only visible" in the docks. Default: false |
| Animation > Loop > Enabled | Enables animation loop by default. Default: `true` |
| Animation > Loop > Exception Prefix | Animations with this prefix are imported with opposite loop configuration. For example, if your default configuration is Loop = true, animations starting with `_` would have Loop = false. The prefix is removed from the animation name on import (i.e  `_death` > `death`). Default: `_` |
| Import > Cleanup > Remove Json File | Remove temporary `*.json` files generated during import. Default: `true` |
| Import > Cleanup > Automatically Hide Sprites Not In Animation | Default configuration for AnimationPlayer option to hide sprite when not in animation. Default: `false` |
| Import > Import Plugin > Default Automatic Importer | Which importer to use by default for aseprite files. Options: `No Import`, `SpriteFrames`, `Static Texture`, `Tileset Texture`. Default: `No Import` |

## Usage

Check the [importing docs](../2-importing/index.md) for usage details.
