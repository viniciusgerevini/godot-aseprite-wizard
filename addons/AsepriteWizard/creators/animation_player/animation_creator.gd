@tool
extends "../base_sprite_resource_creator.gd"

const wizard_config = preload("../../config/wizard_config.gd")

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

	_setup_texture(target_node, sprite_sheet, content, context, options.slice != "")
	var result = _configure_animations(target_node, player, content, context, options)
	if result != result_code.SUCCESS:
		return result

	return _cleanup_animations(target_node, player, content, options)


func _load_texture(sprite_sheet: String) -> Texture2D:
	var texture = ResourceLoader.load(sprite_sheet, 'Image', ResourceLoader.CACHE_MODE_IGNORE)
	texture.take_over_path(sprite_sheet)
	return texture


func _configure_animations(target_node: Node, player: AnimationPlayer, content: Dictionary, context: Dictionary, options: Dictionary):
	var frames = _aseprite.get_content_frames(content)
	var slice_rect = null
	if options.slice != "":
		options["slice_rect"] = _aseprite.get_slice_rect(content, options.slice)

	if not player.has_animation_library(_DEFAULT_ANIMATION_LIBRARY):
		player.add_animation_library(_DEFAULT_ANIMATION_LIBRARY, AnimationLibrary.new())

	if content.meta.has("frameTags") and content.meta.frameTags.size() > 0:
		var result = result_code.SUCCESS
		for tag in content.meta.frameTags:
			var selected_frames = frames.slice(tag.from, tag.to + 1)
			result = _add_animation_frames(target_node, player, tag.name, selected_frames, context, options, tag.direction, int(tag.get("repeat", -1)))
			if result != result_code.SUCCESS:
				break
		return result
	else:
		return _add_animation_frames(target_node, player, "default", frames, context, options)


func _add_animation_frames(target_node: Node, player: AnimationPlayer, anim_name: String, frames: Array, context: Dictionary, options: Dictionary, direction = 'forward', repeat = -1):
	var animation_name = anim_name
	var library_name = _DEFAULT_ANIMATION_LIBRARY
	var is_loopable = _config.is_default_animation_loop_enabled()
	var slice_rect = options.get("slice_rect")
	var is_importing_slice: bool = slice_rect != null

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
	_cleanup_tracks(target_node, player, animation)

	var frame_track = _get_property_track_path(player, target_node, _get_frame_property(is_importing_slice))
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
			var frame_key = _get_frame_key(target_node, frame, context, slice_rect)
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
				var frame_key = _get_frame_key(target_node, frame, context, slice_rect)
				animation.track_insert_key(frame_track_index, animation_length, frame_key)
				animation_length += frame.duration / 1000

	# if keep_anim_length is enabled only adjust length if
	# - there aren't other tracks besides metas and frame
	# - the current animation is shorter than new one
	if not options.keep_anim_length or (animation.get_track_count() == 1 or animation.length < animation_length):
		animation.length = animation_length

	animation.loop_mode = Animation.LOOP_LINEAR if is_loopable else Animation.LOOP_NONE

	return result_code.SUCCESS


const _INVALID_TOKENS := ["/", ":", ",", "["]


func _validate_animation_name(name: String) -> bool:
	return not _INVALID_TOKENS.any(func(token: String): return token in name)


func _create_track(target_node: Node, animation: Animation, track: String) -> int:
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

	_remove_unused_animations(target_node, player, content)

	_hide_unused_nodes(player, content)

	return result_code.SUCCESS


## remove tracks and animations for nodes without animation tag
func _remove_unused_animations(target_node: Node, player: AnimationPlayer, content: Dictionary):
	var tags: Array[String] = []
	for t in content.meta.frameTags:
		tags.push_back(_animation_name_without_loop_prefix(t.name))

	for a in player.get_animation_list():
		if tags.has(a):
			continue
		var animation := player.get_animation(a)

		for p in _get_props_to_cleanup():
			var track = _get_property_track_path(player, target_node, p)
			var track_index = animation.find_track(track, Animation.TYPE_VALUE)
			if track_index != -1:
				animation.remove_track(track_index)


		if animation.get_track_count() == 0:
			var p = _get_animation_data(a)
			player.get_animation_library(p.library).remove_animation(p.animation)


