@tool
extends EditorInspectorPlugin

const APInspectorDock = preload("./docks/animation_player_inspector_dock.tscn")

var config
var file_system: EditorFileSystem

func _can_handle(object):
	return object is Sprite2D || object is Sprite3D || object is TextureRect


func _parse_end(object):
	var dock = APInspectorDock.instantiate()
	dock.target_node = object
	dock.config = config
	dock.file_system = file_system
	add_custom_control(dock)
