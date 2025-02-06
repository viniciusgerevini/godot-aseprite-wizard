@tool
extends "../base_sprite_resource_creator.gd"

enum {
	FILE_EXPORT_MODE,
	LAYERS_EXPORT_MODE
}

###
### Create SpriteFrames from aseprite files and insert
### them to the animated_sprite node
###
func create_animations(animated_sprite: Node, aseprite_files: Dictionary, options: Dictionary) -> void:
	var sprite_frames_result = _create_sprite_frames(aseprite_files, options)
	if not sprite_frames_result.is_ok:
		printerr(result_code.get_error_message(sprite_frames_result.code))
		return

	animated_sprite.frames = sprite_frames_result.content.resource

	if animated_sprite is CanvasItem:
		animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		animated_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST


func create_resources(source_files: Array, options: Dictionary = {}) -> Dictionary:
	var resources = []

	for o in source_files:
		if o.is_empty():
			return result_code.error(result_code.ERR_ASEPRITE_EXPORT_FAILED)

		var result = _create_sprite_frames(o, options)

		if not result.is_ok:
			return result

		resources.push_back({
			"data_file": o.data_file,
			"resource": result.content.resource,
			"extra_gen_files": result.content.extra_gen_files
		})

	return result_code.result(resources)


func _create_sprite_frames(data: Dictionary, options: Dictionary) -> Dictionary:
	var aseprite_resources = _load_aseprite_resources(data, options)
	if not aseprite_resources.is_ok:
		return aseprite_resources

	var resource = _create_sprite_frames_with_animations(
		aseprite_resources.content.metadata,
		aseprite_resources.content.texture,
		options,
	)

	return result_code.result({
		"resource": resource,
		"extra_gen_files": aseprite_resources.content.extra_gen_files
	})

func _load_aseprite_resources(aseprite_data: Dictionary, options: Dictionary) -> Dictionary:
	var content_result = _aseprite_file_exporter.load_json_content(aseprite_data.data_file)

	if not content_result.is_ok:
		return content_result

	var result = _load_or_create_texture_resource(aseprite_data.sprite_sheet, options)

	return result_code.result({
		"metadata": content_result.content,
		"texture": result.texture,
		"extra_gen_files": result.extra_gen_files
	})


func _load_or_create_texture_resource(sprite_sheet: String, options: Dictionary) -> Dictionary:
	if not options.get("should_create_portable_texture", false):
		return { "texture": _load_texture(sprite_sheet), "extra_gen_files": [] }

	if options.get("sheet_base_path", "") == "":
		return {
			"texture": create_packed_texture(sprite_sheet),
			"extra_gen_files": []
		}

	var texture_path = "%s.%s.texture.res" % [options.sheet_base_path, sprite_sheet.get_file().get_basename() ]

	return {
		"texture": create_packed_texture(sprite_sheet, texture_path),
		"extra_gen_files": [texture_path]
	}


func save_resources(resources: Array) -> int:
	for resource in resources:
		var code = _save_resource(resource.resource, resource.data_file)
		if code != OK:
			return code
	return OK


