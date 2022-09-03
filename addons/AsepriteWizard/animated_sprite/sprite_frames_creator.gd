tool
extends Reference

var result_code = preload("../config/result_codes.gd")
var _aseprite = preload("../aseprite/aseprite.gd").new()

enum {
	FILE_EXPORT_MODE,
	LAYERS_EXPORT_MODE
}

var _config
var _file_system: EditorFileSystem
var _should_check_file_system := false


func init(config, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_should_check_file_system = _file_system != null
	_aseprite.init(config)


func _loop_config_prefix() -> String:
	return _config.get_animation_loop_exception_prefix()


func _is_loop_config_enabled() -> String:
	return _config.is_default_animation_loop_enabled()


func create_animations(sprite: Node, options: Dictionary):
	if not _aseprite.test_command():
		return result_code.ERR_ASEPRITE_CMD_NOT_FOUND

	var dir = Directory.new()
	if not dir.file_exists(options.source):
		return result_code.ERR_SOURCE_FILE_NOT_FOUND

	if not dir.dir_exists(options.output_folder):
		return result_code.ERR_OUTPUT_FOLDER_NOT_FOUND

	var result = _create_animations_from_file(sprite, options)

	if result is GDScriptFunctionState:
		result = yield(result, "completed")

	if result != result_code.SUCCESS:
		printerr(result_code.get_error_message(result))


func _create_animations_from_file(sprite: Node, options: Dictionary):
	var output

	if options.get("layer", "") == "":
		output = _aseprite.export_file(options.source, options.output_folder, options)
	else:
		output = _aseprite.export_layer(options.source, options.layer, options.output_folder, options)

	if output.empty():
		return result_code.ERR_ASEPRITE_EXPORT_FAILED

	if _config.is_import_preset_enabled():
		_config.create_import_file(output)

	yield(_scan_filesystem(), "completed")

	var result = _import(output, sprite)

	if _config.should_remove_source_files():
		var dir = Directory.new()
		dir.remove(output.data_file)
		yield(_scan_filesystem(), "completed")

	return result


func create_resource(source_file: String, output_folder: String, options = {}):
	var export_mode = options.get('export_mode', FILE_EXPORT_MODE)

	if not _aseprite.test_command():
		return result_code.ERR_ASEPRITE_CMD_NOT_FOUND

	var dir = Directory.new()
	if not dir.file_exists(source_file):
		return result_code.ERR_SOURCE_FILE_NOT_FOUND

	if not dir.dir_exists(output_folder):
		return result_code.ERR_OUTPUT_FOLDER_NOT_FOUND

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
			return result_code.ERR_UNKNOWN_EXPORT_MODE


func create_sprite_frames_from_aseprite_file(source_file: String, output_folder: String, options: Dictionary):
	var output = _aseprite.export_file(source_file, output_folder, options)
	if output.empty():
		return result_code.ERR_ASEPRITE_EXPORT_FAILED

	if (_should_check_file_system):
		yield(_scan_filesystem(), "completed")

	if options.get("do_not_create_resource", false):
		return OK

	var result = _import(output)

	if options.get("remove_source_files_allowed", false) and _config.should_remove_source_files():
		var dir = Directory.new()
		dir.remove(output.data_file)
		if (_should_check_file_system):
			yield(_scan_filesystem(), "completed")

	return result


func create_sprite_frames_from_aseprite_layers(source_file: String, output_folder: String, options: Dictionary):
	var output = _aseprite.export_layers(source_file, output_folder, options)
	if output.empty():
		return result_code.ERR_NO_VALID_LAYERS_FOUND

	var result = OK

	if (_should_check_file_system):
		yield(_scan_filesystem(), "completed")

	var should_remove_source = options.get("remove_source_files_allowed", false) and _config.should_remove_source_files()

	for o in output:
		if o.empty():
			result = result_code.ERR_ASEPRITE_EXPORT_FAILED
		else:
			if options.get("do_not_create_resource", false):
				result = OK
			else:
				result = _import(o)
				if should_remove_source:
					var dir = Directory.new()
					dir.remove(o.data_file)

	if should_remove_source and _should_check_file_system:
		yield(_scan_filesystem(), "completed")

	return result


func _get_file_basename(file_path: String) -> String:
	return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())


