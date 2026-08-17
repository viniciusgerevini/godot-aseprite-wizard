@tool
extends "../base_sprite_resource_creator.gd"

func load_texture(target_node: Node, aseprite_files: Dictionary, options: Dictionary) -> void:
	var source_file = aseprite_files.data_file
	var sprite_sheet = aseprite_files.sprite_sheet
	var data = _aseprite_file_exporter.load_json_content(source_file)
	var texture

	if options.get("should_create_portable_texture", false):
		texture = _load_compressed_texture(sprite_sheet)
	else:
		texture = ResourceLoader.load(sprite_sheet)

	if not data.is_ok:
		logger.error("Failed to load aseprite source", source_file)
		return

	var normalmap_tex: Texture2D = options.get("normalmap_texture")
	if normalmap_tex != null:
		var canvas_tex := CanvasTexture.new()
		canvas_tex.diffuse_texture = texture
		canvas_tex.normal_texture = normalmap_tex
		texture = canvas_tex

	if not options.get("normalmap_embed_resource", true):
		var tres_path := sprite_sheet.get_basename() + ".tres"
		ResourceSaver.save(texture, tres_path)
		texture = ResourceLoader.load(tres_path)

	if options.slice == "":
		target_node.texture = texture
	else:
		var region = _aseprite.get_slice_rect(data.content, options.slice)
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = region
		target_node.texture = atlas_texture

	if target_node is CanvasItem:
		target_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		target_node.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
