@tool
extends HBoxContainer

signal add_pressed
signal removed_pressed
signal data_requested
signal value_changed(value: String)

var _value: String = ""
var is_only_field := false

func _ready():
	$add_btn.icon = get_theme_icon("Add", "EditorIcons")
	$remove_btn.icon = get_theme_icon("Remove", "EditorIcons")

func set_add_button(visibility: bool) -> void:
	$add_btn.visible = visibility


func set_remove_button(visibility: bool) -> void:
	$remove_btn.visible = visibility


func _on_remove_btn_pressed() -> void:
	removed_pressed.emit()


func _on_add_btn_pressed() -> void:
	add_pressed.emit()


func _on_options_button_down() -> void:
	data_requested.emit()


func _on_options_item_selected(index: int) -> void:
	if index == 0:
		_value = ""
	else:
		_value = $options.get_item_text(index)

	value_changed.emit(_value)


func populate_field(option_values):
	var current = 0
	$options.clear()
	set_default_item()

	for v in option_values:
		if v == "":
			continue

		$options.add_item(v)
		if v == _value:
			current = $options.get_item_count() - 1
	$options.select(current)


func set_value(new_value: String) -> void:
	_value = new_value
	$options.clear()

	if new_value == "":
		set_default_item()
	else:
		$options.add_item(_value)


func get_value():
	return _value


func clear_options():
	$options.clear()
	set_default_item()
	$options.select(0)


func set_default_item():
	$options.add_item("[all]" if is_only_field else "Select layer...")
