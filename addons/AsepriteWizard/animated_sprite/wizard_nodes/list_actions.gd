tool
extends HBoxContainer

signal import_clicked(index)
signal edit_clicked(index)
signal removed_clicked(index)

var history_index = -1


func _on_edit_pressed():
	emit_signal("edit_clicked", history_index)


func _on_reimport_pressed():
	emit_signal("import_clicked", history_index)


func _on_remove_pressed():
	emit_signal("removed_clicked", history_index)
