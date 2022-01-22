tool
extends EditorInspectorPlugin

const InspectorDock = preload("sprite_inspector_dock.tscn")

var config
var file_system: EditorFileSystem

var _sprite: Sprite

func can_handle(object):
	return object is Sprite


func parse_begin(object):
	_sprite = object


func parse_end():
	var dock = InspectorDock.instance()
	dock.sprite = _sprite
	dock.config = config
	dock.file_system = file_system
	
	add_custom_control(dock)
