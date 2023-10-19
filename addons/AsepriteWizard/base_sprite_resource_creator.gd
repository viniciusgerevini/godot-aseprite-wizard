@tool
extends RefCounted

var result_code = preload("config/result_codes.gd")
var _aseprite = preload("aseprite/aseprite.gd").new()

var _config
var _file_system: EditorFileSystem

##
## Load initial dependencies
##
func init(config, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_aseprite.init(config)


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
func _load_json_content(source_file: String) -> Dictionary:
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return result_code.error(file.get_open_error())
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())

	var content = test_json_conv.get_data()

	if not _aseprite.is_valid_spritesheet(content):
		return result_code.error(result_code.ERR_INVALID_ASEPRITE_SPRITESHEET)

	return result_code.result(content)
