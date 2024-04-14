@tool
extends VBoxContainer

signal import_triggered

@onready var _import_message = $message
@onready var _import_button = $buttons

func set_selected_count(number_of_items: int) -> void:
	_import_message.text = "%2d items selected" % number_of_items


func show_buttons():
	_import_button.show()


func hide_buttons():
	_import_button.hide()


func _on_import_selected_button_up():
	import_triggered.emit()
