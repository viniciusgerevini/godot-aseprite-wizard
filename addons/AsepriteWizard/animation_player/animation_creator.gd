extends RefCounted

var result_code = preload("../config/result_codes.gd")
var _aseprite = preload("../aseprite/aseprite.gd").new()

var _config
var _file_system

var _DEFAULT_ANIMATION_LIBRARY = "" # GLOBAL


func init(config, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_aseprite.init(config)


func create_animations(target_node: Node, player: AnimationPlayer, options: Dictionary):
	if not _aseprite.test_command():
		return result_code.ERR_ASEPRITE_CMD_NOT_FOUND

	if not FileAccess.file_exists(options.source):
		return result_code.ERR_SOURCE_FILE_NOT_FOUND

	if not DirAccess.dir_exists_absolute(options.output_folder):
		return result_code.ERR_OUTPUT_FOLDER_NOT_FOUND

	var result = await _create_animations_from_file(target_node, player, options)

	if result != result_code.SUCCESS:
		printerr(result_code.get_error_message(result))


func _create_animations_from_file(target_node: Node, player: AnimationPlayer, options: Dictionary):
	var output

	if options.get("layer", "") == "":
		output = _aseprite.export_file(options.source, options.output_folder, options)
	else:
		output = _aseprite.export_layer(options.source, options.layer, options.output_folder, options)

	if output.is_empty():
		return result_code.ERR_ASEPRITE_EXPORT_FAILED

	if _config.is_import_preset_enabled():
		_config.create_import_file(output)

	await _scan_filesystem()

	var result = _import(target_node, player, output, options)

	if _config.should_remove_source_files():
		DirAccess.remove_absolute(output.data_file)

	return result


func _import(target_node: Node, player: AnimationPlayer, data: Dictionary, options: Dictionary):
	var source_file = data.data_file
	var sprite_sheet = data.sprite_sheet

	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return file.get_open_error()

	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var content =  test_json_conv.get_data()
	
	if not _aseprite.is_valid_spritesheet(content):
		return result_code.ERR_INVALID_ASEPRITE_SPRITESHEET
	
	var context = {}

	target_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_setup_texture(target_node, sprite_sheet, content, context)
	var result = _configure_animations(target_node, player, content, context)
	if result != result_code.SUCCESS:
		return result

	return _cleanup_animations(target_node, player, content, options)
	

func _load_texture(sprite_sheet: String) -> Texture2D:
	var texture = ResourceLoader.load(sprite_sheet, 'Image', true)
	texture.take_over_path(sprite_sheet)
	return texture


func _configure_animations(target_node: Node, player: AnimationPlayer, content: Dictionary, context: Dictionary):
	var frames = _aseprite.get_content_frames(content)

	if not player.has_animation_library(_DEFAULT_ANIMATION_LIBRARY):
		player.add_animation_library(_DEFAULT_ANIMATION_LIBRARY, AnimationLibrary.new())

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		var result = result_code.SUCCESS
		for tag in content.meta.frameTags:
			var selected_frames = frames.slice(tag.from, tag.to + 1)
			result = _add_animation_frames(target_node, player, tag.name, selected_frames, context, tag.direction)
			if result != result_code.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames(target_node, player, "default", frames, context)


func _add_animation_frames(target_node: Node, player: AnimationPlayer, anim_name: String, frames: Array, context: Dictionary, direction = 'forward'):
	var animation_name = anim_name
	var library_name = _DEFAULT_ANIMATION_LIBRARY
	var is_loopable = _config.is_default_animation_loop_enabled()

	var anim_tokens := anim_name.split("/")

	if anim_tokens.size() > 2:
		push_error("Invalid animation name: %s" % animation_name)
		return
	elif anim_tokens.size() == 2:
		library_name = anim_tokens[0]
		animation_name = anim_tokens[1]
		
	if not _validate_animation_name(animation_name):
		push_error("Invalid animation name: %s" % animation_name)
		return

	# Create library if doesn't exist
	if library_name != _DEFAULT_ANIMATION_LIBRARY and not player.has_animation_library(library_name):
		player.add_animation_library(library_name, AnimationLibrary.new())

	# Check loop
	if animation_name.begins_with(_config.get_animation_loop_exception_prefix()):
		animation_name = anim_name.substr(_config.get_animation_loop_exception_prefix().length())
		is_loopable = not is_loopable

	# Add library
	if not player.get_animation_library(library_name).has_animation(animation_name):
		player.get_animation_library(library_name).add_animation(animation_name, Animation.new())

	var full_name = (
		animation_name if library_name == "" else "%s/%s" % [library_name, animation_name]
	)

	var animation = player.get_animation(full_name)
	_create_meta_tracks(target_node, player, animation)
	var frame_track = _get_property_track_path(player, target_node, _get_frame_property())
	var frame_track_index = _create_track(target_node, animation, frame_track)

	if direction == 'reverse':
		frames.reverse()

	var animation_length = 0

	for frame in frames:
		var frame_key = _get_frame_key(target_node, frame, context)
		animation.track_insert_key(frame_track_index, animation_length, frame_key)
		animation_length += frame.duration / 1000

	# Godot 4 has an Animation.LOOP_PINGPONG mode, however it does not
	# behave like in Aseprite, so I'm keeping the custom implementation
	if direction == 'pingpong':
		frames.remove_at(frames.size() - 1)
		if is_loopable:
			frames.remove_at(0)
		frames.reverse()

		for frame in frames:
			var frame_key = _get_frame_key(target_node, frame, context)
			animation.track_insert_key(frame_track_index, animation_length, frame_key)
			animation_length += frame.duration / 1000

	animation.length = animation_length
	animation.loop_mode = Animation.LOOP_LINEAR if is_loopable else Animation.LOOP_NONE

	return result_code.SUCCESS


const _INVALID_TOKENS := ["/", ":", ",", "["]


func _validate_animation_name(name: String) -> bool:
	return not _INVALID_TOKENS.any(func(token: String): return token in name)


func _create_track(target_node: Node, animation: Animation, track: String):
	var track_index = animation.find_track(track, Animation.TYPE_VALUE)

	if track_index != -1:
		animation.remove_track(track_index)

	track_index = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index, track)
	animation.track_set_interpolation_loop_wrap(track_index, false)
	animation.value_track_set_update_mode(track_index, Animation.UPDATE_DISCRETE)

	return track_index


