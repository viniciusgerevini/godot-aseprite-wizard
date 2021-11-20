tool
extends Node

enum {
	FILE_EXPORT_MODE,
	LAYERS_EXPORT_MODE
}

enum {
	SUCCESS,
	ERR_ASEPRITE_CMD_NOT_FOUND,
	ERR_SOURCE_FILE_NOT_FOUND,
	ERR_OUTPUT_FOLDER_NOT_FOUND,
	ERR_ASEPRITE_EXPORT_FAILED,
	ERR_UNKNOWN_EXPORT_MODE,
	ERR_NO_VALID_LAYERS_FOUND,
	ERR_INVALID_ASEPRITE_SPRITESHEET
}

var default_command = 'aseprite'
var config: ConfigFile
var file_system: EditorFileSystem

var _should_check_file_system = false

func init(config_file: ConfigFile, default_cmd: String, editor_file_system: EditorFileSystem = null):
	config = config_file
	default_command = default_cmd
	file_system = editor_file_system
	_should_check_file_system = file_system != null


func _aseprite_command() -> String:
	var command
	if config.has_section_key('aseprite', 'command'):
		command = config.get_value('aseprite', 'command')

	if not command or command == "":
		return default_command
	return command


func _loop_config_prefix() -> String:
	return config.get_value('aseprite', 'loop_config_prefix', '_')


func _is_loop_config_enabled() -> String:
	return config.get_value('aseprite', 'loop_enabled', true)


func _aseprite_list_layers(file_name: String, only_visible = false) -> Array:
	var output = []
	var arguments = ["-b", "--list-layers", file_name]

	if not only_visible:
		arguments.push_front("--all-layers")

	var exit_code = OS.execute(_aseprite_command(), arguments, true, output, true)

	if exit_code != 0:
		print('aseprite: failed listing layers')
		print(output)
		return []

	if output.empty():
		return output

	return output[0].split('\n')


