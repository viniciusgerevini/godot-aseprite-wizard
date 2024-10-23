@tool
extends RefCounted

var _config = preload("../config/config.gd").new()

#
# Output:
# {
#   "data_file": file path to the json file
#   "sprite_sheet": file path to the raw image file
# }
func export_file(file_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var exception_pattern = options.get('exception_pattern', "")
	var only_visible_layers = options.get('only_visible_layers', false)
	var output_name = file_name if options.get('output_filename') == "" else options.get('output_filename', file_name)
	var first_frame_only = options.get("first_frame_only", false)
	var basename = _get_file_basename(output_name)
	var output_dir = ProjectSettings.globalize_path(output_folder)
	var data_file = "%s/%s.json" % [output_dir, basename]
	var sprite_sheet = "%s/%s.png" % [output_dir, basename]
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)

	if not only_visible_layers:
		arguments.push_front("--all-layers")

	if first_frame_only:
		arguments.push_front("'[0, 0]'")
		arguments.push_front("--frame-range")

	_add_sheet_type_arguments(arguments, options)

	_add_ignore_layer_arguments(file_name, arguments, exception_pattern)

	var local_sprite_sheet_path = ProjectSettings.localize_path(sprite_sheet)
	var is_new = not ResourceLoader.exists(local_sprite_sheet_path)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		printerr('aseprite: failed to export spritesheet')
		printerr(output)
		return {}

	return {
		"data_file": ProjectSettings.localize_path(data_file),
		"sprite_sheet": local_sprite_sheet_path,
		"is_first_import": is_new,
	}


func export_layers(file_name: String, output_folder: String, options: Dictionary) -> Array:
	var exception_pattern = options.get('exception_pattern', "")
	var only_visible_layers = options.get('only_visible_layers', false)
	var basename = _get_file_basename(file_name)
	var layers = list_layers(file_name, only_visible_layers)
	var exception_regex = _compile_regex(exception_pattern)

	var output = []

	for layer in layers:
		if layer != "" and (not exception_regex or exception_regex.search(layer) == null):
			output.push_back(export_file_with_layers(file_name, [layer], output_folder, options))

	return output


func export_file_with_layers(file_name: String, layer_names: Array, output_folder: String, options: Dictionary) -> Dictionary:
	var output_prefix = options.get('output_filename', "").strip_edges()
	var output_dir = output_folder.replace("res://", "./").strip_edges()
	var base_output_path = "%s/%s%s" % [output_dir, output_prefix, layer_names[0] if layer_names.size() == 1 else ""]
	var data_file = "%s.json" % base_output_path
	var sprite_sheet = "%s.png" % base_output_path
	var first_frame_only = options.get("first_frame_only", false)
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)

	for layer_name in layer_names:
		arguments.push_front(layer_name)
		arguments.push_front("--layer")

	if first_frame_only:
		arguments.push_front("'[0, 0]'")
		arguments.push_front("--frame-range")

	_add_sheet_type_arguments(arguments, options)

	var local_sprite_sheet_path = ProjectSettings.localize_path(sprite_sheet)
	var is_new = not ResourceLoader.exists(local_sprite_sheet_path)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		print('aseprite: failed to export layer spritesheet')
		print(output)
		return {}

	return {
		"data_file": ProjectSettings.localize_path(data_file),
		"sprite_sheet": local_sprite_sheet_path,
		"is_first_import": is_new,
	}


func _add_ignore_layer_arguments(file_name: String, arguments: Array, exception_pattern: String):
	var layers = _get_exception_layers(file_name, exception_pattern)
	if not layers.is_empty():
		for l in layers:
			arguments.push_front(l)
			arguments.push_front('--ignore-layer')


func _add_sheet_type_arguments(arguments: Array, options : Dictionary):
	if options.has("column_count"):
		_old_sheet_type_config(arguments, options)
		return

	var sheet_type = options.get("sheet_type", "packed")
	var item_count = options.get("sheet_columns", 0)

	if (sheet_type == "columns" or sheet_type == "rows") and item_count == 0:
		sheet_type = "packed"
	elif options.get("sheet_merge_duplicates", true):
		arguments.push_back("--merge-duplicates")

	if sheet_type == "columns":
		arguments.push_back("--sheet-columns")
		arguments.push_back(item_count)
	else:
		arguments.push_back("--sheet-type")
		arguments.push_back(sheet_type)


