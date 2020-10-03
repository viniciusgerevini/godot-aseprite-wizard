tool
extends WindowDialog

var config: ConfigFile

func _ready():
	if config.has_section_key('aseprite', 'command'):
		_aseprite_command_field().text = config.get_value('aseprite', 'command')
	else:
		_aseprite_command_field().text = get_default_command()

func init(config_file: ConfigFile):
	config = config_file

func _on_save_button_up():
	if _aseprite_command_field().text == "":
		config.set_value('aseprite', 'command', get_default_command())
	else:
		config.set_value('aseprite', 'command', _aseprite_command_field().text)

	self.hide()

func _on_close_button_up():
	self.hide()

static func get_default_command() -> String:
	return 'aseprite'

func _aseprite_command_field() -> LineEdit:
	return $MarginContainer/VBoxContainer/VBoxContainer/aseprite_command as LineEdit