func _aseprite_export_spritesheet(file_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var exception_pattern = options.get('exception_pattern', "")
	var only_visible_layers = options.get('only_visible_layers', false)
	var output_name = file_name if options.get('output_filename') == "" else options.get('output_filename')
	var basename = _get_file_basename(output_name)
	var output_dir = output_folder.replace("res://", "./")
	var data_file = "%s/%s.json" % [output_dir, basename]
	var sprite_sheet = "%s/%s.png" % [output_dir, basename]
	var output = []

	var arguments = [
		"-b",
		"--list-tags",
		"--data",
		data_file,
		"--format",
		"json-array",
		"--sheet",
		sprite_sheet,
		file_name
	]

	if not only_visible_layers:
		arguments.push_front("--all-layers")

	if options.get('trim_images', false):
		arguments.push_front("--trim")

	if options.get('trim_by_grid', false):
		arguments.push_front('--trim-by-grid')

	if exception_pattern != "":
		_add_ignore_layer_arguments(file_name, arguments, exception_pattern)

	var exit_code = OS.execute(_aseprite_command(), arguments, true, output, true)

	if exit_code != 0:
		print('aseprite: failed to export spritesheet')
		print(output)
		return {}
	return {
		'data_file': data_file.replace("./", "res://"),
		"sprite_sheet": sprite_sheet.replace("./", "res://")
	}


func _aseprite_export_layers_spritesheet(file_name: String, output_folder: String, options: Dictionary) -> Array:
	var exception_pattern = options.get('exception_pattern', "")
	var only_visible_layers = options.get('only_visible_layers', false)
	var basename = _get_file_basename(file_name)
	var output_dir = output_folder.replace("res://", "./")

	var layers = _aseprite_list_layers(file_name, only_visible_layers)

	var exception_regex

	if exception_pattern != "":
		exception_regex = RegEx.new()
		if exception_regex.compile(exception_pattern) != OK:
			print('exception regex error')
			exception_regex = null

	var output = []

	for layer in layers:
		if layer != "" and (not exception_regex or exception_regex.search(layer) == null):
			output.push_back(_aseprite_export_layer(file_name, layer, output_dir, options))

	return output


func _aseprite_export_layer(file_name: String, layer_name: String, output_folder: String, options: Dictionary) -> Dictionary:
	var output_prefix = options.get('output_filename', "")
	var data_file = "%s/%s%s.json" % [output_folder, output_prefix, layer_name]
	var sprite_sheet = "%s/%s%s.png" % [output_folder, output_prefix, layer_name]
	var output = []

	var arguments = [
		"-b",
		"--list-tags",
		"--layer",
		layer_name,
		"--data",
		data_file,
		"--format",
		"json-array",
		"--sheet",
		sprite_sheet,
		file_name
	]

	if options.get('trim_images', false):
		arguments.push_front("--trim")

	if options.get('trim_by_grid', false):
		arguments.push_front('--trim-by-grid')

	var exit_code = OS.execute(_aseprite_command(), arguments, true, output, true)

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
	if not layers.empty():
		for l in layers:
			arguments.push_front(l)
			arguments.push_front('--ignore-layer')


func _get_exception_layers(file_name: String, exception_pattern: String) -> Array:
	var layers = _aseprite_list_layers(file_name)
	var regex = RegEx.new()
	if regex.compile(exception_pattern) != OK:
		print('exception regex error')
		return []

	var exception_layers = []
	for layer in layers:
		if regex.search(layer) != null:
			exception_layers.push_back(layer)
	print('Layers ignored:')
	print(exception_layers)
	return exception_layers


func create_resource(source_file: String, output_folder: String, options = {}):

	if not _is_aseprite_command_valid():
		return ERR_ASEPRITE_CMD_NOT_FOUND

	var export_mode = options.get('export_mode', FILE_EXPORT_MODE)

	var dir = Directory.new()
	if not dir.file_exists(source_file):
		return ERR_SOURCE_FILE_NOT_FOUND

	if not dir.dir_exists(output_folder):
		return ERR_OUTPUT_FOLDER_NOT_FOUND

	match export_mode:
		FILE_EXPORT_MODE:
			if _should_check_file_system:
				return yield(create_sprite_frames_from_aseprite_file(source_file, output_folder, options), "completed")
			return create_sprite_frames_from_aseprite_file(source_file, output_folder, options)
		LAYERS_EXPORT_MODE:
			if _should_check_file_system:
				return yield(create_sprite_frames_from_aseprite_layers(source_file, output_folder, options), "completed")
			return create_sprite_frames_from_aseprite_layers(source_file, output_folder, options)
		_:
			return ERR_UNKNOWN_EXPORT_MODE


func create_sprite_frames_from_aseprite_file(source_file: String, output_folder: String, options: Dictionary):
	var output = _aseprite_export_spritesheet(source_file, output_folder, options)
	if output.empty():
		return ERR_ASEPRITE_EXPORT_FAILED

	if (_should_check_file_system):
		yield(_scan_filesystem(), "completed")

	if options.get("do_not_create_resource", false):
		return OK

	var result = _import(output)

	if options.get("remove_source_files_allowed", false) and config.get_value('aseprite', 'remove_source_files', false):
		var dir = Directory.new()
		dir.remove(output.data_file)
		dir.remove(output.sprite_sheet)
		if (_should_check_file_system):
			yield(_scan_filesystem(), "completed")

	return result


func create_sprite_frames_from_aseprite_layers(source_file: String, output_folder: String, options: Dictionary):
	var output = _aseprite_export_layers_spritesheet(source_file, output_folder, options)
	if output.empty():
		return ERR_NO_VALID_LAYERS_FOUND

	var result = OK

	if (_should_check_file_system):
		yield(_scan_filesystem(), "completed")

	var should_remove_source = options.get("remove_source_files_allowed", false) and config.get_value('aseprite', 'remove_source_files', false)

	for o in output:
		if o.empty():
			result = ERR_ASEPRITE_EXPORT_FAILED
		else:
			if options.get("do_not_create_resource", false):
				result = OK
			else:
				result = _import(o)
				if should_remove_source:
					var dir = Directory.new()
					dir.remove(o.data_file)
					dir.remove(o.sprite_sheet)

	if should_remove_source and _should_check_file_system:
		yield(_scan_filesystem(), "completed")

	return result


func _get_file_basename(file_path: String) -> String:
	return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())


