@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")
const logger = preload("../config/logger.gd")
var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()
var _bakery = preload("./helpers/bakery.gd").new()
var _normal_map_generator = preload("../normalmap/normal_map_generator.gd")

var config = preload("../config/config.gd").new()

const CONTINUE_STATUS_CODE = 91919

func _get_save_extension():
	return "res"


func _get_resource_type():
	return "Texture2D"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_import_order():
	return 1


func _get_option_visibility(path, option, options):
	if option.begins_with("normalmap/") and option != "normalmap/generate":
		return options.get("normalmap/generate", false)
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


func _save_resource(source_file: String, sprite_sheet: String, save_path: String, data_file_path: String, size: Dictionary, normalmap_options: Dictionary = {}) -> int:
	var image = Image.load_from_file(ProjectSettings.globalize_path(sprite_sheet))

	var tex := PortableCompressedTexture2D.new()
	tex.create_from_image(image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	var final_tex: Texture2D = tex

	if normalmap_options.get("generate", false):
		var params: Dictionary = normalmap_options.get("params", {})
		var normal_img = _normal_map_generator.generate_normal_map(image, params)

		if normalmap_options.get("save_debug_png", false):
			var base = sprite_sheet.get_basename()
			normal_img.save_png(ProjectSettings.globalize_path(base + "_n.png"))

		var normal_tex := PortableCompressedTexture2D.new()
		normal_tex.create_from_image(normal_img, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

		var canvas_tex := CanvasTexture.new()
		canvas_tex.diffuse_texture = tex
		canvas_tex.normal_texture = normal_tex
		final_tex = canvas_tex

	var exit_code = ResourceSaver.save(final_tex, "%s.%s" % [save_path, _get_save_extension()])

	if config.should_remove_source_files():
		DirAccess.remove_absolute(data_file_path)
		DirAccess.remove_absolute(sprite_sheet)

	if exit_code != OK:
		logger.error("Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code), source_file)
		return FAILED

	if config.should_generate_bake_files():
		var bake_code = _bakery.save_bake_file(source_file, final_tex)
		if bake_code != OK:
			logger.error('Bake file creation failed (%s)' % bake_code, source_file)

	return OK


func _handle_bake_fallback(source_file: String, save_path: String) -> int:
	if _aseprite_file_exporter.is_aseprite_command_working():
		return CONTINUE_STATUS_CODE

	if config.should_generate_bake_files() && _bakery.has_bake_file(source_file):
		logger.warn("Aseprite command failed. Falling back to baked file", source_file)
		var resource_path = "%s.%s" % [save_path, _get_save_extension()]
		return _bakery.load_bake_texture(source_file, resource_path)
	else:
		return ERR_UNCONFIGURED
