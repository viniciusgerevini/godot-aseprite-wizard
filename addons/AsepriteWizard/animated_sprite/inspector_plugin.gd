tool
extends EditorInspectorPlugin

const AsepriteInspectorDock = preload("./docks/animated_sprite_inspector_dock.tscn")

var config
var file_system: EditorFileSystem
var _sprite: Node

func can_handle(object):
	return object is AnimatedSprite || object is AnimatedSprite3D


func parse_begin(object):
	_sprite = object


func parse_end():
	var dock = AsepriteInspectorDock.instance()
	dock.sprite = _sprite
	dock.config = config
	dock.file_system = file_system
	add_custom_control(dock)
