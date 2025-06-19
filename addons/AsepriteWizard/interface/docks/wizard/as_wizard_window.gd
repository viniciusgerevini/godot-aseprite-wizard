@tool
extends PanelContainer

signal close_requested
signal import_success(file_settings)

const result_code = preload("../../../config/result_codes.gd")
var _config = preload("../../../config/config.gd").new()

var _import_helper = preload("./wizard_import_helper.gd").new()

var _file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()

var _file_dialog_aseprite: EditorFileDialog
var _output_folder_dialog: EditorFileDialog
var _warning_dialog: AcceptDialog

@onready var _layer_section_btn: Button = $container/options/layer_section/header/section_header
@onready var _layer_section_content: MarginContainer = $container/options/layer_section/section_content

@onready var _animation_section_btn: Button = $container/options/animation_section/header/section_header
@onready var _animation_section_content: MarginContainer = $container/options/animation_section/section_content

@onready var _output_section_btn: Button = $container/options/output_section/header/section_header
@onready var _output_section_content: MarginContainer = $container/options/output_section/section_content

@onready var _file_location_field: LineEdit = $container/options/file_location/HBoxContainer/file_location_path

@onready var _output_folder_field: LineEdit = $container/options/output_section/section_content/items/output_folder/HBoxContainer/file_location_path

@onready var _exception_pattern_field: LineEdit = $container/options/layer_section/section_content/items/exclude_pattern/pattern

@onready var _split_mode_field: CheckBox = $container/options/layer_section/section_content/items/split_layers/field

@onready var _only_visible_layers_field: CheckBox = $container/options/layer_section/section_content/items/visible_layers/field

@onready var _custom_name_field: LineEdit = $container/options/output_section/section_content/items/custom_filename/pattern

@onready var _round_fps_field: CheckBox = $container/options/animation_section/section_content/items/round_fps/field

@onready var _scale_field: SpinBox = $container/options/output_section/section_content/items/scale/SpinBox

@onready var _do_not_create_res_field: CheckBox = $container/options/output_section/section_content/items/disable_resource_creation/field

const INTERFACE_SECTION_KEY_LAYER = "layer_section"
const INTERFACE_SECTION_KEY_ANIMATION = "animation_section"
const INTERFACE_SECTION_KEY_OUTPUT = "output_section"

@onready var _expandable_sections = {
	INTERFACE_SECTION_KEY_LAYER: { "header": _layer_section_btn, "content": _layer_section_content},
	INTERFACE_SECTION_KEY_ANIMATION: { "header": _animation_section_btn, "content": _animation_section_content},
	INTERFACE_SECTION_KEY_OUTPUT: { "header": _output_section_btn, "content": _output_section_content},
}

var _interface_section_state = {}


func _ready():
	_configure_sections()
	_load_persisted_config()


func _exit_tree():
	if is_instance_valid(_file_dialog_aseprite):
		_file_dialog_aseprite.queue_free()
	if is_instance_valid(_output_folder_dialog):
		_output_folder_dialog.queue_free()
	if is_instance_valid(_warning_dialog):
		_warning_dialog.queue_free()


func _init_aseprite_file_selection_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().get_parent().add_child(_file_dialog_aseprite)


func _init_output_folder_selection_dialog():
	_output_folder_dialog = _create_outuput_folder_selection()
	get_parent().get_parent().add_child(_output_folder_dialog)


func _init_warning_dialog():
	_warning_dialog = AcceptDialog.new()
	_warning_dialog.exclusive = false
	get_parent().get_parent().add_child(_warning_dialog)


func _load_persisted_config() -> void:
	var cfg = _load_last_import_cfg()
	_load_config(cfg)


func _load_config(cfg: Dictionary) -> void:
	_split_mode_field.button_pressed = cfg.split_layers
	_only_visible_layers_field.button_pressed = cfg.only_visible_layers
	_exception_pattern_field.text = cfg.layer_exclusion_pattern
	_custom_name_field.text = cfg.output_name
	_file_location_field.text = cfg.source_file
	_do_not_create_res_field.button_pressed = cfg.do_not_create_resource
	_round_fps_field.button_pressed = cfg.get("should_round_fps", true)
	_scale_field.value = float(cfg.get("scale", 1))
	_output_folder_field.text = cfg.output_location if cfg.output_location != "" else "res://"


func _save_config() -> void:
	_config.set_standalone_spriteframes_last_import_config(_get_field_values())


func _get_field_values() -> Dictionary:
	return {
		"split_layers": _split_mode_field.button_pressed,
		"only_visible_layers": _only_visible_layers_field.button_pressed,
		"layer_exclusion_pattern": _exception_pattern_field.text,
		"output_name": _custom_name_field.text,
		"source_file": _file_location_field.text,
		"do_not_create_resource": _do_not_create_res_field.button_pressed,
		"output_location": _output_folder_field.text if _output_folder_field.text != "" else "res://",
		"should_round_fps": _round_fps_field.button_pressed,
		"scale": str(_scale_field.value),
	}