func _import(data) -> int:
	var source_file = data.data_file
	var sprite_sheet = data.sprite_sheet
	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
			return err
	var content =  parse_json(file.get_as_text())

	if not _is_valid_aseprite_spritesheet(content):
		return ERR_INVALID_ASEPRITE_SPRITESHEET

	var texture = _parse_texture_path(sprite_sheet)

	var resource = _create_sprite_frames_with_animations(content, texture)

	var save_path = "%s.%s" % [source_file.get_basename(), "res"]
	var code =  ResourceSaver.save(save_path, resource, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	resource.take_over_path(save_path)
	return code


func _create_sprite_frames_with_animations(content, texture):
	var frames = _get_frames_from_content(content)
	var sprite_frames = SpriteFrames.new()
	sprite_frames.remove_animation("default")

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		for tag in content.meta.frameTags:
			var selected_frames = frames.slice(tag.from, tag.to)
			_add_animation_frames(sprite_frames, tag.name, selected_frames, texture, tag.direction)
	else:
		_add_animation_frames(sprite_frames, "default", frames, texture)

	return sprite_frames


func _get_frames_from_content(content):
	return content.frames if typeof(content.frames) == TYPE_ARRAY  else content.frames.values()


func _add_animation_frames(sprite_frames, anim_name, frames, texture, direction = 'forward'):
	var animation_name = anim_name
	var is_loopable = _is_loop_config_enabled()

	if animation_name.begins_with(_loop_config_prefix()):
		animation_name = anim_name.substr(_loop_config_prefix().length())
		is_loopable = not is_loopable

	sprite_frames.add_animation(animation_name)

	var min_duration = _get_min_duration(frames)
	var fps = _calculate_fps(min_duration)

	if direction == 'reverse':
		frames.invert()

	for frame in frames:
		var atlas = _create_atlastexture_from_frame(texture, frame)
		var number_of_sprites = ceil(frame.duration / min_duration)
		for _i in range(number_of_sprites):
			sprite_frames.add_frame(animation_name, atlas)

	if direction == 'pingpong':
		frames.remove(frames.size() - 1)
		frames.remove(0)
		frames.invert()

		for frame in frames:
			var atlas = _create_atlastexture_from_frame(texture, frame)
			var number_of_sprites = ceil(frame.duration / min_duration)
			for _i in range(number_of_sprites):
				sprite_frames.add_frame(animation_name, atlas)

	sprite_frames.set_animation_loop(animation_name, is_loopable)
	sprite_frames.set_animation_speed(animation_name, fps)

func _calculate_fps(min_duration: int) -> float:
	return ceil(1000 / min_duration)

func _get_min_duration(frames) -> int:
	var min_duration = 100000
	for frame in frames:
		if frame.duration < min_duration:
			min_duration = frame.duration
	return min_duration

func _parse_texture_path(path):
	if not _should_check_file_system and not ResourceLoader.has_cached(path):
		# this is a fallback for the importer. It generates the spritesheet file when it hasn't
		# been imported before. Files generated in this method are usually
		# bigger in size than the ones imported by Godot's default importer.
		var image = Image.new()
		image.load(path)
		var texture = ImageTexture.new()
		texture.create_from_image(image, 0)
		return texture

	return ResourceLoader.load(path, 'Image', true)


func _is_valid_aseprite_spritesheet(content):
	return content.has("frames") and content.has("meta") and content.meta.has('image')


func _create_atlastexture_from_frame(image, frame_data):
	var atlas = AtlasTexture.new()
	var frame = frame_data.frame
	atlas.atlas = image
	atlas.region = Rect2(frame.x, frame.y, frame.w, frame.h)
	return atlas


func _is_aseprite_command_valid():
	var exit_code = OS.execute(_aseprite_command(), ['--version'], true)
	return exit_code == 0


func _scan_filesystem():
	file_system.scan()
	yield(file_system, "filesystem_changed")