## control visibility track when node has "hide unused" option available
func _hide_unused_nodes(player: AnimationPlayer, content: Dictionary):
	var root_node := player.get_node(player.root_node)
	var all_animations := player.get_animation_list()
	var all_sprite_nodes: Array[Node] = []
	var animation_sprites := {}

	for a in all_animations:
		var animation := player.get_animation(a)
		var sprite_nodes: Array[Node] = []

		# get all supported nodes in animation
		for track_idx in animation.get_track_count():
			var raw_path := animation.track_get_path(track_idx)

			var path := _remove_properties_from_path(raw_path)
			var sprite_node := root_node.get_node(path)

			if not _is_supported_node(sprite_node):
				continue

			# ignore nodes with no wizard config or not supposed to be hidden
			if not wizard_config.has_config(sprite_node) or not wizard_config.load_config(sprite_node).get("set_vis_track", false):
				continue

			if not sprite_nodes.has(sprite_node):
				sprite_nodes.append(sprite_node)
				if not all_sprite_nodes.has(sprite_node):
					all_sprite_nodes.append(sprite_node)

		animation_sprites[animation] = sprite_nodes

	for animation: Animation in animation_sprites:
		var sprite_nodes : Array[Node] = animation_sprites[animation]
		for node in all_sprite_nodes:
			# node should be visible if they are in the list and have tracks available
			var node_visibility: bool = sprite_nodes.has(node) and _relevant_track_count(node, player, animation) > 0
			var visible_track := _get_property_track_path(player, node, "visible")
			var visible_track_index := _create_track(node, animation, visible_track)
			animation.track_insert_key(visible_track_index, 0, node_visibility)


func list_layers(file: String, only_visibles = false) -> Array:
	return _aseprite.list_layers(file, only_visibles)


func list_slices(file: String) -> Array:
	return _aseprite.list_slices(file)


func _remove_properties_from_path(path: NodePath) -> NodePath:
	var string_path := path as String
	if !(":" in string_path):
		return string_path as NodePath

	var property_path := path.get_concatenated_subnames() as String
	string_path = string_path.substr(0, string_path.length() - property_path.length() - 1)

	return string_path as NodePath


func _cleanup_tracks(target_node: Node, player: AnimationPlayer, animation: Animation):
	for track_key in ["texture", "hframes", "vframes", "region_rect", "frame"]:
		var track = _get_property_track_path(player, target_node, track_key)
		var track_index = animation.find_track(track, Animation.TYPE_VALUE)
		if track_index != -1:
			animation.remove_track(track_index)


func _setup_texture(target_node: Node, sprite_sheet: String, content: Dictionary, context: Dictionary, is_importing_slice: bool):
	push_error("_setup_texture not implemented!")


func _get_frame_property(is_importing_slice: bool) -> String:
	push_error("_get_frame_property not implemented!")
	return ""


func _get_frame_key(target_node: Node, frame: Dictionary, context: Dictionary, slice_info: Variant):
	push_error("_get_frame_key not implemented!")


func _get_props_to_cleanup() -> Array[String]:
	push_error("_props_to_cleanup not implemented!")
	return []


func _is_supported_node(target_node: Node):
	return target_node is Sprite2D or target_node is Sprite3D or target_node is TextureRect


func _get_animation_data(animaton_name: String) -> Dictionary:
	var parts = animaton_name.split("/")

	if parts.size() == 2:
		return {
			"library": parts[0],
			"animation": parts[1],
		}
	return {
		"library": _DEFAULT_ANIMATION_LIBRARY,
		"animation": parts[0],
	}


func _relevant_track_count(target_node: Node, player: AnimationPlayer, animation: Animation) -> int:
	var track_count := 0
	for p in _get_props_to_cleanup():
		if p == "visible":
			continue
		var track = _get_property_track_path(player, target_node, p)
		var track_index = animation.find_track(track, Animation.TYPE_VALUE)
		if track_index != -1:
			track_count += 1

	return track_count


func _animation_name_without_loop_prefix(animation_name: String) -> String:
	if animation_name.begins_with(_config.get_animation_loop_exception_prefix()):
		return animation_name.substr(_config.get_animation_loop_exception_prefix().length())
	return animation_name
