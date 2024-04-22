@tool
extends EditorInspectorPlugin

const APInspectorDock = preload("./sprite_inspector_dock.tscn")


func _can_handle(object):
	return object is Sprite2D || object is Sprite3D || object is TextureRect


func _parse_end(object):
	var dock = APInspectorDock.instantiate()
	dock.target_node = object
	add_custom_control(dock)
