@tool
extends "../base_inspector_dock.gd"

var sprite_frames_creator = preload("../../../creators/sprite_frames/sprite_frames_creator.gd").new()


func _get_available_layers(global_source_path: String) -> Array:
	return sprite_frames_creator.list_layers(global_source_path)


func _get_available_slices(global_source_path: String) -> Array:
	return sprite_frames_creator.list_slices(global_source_path)


func _do_import():
	var root = get_tree().get_edited_scene_root()

	var source_path = ProjectSettings.globalize_path(_source)
	var options = _get_import_options(root.scene_file_path.get_base_dir())

	_save_config()

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_file(source_path, options)

	if not aseprite_output.is_ok:
		var error = result_code.get_error_message(aseprite_output.code)
		printerr(error)
		_show_message(error)
		return

	file_system.scan()
	await file_system.filesystem_changed

	sprite_frames_creator.create_animations(target_node, aseprite_output.content, { "slice": _slice })

	wizard_config.set_source_hash(target_node, FileAccess.get_md5(source_path))

	_handle_cleanup(aseprite_output.content)
