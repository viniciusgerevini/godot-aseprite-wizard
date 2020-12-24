# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

The Working in Progress (WIP) section is for changes that are already in master, but haven't been published to Godot's asset library yet. Even though the section is called WIP, all changes in master are stable and functional.

## WIP

### Added

- Configuration to enable/disable Aseprite Importer. Enabled by default

## 1.1.0 (2020-12-07)

### Added

- Aseprite Importer. Now `ase` and `aseprite` files can be used seamlessly.
- Importer with options to also create AtlasTexture, AnimatedTexture and Image strip files.


## 1.0.2 (2020-10-26)

### Fixed

- Import Aseprite file without tags as default animation

## 1.0.1 (2020-10-03)

### Added

- Changelog file

### Changed

- show better error message when Aseprite command fails
- replace space indentation by tabs, as people were seing some weird issues with mixed indent errors on instalation.

## 1.0.0 (2020-09-03)

Initial release

### Added

- Creates SpriteFrames with Atlas Texture to be used in AnimatedSprites.
- Separate each Aseprite Tag as its own animation. In case no tags are defined, import everything as default animation.
- Converts Aseprite frame duration (defined in milliseconds) to Godot's animation FPS. This way you can create your animation with the right timing in Aseprite, and it should work the same way in Godot.
- Choose to export Aseprite file as single SpriteFrames resource, or separate each layer as its own resource.
- Filter out layers you don't want in the final animation, using regex.
- Supports Aseprite animation direction (forward, reverse, ping-pong)
