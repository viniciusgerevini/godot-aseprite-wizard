tool
extends PanelContainer

signal request_edit(import_cfg)
signal request_import(import_cfg)

const SourcePathField = preload("./wizard_nodes/source_path.tscn")
const OutputPathField = preload("./wizard_nodes/output_path.tscn")
const ImportDateField = preload("./wizard_nodes/import_date.tscn")
const ItemActions = preload("./wizard_nodes/list_actions.tscn")

# TODO option: one entry per file (when importing, if file already exists, remove from list)

var _config
var _history: Array

var _history_nodes := {}
var _is_busy := false

onready var grid = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
onready var loading_warning = $MarginContainer/VBoxContainer/loading_warning
onready var no_history_warning = $MarginContainer/VBoxContainer/no_history_warning

func init(config):
	_config = config


func reload():
	if _history:
		return
	_history = _config.get_import_history()

	for index in range(_history.size()):
		var entry = _history[index]
		_add_to_node_list(entry, _create_nodes(entry, index))

	loading_warning.hide()

	if _history.empty():
		no_history_warning.show()
	else:
		grid.get_parent().show()


func _create_nodes(entry: Dictionary, index: int) -> Dictionary:
	var source_path = SourcePathField.instance()
	source_path.set_entry(entry)
	grid.add_child_below_node(grid.get_child(3), source_path)

	var output_path = OutputPathField.instance()
	output_path.text = entry.output_location
	grid.add_child_below_node(source_path, output_path)

	var import_date = ImportDateField.instance()
	import_date.set_date(entry.import_date)
	grid.add_child_below_node(output_path, import_date)

	var actions = ItemActions.instance()
	actions.history_index = index
	grid.add_child_below_node(import_date, actions)

	actions.connect("import_clicked", self, "_on_entry_reimport_clicked")
	actions.connect("edit_clicked", self, "_on_entry_edit_clicked")
	actions.connect("removed_clicked", self, "_on_entry_remove_clicked")

	return {
		"history_index": index,
		"source_path_node": source_path,
		"output_path_node": output_path,
		"import_date_node": import_date,
		"actions_node": actions,
	}

func add_entry(file_settings: Dictionary):
	print(" ADD NEW ENTRY ")
	print(file_settings)
	if not _history:
		reload()
	file_settings["import_date"] = OS.get_unix_time()

	# TODO if unique, remove existing ones, otherwise just add to the list.

	_history.push_back(file_settings)
	_config.save_import_history(_history)
	_add_to_node_list(file_settings, _create_nodes(file_settings, _history.size() - 1))

	no_history_warning.hide()
	grid.get_parent().show()
	_is_busy = false


func _on_entry_reimport_clicked(entry_index: int):
	if _is_busy:
		return
	_is_busy = true
	emit_signal("request_import", _history[entry_index])


func _on_entry_edit_clicked(entry_index: int):
	if _is_busy:
		return
	emit_signal("request_edit", _history[entry_index])


func _on_entry_remove_clicked(entry_index: int):
	if _is_busy:
		return
	_is_busy = true

	_remove_item(entry_index)
	_config.save_import_history(_history)

	if (_history.empty()):
		grid.get_parent().hide()
		no_history_warning.show()

	_is_busy = false


func _remove_item(entry_index: int):
	var entry = _history[entry_index]
	var files_entries = _history_nodes[entry.source_file]

	# removes from node list
	for f in files_entries:
		if f.history_index == entry_index:
			f.source_path_node.queue_free()
			f.output_path_node.queue_free()
			f.import_date_node.queue_free()
			f.actions_node.queue_free()
			files_entries.erase(f)
			break

	_history.remove(entry_index)

	# to avoid re-creating the whole nodes list, I just decrement
	# the index from items newer than the excluded one
	for index in range(entry_index, _history.size()):
		var nodes = _history_nodes[_history[index].source_file]
		for f in nodes:
			if f.history_index > entry_index:
				f.history_index -= 1
				f.actions_node.history_index = f.history_index
				print("update index")


func _add_to_node_list(entry: Dictionary, node: Dictionary):
	if not _history_nodes.has(entry.source_file):
		_history_nodes[entry.source_file] = []
	_history_nodes[entry.source_file].push_back(node)
