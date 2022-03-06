@tool
extends RefCounted

const SUCCESS = 0
const ERR_ASEPRITE_CMD_NOT_FOUND = 1
const ERR_SOURCE_FILE_NOT_FOUND = 2
const ERR_OUTPUT_FOLDER_NOT_FOUND = 3
const ERR_ASEPRITE_EXPORT_FAILED = 4
const ERR_UNKNOWN_EXPORT_MODE = 5
const ERR_NO_VALID_LAYERS_FOUND = 6
const ERR_INVALID_ASEPRITE_SPRITESHEET = 7


static func get_error_message(code: int):
	match code:
		ERR_ASEPRITE_CMD_NOT_FOUND:
			return "Aseprite command failed. Please, check if the right command is in your PATH or configured through \"Project > Tools > Aseprite Wizard Config\"."
		ERR_SOURCE_FILE_NOT_FOUND:
			return "source file does not exist"
		ERR_OUTPUT_FOLDER_NOT_FOUND:
			return "output location does not exist"
		ERR_ASEPRITE_EXPORT_FAILED:
			return "unable to import file"
		ERR_INVALID_ASEPRITE_SPRITESHEET:
			return "aseprite generated bad data file"
		ERR_NO_VALID_LAYERS_FOUND:
			return "no valid layers found"
		_:
			return "import failed with code %d" % code
