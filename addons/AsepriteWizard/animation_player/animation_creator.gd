extends RefCounted

var result_code = preload("../config/result_codes.gd")
var _aseprite = preload("../aseprite/aseprite.gd").new()

var _config
var _file_system

func init(config, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_aseprite.init(config)


func create_animations(sprite: Sprite2D, player: AnimationPlayer, options: Dictionary):
	if not _aseprite.test_command():
		return result_code.ERR_ASEPRITE_CMD_NOT_FOUND

	var dir = Directory.new()
	if not dir.file_exists(options.source):
		return result_code.ERR_SOURCE_FILE_NOT_FOUND

	if not dir.dir_exists(options.output_folder):
		return result_code.ERR_OUTPUT_FOLDER_NOT_FOUND

	await _create_animations_from_file(sprite, player, options)


func _create_animations_from_file(sprite: Sprite2D, player: AnimationPlayer, options: Dictionary):
	var output

	if options.get("layer", "") == "":
		output = _aseprite.export_file(options.source, options.output_folder, options)
	else:
		output = _aseprite.export_layer(options.source, options.layer, options.output_folder, options)

	if output.is_empty():
		return result_code.ERR_ASEPRITE_EXPORT_FAILED
	await _scan_filesystem()

	var result = _import(sprite, player, output)

	if _config.should_remove_source_files():
		var dir = Directory.new()
		dir.open('res://')
		dir.remove(output.data_file)

	return result


func _import(sprite: Sprite2D, player: AnimationPlayer, data: Dictionary):
	var source_file = data.data_file
	var sprite_sheet = data.sprite_sheet

	var file = File.new()
	var err = file.open(source_file, File.READ)
	if err != OK:
			return err

	var json = JSON.new()
	json.parse(file.get_as_text())
	var content = json.get_data()

	if not _aseprite.is_valid_spritesheet(content):
		return result_code.ERR_INVALID_ASEPRITE_SPRITESHEET

	_load_texture(sprite, sprite_sheet, content)
	var result = _configure_animations(sprite, player, content)
	if result != result_code.SUCCESS:
		return result

	return _cleanup_animations(sprite, player, content)


func _load_texture(sprite: Sprite2D, sprite_sheet: String, content: Dictionary):
	var texture = ResourceLoader.load(sprite_sheet, 'Image', true)
	sprite.texture = texture

	if content.frames.is_empty():
		return

	sprite.hframes = content.meta.size.w / content.frames[0].sourceSize.w
	sprite.vframes = content.meta.size.h / content.frames[0].sourceSize.h


func _configure_animations(sprite: Sprite2D, player: AnimationPlayer, content: Dictionary):
	var frames = _aseprite.get_content_frames(content)
	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		var result = result_code.SUCCESS
		for tag in content.meta.frameTags:
			var selected_frames = frames.slice(tag.from, tag.to + 1)
			result = _add_animation_frames(sprite, player, tag.name, selected_frames, tag.direction)
			if result != result_code.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames(sprite, player, "default", frames)


func _add_animation_frames(sprite: Sprite2D, player: AnimationPlayer, anim_name: String, frames: Array, direction = 'forward'):
	var animation_name = anim_name
	var is_loopable = _config.is_default_animation_loop_enabled()

	if animation_name.begins_with(_config.get_animation_loop_exception_prefix()):
		animation_name = anim_name.substr(_config.get_animation_loop_exception_prefix().length())
		is_loopable = not is_loopable

	if not player.has_animation(animation_name):
		player.add_animation(animation_name, Animation.new())

	var animation = player.get_animation(animation_name)
	var track = _get_frame_track_path(player, sprite)
	var track_index = _create_frame_track(sprite, animation, track)

	if direction == 'reverse':
		frames.reverse()

	var animation_length = 0

	for frame in frames:
		var frame_index = _calculate_frame_index(sprite, frame)
		animation.track_insert_key(track_index, animation_length, frame_index)
		animation_length += frame.duration / 1000

	animation.loop_mode = Animation.LOOP_NONE

	if is_loopable:
		if direction == 'pingpong':
			animation.loop_mode = Animation.LOOP_PINGPONG
		else:
			animation.loop_mode = Animation.LOOP_LINEAR
	elif direction == 'pingpong':
		frames.remove_at(frames.size() - 1)
		if is_loopable:
			frames.remove_at(0)
		frames.reverse()

		for frame in frames:
			var frame_index = _calculate_frame_index(sprite, frame)
			animation.track_insert_key(track_index, animation_length, frame_index)
			animation_length += frame.duration / 1000

	animation.length = animation_length

	return result_code.SUCCESS


func _calculate_frame_index(sprite: Sprite2D, frame: Dictionary) -> int:
	var column = floor(frame.frame.x * sprite.hframes / sprite.texture.get_width())
	var row = floor(frame.frame.y * sprite.vframes / sprite.texture.get_height())
	return (row * sprite.hframes) + column as int


func _create_frame_track(sprite: Sprite2D, animation: Animation, track: String):
	var track_index = animation.find_track(track, Animation.TYPE_VALUE)

	if track_index != -1:
		animation.remove_track(track_index)

	track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, track)
	animation.track_set_interpolation_loop_wrap(track_index, false)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)

	return track_index


func _get_frame_track_path(player: AnimationPlayer, sprite: Sprite2D):
	var node_path = player.get_node(player.root_node).get_path_to(sprite)
	return "%s:frame" % node_path


func _cleanup_animations(sprite: Sprite2D, player: AnimationPlayer, content: Dictionary):
	if not (content.meta.has("frameTags") and content.meta.frameTags.size() > 0):
		return result_code.SUCCESS

	var track = _get_frame_track_path(player, sprite)
	var tags = ["RESET"]
	for t in content.meta.frameTags:
		var a = t.name
		if a.begins_with(_config.get_animation_loop_exception_prefix()):
			a = a.substr(_config.get_animation_loop_exception_prefix().length())
		tags.push_back(a)

	for a in player.get_animation_list():
		if tags.has(a):
			continue

		var animation = player.get_animation(a)

		if animation.get_track_count() != 1:
			var t = animation.find_track(track, Animation.TYPE_VALUE)
			if t != -1:
				animation.remove_track(t)
			continue

		if animation.find_track(track, Animation.TYPE_VALUE) != -1:
			player.remove_animation(a)

	return result_code.SUCCESS

func _scan_filesystem():
	_file_system.scan()
	await _file_system.filesystem_changed


func list_layers(file: String, only_visibles = false) -> Array:
	return _aseprite.list_layers(file, only_visibles)
