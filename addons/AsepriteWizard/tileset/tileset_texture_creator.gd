@tool
extends "../base_sprite_resource_creator.gd"

##
## Generate a spritesheet with all tilesets in the file
##
## Options:
##    exception_pattern (string)
##    only_visible_layers (boolean)
##    output_filename (string)
##    output_folder (string)
##
## Return:
##  Dictionary
##     sprite_sheet: sprite sheet path
##     data_file:  json file path
##     data_content: content of aseprite json file
##
func generate_aseprite_spritesheet(source_file: String, options = {}) -> Dictionary:
	var output = _aseprite_file_exporter.generate_tileset_files(source_file, options)

	if not output.is_ok:
		printerr(result_code.get_error_message(output.code))
		return result_code.error(output.code)

	var data = _aseprite_file_exporter.load_json_content(output.data_file)

	if not data.is_ok:
		return data

	return result_code.result({
		"sprite_sheet": output.sprite_sheet,
		"data_file": output.data_file,
		"data_content": data.content
	})
