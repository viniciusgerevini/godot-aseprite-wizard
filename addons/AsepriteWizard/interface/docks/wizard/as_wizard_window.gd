@tool
extends PanelContainer

signal close_requested
signal import_success(file_settings)

var result_code = preload("../../../config/result_codes.gd")
var _aseprite_file_exporter = preload("../../../aseprite/file_exporter.gd").new()
var _sf_creator = preload("../../../creators/sprite_frames/sprite_frames_creator.gd").new()

var _config
var _file_system: EditorFileSystem

var _file_dialog_aseprite: EditorFileDialog
var _output_folder_dialog: EditorFileDialog
var _warning_dialog: AcceptDialog

@onready var _layer_section_btn: Button = $container/options/layer_section/header/section_header
@onready var _layer_section_content: MarginContainer = $container/options/layer_section/section_content

@onready var _output_section_btn: Button = $container/options/output_section/header/section_header
@onready var _output_section_content: MarginContainer = $container/options/output_section/section_content

@onready var _file_location_field: LineEdit = $container/options/file_location/HBoxContainer/file_location_path

@onready var _output_folder_field: LineEdit = $container/options/output_section/section_content/items/output_folder/HBoxContainer/file_location_path

@onready var _exception_pattern_field: LineEdit = $container/options/layer_section/section_content/items/exclude_pattern/pattern

@onready var _split_mode_field: CheckBox = $container/options/layer_section/section_content/items/split_layers/field

@onready var _only_visible_layers_field: CheckBox = $container/options/layer_section/section_content/items/visible_layers/field

@onready var _custom_name_field: LineEdit = $container/options/output_section/section_content/items/custom_filename/pattern

@onready var _do_not_create_res_field: CheckBox = $container/options/output_section/section_content/items/disable_resource_creation/field

const INTERFACE_SECTION_KEY_LAYER = "layer_section"
const INTERFACE_SECTION_KEY_OUTPUT = "output_section"

@onready var _expandable_sections = {
	INTERFACE_SECTION_KEY_LAYER: { "header": _layer_section_btn, "content": _layer_section_content},
	INTERFACE_SECTION_KEY_OUTPUT: { "header": _output_section_btn, "content": _output_section_content},
}

var _interface_section_state = {}

# TODO persist expanded collapsed sections
# TODO Imported SpriteFrames tab

func _ready():
	_configure_sections()


func _exit_tree():
	_file_dialog_aseprite.queue_free()
	_output_folder_dialog.queue_free()
	_warning_dialog.queue_free()


func init(config, editor_file_system: EditorFileSystem):
	_config = config
	_file_system = editor_file_system
	_file_dialog_aseprite = _create_aseprite_file_selection()
	_output_folder_dialog = _create_outuput_folder_selection()
	_warning_dialog = AcceptDialog.new()
	_warning_dialog.exclusive = false

	_sf_creator.init(_config)
	_aseprite_file_exporter.init(config)

	get_parent().get_parent().add_child(_file_dialog_aseprite)
	get_parent().get_parent().add_child(_output_folder_dialog)
	get_parent().get_parent().add_child(_warning_dialog)

	_load_persisted_config()


func _load_persisted_config():
	_split_mode_field.button_pressed = _config.should_split_layers()
	_only_visible_layers_field.button_pressed = _config.should_include_only_visible_layers()
	_exception_pattern_field.text = _config.get_exception_pattern()
	_custom_name_field.text = _config.get_last_custom_name()
	_file_location_field.text = _config.get_last_source_path()
	_do_not_create_res_field.button_pressed = _config.should_not_create_resource()

	var output_folder = _config.get_last_output_path()
	_output_folder_field.text = output_folder if output_folder != "" else "res://"


func load_import_config(import_config: Dictionary):
	_split_mode_field.button_pressed = import_config.options.export_mode == _aseprite_file_exporter.LAYERS_EXPORT_MODE
	_only_visible_layers_field.button_pressed = import_config.options.only_visible_layers
	_exception_pattern_field.text = import_config.options.exception_pattern
	_custom_name_field.text = import_config.options.output_filename
	_file_location_field.text = import_config.source_file
	_do_not_create_res_field.button_pressed = import_config.options.do_not_create_resource
	_output_folder_field.text = import_config.output_location if import_config.output_location != "" else "res://"


func _open_aseprite_file_selection_dialog():
	var current_selection = _file_location_field.text
	if current_selection != "":
		_file_dialog_aseprite.current_dir = current_selection.get_base_dir()
	_file_dialog_aseprite.popup_centered_ratio()


func _open_output_folder_selection_dialog():
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
	_config.set_last_source_path(localized_path)


func _on_output_folder_selected(path):
	_output_folder_field.text = path
	_config.set_last_output_path(path)


func _on_next_btn_up():
	var aseprite_file = _file_location_field.text
	var output_location = _output_folder_field.text
	var split_layers = _split_mode_field.button_pressed

	var export_mode = _aseprite_file_exporter.LAYERS_EXPORT_MODE if split_layers else _aseprite_file_exporter.FILE_EXPORT_MODE
	var options = {
		"export_mode": export_mode,
		"exception_pattern": _exception_pattern_field.text,
		"only_visible_layers": _only_visible_layers_field.button_pressed,
		"output_filename": _custom_name_field.text,
		"do_not_create_resource": _do_not_create_res_field.button_pressed,
		"output_folder": output_location,
	}

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_files(
		ProjectSettings.globalize_path(aseprite_file),
		options
	)

	if not aseprite_output.is_ok:
		_show_error(aseprite_output.code)
		return

	_file_system.scan()
	await _file_system.filesystem_changed

	var exit_code = OK

	if !options.get("do_not_create_resource", false):
		exit_code = _sf_creator.create_and_save_resources(aseprite_output.content)

	if _config.should_remove_source_files():
		_remove_source_files(aseprite_output.content)

	if exit_code != OK:
		_show_error(exit_code)
		return

	emit_signal("import_success", {
		"source_file": aseprite_file,
		"output_location": output_location,
		"options": options,
	})

	_show_import_success_message()


func trigger_import():
	_on_next_btn_up()


func _on_close_btn_up():
	_close_window()


func _close_window():
	_save_config()
	self.emit_signal("close_requested")


func _save_config():
	_config.set_split_layers(_split_mode_field.button_pressed)
	_config.set_exception_pattern(_exception_pattern_field.text)
	_config.set_custom_name(_custom_name_field.text)
	_config.set_include_only_visible_layers(_only_visible_layers_field.button_pressed)
	_config.set_do_not_create_resource(_do_not_create_res_field.button_pressed)


func _show_error(code: int):
	_show_error_message(result_code.get_error_message(code))


func _show_error_message(message: String):
	_warning_dialog.dialog_text = "Error: %s" % message
	_warning_dialog.popup_centered()


func _show_import_success_message():
	_warning_dialog.dialog_text = "Aseprite import succeeded"
	_warning_dialog.popup_centered()
	_save_config()

func _remove_source_files(source_files: Array):
	for s in source_files:
		DirAccess.remove_absolute(s.data_file)

	_file_system.call_deferred("scan")


func _configure_sections():
	#var cfg = wizard_config.load_interface_config(target_node)
	#_interface_section_state = cfg

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
	#wizard_config.save_interface_config(target_node, _interface_section_state)


func _on_layer_section_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_LAYER)


func _on_output_section_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_OUTPUT)
