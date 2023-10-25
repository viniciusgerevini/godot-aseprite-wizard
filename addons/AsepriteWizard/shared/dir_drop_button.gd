tool
extends Button

signal dir_dropped(path)

func can_drop_data(_pos, data):
	if data.type == "files_and_dirs":
		var dir = Directory.new()
		return dir.dir_exists(data.files[0])
	return false


func drop_data(_pos, data):
	emit_signal("dir_dropped", data.files[0])