func _clear_config() -> void:
	_config.clear_standalone_spriteframes_last_import_config()
	var default = _get_default_config()
	_load_config(default)


## This is used by the other tabs to set the form fields
func load_import_config(field_values: Dictionary):
	_split_mode_field.button_pressed = field_values.split_layers
	_only_visible_layers_field.button_pressed = field_values.only_visible_layers
	_exception_pattern_field.text = field_values.layer_exclusion_pattern
	_custom_name_field.text = field_values.output_name
	_file_location_field.text = field_values.source_file
	_do_not_create_res_field.button_pressed = field_values.do_not_create_resource
	_output_folder_field.text = field_values.output_location
	_round_fps_field.button_pressed = field_values.get("should_round_fps", true)
	_scale_field.value = float(field_values.get("scale", 1))


func _open_aseprite_file_selection_dialog():
	if not is_instance_valid(_file_dialog_aseprite):
		_init_aseprite_file_selection_dialog()

	var current_selection = _file_location_field.text
	if current_selection != "":
		_file_dialog_aseprite.current_dir = current_selection.get_base_dir()
	_file_dialog_aseprite.popup_centered_ratio()


func _open_output_folder_selection_dialog():
	if not is_instance_valid(_output_folder_dialog):
		_init_output_folder_selection_dialog()
	var current_selection = _output_folder_field.text
	if current_selection != "":
		_output_folder_dialog.current_dir = current_selection
	_output_folder_dialog.popup_centered_ratio()


func _create_aseprite_file_selection():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected", _on_aseprite_file_selected)
	file_dialog.set_filters(PackedStringArray(["*.ase","*.aseprite"]))
	return file_dialog


func _create_outuput_folder_selection():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.connect("dir_selected", _on_output_folder_selected)
	return file_dialog


func _on_aseprite_file_selected(path):
	var localized_path = ProjectSettings.localize_path(path)
	_file_location_field.text = localized_path


func _on_output_folder_selected(path):
	_output_folder_field.text = path


func _on_next_btn_up():
	var aseprite_file = _file_location_field.text
	var fields = _get_field_values()
	var exit_code = await _import_helper.import_and_create_resources(aseprite_file, _get_field_values())

	if exit_code != OK:
		_show_error(exit_code)
		return

	emit_signal("import_success", fields)

	if _config.should_remove_source_files():
		_file_system.call_deferred("scan")

	_show_import_success_message()


func trigger_import():
	_on_next_btn_up()


func _on_close_btn_up():
	_close_window()


func _close_window():
	_save_config()
	self.emit_signal("close_requested")


func _on_clear_button_up():
	_clear_config()


func _show_error(code: int):
	_show_error_message(result_code.get_error_message(code))


func _show_error_message(message: String):
	if not is_instance_valid(_warning_dialog):
		_init_warning_dialog()
	_warning_dialog.dialog_text = "Error: %s" % message
	_warning_dialog.popup_centered()


func _show_import_success_message():
	if not is_instance_valid(_warning_dialog):
		_init_warning_dialog()
	_warning_dialog.dialog_text = "Aseprite import succeeded"
	_warning_dialog.popup_centered()
	_save_config()


func _configure_sections():
	for key in _expandable_sections:
		_adjust_section_visibility(key)


func _adjust_section_visibility(key: String) -> void:
	var section = _expandable_sections[key]
	var is_visible = _interface_section_state.get(key, true)
	_adjust_icon(section.header, is_visible)
	section.content.visible = is_visible


func _adjust_icon(section: Button, is_visible: bool = true) -> void:
	var icon_name = "GuiTreeArrowDown" if is_visible else "GuiTreeArrowRight"
	section.icon = get_theme_icon(icon_name, "EditorIcons")


func _toggle_section_visibility(key: String) -> void:
	_interface_section_state[key] = not _interface_section_state.get(key, true)
	_adjust_section_visibility(key)


func _on_layer_section_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_LAYER)


func _on_output_section_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_OUTPUT)


func _on_animation_header_button_down() -> void:
		_toggle_section_visibility(INTERFACE_SECTION_KEY_ANIMATION)


func _load_last_import_cfg() -> Dictionary:
	var cfg = _config.get_standalone_spriteframes_last_import_config()

	if cfg.is_empty():
		return _get_default_config()

	return cfg


func _get_default_config() -> Dictionary:
	return {
		"split_layers": false,
		"only_visible_layers": _config.should_include_only_visible_layers_by_default(),
		"layer_exclusion_pattern": _config.get_default_exclusion_pattern(),
		"output_name": "",
		"source_file": "",
		"do_not_create_resource": false,
		"output_location": "res://",
		"should_round_fps": true,
		"scale": "1",
	}
