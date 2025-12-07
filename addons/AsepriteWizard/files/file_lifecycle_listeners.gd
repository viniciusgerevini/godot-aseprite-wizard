@tool
extends RefCounted

const result_codes = preload("../config/result_codes.gd")
const logger = preload("../config/logger.gd")
var bakery = preload("../importers/helpers/bakery.gd").new()

const ase_file_extensions = ["aseprite", "ase"]

func setup_listeners() -> void:
	var file_sytem_dock = EditorInterface.get_file_system_dock()
	file_sytem_dock.file_removed.connect(_on_file_removed)
	file_sytem_dock.files_moved.connect(_on_file_moved)


func remove_listeners() -> void:
	var file_sytem_dock = EditorInterface.get_file_system_dock()
	if file_sytem_dock.file_removed.is_connected(_on_file_removed):
		file_sytem_dock.file_removed.disconnect(_on_file_removed)
		file_sytem_dock.files_moved.disconnect(_on_file_moved)


func _on_file_removed(file: String) -> void:
	var ext = file.get_extension()
	
	if not ase_file_extensions.has(ext):
		return
	
	if bakery.has_bake_file(file):
		var result = bakery.delete_bake_file(file)

		if result != OK:
			logger.warn(
				"Failed to delete bake file: " + result_codes.get_error_message(result),
				file
			)


func _on_file_moved(old_file: String, new_file: String) -> void:
	var ext = old_file.get_extension()
	
	if not ase_file_extensions.has(ext):
		return
		
	if bakery.has_bake_file(old_file):
		var result = bakery.move_bake_file(old_file, new_file)
		if result != OK:
			logger.warn(
				"Failed to move bake file: " + result_codes.get_error_message(result),
				old_file
			)
