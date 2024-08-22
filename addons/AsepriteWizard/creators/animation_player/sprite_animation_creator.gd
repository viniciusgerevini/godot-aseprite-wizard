extends "animation_creator.gd"


func _setup_texture(sprite: Node, sprite_sheet: String, content: Dictionary, context: Dictionary, is_importing_slice: bool):
	var texture = _load_texture(sprite_sheet)
	sprite.texture = texture

	if content.frames.is_empty():
		return

	if is_importing_slice:
		sprite.region_enabled = true
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.frame = 0
	else:
		sprite.region_enabled = false
		sprite.hframes = content.meta.size.w / content.frames[0].sourceSize.w
		sprite.vframes = content.meta.size.h / content.frames[0].sourceSize.h


func _get_frame_property(is_importing_slice: bool) -> String:
	return "frame" if not is_importing_slice else "region_rect"


func _get_props_to_cleanup() -> Array[String]:
	return ["frame", "region_rect", "visible"]



func _get_frame_key(sprite:  Node, frame: Dictionary, context: Dictionary, slice_info: Variant):
	if slice_info != null:
		return _create_slice_rect(frame, slice_info)
	return _calculate_frame_index(sprite,frame)


func _calculate_frame_index(sprite: Node, frame: Dictionary) -> int:
	var column = floor(frame.frame.x * sprite.hframes / sprite.texture.get_width())
	var row = floor(frame.frame.y * sprite.vframes / sprite.texture.get_height())
	return (row * sprite.hframes) + column


func _create_slice_rect(frame_data: Dictionary, slice_rect: Rect2) -> Rect2:
	var frame = frame_data.frame
	return Rect2(
		frame.x + slice_rect.position.x,
		frame.y + slice_rect.position.y,
		slice_rect.size.x,
		slice_rect.size.y
	)
