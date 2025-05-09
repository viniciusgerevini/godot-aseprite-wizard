# Godot Aseprite Wizard (Godot 4)

<p align="center"><img src="icon.png" alt="Aseprite Wizard Logo"/></p>

Aseprite Wizard is a godot plugin to help import Aseprite animations to Godot. It provides a few different import methods, and supports various nodes, such as AnimationPlayers, AnimatedSprites 2D/3D and SpriteFrames.

Check the [documentation](https://thisisvini.com/aseprite-wizard) for more details.

_This branch supports Godot 4. For Godot 3 docs and code check the [godot_3](https://github.com/viniciusgerevini/godot-aseprite-wizard/tree/godot_3) branch. You can find more details about the differences between Godot 3 and Godot 4 on issue https://github.com/viniciusgerevini/godot-aseprite-wizard/issues/70._

<img align="center" src="./screenshots/comparison.png" />

_Check the screenshots folder for more examples._

## Features

- Godot importer and inspector docks for easy import and re-import.
- Adds automatic importers:
	- Aseprite SpriteFrames: Use aseprite files as SpriteFrames resources.
	- Aseprite Texture: Use aseprite files as static images (only first frame is imported)
	- Aseprite Tileset Texture: Use aseprite files with tilemap layers as AtlasTexture which can be added directly to Godot's tileset creator.
- Inspector docks to manually import animations to:
	- AnimationPlayer (Sprite2D, Sprite3D and TextureRect).
	- AnimatedSprite2D/3D.
	- As standalone SpritesFrames resource.
- Supports Aseprite animation directions (forward, reverse, ping-pong, ping-pong reverse).
- Supports loopable and non-loopable animations via Aseprite repeat or tags.
- Separates each Aseprite Tag into animations. In case no tags are defined, imports everything as default animation.
- Filters out layers you don't want in the final animation using regex.
- Supports slices. Import only a region from your file.
- For AnimatedSprite
  - Creates SpriteFrames with Atlas Texture to be used in AnimatedSprites.
  - Converts Aseprite frame duration (defined in milliseconds) to Godot's animation FPS. This way you can create your animation with the right timing in Aseprite and it should work the same way in Godot.
  - Choose to export the Aseprite file as a single SpriteFrames resource or separate each layer in different resources.
  - Adds Aseprite file importer to Godot.
- AnimationPlayer
  - Adds and removes animation tracks without removing other existing tracks.
  - You are free to import multiple files to the same AnimationPlayer or import each layer to their own Sprite/TextureRect and AnimationPlayer.
  - Supports animation libraries.

Aseprite Wizard is only required during development. If you decide to not use it anymore, you can remove the plugin and all animations previously imported should keep working as expected.

## Contact

Thanks for the constant feedback and suggestions. If you are facing problems with the plugin or have suggestions/questions, please open an issue in this repo.

If you like game dev related content, you might like my [channel](http://youtube.com/c/ThisIsVini).

Check my [website](https://thisisvini.com) for more contact options.
