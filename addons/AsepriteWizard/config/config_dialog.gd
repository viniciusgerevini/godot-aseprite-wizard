tool
extends PopupPanel

signal importer_state_changed

var _config

onready var _aseprite_command_field = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/aseprite_command
onready var _importer_enable_field = $MarginContainer/VBoxContainer/enable_importer
onready var _remove_source_files_field = $MarginContainer/VBoxContainer/remove_source
onready var _enable_animation_loop = $MarginContainer/VBoxContainer/loop_animations
onready var _loop_ex_prefix = $MarginContainer/VBoxContainer/loop/loop_config_prefix
onready var _layer_ex_pattern = $MarginContainer/VBoxContainer/layer_ex/ex_p_config_prefix
onready var _version_label = $MarginContainer/VBoxContainer/VBoxContainer/version_found
onready var _import_preset_enable_field = $MarginContainer/VBoxContainer/enable_import_preset


func _ready():
	_aseprite_command_field.text = _config.get_command()
	_importer_enable_field.pressed = _config.is_importer_enabled()
	_remove_source_files_field.pressed = _config.should_remove_source_files()
	_enable_animation_loop.pressed = _config.is_default_animation_loop_enabled()
	_loop_ex_prefix.text = _config.get_animation_loop_exception_prefix()
	_layer_ex_pattern.text = _config.get_default_exclusion_pattern()
	_version_label.modulate.a = 0
	_import_preset_enable_field.pressed = _config.is_import_preset_enabled()


func init(config):
	_config = config


func _on_save_button_up():
	_config.set_command(_aseprite_command_field.text)

	if _importer_enable_field.pressed != _config.is_importer_enabled():
		_config.set_importer_enabled(_importer_enable_field.pressed)
		self.emit_signal("importer_state_changed")

	_config.set_remove_source_files(_remove_source_files_field.pressed)
	_config.set_default_animation_loop(_enable_animation_loop.pressed)
	_config.set_animation_loop_exception_prefix(_loop_ex_prefix.text)
	_config.set_default_exclusion_pattern(_layer_ex_pattern.text)
	_config.set_import_preset_enabled(_import_preset_enable_field.pressed)

	_config.save()
	if _import_preset_enable_field.pressed:
		_config._create_import_preset_setting()
		
	self.hide()


func _on_close_button_up():
	self.hide()


func _on_test_pressed():
	var output = []
	if _test_command(output):
		_version_label.text = "%s found." % PoolStringArray(output).join("\n").strip_edges()
	else:
		_version_label.text = "Command not found."
	_version_label.modulate.a = 1


func _test_command(output):
	var exit_code = OS.execute(_aseprite_command_field.text, ['--version'], true, output, true)
	return exit_code == 0
