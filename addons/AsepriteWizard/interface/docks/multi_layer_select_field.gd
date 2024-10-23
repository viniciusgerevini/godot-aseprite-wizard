@tool
extends VBoxContainer

const LayerField = preload("./layer_select_field.tscn")

signal value_changed

var data_fetcher: Callable

func set_selected_layers(layers: Array):
	for c in get_children():
		c.queue_free()

	if layers.size() > 1:
		var last
		for layer in layers:
			var field = LayerField.instantiate()
			field.set_remove_button(true)
			add_child(field)
			field.set_value(layer)
			_hook_signals(field)
			last = field
		last.set_add_button(true)
		return

	var field = LayerField.instantiate()
	field.is_only_field = true
	add_child(field)

	if layers.is_empty():
		field.set_value("")
	else:
		field.set_value(layers[0])
		field.set_add_button(true)
	_hook_signals(field)


func get_selected_layers() -> Array:
	return _get_field_values()


func _get_field_values() -> Array:
	var values = []

	for c in get_children():
		var v = c.get_value()
		if v != "" and not values.has(v):
			values.push_back(v)

	return values


func _hook_signals(field: Control):
	field.add_pressed.connect(_on_add_pressed.bind(field))
	field.removed_pressed.connect(_on_removed_pressed.bind(field))
	field.data_requested.connect(_on_data_requested.bind(field))
	field.value_changed.connect(_on_value_changed.bind(field))


func _on_add_pressed(field: Control) -> void:
	field.is_only_field = false
	field.set_add_button(false)
	field.set_remove_button(true)

	var new_field = LayerField.instantiate()
	add_child(new_field)
	new_field.set_add_button(true)
	new_field.set_remove_button(true)
	new_field.clear_options()

	_hook_signals(new_field)


func _on_removed_pressed(field: Control) -> void:
	var count := get_child_count()
	var node_position := field.get_index()
	var should_notify_change: bool = field.get_value() != ""

	remove_child(field)
	field.queue_free()

	if should_notify_change:
		value_changed.emit()

	if count == 2:
		for c in get_children():
			if c != field:
				var last_node = c
				last_node.set_add_button(true)
				last_node.set_remove_button(false)
				last_node.is_only_field = true
	elif (count - 1) == node_position:
		get_child(count - 2).set_add_button(true)


func _on_data_requested(field: Control) -> void:
	var layers = data_fetcher.call()

	if layers == null:
		return

	var selected_layers = get_selected_layers()

	var valid_values := []

	for l in layers:
		if not selected_layers.has(l) or l == field.get_value():
			valid_values.push_back(l)

	field.populate_field(valid_values)


func _on_value_changed(value: String, field: Control) -> void:
	if value != "" and field.get_index() == get_child_count() - 1:
		field.set_add_button(true)
	value_changed.emit()
