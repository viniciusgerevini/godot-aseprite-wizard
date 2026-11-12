extends ImageFormatLoaderExtension

const result_codes = preload("../config/result_codes.gd")
const logger = preload("../config/logger.gd")
var _aseprite = preload("../aseprite/aseprite.gd").new()

var config = preload("../config/config.gd").new()


func _get_recognized_extensions() -> PackedStringArray:
	return ["ase", "aseprite"]


func _load_image(image: Image, fileaccess: FileAccess, flags: int, scale: float) -> Error:
	if not _aseprite.test_command():
		return FAILED
	var temp_file = OS.get_temp_dir().path_join(
		"aseprite_%s.png" % Time.get_datetime_string_from_system()
	)
	if _aseprite._execute(
		["-b", fileaccess.get_path_absolute(), "--sheet-pack", "--sheet", temp_file],
		[],
	) != 0:
		return FAILED
	var err = image.load_png_from_buffer(FileAccess.get_file_as_bytes(temp_file))
	DirAccess.remove_absolute(temp_file);
	return err;
