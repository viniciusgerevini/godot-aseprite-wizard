extends "animation_creator.gd"


func _setup_texture(target_node: Node, sprite_sheet: String, content: Dictionary, context: Dictionary, _is_importing_slice: bool):
	context["base_texture"] = _load_texture(sprite_sheet)


func _get_frame_property(_is_importing_slice: bool) -> String:
		return "texture"


func _get_frame_key(target_node: Node, frame: Dictionary, context: Dictionary, slice_info):
	return _get_atlas_texture(context["base_texture"], frame, slice_info)


func _create_meta_tracks(target_node: Node, player: AnimationPlayer, animation: Animation):
	var visible_track = _get_property_track_path(player, target_node, "visible")
	var visible_track_index = _create_track(target_node, animation, visible_track)
	animation.track_insert_key(visible_track_index, 0, true)


func _get_atlas_texture(base_texture: Texture, frame_data: Dictionary, slice_info) -> AtlasTexture:
	var tex = AtlasTexture.new()
	tex.atlas = base_texture
	tex.region = Rect2(Vector2(frame_data.frame.x, frame_data.frame.y), Vector2(frame_data.frame.w, frame_data.frame.h))
	tex.filter_clip = true

	if slice_info != null:
		tex.region.position.x += slice_info.position.x
		tex.region.position.y += slice_info.position.y
		tex.region.size.x = slice_info.size.x
		tex.region.size.y = slice_info.size.y

	return tex
