@tool
extends "../base_sprite_resource_creator.gd"

func load_texture(target_node: Node, aseprite_files: Dictionary, options: Dictionary) -> void:
	var source_file = aseprite_files.data_file
	var sprite_sheet = aseprite_files.sprite_sheet
	var data = _aseprite_file_exporter.load_json_content(source_file)
	var texture = ResourceLoader.load(sprite_sheet)

	if not data.is_ok:
		printerr("Failed to load aseprite source %s" % source_file)
		return

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
