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
#	var props = dock.get_editor_properties()
	
#	for prop in props:
#		print("prop")
#		print(props[prop])
#		add_property_editor(prop, props[prop])

#	var property = EditorProperty.new()
#	property.label = "Aseprite/Animation"
#	property.add_child(dock)
#	property.set_bottom_editor(dock)
#	add_custom_control(property)
