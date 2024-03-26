@tool
extends Window

func _on_close_requested():
	self.queue_free()
