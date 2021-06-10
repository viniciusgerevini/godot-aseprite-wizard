# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## 1.4.0 (2021-06-10)

### Changed

- Aseprite Wizard opens on the bottom dock instead of a standalone window.
- Does not close dock after import anymore.
- Configuration window is a panel now. You will not be able to move it around, but it prevents sizing issues.


### Fixed

- Configuration and main wizard screen content would overflow in high resolution screen or scaled interfaces.


## 1.3.0 (2021-04-20)

### Added
- Wizard: option to disable resource generation. Only *.json and *.png files are created
- Wizard: Option for removing *.json and *.png files generated during import.


## 1.2.3 (2021-02-16)

### Fixed

- Automatic importer was importing images with filters on, generating blurry images.

### Thanks

- Thanks to Ryan Lloyd (@SirRamEsq) for identifying and debugging this issue.

## 1.2.2 (2021-01-08)

### Fixed

- Resource files generated were bigger than they should be.
- Sprite sheet path used could lead to silent failure creating `SpriteFrames` with animations, but no images.
- Sprite frame files now are shown in the file system dock as soon as they are created.
- Fixed warnings caused by image import.

### Thanks

- Thanks to Lucas Castro (@castroclucas) for identifying the resource size issue and helping me fix it.

## 1.2.1 (2020-12-31)

### Fixed

- Importer was removing output folder on Windows, failing the import.
- Re-enabling the importer plugin would crash the editor.

## 1.2.0 (2020-12-24)

### Added

- Configuration to enable/disable Aseprite Importer. Enabled by default

## 1.1.0 (2020-12-07)

### Added

- Aseprite Importer. Now `ase` and `aseprite` files can be used seamlessly.
- Importer with options to also create AtlasTexture, AnimatedTexture and Image strip files.

### Thanks

- Thanks to @aaaaaaaaargh for implementing the importer interface.

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
