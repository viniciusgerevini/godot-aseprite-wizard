extends "animation_creator.gd"

func _get_meta_prop_names():
	return [ "visible" ]

func _setup_texture(sprite: Node, sprite_sheet: String, content: Dictionary, context: Dictionary):
	var texture = _load_texture(sprite_sheet)
	sprite.texture = texture

	if content.frames.is_empty():
		return

	sprite.hframes = content.meta.size.w / content.frames[0].sourceSize.w
	sprite.vframes = content.meta.size.h / content.frames[0].sourceSize.h


func _get_frame_property() -> String:
	return "frame"


func _get_frame_key(sprite:  Node, frame: Dictionary, context: Dictionary):
	return _calculate_frame_index(sprite,frame)


func _calculate_frame_index(sprite: Node, frame: Dictionary) -> int:
	var column = floor(frame.frame.x * sprite.hframes / sprite.texture.get_width())
	var row = floor(frame.frame.y * sprite.vframes / sprite.texture.get_height())
	return (row * sprite.hframes) + column

