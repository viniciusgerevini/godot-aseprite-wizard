@tool
extends EditorInspectorPlugin

const ASInspectorDock = preload("./animated_sprite_inspector_dock.tscn")

func _can_handle(object):
	return object is AnimatedSprite2D || object is AnimatedSprite3D


func _parse_end(object):
	var dock = ASInspectorDock.instantiate()
	dock.target_node = object
	add_custom_control(dock)