func _import(data, animated_sprite = null) -> int:
	var source_file = data.data_file
	var sprite_sheet = data.sprite_sheet
	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
			return err
	var content =  parse_json(file.get_as_text())

	if not _aseprite.is_valid_spritesheet(content):
		return result_code.ERR_INVALID_ASEPRITE_SPRITESHEET

	var texture = _parse_texture_path(sprite_sheet)

	var resource = _create_sprite_frames_with_animations(content, texture)

	if is_instance_valid(animated_sprite):
		animated_sprite.frames = resource
		return result_code.SUCCESS

	var save_path = "%s.%s" % [source_file.get_basename(), "res"]
	var code =  ResourceSaver.save(save_path, resource, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	resource.take_over_path(save_path)
	return code


func _create_sprite_frames_with_animations(content, texture) -> SpriteFrames:
	var frame_cache = {}
	var frames = _aseprite.get_content_frames(content)
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		for tag in content.meta.frameTags:
			var selected_frames = frames.slice(tag.from, tag.to)
			_add_animation_frames(sprite_frames, tag.name, selected_frames, texture, tag.direction, frame_cache)
	else:
		_add_animation_frames(sprite_frames, "default", frames, texture)

	return sprite_frames


func _add_animation_frames(
	sprite_frames: SpriteFrames,
	anim_name: String,
	frames : Array,
	texture,
	direction = 'forward',
	frame_cache = {}
):

	var animation_name := anim_name
	var is_loopable = _is_loop_config_enabled()

	var loop_prefix := _loop_config_prefix()
	if animation_name.begins_with(loop_prefix):
		animation_name = anim_name.trim_prefix(loop_prefix)
		is_loopable = not is_loopable

	sprite_frames.add_animation(animation_name)

	var min_duration = _get_min_duration(frames)
	var fps = _calculate_fps(min_duration)

	if direction == 'reverse':
		frames.invert()

	for frame in frames:
		_add_to_sprite_frames(sprite_frames, animation_name, texture, frame, min_duration, frame_cache)

	if direction == 'pingpong':
		frames.remove(frames.size() - 1)
		if is_loopable:
			frames.remove(0)
		frames.invert()

		for frame in frames:
			_add_to_sprite_frames(sprite_frames, animation_name, texture, frame, min_duration, frame_cache)

	sprite_frames.set_animation_loop(animation_name, is_loopable)
	sprite_frames.set_animation_speed(animation_name, fps)


func _calculate_fps(min_duration: int) -> float:
	return ceil(1000.0 / min_duration)


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


func _add_to_sprite_frames(
	sprite_frames,
	animation_name: String,
	texture,
	frame: Dictionary,
	min_duration: int,
	frame_cache: Dictionary
):
	var atlas : AtlasTexture = _create_atlastexture_from_frame(texture, frame, sprite_frames, frame_cache)

	var number_of_sprites = ceil(frame.duration / min_duration)
	for _i in range(number_of_sprites):
		sprite_frames.add_frame(animation_name, atlas)


func _create_atlastexture_from_frame(
	image,
	frame_data,
	sprite_frames: SpriteFrames,
	frame_cache: Dictionary
) -> AtlasTexture:
	var frame = frame_data.frame
	var region := Rect2(frame.x, frame.y, frame.w, frame.h)
	var key := "%s_%s_%s_%s" % [frame.x, frame.y, frame.w, frame.h]

	var texture = frame_cache.get(key)

	if texture != null and texture.atlas == image:
		return texture

	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = image
	atlas_texture.region = region

	frame_cache[key] = atlas_texture

	return atlas_texture


func _scan_filesystem():
	_file_system.scan()
	yield(_file_system, "filesystem_changed")


func list_layers(file: String, only_visibles = false) -> Array:
	return _aseprite.list_layers(file, only_visibles)
