@tool
extends Button

signal dir_dropped(path)

func _can_drop_data(_pos, data):
	if data.type == "files_and_dirs":
		var dir_access = DirAccess.open(data.files[0])
		return dir_access != null
	return false


func _drop_data(_pos, data):
	dir_dropped.emit(data.files[0])
