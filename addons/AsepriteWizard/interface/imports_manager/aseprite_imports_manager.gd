@tool
extends Window

# TODO Undock / Dock button (Aseprite Import Manager)

func _on_close_requested():
	self.queue_free()
