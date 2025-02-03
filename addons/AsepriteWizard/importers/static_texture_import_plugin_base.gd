@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")
var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()

var config = preload("../config/config.gd").new()


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "PortableCompressedTexture2D"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_import_order():
	return 1


func _get_option_visibility(path, option, options):
	return true


func _generate_texture(absolute_source_file: String, options: Dictionary) -> Dictionary:
	var result = _aseprite_file_exporter.generate_aseprite_file(absolute_source_file, options)

	if not result.is_ok:
		return result

	var sprite_sheet = result.content.sprite_sheet
	var data_result = _aseprite_file_exporter.load_json_content(result.content.data_file)

	if not data_result.is_ok:
		return data_result

	var data = data_result.content

	return result_codes.result({
		"data_file": result.content.data_file,
		"sprite_sheet": sprite_sheet,
		"data": data
	})


func _save_resource(sprite_sheet: String, save_path: String, data_file_path: String, size: Dictionary) -> int:
	var image = Image.load_from_file(sprite_sheet)

	var tex := PortableCompressedTexture2D.new()
	tex.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)
#
	var exit_code = ResourceSaver.save(tex, "%s.%s" % [save_path, _get_save_extension()])

	if config.should_remove_source_files():
		DirAccess.remove_absolute(data_file_path)
		DirAccess.remove_absolute(sprite_sheet)

	if exit_code != OK:
		printerr("ERROR - Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code))
		return FAILED

	return OK
