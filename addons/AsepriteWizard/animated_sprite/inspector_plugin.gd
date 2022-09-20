@tool
extends EditorInspectorPlugin

const AnimatedSpriteInspectorDock = preload("animated_sprite_inspector_dock.tscn")

var config
var file_system: EditorFileSystem

func _can_handle(object):
	return object is AnimatedSprite2D

func _parse_end(object):
	var dock = AnimatedSpriteInspectorDock.instantiate()
	dock.sprite = object
	dock.config = config
	dock.file_system = file_system

	add_custom_control(dock)
