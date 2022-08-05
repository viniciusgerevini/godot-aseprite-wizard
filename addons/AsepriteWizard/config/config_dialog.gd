tool
extends PopupPanel

var _config

onready var _aseprite_command_field = $MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/aseprite_command
onready var _version_label = $MarginContainer/VBoxContainer/VBoxContainer/version_found

func _ready():
	_aseprite_command_field.text = _config.get_command()
	_version_label.modulate.a = 0


func init(config):
	_config = config


func _on_save_button_up():
	_config.set_command(_aseprite_command_field.text)
	_config.save()
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
