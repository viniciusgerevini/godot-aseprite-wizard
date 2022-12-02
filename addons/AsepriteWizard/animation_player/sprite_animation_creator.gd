extends "animation_creator.gd"


func _setup_texture(sprite: Node, sprite_sheet: String, content: Dictionary, context: Dictionary):
	var texture = _load_texture(sprite_sheet)
	sprite.texture = texture

	if content.frames.is_empty():
		return

	sprite.hframes = content.meta.size.w / content.frames[0].sourceSize.w
	sprite.vframes = content.meta.size.h / content.frames[0].sourceSize.h


func _get_frame_property() -> String:
	return "frame"


func _create_meta_tracks(sprite: Node, player: AnimationPlayer, animation: Animation):
	var texture_track = _get_property_track_path(player, sprite, "texture")
	var texture_track_index = _create_track(sprite, animation, texture_track)
	animation.track_insert_key(texture_track_index, 0, sprite.texture)

	var hframes_track = _get_property_track_path(player, sprite, "hframes")
	var hframes_track_index = _create_track(sprite, animation, hframes_track)
	animation.track_insert_key(hframes_track_index, 0, sprite.hframes)

	var vframes_track = _get_property_track_path(player, sprite, "vframes")
	var vframes_track_index = _create_track(sprite, animation, vframes_track)
	animation.track_insert_key(vframes_track_index, 0, sprite.vframes)

	var visible_track = _get_property_track_path(player, sprite, "visible")
	var visible_track_index = _create_track(sprite, animation, visible_track)
	animation.track_insert_key(visible_track_index, 0, true)

	
func _get_frame_key(sprite:  Node, frame: Dictionary, context: Dictionary):
	return _calculate_frame_index(sprite,frame)


func _calculate_frame_index(sprite: Node, frame: Dictionary) -> int:
	var column = floor(frame.frame.x * sprite.hframes / sprite.texture.get_width())
	var row = floor(frame.frame.y * sprite.vframes / sprite.texture.get_height())
	return (row * sprite.hframes) + column

