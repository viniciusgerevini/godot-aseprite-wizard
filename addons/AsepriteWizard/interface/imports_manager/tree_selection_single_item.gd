@tool
extends VBoxContainer

signal import_triggered
signal open_scene_triggered

@onready var _name = $GridContainer/name_value
@onready var _type = $GridContainer/type_value
@onready var _path = $GridContainer/path_value

@onready var _source_label = $GridContainer/source_file_label
@onready var _source = $GridContainer/source_file_value
@onready var _layer_label = $GridContainer/layer_label
@onready var _layer = $GridContainer/layer_value
@onready var _slice_label = $GridContainer/slice_label
@onready var _slice = $GridContainer/slice_value

@onready var _o_name_label = $GridContainer/o_name_label
@onready var _o_name = $GridContainer/o_name_value
@onready var _o_folder_label = $GridContainer/o_folder_label
@onready var _o_folder_value = $GridContainer/o_folder_value


@onready var _resource_buttons = $resource_buttons
@onready var _dir_buttons = $dir_buttons
@onready var _scene_buttons = $scene_buttons

@onready var _source_change_warning = $source_changed_warning

@onready var _resource_only_fields = [
	_source_label,
	_source,
	_layer_label,
	_layer,
	_slice_label,
	_slice,
	_o_name_label,
	_o_name,
	_o_folder_label,
	_o_folder_value,
	_source_change_warning,
]

var _current_resource_type = "resource"
var _resource_config: Dictionary = {}

func _ready():
	_source_change_warning.set_text("Source file changed since last import")
	_source_change_warning.hide()


func set_resource_details(resource_details: Dictionary) -> void:
	_resource_config = resource_details
	_resource_buttons.hide()
	_dir_buttons.hide()
	_scene_buttons.hide()
	_source_change_warning.hide()

	_current_resource_type = resource_details.type
	match resource_details.type:
		"dir":
			_name.text = resource_details.name
			_type.text = "Folder"
			_path.text = resource_details.path
			_hide_resource_fields()
			_dir_buttons.show()
		"file":
			_name.text = resource_details.name
			_type.text = "File"
			_path.text = resource_details.path
			_hide_resource_fields()
			_scene_buttons.show()
		"resource":
			_name.text = resource_details.node_name
			_type.text = resource_details.node_type
			_path.text = resource_details.node_path

			var meta = resource_details.meta
			_source.text = meta.source
			_layer.text = "All" if meta.get("layer", "") == "" else meta.layer
			_slice.text = "All" if meta.get("slice", "") == "" else meta.slice

			var folder = resource_details.scene_path.get_base_dir() if meta.get("o_folder", "") == "" else meta.o_folder
			var file_name = "" if meta.get("o_name", "") == "" else meta.o_name

			if _layer.text != "All":
				file_name += _layer.text
			elif file_name == "":
				file_name = meta.source.get_basename().get_file()
			_o_name.text = "%s/%s.png" % [folder, file_name]

			_show_resource_fields()
			_resource_buttons.show()

			_source_change_warning.visible = resource_details.has_changes


func _hide_resource_fields():
	for f in _resource_only_fields:
		f.hide()


func _show_resource_fields():
	for f in _resource_only_fields:
		f.show()


func show_buttons():
	match _current_resource_type:
		"resource":
			_resource_buttons.show()
		"scene":
			_scene_buttons.show()
		_:
			_dir_buttons.show()


func hide_buttons():
	_resource_buttons.hide()
	_dir_buttons.hide()
	_scene_buttons.hide()


func hide_source_change_warning():
	_source_change_warning.hide()


func _on_show_dir_in_fs_button_up():
	EditorInterface.get_file_system_dock().navigate_to_path(_path.text)


func _on_import_all_button_up():
	import_triggered.emit()


func _on_import_button_up():
	import_triggered.emit()


func _on_open_scene_button_up():
	open_scene_triggered.emit()
