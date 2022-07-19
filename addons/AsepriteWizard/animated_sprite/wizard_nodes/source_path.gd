tool
extends LineEdit


func set_entry(entry: Dictionary):
	self.text = entry.source_file
	self.hint_tooltip = _format_hint(entry)


func _format_hint(entry: Dictionary) -> String:
	return """Output filename/prefix: %s
Ex. pattern: %s
Split: %s
Only visible: %s
No Resource: %s
""" % [
	entry.options.output_filename,
	entry.options.exception_pattern,
	"yes" if entry.options.export_mode else "no",
	"yes" if entry.options.only_visible_layers else "no",
	"yes" if entry.options.do_not_create_resource else "no",
]
