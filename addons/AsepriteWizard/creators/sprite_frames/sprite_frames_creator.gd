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

	animated_sprite.frames = sprite_frames_result.content

	if animated_sprite is CanvasItem:
		animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		animated_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST


#func create_and_save_resources(source_files: Array) -> int:
	#var resources = create_resources(source_files)
	#if resources.is_ok:
		#return save_resources(resources.content)
#
	#return resources.code


func create_resources(source_files: Array, options: Dictionary = {}) -> Dictionary:
	var resources = []

	for o in source_files:
		if o.is_empty():
			return result_code.error(result_code.ERR_ASEPRITE_EXPORT_FAILED)

		var resource = _create_sprite_frames(o, options)

		if not resource.is_ok:
			return resource

		resources.push_back({
			"data_file": o.data_file,
			"resource": resource.content,
		})

	return result_code.result(resources)


func _create_sprite_frames(data: Dictionary, options: Dictionary) -> Dictionary:
	var aseprite_resources = _load_aseprite_resources(data)
	if not aseprite_resources.is_ok:
		return aseprite_resources

	return result_code.result(
		_create_sprite_frames_with_animations(
			aseprite_resources.content.metadata,
			aseprite_resources.content.texture,
			options,
		)
	)


func _load_aseprite_resources(aseprite_data: Dictionary):
	var content_result = _aseprite_file_exporter.load_json_content(aseprite_data.data_file)

	if not content_result.is_ok:
		return content_result

	var texture = _load_texture(aseprite_data.sprite_sheet)

	return result_code.result({
		"metadata": content_result.content,
		"texture": texture
	})


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
			_add_animation_frames(sprite_frames, tag.name, selected_frames, texture, frame_rect, tag.direction, int(tag.get("repeat", -1)), frame_cache)
	else:
		_add_animation_frames(sprite_frames, "default", frames, texture, frame_rect)

	return sprite_frames


func _add_animation_frames(
	sprite_frames: SpriteFrames,
	anim_name: String,
	frames: Array,
	texture,
	frame_rect: Variant,
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
	var fps = _calculate_fps(min_duration)

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


func _calculate_fps(min_duration: int) -> float:
	return ceil(1000.0 / min_duration)


func _get_min_duration(frames) -> int:
	var min_duration = 100000
	for frame in frames:
		if frame.duration < min_duration:
			min_duration = frame.duration
	return min_duration


func _load_texture(path) -> CompressedTexture2D:
	return ResourceLoader.load(path, "CompressedTexture2D", ResourceLoader.CACHE_MODE_REPLACE)


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
