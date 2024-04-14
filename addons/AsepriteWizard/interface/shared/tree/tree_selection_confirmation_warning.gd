@tool
extends VBoxContainer

signal warning_confirmed
signal warning_declined

@onready var _warning_message = $MarginContainer/warning_message

func set_message(text: String) -> void:
	_warning_message.text = text


func _on_confirm_button_up():
	warning_confirmed.emit()


func _on_cancel_button_up():
	warning_declined.emit()
