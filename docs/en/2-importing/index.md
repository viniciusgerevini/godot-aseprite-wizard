<!--
template: page-with-child-list
-->
# Importing

_You can check [this video](https://youtu.be/1W-CCbrzG_0) for usage examples. It's a bit outdated but it might give you an idea how the plugin works_.

## Different ways to import an animation

There are three different methods you can use to import animations to Godot:

1. Using the automatic importers: Any file saved in the project will be automatically converted to the chosen resource type.
1. Using the Inspector Dock: There will be a section called Aseprite in the inspector dock when selecting Sprite, TextureRect and AnimatedSprite nodes.
1. Using the wizard dock (deprecated): You can open the wizard dock via `Project -> Tools -> Aseprite Wizard -> Spritesheet Wizard Dock...` menu. In this dock you can generate standalone SpriteFrames files from anywhere in your system.

## Imports and Trade-offs

Both methods are equivalent and will depend on your workflow. Although, there are a few trade-offs you should be aware of:

### Automatic importers

The automatic importer method is great for quick iteration, as any change in the Aseprite source file will trigger an import. It also makes file management easier, as you can reference the aseprite file directly in the nodes using them (Sprite2D, AnimatedSprite, etc), making it easier to identify which files are in use and what is impacted when they are deleted.

With the automatic importer, only the source files are included in the version control, and the import happens automatically once the project is opened. This means you need to make sure you have Aseprite installed and configured on every machine working on the game, even if they don't intend to work on the animations.

If you do need to open your project in machines without Aseprite installed (e.g. a CI pipeline) you might want to consider enabling [baking](./3-importers/index.md#baking).

### Inspector dock

When using the "Inspector dock" method, the plugin will generate the texture and animations and embed them to your scene. This method requires you to manually trigger re-import when the source file has changed, which might be cumbersome, but it brings the benefit of being able to open your project on machines without Aseprite installed. Also, in the (unlikely) scenario you decide to stop using Aseprite, any animation imported before will still work in your game.

The Inspector dock method also gives you more flexibility on when and how to import your animations. For example, you can have multiple Sprite2D that are imported from the same Aseprite file, but with different configurations (layers, slices, etc).

-----
