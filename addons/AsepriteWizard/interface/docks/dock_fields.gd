@tool
extends MarginContainer


@onready
var _source_changed_warning_container = $VBoxContainer/source_changed_warning
@onready
var _source_changed_warning_icon = $VBoxContainer/source_changed_warning/MarginContainer/HBoxContainer/Icon


func _ready():
	var sb = _source_changed_warning_container.get_theme_stylebox("panel")
	var color = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	color.a = 0.2
	sb.bg_color = color

	_source_changed_warning_icon.texture = get_theme_icon("NodeInfo", "EditorIcons")
	hide_source_change_warning()


func show_source_change_warning():
	_source_changed_warning_container.show()


func hide_source_change_warning():
	_source_changed_warning_container.hide()
