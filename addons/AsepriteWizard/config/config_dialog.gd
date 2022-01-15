tool
extends PopupPanel

signal importer_state_changed

var _config

func _ready():
	_aseprite_command_field().text = _config.get_command()
	_importer_enable_field().pressed = _config.is_importer_enabled()
	_remove_source_files_field().pressed = _config.should_remove_source_files()
	_enable_animation_loop().pressed = _config.is_default_animation_loop_enabled()
	_loop_ex_prefix().text = _config.get_animation_loop_exception_prefix()


func init(config):
	_config = config


func _on_save_button_up():
	_config.set_command(_aseprite_command_field().text)

	if _importer_enable_field().pressed != _config.is_importer_enabled():
		_config.set_importer_enabled(_importer_enable_field().pressed)
		self.emit_signal("importer_state_changed")

	_config.set_remove_source_files(_remove_source_files_field().pressed)
	_config.set_default_animation_loop(_enable_animation_loop().pressed)
	_config.set_animation_loop_exception_prefix(_loop_ex_prefix().text)

	_config.save()
	self.hide()


func _on_close_button_up():
	self.hide()


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
