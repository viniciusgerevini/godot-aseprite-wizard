extends EditorResourceTooltipPlugin


func _make_tooltip_for_path(path: String, metadata: Dictionary, base: Control) -> Control:
	match path.get_extension():
		"aseprite", "ase":
			var hb := HBoxContainer.new()
			var vb: VBoxContainer = base

			vb.alignment = BoxContainer.ALIGNMENT_CENTER

			var tr := TextureRect.new()

			tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(tr)
			request_thumbnail(path, tr)

			hb.add_child(vb)
			hb.add_theme_constant_override("separation", 8 * EditorInterface.get_editor_scale())

			return hb
		_:
			return null


func _handles(type: String) -> bool:
	return type == "SpriteFrames"
