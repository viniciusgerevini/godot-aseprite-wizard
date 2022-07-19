tool
extends Label


func set_date(timestamp: int):
	self.text = _format_date(timestamp)


func _format_date(timestamp: int) -> String:
	var dt = OS.get_datetime_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
