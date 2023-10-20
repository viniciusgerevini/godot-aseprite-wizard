@tool
extends RefCounted

var result_code = preload("config/result_codes.gd")
var _aseprite = preload("aseprite/aseprite.gd").new()
var _aseprite_file_exporter = preload("aseprite/file_exporter.gd").new()

var _config

##
## Load initial dependencies
##
func init(config):
	_config = config
	_aseprite.init(config)
	_aseprite_file_exporter.init(config)
