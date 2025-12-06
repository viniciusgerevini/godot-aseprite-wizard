@tool
extends RefCounted

const SUCCESS = 0
const ERR_ASEPRITE_CMD_NOT_FOUND = 991
const ERR_SOURCE_FILE_NOT_FOUND = 992
const ERR_OUTPUT_FOLDER_NOT_FOUND = 993
const ERR_ASEPRITE_EXPORT_FAILED = 994
const ERR_UNKNOWN_EXPORT_MODE = 995
const ERR_NO_VALID_LAYERS_FOUND = 996
const ERR_INVALID_ASEPRITE_SPRITESHEET = 997


static func get_error_message(code: int):
	match code:
		ERR_ASEPRITE_CMD_NOT_FOUND:
			return "Aseprite command failed. Please, check if the right command is in your PATH or configured through \"Editor > Editor Settings > Aseprite > General > Command Path\"."
		ERR_SOURCE_FILE_NOT_FOUND:
			return "source file does not exist"
		ERR_OUTPUT_FOLDER_NOT_FOUND:
			return "output location does not exist"
		ERR_ASEPRITE_EXPORT_FAILED:
			return "unable to import file"
		ERR_INVALID_ASEPRITE_SPRITESHEET:
			return "aseprite generated bad data file"
		ERR_UNKNOWN_EXPORT_MODE:
			return "wrong export mode"
		ERR_NO_VALID_LAYERS_FOUND:
			return "no valid layers found"
		_:
			return "import failed: %d" % error_string(code)


static func error(error_code: int):
	return { "code": error_code, "content": null, "is_ok": false }


static func result(result):
	return { "code": SUCCESS, "content": result, "is_ok": true }
