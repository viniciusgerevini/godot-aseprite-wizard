@tool
extends EditorInspectorPlugin

const InspectorDock = preload("sprite_inspector_dock.tscn")

var config
var file_system: EditorFileSystem

func _can_handle(object):
	return object is Sprite2D

func _parse_end(object):
	var dock = InspectorDock.instantiate()
	dock.sprite = object
	dock.config = config
	dock.file_system = file_system

	add_custom_control(dock)
