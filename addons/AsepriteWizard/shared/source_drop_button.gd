tool
extends Button

signal aseprite_file_dropped(path)

func can_drop_data(_pos, data):
	if data.type == "files":
		var extension = data.files[0].get_extension()
		return extension == "ase" or extension == "aseprite"
	return false


func drop_data(_pos, data):
	var path = data.files[0]
	emit_signal("aseprite_file_dropped", path)
