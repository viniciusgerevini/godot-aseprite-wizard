@tool
extends VBoxContainer

signal import_triggered

@onready var _file_name = $GridContainer/file_name_value
@onready var _type = $GridContainer/type_value
@onready var _path = $GridContainer/path_value

@onready var _source_label = $GridContainer/source_file_label
@onready var _source = $GridContainer/source_file_value
@onready var _only_visible_layers_label = $GridContainer/only_visible_layers_label
@onready var _only_visible_layers = $GridContainer/only_visible_layers_value
@onready var _layer_ex_pattern_label = $GridContainer/layer_ex_patt_label
@onready var _layer_ex_pattern = $GridContainer/layer_ex_patt_value

@onready var _o_name_label = $GridContainer/o_name_label
@onready var _o_name = $GridContainer/o_name_value
@onready var _o_folder_label = $GridContainer/o_folder_label
@onready var _o_folder_value = $GridContainer/o_folder_value

@onready var _resource_list_label = $GridContainer/resource_list_label
@onready var _resource_list = $GridContainer/resource_list
@onready var _resource_list_separator_1 = $GridContainer/HSeparator3
@onready var _resource_list_separator_2 = $GridContainer/HSeparator4

@onready var _resource_buttons = $resource_buttons
@onready var _dir_buttons = $dir_buttons
@onready var _group_buttons = $group_buttons

@onready var _source_change_warning = $source_changed_warning

@onready var _resource_only_fields = [
	_source_label,
	_source,
	_only_visible_layers_label,
	_only_visible_layers,
	_layer_ex_pattern_label,
	_layer_ex_pattern,
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
	_group_buttons.hide()
	_hide_resource_list()

	_source_change_warning.hide()

	_file_name.text = resource_details.name
	_path.text = resource_details.path

	_current_resource_type = resource_details.type
	match resource_details.type:
		"resource":
			_type.text = resource_details.resource_type
			_show_resource_fields()
			_resource_buttons.show()

			var fields = resource_details.meta.fields
			_load_fields(fields)
			_resource_buttons.show()
			_source_change_warning.visible = resource_details.has_changes
		"group":
			_type.text = "Split Group"
			_show_resource_fields()
			_load_fields(resource_details.children[0].meta.fields)
			_source_change_warning.visible = resource_details.children[0].has_changes
			_group_buttons.show()
			_show_resource_list()
			for c in _resource_list.get_children():
				c.queue_free()

			for child_resource in resource_details.children:
				var label = Label.new()
				label.text = child_resource.name
				_resource_list.add_child(label)
		_:
			_type.text = "Folder"
			_hide_resource_fields()
			_dir_buttons.show()
			return


func _load_fields(fields: Dictionary):
	_only_visible_layers.text = "Yes" if fields.only_visible_layers else "No"
	_layer_ex_pattern.text = fields.layer_exclusion_pattern

	_o_name.text = fields.output_name
	_o_folder_value.text = fields.output_location

	_source.text = fields.source_file


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
		_:
			_dir_buttons.show()


func hide_buttons():
	_resource_buttons.hide()
	_dir_buttons.hide()


func hide_source_change_warning():
	_source_change_warning.hide()


func _on_show_in_fs_button_up():
	EditorInterface.get_file_system_dock().navigate_to_path(_path.text)


func _on_show_dir_in_fs_button_up():
	EditorInterface.get_file_system_dock().navigate_to_path(_path.text)


func _on_import_all_button_up():
	import_triggered.emit()


func _on_import_button_up():
	import_triggered.emit()


func _hide_resource_list():
	_resource_list_separator_1.hide()
	_resource_list_separator_2.hide()
	_resource_list_label.hide()
	_resource_list.hide()


func _show_resource_list():
	_resource_list_separator_1.show()
	_resource_list_separator_2.show()
	_resource_list_label.show()
	_resource_list.show()


func _on_import_all_pressed():
	import_triggered.emit()


func _on_show_in_fs_pressed():
	EditorInterface.get_file_system_dock().navigate_to_path(_resource_config.children[0].path)
