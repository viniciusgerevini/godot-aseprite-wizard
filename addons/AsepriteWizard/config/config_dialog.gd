@tool
extends Window

#var _file_dialog: EditorFileDialog

# change this to be a window instead of popup

var _config = preload("./config.gd").new()

@onready var _aseprite_command_field = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/HBoxContainer/aseprite_command
@onready var _version_label = $PanelContainer/MarginContainer/VBoxContainer/VBoxContainer/version_found

@onready var _warnings_block = $PanelContainer/MarginContainer/VBoxContainer/warnings
@onready var _warnings_icon = $PanelContainer/MarginContainer/VBoxContainer/warnings/MarginContainer/VBoxContainer/HBoxContainer/Icon

@onready
var _command_path := _config.get_command()

func _ready():
	_aseprite_command_field.text = _command_path
	_version_label.modulate.a = 0

	var sb = _warnings_block.get_theme_stylebox("panel")
	var color = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	color.a = 0.2
	sb.bg_color = color

	_warnings_icon.texture = get_theme_icon("NodeInfo", "EditorIcons")

	var p = $PanelContainer.get_theme_stylebox("panel")
	var p_color = EditorInterface.get_editor_settings().get_setting("interface/theme/base_color")
	p.bg_color = p_color


func _on_close_button_up():
	self.hide()


func _on_test_pressed():
	var output = []
	if _test_command(output):
		_version_label.text = "%s found." % "\n".join(PackedStringArray(output)).strip_edges()
	else:
		_version_label.text = "Command not found."
	_version_label.modulate.a = 1


func _test_command(output):
	var exit_code = OS.execute(_aseprite_command_field.text, ['--version'], output, true, true)
	return exit_code == 0


func _on_aseprite_command_text_changed(new_text: String) -> void:
	_command_path = new_text


func _on_save_button_up() -> void:
	_config.set_command(_command_path)
	self.hide()


func _on_select_pressed() -> void:
	_create_file_selection()


func _create_file_selection():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.file_selected.connect(_on_file_selected.bind(file_dialog))
	file_dialog.close_requested.connect(file_dialog.queue_free)
	get_parent().add_child(file_dialog)
	file_dialog.popup_centered_ratio()



func _on_file_selected(path: String, file_dialog):
	if OS.get_name() == "macOS" and path.ends_with(".app"):
		path += "/Contents/MacOS/aseprite"
	_command_path = path
	_aseprite_command_field.text = _command_path
	_aseprite_command_field.grab_focus()
	file_dialog.queue_free()


func _on_close_requested() -> void:
	_on_close_button_up()
