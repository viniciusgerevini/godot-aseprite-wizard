@tool
extends LineEdit

func set_entry(entry: Dictionary):
	self.text = entry.source_file
	self.tooltip_text = entry.source_file