func _save_resource(resource, source_path: String) -> int:
	var save_path = "%s.%s" % [source_path.get_basename(), "res"]
	var code = ResourceSaver.save(resource, save_path, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	resource.take_over_path(save_path)
	return code


func _create_sprite_frames_with_animations(content: Dictionary, texture, options: Dictionary) -> SpriteFrames:
	var frame_cache = {}
	var frames = _aseprite.get_content_frames(content)
	var sprite_frames := SpriteFrames.new()
	sprite_frames.remove_animation("default")

	var frame_rect: Variant = null

	# currently, aseprite does not work with the --slice option, so we need to manually
	# do it. https://github.com/aseprite/aseprite/issues/2469
	if options.get("slice", "") != "":
		frame_rect = _aseprite.get_slice_rect(content, options.slice)

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		for tag in content.meta.frameTags:
			var selected_frames = frames.slice(tag.from, tag.to + 1)
			_add_animation_frames(
				sprite_frames,
				tag.name,
				selected_frames,
				texture,
				frame_rect,
				{ "should_round_fps": options.get("should_round_fps", true) },
				tag.direction,
				int(tag.get("repeat", -1)),
				frame_cache
			)
	else:
		_add_animation_frames(sprite_frames, "default", frames, texture, frame_rect, { "should_round_fps": options.get("should_round_fps", true) })

	return sprite_frames


func _add_animation_frames(
	sprite_frames: SpriteFrames,
	anim_name: String,
	frames: Array,
	texture,
	frame_rect: Variant,
	options: Dictionary,
	direction = 'forward',
	repeat = -1,
	frame_cache = {}
):
	var animation_name := anim_name
	var is_loopable = _config.is_default_animation_loop_enabled()

	var loop_prefix = _config.get_animation_loop_exception_prefix()
	if animation_name.begins_with(loop_prefix):
		animation_name = anim_name.trim_prefix(loop_prefix)
		is_loopable = not is_loopable

	sprite_frames.add_animation(animation_name)

	var min_duration = _get_min_duration(frames)
	var fps = _calculate_fps(min_duration, options.should_round_fps)

	if direction == "reverse" or direction == "pingpong_reverse":
		frames.reverse()

	var repetition = 1

	if repeat != -1:
		is_loopable = false
		repetition = repeat

	for i in range(repetition):
		for frame in frames:
			_add_to_sprite_frames(sprite_frames, animation_name, texture, frame, min_duration, frame_cache, frame_rect)

		if direction.begins_with("pingpong"):
			var working_frames = frames.duplicate()
			working_frames.remove_at(working_frames.size() - 1)
			if is_loopable or (repetition > 1 and i < repetition - 1):
				working_frames.remove_at(0)
			working_frames.reverse()

			for frame in working_frames:
				_add_to_sprite_frames(sprite_frames, animation_name, texture, frame, min_duration, frame_cache, frame_rect)

	sprite_frames.set_animation_loop(animation_name, is_loopable)
	sprite_frames.set_animation_speed(animation_name, fps)


func _calculate_fps(min_duration: int, should_round: bool) -> float:
	if should_round:
		return ceil(1000.0 / min_duration)
	return 1000.0 / min_duration


func _get_min_duration(frames) -> int:
	var min_duration = 100000
	for frame in frames:
		if frame.duration < min_duration:
			min_duration = frame.duration
	return min_duration


func _load_texture(path) -> CompressedTexture2D:
	ResourceLoader.load_threaded_request(path, "CompressedTexture2D", false, ResourceLoader.CACHE_MODE_REPLACE)
	return ResourceLoader.load_threaded_get(path)


func create_packed_texture(sprite_sheet: String, save_path: String = "") -> PortableCompressedTexture2D:
	var tex := _load_compressed_texture(sprite_sheet)
	# if no path was provided, we just want the texture in memory
	if save_path == "":
		return tex

	var exit_code = ResourceSaver.save(tex, save_path)
	if exit_code != OK:
		printerr(result_code.get_error_message(result_code.ERR_ASEPRITE_EXPORT_FAILED))
		return null

	return ResourceLoader.load(save_path)


func _add_to_sprite_frames(
	sprite_frames,
	animation_name: String,
	texture,
	frame: Dictionary,
	min_duration: int,
	frame_cache: Dictionary,
	frame_rect: Variant,
):
	var atlas : AtlasTexture = _create_atlastexture_from_frame(texture, frame, sprite_frames, frame_cache, frame_rect)
	var duration = frame.duration / min_duration
	sprite_frames.add_frame(animation_name, atlas, duration)


func _create_atlastexture_from_frame(
	image,
	frame_data,
	sprite_frames: SpriteFrames,
	frame_cache: Dictionary,
	frame_rect: Variant,
) -> AtlasTexture:
	var frame = frame_data.frame
	var region := Rect2(frame.x, frame.y, frame.w, frame.h)

	# this is to manually set the slice
	if frame_rect != null:
		region.position.x += frame_rect.position.x
		region.position.y += frame_rect.position.y
		region.size.x = frame_rect.size.x
		region.size.y = frame_rect.size.y

	var key := "%s_%s_%s_%s" % [frame.x, frame.y, frame.w, frame.h]
	var texture = frame_cache.get(key)

	if texture != null and texture.atlas == image:
		return texture

	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = image
	atlas_texture.region = region

	frame_cache[key] = atlas_texture

	return atlas_texture


func list_layers(file: String, only_visibles = false) -> Array:
	return _aseprite.list_layers(file, only_visibles)


func list_slices(file: String) -> Array:
	return _aseprite.list_slices(file)


func _get_file_basename(file_path: String) -> String:
	return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())
