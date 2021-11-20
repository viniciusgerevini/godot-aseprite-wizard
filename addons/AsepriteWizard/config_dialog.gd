tool
extends PopupPanel

signal importer_state_changed

const _CONFIG_SECTION_KEY = 'aseprite'
const _COMMAND_KEY = 'command'
const _IMPORTER_ENABLE_KEY = 'is_importer_enabled'
const _REMOVE_SOURCE_FILES_KEY = 'remove_source_files'
const _LOOP_ENABLED = 'loop_enabled'
const _LOOP_EXCEPTION_PREFIX = 'loop_config_prefix'

const _DEFAULT_LOOP_EX_PREFIX = '_'

var config: ConfigFile


func _ready():
	_aseprite_command_field().text = config.get_value(_CONFIG_SECTION_KEY, _COMMAND_KEY, get_default_command())
	_importer_enable_field().pressed = config.get_value(_CONFIG_SECTION_KEY, _IMPORTER_ENABLE_KEY, true)
	_remove_source_files_field().pressed = config.get_value(_CONFIG_SECTION_KEY, _REMOVE_SOURCE_FILES_KEY, false)
	_enable_animation_loop().pressed = config.get_value(_CONFIG_SECTION_KEY, _LOOP_ENABLED, true)
	_loop_ex_prefix().text = config.get_value(_CONFIG_SECTION_KEY, _LOOP_EXCEPTION_PREFIX, _DEFAULT_LOOP_EX_PREFIX)

func init(config_file: ConfigFile):
	config = config_file


func _on_save_button_up():
	if _aseprite_command_field().text == "":
		config.set_value(_CONFIG_SECTION_KEY, _COMMAND_KEY, get_default_command())
	else:
		config.set_value(_CONFIG_SECTION_KEY, _COMMAND_KEY, _aseprite_command_field().text)

	if _importer_enable_field().pressed != config.get_value(_CONFIG_SECTION_KEY, _IMPORTER_ENABLE_KEY, true):
		config.set_value(_CONFIG_SECTION_KEY, _IMPORTER_ENABLE_KEY, _importer_enable_field().pressed)
		self.emit_signal("importer_state_changed")

	config.set_value(_CONFIG_SECTION_KEY, _REMOVE_SOURCE_FILES_KEY, _remove_source_files_field().pressed)
	config.set_value(_CONFIG_SECTION_KEY, _LOOP_EXCEPTION_PREFIX, _loop_ex_prefix().text if _loop_ex_prefix().text != "" else _DEFAULT_LOOP_EX_PREFIX)
	config.set_value(_CONFIG_SECTION_KEY, _LOOP_ENABLED, _enable_animation_loop().pressed)

	self.hide()


func _on_close_button_up():
	self.hide()


static func get_default_command() -> String:
	return 'aseprite'


func _aseprite_command_field() -> LineEdit:
	return $MarginContainer/VBoxContainer/VBoxContainer/aseprite_command as LineEdit


func _importer_enable_field() -> CheckBox:
	return $MarginContainer/VBoxContainer/enable_importer as CheckBox


func _remove_source_files_field() -> CheckBox:
	return $MarginContainer/VBoxContainer/remove_source as CheckBox


func _enable_animation_loop() -> CheckBox:
	return $MarginContainer/VBoxContainer/loop_animations as CheckBox


func _loop_ex_prefix() -> LineEdit:
	return $MarginContainer/VBoxContainer/loop/loop_config_prefix as LineEdit
