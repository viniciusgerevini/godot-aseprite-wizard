@tool
extends RefCounted

const logger = preload("../config/logger.gd")
var result_code = preload("../config/result_codes.gd")
var _aseprite = preload("../aseprite/aseprite.gd").new()
var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()

var _config = preload("../config/config.gd").new()


func _load_compressed_texture(sprite_sheet: String) -> PortableCompressedTexture2D:
	var global_path = ProjectSettings.globalize_path(sprite_sheet)
	var image = Image.load_from_file(global_path)
	if image == null or image.is_empty():
		logger.error('Failed to load sprite sheet image', sprite_sheet)
		return null
	var tex := PortableCompressedTexture2D.new()
	tex.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
	return tex
