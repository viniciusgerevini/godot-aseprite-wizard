<!--
template: page-with-child-list
-->
# Importing

_You can check [this video](https://youtu.be/1W-CCbrzG_0) for usage examples. It's a bit outdated but it might give you an idea how the plugin works_.

## Different ways to import an animation

There are three different methods you can use to import animations to Godot:

1. Using the automatic importers: Any file saved in the project will be automatically converted to the chosen resource.
1. Using the Inspector Dock: There will be a section called Aseprite in the inspector dock when selecting Sprite, TextureRect and AnimatedSprite nodes.
1. Using the wizard dock: You can open the wizard dock via `Project -> Tools -> Aseprite Wizard -> Spritesheet Wizard Dock...` menu. In this dock you can generate standalone SpriteFrames files from anywhere in your system.

## Imports and Trade-offs

You should choose the method that best fits your workflow. However, there are some trade-offs you should be aware of.


### Inspector dock

When using the "Inspector dock" method, the plugin will generate the texture and animations and embed them to your scene. This method requires you to manually trigger re-import when the source file has changed, which might be cumbersome, but it brings the benefit of being able to open your project on machines without Aseprite installed. Also, in the (unlikely) scenario you decide to stop using Aseprite, any animation imported before will still work in your game.

The Inspector dock method also gives you more flexibility on when and how to import your animations. For example, you can have multiple Sprite2D that are imported from the same Aseprite file, but with different configurations (layers, slices, etc).

### Automatic importers

The automatic importer method is great for quick iteration, as any change in the Aseprite source file will trigger an import. It also makes file management easier, as you can link the aseprite file directly to the nodes using them (Sprite2D, AnimatedSprite, etc), making it easier to identify which files are in use and what is impacted when they are deleted.

The automatic importer comes with a big caveat though. As only the source files are included in your version control, and the import happens automatically, you need to make sure you have Aseprite installed and configured on every machine working on the game, even if they don't intend to work on the animations. This includes having Aseprite in your build pipeline, which might be a bit of a headache as Aseprite is a proprietary software, which requires either a license or being built from source.

Imagine this as the equivalent of using Blender files (.blend) instead of another final format like .fbx.

-----
