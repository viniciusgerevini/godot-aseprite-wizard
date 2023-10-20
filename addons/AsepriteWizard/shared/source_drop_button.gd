@tool
extends Button

signal aseprite_file_dropped(path)

func _can_drop_data(_pos, data):
	if data.type == "files":
		var extension = data.files[0].get_extension()
		return extension == "ase" or extension == "aseprite"
	return false


func _drop_data(_pos, data):
	var path = data.files[0]
	aseprite_file_dropped.emit(path)
