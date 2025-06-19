@tool
extends RefCounted

var result_code = preload("../config/result_codes.gd")
var _aseprite = preload("aseprite.gd").new()

enum {
	FILE_EXPORT_MODE,
	LAYERS_EXPORT_MODE
}

##
## Generate Aseprite spritesheet and data files for source.
##
## Options:
##    output_folder (string)
##    output_filename (string, optional)
##    export_mode (FILE_EXPORT_MODE, LAYERS_EXPORT_MODE) default: FILE_EXPORT_MODE
##    exception_pattern (string, optional)
##    only_visible_layers (boolean, optional)
##    scale (string, optional)
##
## Return:
##  Array
##    Dictionary
##     sprite_sheet: sprite sheet path
##     data_file:  json file path
##
func generate_aseprite_files(source_file: String, options: Dictionary):
	var check = _initial_checks(source_file, options)

	if check != result_code.SUCCESS:
		return result_code.error(check)

	match options.get('export_mode', FILE_EXPORT_MODE):
		FILE_EXPORT_MODE:
			var output = _aseprite.export_file(source_file, options.output_folder, options)
			if output.is_empty():
				return result_code.error(result_code.ERR_ASEPRITE_EXPORT_FAILED)
			return result_code.result([output])
		LAYERS_EXPORT_MODE:
			var output = _aseprite.export_layers(source_file, options.output_folder, options)
			if output.is_empty():
				return result_code.error(result_code.ERR_NO_VALID_LAYERS_FOUND)
			return result_code.result(output)
		_:
			return result_code.error(result_code.ERR_UNKNOWN_EXPORT_MODE)


##
## Generate Aseprite spritesheet and data file for source.
##
## Options:
##    output_folder (string)
##    output_filename (string, optional)
##    layer (string, optional)
##    exception_pattern (string, optional)
##    only_visible_layers (boolean, optional)
##    scale (string, optional)
##
## Return:
##    Dictionary
##     sprite_sheet: sprite sheet path
##     data_file:  json file path
##
func generate_aseprite_file(source_file: String, options: Dictionary) -> Dictionary:
	var check = _initial_checks(source_file, options)

	if check != result_code.SUCCESS:
		return result_code.error(check)

	var output

	if options.get("layer") != null and options.get("layer") != "":
		output = _aseprite.export_file_with_layers(source_file, [options.layer], options.output_folder, options)
	elif options.get("layers", []).size() > 0:
		output = _aseprite.export_file_with_layers(source_file, options.layers, options.output_folder, options)
	else:
		output = _aseprite.export_file(source_file, options.output_folder, options)


	if output.is_empty():
		return result_code.error(result_code.ERR_ASEPRITE_EXPORT_FAILED)

	return result_code.result(output)


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
##
func generate_tileset_files(source_file: String, options = {}) -> Dictionary:
	var check = _initial_checks(source_file, options)

	if check != result_code.SUCCESS:
		return result_code.error(check)

	var output = _aseprite.export_tileset_texture(source_file, options.output_folder, options)

	if output.is_empty():
		return result_code.error(result_code.ERR_ASEPRITE_EXPORT_FAILED)

	return result_code.result(output)


##
## Perform initial source file and output folder checks
##
func _initial_checks(source: String, options: Dictionary) -> int:
	if not _aseprite.test_command():
		return result_code.ERR_ASEPRITE_CMD_NOT_FOUND

	if not FileAccess.file_exists(source):
		return result_code.ERR_SOURCE_FILE_NOT_FOUND

	if not DirAccess.dir_exists_absolute(options.output_folder):
		return result_code.ERR_OUTPUT_FOLDER_NOT_FOUND

	return result_code.SUCCESS


##
## Load Aseprite source data file and fails if the
## content is not valid
##
func load_json_content(source_file: String) -> Dictionary:
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return result_code.error(FileAccess.get_open_error())
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())

	var content = test_json_conv.get_data()

	if not _aseprite.is_valid_spritesheet(content):
		return result_code.error(result_code.ERR_INVALID_ASEPRITE_SPRITESHEET)

	return result_code.result(content)
