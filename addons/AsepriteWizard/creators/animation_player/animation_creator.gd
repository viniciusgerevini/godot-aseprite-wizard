@tool
extends "../base_sprite_resource_creator.gd"

var _DEFAULT_ANIMATION_LIBRARY = "" # GLOBAL

func create_animations(target_node: Node, player: AnimationPlayer,  aseprite_files: Dictionary, options: Dictionary):
	var result = _import(target_node, player, aseprite_files, options)

	if result != result_code.SUCCESS:
		printerr(result_code.get_error_message(result))


func _import(target_node: Node, player: AnimationPlayer, aseprite_files: Dictionary, options: Dictionary):
	var source_file = aseprite_files.data_file
	var sprite_sheet = aseprite_files.sprite_sheet
	var data = _aseprite_file_exporter.load_json_content(source_file)

	if not data.is_ok:
		return data.code

	var content = data.content

	var context = {}

	if target_node is CanvasItem:
		target_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		target_node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	_setup_texture(target_node, sprite_sheet, content, context)
	var result = _configure_animations(target_node, player, content, context, options.keep_anim_length)
	if result != result_code.SUCCESS:
		return result

	return _cleanup_animations(target_node, player, content, options)


func _load_texture(sprite_sheet: String) -> Texture2D:
	var texture = ResourceLoader.load(sprite_sheet, 'Image', ResourceLoader.CACHE_MODE_IGNORE)
	texture.take_over_path(sprite_sheet)
	return texture


func _configure_animations(target_node: Node, player: AnimationPlayer, content: Dictionary, context: Dictionary, keep_anim_length: bool):
	var frames = _aseprite.get_content_frames(content)

	if not player.has_animation_library(_DEFAULT_ANIMATION_LIBRARY):
		player.add_animation_library(_DEFAULT_ANIMATION_LIBRARY, AnimationLibrary.new())

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		var result = result_code.SUCCESS
		for tag in content.meta.frameTags:
			var selected_frames = frames.slice(tag.from, tag.to + 1)
			result = _add_animation_frames(target_node, player, tag.name, selected_frames, context, keep_anim_length, tag.direction, int(tag.get("repeat", -1)))
			if result != result_code.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames(target_node, player, "default", frames, context, keep_anim_length)


func _add_animation_frames(target_node: Node, player: AnimationPlayer, anim_name: String, frames: Array, context: Dictionary, keep_anim_length: bool, direction = 'forward', repeat = -1):
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
		animation_name = animation_name.substr(_config.get_animation_loop_exception_prefix().length())
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

	if direction == "reverse" or direction == "pingpong_reverse":
		frames.reverse()

	var animation_length = 0

	var repetition = 1

	if repeat != -1:
		is_loopable = false
		repetition = repeat

	for i in range(repetition):
		for frame in frames:
			var frame_key = _get_frame_key(target_node, frame, context)
			animation.track_insert_key(frame_track_index, animation_length, frame_key)
			animation_length += frame.duration / 1000

		# Godot 4 has an Animation.LOOP_PINGPONG mode, however it does not
		# behave like in Aseprite, so I'm keeping the custom implementation
		if direction.begins_with("pingpong"):
			var working_frames = frames.duplicate()
			working_frames.remove_at(working_frames.size() - 1)
			if is_loopable or (repetition > 1 and i < repetition - 1):
				working_frames.remove_at(0)
			working_frames.reverse()

			for frame in working_frames:
				var frame_key = _get_frame_key(target_node, frame, context)
				animation.track_insert_key(frame_track_index, animation_length, frame_key)
				animation_length += frame.duration / 1000

	# if keep_anim_length is enabled only adjust length if
	# - there aren't other tracks besides metas and frame
	# - the current animation is shorter than new one
	if not keep_anim_length or (animation.get_track_count() == (_get_meta_prop_names().size() + 1) or animation.length < animation_length):
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
			if animation.find_track(visible_track, Animation.TYPE_VALUE) != -1:
				continue
			var visible_track_index = _create_track(node, animation, visible_track)
			animation.track_insert_key(visible_track_index, 0, false)


func list_layers(file: String, only_visibles = false) -> Array:
	return _aseprite.list_layers(file, only_visibles)


func _remove_properties_from_path(path: NodePath) -> NodePath:
	var string_path := path as String
	if !(":" in string_path):
		return string_path as NodePath

	var property_path := path.get_concatenated_subnames() as String
	string_path = string_path.substr(0, string_path.length() - property_path.length() - 1)

	return string_path as NodePath


func _create_meta_tracks(target_node: Node, player: AnimationPlayer, animation: Animation):
	_cleanup_meta_tracks(target_node, player, animation)
	for prop in _get_meta_prop_names():
		var track = _get_property_track_path(player, target_node, prop)
		var track_index = _create_track(target_node, animation, track)
		animation.track_insert_key(track_index, 0, true if prop == "visible" else target_node.get(prop))


func _cleanup_meta_tracks(target_node: Node, player: AnimationPlayer, animation: Animation):
	for track_key in ["texture", "hframes", "vframes"]:
		var track = _get_property_track_path(player, target_node, track_key)
		var track_index = animation.find_track(track, Animation.TYPE_VALUE)
		if track_index != -1:
			animation.remove_track(track_index)


func _setup_texture(target_node: Node, sprite_sheet: String, content: Dictionary, context: Dictionary):
	push_error("_setup_texture not implemented!")


func _get_frame_property() -> String:
	push_error("_get_frame_property not implemented!")
	return ""


func _get_frame_key(target_node: Node, frame: Dictionary, context: Dictionary):
	push_error("_get_frame_key not implemented!")


func _get_meta_prop_names():
	push_error("_get_meta_prop_names not implemented!")
