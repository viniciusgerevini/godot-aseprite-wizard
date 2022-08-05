# Changelog

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)

## Unreleased

### Breaking Changes

- Settings are set now via EditorSettings and Project Settings. After migrating, any custom config has to be set again in those places.
- Some files moved around. Even though this won't break anything, when updating you migth consider deleting the folder to avoid orphan files.

### Changed
- Moved command configuration to Editor Settings > Aseprite
- Moved all project related settings to Project Settings > Aseprite
- Moved wizard dock previous data to editor settings project metadata
- Standardized filename outliers and reorganized folders

### Thanks

Thanks to @TheOrioli for suggesting the settings changes.

## 4.2.0

### Added

- Custom texture import preset for files imported via plugin.
- Wizard history tab to track imports made via wizard screen. Options to order by date or path.

### Thanks

Thanks to @TheOrioli for contributing with the custom preset feature.

## 4.1.1 (2022-06-05)

### Changed

- Remove unnecessary files from the distribution zip. This guarantees only the important addons files will be added to your project, as opposed to downloading all the examples/screenshots and project.godot files.

### Thanks

Thanks to Gustavo Maciel (@gumaciel) for contributing with this patch.

## 4.1.0 (2022-03-02)

### Added

- Added Importer option: Sheet type.

### Changed

- SpriteFrames: reuse same AtlasTexture for frames using same region in Spritesheet. This decrease file size by a few bytes.

### Fixed

- Do not remove spritesheet files when source files are set to be removed as they are used by the SpriteFrames.

### Thanks

Thanks to @Mickeon for contributing with the AtlasTexture re-use and import option.

## 4.0.1 (2022-02-08)

### Fixed

- SpriteFrames FPS was being rounded down, while they should've be rounded up.

## 4.0.0 (2022-01-23)

The highlight in this version is the addition of `AnimationPlayer` support and a simplified flow for `AnimatedSprite`s. It also contains a major code refactor and improvements to the configuration options.

### Added

- Added AnimationPlayer support. Check README for usage.
- Added AnimatedSprite Inspector import section, similar to the new AnimationPlayer support.
- Added "default layer exclusion pattern" option to configuration screen.
- Added button to test Aseprite command in the configuration screen.

### Changed

- Moved configuration window from dock to "Project > Tools > Aseprite Wizard Config".
- Enabled `--sheet-pack` for optmised spritesheet generation.
- Major code refactor.
- Importer is not enabled by default anymore. I intend to deprecate the importer in the next major version (speak now or forever hold your peace).
- "Remove source files" is enabled by default.

### Removed

- Removed "Trim" and "Trim by Grid" options. Reason: Trimming didn't work as expected and fixing it defeated its purposed. When trimming an animation, each frame would have a different size, making the animation
boundary and position change constantly. This could be fixed in SpriteFrames by calculating the proper margin, however, the resulting file would be bigger than the one with trimming disabled.
Check [issue #39](https://github.com/viniciusgerevini/godot-aseprite-wizard/issues/39) for more details.


### Thanks

- Thanks to @TheOrioli, @furroy and @tavurth for weighting in the AnimationPlayer support discussion. [issue #37](https://github.com/viniciusgerevini/godot-aseprite-wizard/issues/37)
- Thanks again to @TheOrioli for providing a quick [workaround](https://github.com/KikimoraGames/godot_animationplayer_spriteframes_helper) for whoever is struggling with the lack of AnimationPlayer support.

## 3.0.0 (2021-11-20)

### Breaking changes

- Animations starting with `_` will be set as non loopable (loop = false). Both default loop configuration and the exception prefix can be changed via configuration window.

### Added

- Default loop value configuration.
- Loop exception prefix configuration.

### Fixed

- wizard dock was not persisting pre-filled options if not closed.

### Thanks

Thanks to Micky (@Mickeon) for suggesting the loop prefix feature.

## 2.1.1 (2021-10-20)

### Fixed

- Node renaming was breking wizard screen

## 2.1.0 (2021-10-17)

### Added

- Added `Trim by grid` option, which trims empty tiles respecting Aseprite's configured grid.

### Changed

- Wizard option list consistent to Godot's options.

### Thanks

- Thanks to @aaaaaaaaargh for adding the `Trim by grid` option.


## 2.0.0 (2021-07-31)

### Breaking Changes

- Animations with ping-pong method are adding two less frames. It aligns with how they behave in
Aseprite, but this means if you re-import previous imported ping-poing animations they will be faster than before.

### Fixes

- Ping-pong method was adding first and last frame twice.
- Capitalised buttons text.
- Fixed wrong tooltip for option to disable resource generation.

### Thanks

- Thanks to @imsamuka for implementing these changes.


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
