@tool
extends RefCounted

var _config

func init(config):
	_config = config

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
	var basename = _get_file_basename(output_name)
	var output_dir = output_folder.replace("res://", "./")
	var data_file = "%s/%s.json" % [output_dir, basename]
	var sprite_sheet = "%s/%s.png" % [output_dir, basename]
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)

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
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
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
			output.push_back(export_layer(file_name, layer, output_folder, options))

	return output


func export_layer(file_name: String, layer_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var output_prefix = options.get('output_filename', "").strip_edges()
	var output_dir = output_folder.replace("res://", "./").strip_edges()
	var data_file = "%s/%s%s.json" % [output_dir, output_prefix, layer_name]
	var sprite_sheet = "%s/%s%s.png" % [output_dir, output_prefix, layer_name]
	var output = []
	var arguments = _export_command_common_arguments(file_name, data_file, sprite_sheet)
	arguments.push_front(layer_name)
	arguments.push_front("--layer")
	
	_add_sheet_type_arguments(arguments, options)

	var exit_code = _execute(arguments, output)
	if exit_code != 0:
		print('aseprite: failed to export layer spritesheet')
		print(output)
		return {}

	return {
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
	}


func _add_ignore_layer_arguments(file_name: String, arguments: Array, exception_pattern: String):
	var layers = _get_exception_layers(file_name, exception_pattern)
	if not layers.is_empty():
		for l in layers:
			arguments.push_front(l)
			arguments.push_front('--ignore-layer')

func _add_sheet_type_arguments(arguments: Array, options : Dictionary):
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


func _export_command_common_arguments(source_name: String, data_path: String, spritesheet_path: String) -> Array:
	return [
		"-b",
		"--list-tags",
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
