tool
extends EditorInspectorPlugin

const AsepriteInspectorDock = preload("./docks/animation_player_inspector_dock.tscn")

var config
var file_system: EditorFileSystem
var _target_node: Node

func can_handle(object):
	return object is Sprite || object is Sprite3D || object is TextureRect


func parse_begin(object):
	_target_node = object


func parse_end():
	var dock = AsepriteInspectorDock.instance()
	dock.target_node = _target_node
	dock.config = config
	dock.file_system = file_system
	add_custom_control(dock)
