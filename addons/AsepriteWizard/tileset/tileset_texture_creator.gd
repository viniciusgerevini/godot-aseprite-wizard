@tool
extends "../base_sprite_resource_creator.gd"

func generate_aseprite_spritesheet(source_file: String, options = {}) -> Dictionary:
	var check = _initial_checks(source_file, options)

	if check != result_code.SUCCESS:
		printerr(result_code.get_error_message(check))
		return result_code.error(check)

	var output = _aseprite.export_tileset_texture(source_file, options.output_folder, options)

	if output.is_empty():
		printerr(result_code.get_error_message(result_code.ERR_ASEPRITE_EXPORT_FAILED))
		return result_code.error(check)

	var data = _load_json_content(output.data_file)

	if not data.is_ok:
		return data

	output.data = data.content

	return result_code.result(output)
