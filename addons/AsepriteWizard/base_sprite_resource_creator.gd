@tool
extends RefCounted

var result_code = preload("config/result_codes.gd")
var _aseprite = preload("aseprite/aseprite.gd").new()
var _aseprite_file_exporter = preload("aseprite/file_exporter.gd").new()

var _config
var _file_system: EditorFileSystem

##
## Load initial dependencies
##
func init(config, editor_file_system: EditorFileSystem = null):
	_config = config
	_file_system = editor_file_system
	_aseprite.init(config)
	_aseprite_file_exporter.init(_aseprite)