func _old_sheet_type_config(arguments: Array, options : Dictionary):
	var column_count : int = options.get("column_count", 0)
	if column_count > 0:
		arguments.push_back("--merge-duplicates") # Yes, this is undocumented
		arguments.push_back("--sheet-columns")
		arguments.push_back(column_count)
	else:
		arguments.push_back("--sheet-pack")


func _get_exception_layers(file_name: String, exception_pattern: String) -> Array:
	var layers = list_layers(file_name)
	var regex = _compile_regex(exception_pattern)
	if regex == null:
		return []

	var exception_layers = []
	for layer in layers:
		if regex.search(layer) != null:
			exception_layers.push_back(layer)

	return exception_layers


func list_layers(file_name: String, only_visible = false) -> Array:
	var output = []
	var arguments = ["-b", "--list-layers", file_name]

	if not only_visible:
		arguments.push_front("--all-layers")

	var exit_code = _execute(arguments, output)

	if exit_code != 0:
		printerr('aseprite: failed listing layers')
		printerr(output)
		return []

	if output.is_empty():
		return output

	var raw = output[0].split('\n')
	var sanitized = []
	for s in raw:
		sanitized.append(s.strip_edges())
	return sanitized


func list_slices(file_name: String) -> Array:
	var output = []
	var arguments = ["-b", "--list-slices", file_name]

	var exit_code = _execute(arguments, output)

	if exit_code != 0:
		printerr('aseprite: failed listing slices')
		printerr(output)
		return []

	if output.is_empty():
		return output

	var raw = output[0].split('\n')
	var sanitized = []
	for s in raw:
		sanitized.append(s.strip_edges())
	return sanitized


func _export_command_common_arguments(source_name: String, data_path: String, spritesheet_path: String) -> Array:
	return [
		"-b",
		"--list-tags",
		"--list-slices",
		"--data",
		data_path,
		"--format",
		"json-array",
		"--sheet",
		spritesheet_path,
		source_name
	]


func _execute(arguments, output):
	return OS.execute(_aseprite_command(), arguments, output, true, true)


func _aseprite_command() -> String:
	return _config.is_command_or_control_pressed()


func _get_file_basename(file_path: String) -> String:
	return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())


func _compile_regex(pattern):
	if pattern == "":
		return

	var rgx = RegEx.new()
	if rgx.compile(pattern) == OK:
		return rgx

	printerr('exception regex error')


func test_command():
	var exit_code = OS.execute(_aseprite_command(), ['--version'], [], true)
	return exit_code == 0


func is_valid_spritesheet(content):
	return content.has("frames") and content.has("meta") and content.meta.has('image')


func get_content_frames(content):
	return content.frames if typeof(content.frames) == TYPE_ARRAY  else content.frames.values()


func get_slice_rect(content: Dictionary, slice_name: String) -> Variant:
	if not content.has("meta") or not content.meta.has("slices"):
		return null
	for slice in content.meta.slices:
		if slice.name == slice_name:
			if slice.keys.size() > 0:
				var p = slice.keys[0].bounds
				return Rect2(p.x, p.y, p.w, p.h)
	return null


##
## Exports tileset layers
##
## Return (dictionary):
##      data_file: path to aseprite generated JSON file
##      sprite_sheet: localized path to spritesheet file
func export_tileset_texture(file_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var exception_pattern = options.get('exception_pattern', "")
	var only_visible_layers = options.get('only_visible_layers', false)
	var output_name = file_name if options.get('output_filename') == "" else options.get('output_filename', file_name)
	var basename = _get_file_basename(output_name)
	var output_dir = ProjectSettings.globalize_path(output_folder)
	var data_path = "%s/%s.json" % [output_dir, basename]
	var sprite_sheet = "%s/%s.png" % [output_dir, basename]
	var output = []

	var arguments = [
		"-b",
		"--export-tileset",
		"--data",
		data_path,
		"--format",
		"json-array",
		"--sheet",
		sprite_sheet,
		file_name
	]

	if not only_visible_layers:
		arguments.push_front("--all-layers")

	_add_sheet_type_arguments(arguments, options)

	_add_ignore_layer_arguments(file_name, arguments, exception_pattern)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		printerr('aseprite: failed to export spritesheet')
		printerr(output)
		return {}

	return {
		"data_file": ProjectSettings.localize_path(data_path),
		"sprite_sheet": ProjectSettings.localize_path(sprite_sheet)
	}