func _get_property_track_path(player: AnimationPlayer, target_node: Node, prop: String) -> String:
		var node_path = player.get_node(player.root_node).get_path_to(target_node)
		return "%s:%s" % [node_path, prop]


func _cleanup_animations(target_node: Node, player: AnimationPlayer, content: Dictionary, options: Dictionary):
	if not (content.meta.has("frameTags") and content.meta.frameTags.size() > 0):
		return result_code.SUCCESS

	_remove_unused_animations(content, player)

	if options.get("cleanup_hide_unused_nodes", false):
		_hide_unused_nodes(target_node, player, content)

	return result_code.SUCCESS

func _remove_unused_animations(content: Dictionary, player: AnimationPlayer):
	pass # FIXME it's not removing unused animations anymore. Sample impl bellow
#	var tags = ["RESET"]
#	for t in content.meta.frameTags:
#		var a = t.name
#		if a.begins_with(_config.get_animation_loop_exception_prefix()):
#			a = a.substr(_config.get_animation_loop_exception_prefix().length())
#		tags.push_back(a)

#   var track = _get_frame_track_path(player, sprite)
#	for a in player.get_animation_list():
#		if tags.has(a):
#			continue
#
#		var animation = player.get_animation(a)
#		if animation.get_track_count() != 1:
#			var t = animation.find_track(track)
#			if t != -1:
#				animation.remove_track(t)
#			continue
#
#		if animation.find_track(track) != -1:
#			player.remove_animation(a)


func _hide_unused_nodes(target_node: Node, player: AnimationPlayer, content: Dictionary):
	var root_node := player.get_node(player.root_node)
	var all_animations := player.get_animation_list()
	var all_sprite_nodes := []
	var animation_sprites := {}

	for a in all_animations:
		var animation := player.get_animation(a)
		var sprite_nodes := []

		for track_idx in animation.get_track_count():
			var raw_path := animation.track_get_path(track_idx)
			
			if raw_path.get_subname(0) == "visible":
				continue

			var path := _remove_properties_from_path(raw_path)
			var sprite_node := root_node.get_node(path)

			if !(sprite_node is Sprite2D || sprite_node is Sprite3D):
				continue

			if sprite_nodes.has(sprite_node):
				continue
			sprite_nodes.append(sprite_node)

		animation_sprites[animation] = sprite_nodes
		for sn in sprite_nodes:
			if all_sprite_nodes.has(sn):
				continue
			all_sprite_nodes.append(sn)

	for animation in animation_sprites:
		var sprite_nodes : Array = animation_sprites[animation]
		for node in all_sprite_nodes:
			if sprite_nodes.has(node):
				continue
			var visible_track = _get_property_track_path(player, node, "visible")
			if animation.find_track(visible_track) != -1:
				continue
			var visible_track_index = _create_track(node, animation, visible_track)
			animation.track_insert_key(visible_track_index, 0, false)


func _scan_filesystem():
	_file_system.scan()
	await _file_system.filesystem_changed


func list_layers(file: String, only_visibles = false) -> Array:
	return _aseprite.list_layers(file, only_visibles)


func _remove_properties_from_path(path: NodePath) -> NodePath:
	var string_path := path as String
	if !(":" in string_path):
		return string_path as NodePath

	var property_path := path.get_concatenated_subnames() as String
	string_path = string_path.substr(0, string_path.length() - property_path.length() - 1)

	return string_path as NodePath


func _setup_texture(target_node: Node, sprite_sheet: String, content: Dictionary, context: Dictionary):
	push_error("_setup_texture not implemented!")


func _get_frame_property() -> String:
	push_error("_get_frame_property not implemented!")
	return ""


func _get_frame_key(target_node: Node, frame: Dictionary, context: Dictionary):
	push_error("_get_frame_key not implemented!")


func _create_meta_tracks(target_node: Node, player: AnimationPlayer, animation: Animation):
	push_error("_create_meta_tracks not implemented!")
