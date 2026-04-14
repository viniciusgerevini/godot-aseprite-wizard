@tool
extends "../base_sprite_resource_creator.gd"

var _normal_map_generator = preload("../../normalmap/normal_map_generator.gd")

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

	if options.get("normalmap_generate", false):
		var params: Dictionary = options.get("normalmap_params", {})
		var global_path = ProjectSettings.globalize_path(sprite_sheet)
		var source_image = Image.load_from_file(global_path)
		if source_image != null and not source_image.is_empty():
			var normal_img = _normal_map_generator.generate_normal_map(source_image, params)

			if options.get("normalmap_save_debug_png", false):
				var base = sprite_sheet.get_basename()
				normal_img.save_png(ProjectSettings.globalize_path(base + "_n.png"))

			var normal_tex := PortableCompressedTexture2D.new()
			normal_tex.create_from_image(normal_img, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
			var canvas_tex := CanvasTexture.new()
			canvas_tex.diffuse_texture = texture
			canvas_tex.normal_texture = normal_tex
			texture = canvas_tex

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
