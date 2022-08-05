tool
extends EditorInspectorPlugin

const InspectorDock = preload("SpriteInspectorDock.tscn")

var config
var file_system: EditorFileSystem
var plugin_icons: Dictionary

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
	dock.collapsed_icon = plugin_icons.collapsed
	dock.expanded_icon = plugin_icons.expanded
	
	add_custom_control(dock)
