tool
extends PopupPanel

signal importer_state_changed

const _CONFIG_SECTION_KEY = 'aseprite'
const _COMMAND_KEY = 'command'
const _IMPORTER_ENABLE_KEY = 'is_importer_enabled'
const _REMOVE_SOURCE_FILES_KEY = 'remove_source_files'

var config: ConfigFile


func _ready():
	_aseprite_command_field().text = config.get_value(_CONFIG_SECTION_KEY, _COMMAND_KEY, get_default_command())
	_importer_enable_field().pressed = config.get_value(_CONFIG_SECTION_KEY, _IMPORTER_ENABLE_KEY, true)
	_remove_source_files_field().pressed = config.get_value(_CONFIG_SECTION_KEY, _REMOVE_SOURCE_FILES_KEY, false)


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
