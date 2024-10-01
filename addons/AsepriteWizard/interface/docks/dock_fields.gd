@tool
extends MarginContainer

signal revert_changes_requested
signal field_changed

@onready
var _source_changed_warning_container = $VBoxContainer/source_changed_warning
@onready
var _source_changed_warning_icon = $VBoxContainer/source_changed_warning/MarginContainer/HBoxContainer/Icon

@onready
var _fields_changed_warning_container = $VBoxContainer/fields_changed_warning
@onready
var _fields_changed_warning_icon = $VBoxContainer/fields_changed_warning/MarginContainer/VBoxContainer/HBoxContainer/Icon

var disable_change_notification := false

func _ready():
	var sb = _source_changed_warning_container.get_theme_stylebox("panel")
	var color = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	color.a = 0.2
	sb.bg_color = color

	_source_changed_warning_icon.texture = get_theme_icon("NodeInfo", "EditorIcons")
	_fields_changed_warning_icon.texture = get_theme_icon("NodeInfo", "EditorIcons")
	hide_source_change_warning()
	hide_fields_change_warning()


func show_source_change_warning():
	_source_changed_warning_container.show()


func hide_source_change_warning():
	_source_changed_warning_container.hide()


func show_fields_change_warning():
	_fields_changed_warning_container.show()


func hide_fields_change_warning():
	_fields_changed_warning_container.hide()


func _on_revert_changes_button_up() -> void:
	revert_changes_requested.emit()


func _on_ex_pattern_text_changed(_new_text: String) -> void:
	_notify_change_with_debounce()


func _on_visible_layer_toggled(_toggled_on: bool) -> void:
	_notify_change_with_debounce()


func _on_keep_length_toggled(_toggled_on: bool) -> void:
	_notify_change_with_debounce()


func _on_anim_vis_toggled(_toggled_on: bool) -> void:
	_notify_change_with_debounce()


func _on_line_edit_text_changed(_new_text: String) -> void:
	_notify_change_with_debounce()


func _on_debounce_timer_timeout() -> void:
	if not $DebounceTimer.is_stopped():
		$DebounceTimer.stop()
	$DebounceTimer.start()


func _notify_change_with_debounce():
	if disable_change_notification:
		return

	field_changed.emit()
