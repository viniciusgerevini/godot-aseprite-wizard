extends "animation_creator.gd"


func _get_meta_prop_names():
	return [ "visible" ]


func _setup_texture(target_node: Node, sprite_sheet: String, content: Dictionary, context: Dictionary):
	context["base_texture"] = _load_texture(sprite_sheet)


func _get_frame_property() -> String:
	return "texture"


func _get_frame_key(target_node: Node, frame: Dictionary, context: Dictionary):
	return _get_atlas_texture(context["base_texture"], frame)


func _get_atlas_texture(base_texture: Texture2D, frame_data: Dictionary) -> AtlasTexture:
	var tex = AtlasTexture.new()
	tex.atlas = base_texture
	tex.region = Rect2(Vector2(frame_data.frame.x, frame_data.frame.y), Vector2(frame_data.frame.w, frame_data.frame.h))
	tex.filter_clip = true
	return tex
