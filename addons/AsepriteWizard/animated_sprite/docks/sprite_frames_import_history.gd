tool
extends PanelContainer

signal request_edit(import_cfg)
signal request_import(import_cfg)

const SourcePathField = preload("./wizard_nodes/source_path.tscn")
const OutputPathField = preload("./wizard_nodes/output_path.tscn")
const ImportDateField = preload("./wizard_nodes/import_date.tscn")
const ItemActions = preload("./wizard_nodes/list_actions.tscn")

const SORT_BY_DATE := 0
const SORT_BY_PATH := 1
const INITIAL_GRID_INDEX := 3

var _config
var _history: Array
var _history_nodes := {}
var _history_nodes_list := []
var _is_busy := false
var _import_requested_for := -1
var _sort_by = SORT_BY_DATE

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
		_create_node_list_entry(entry, index)

	loading_warning.hide()

	if _history.empty():
		no_history_warning.show()
	else:
		grid.get_parent().show()


func _create_node_list_entry(entry: Dictionary, index: int):
	_add_to_node_list(entry, _create_nodes(entry, index))


func _create_nodes(entry: Dictionary, index: int) -> Dictionary:
	var source_path = SourcePathField.instance()
	source_path.set_entry(entry)

	grid.add_child_below_node(grid.get_child(INITIAL_GRID_INDEX), source_path)

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
		"timestamp": entry.import_date,
		"source_file": entry.source_file,
		"source_path_node": source_path,
		"output_path_node": output_path,
		"import_date_node": import_date,
		"actions_node": actions,
	}


func _add_to_node_list(entry: Dictionary, node: Dictionary):
	if not _history_nodes.has(entry.source_file):
		_history_nodes[entry.source_file] = []
	_history_nodes[entry.source_file].push_front(node)
	_history_nodes_list.push_front(node)


func add_entry(file_settings: Dictionary):
	if not _history:
		reload()

	var dt = OS.get_datetime()
	file_settings["import_date"] = "%04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]

	if _import_requested_for != -1:
		_remove_item(_import_requested_for)
		_import_requested_for = -1
	elif _config.is_single_file_history() and _history_nodes.has(file_settings.source_file):
		_remove_entries(file_settings.source_file)

	_history.push_back(file_settings)
	_config.save_import_history(_history)
	_create_node_list_entry(file_settings, _history.size() - 1)

	if _sort_by == SORT_BY_PATH:
		_trigger_sort()

	no_history_warning.hide()
	grid.get_parent().show()
	_is_busy = false


func _on_entry_reimport_clicked(entry_index: int):
	if _is_busy:
		return
	_is_busy = true
	_import_requested_for = entry_index
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
	_remove_entries(entry.source_file, entry_index)


# removes nodes and entry from history. If entry_index is not provided, all
# entries for path are removed.
func _remove_entries(source_file_path: String, entry_index: int = -1):
	var files_entries = _history_nodes[source_file_path]
	var indexes_to_remove = []

	for f in files_entries:
		if entry_index == -1 or f.history_index == entry_index:
			_free_entry_nodes(f)
			_history_nodes_list.erase(f)

			if entry_index != -1:
				files_entries.erase(f)
				_remove_from_history(f.history_index)
				return

			indexes_to_remove.push_back(f.history_index)

	for i in indexes_to_remove:
		_remove_from_history(i)

	_history_nodes[source_file_path] = []


func _remove_from_history(entry_index: int):
	var _already_adjusted = []
	# to avoid re-creating the whole nodes list, I just decrement
	# the index from items newer than the excluded one
	for index in range(entry_index + 1, _history.size()):
		if _already_adjusted.has(_history[index].source_file):
			continue
		_already_adjusted.push_back(_history[index].source_file)
		var nodes = _history_nodes[_history[index].source_file]
		for f in nodes:
			if f.history_index > entry_index:
				f.history_index -= 1
				f.actions_node.history_index = f.history_index

	_history.remove(entry_index)


func _free_entry_nodes(entry_history_node: Dictionary):
	entry_history_node.source_path_node.queue_free()
	entry_history_node.output_path_node.queue_free()
	entry_history_node.import_date_node.queue_free()
	entry_history_node.actions_node.queue_free()


func _on_SortOptions_item_selected(index):
	if index == _sort_by:
		return

	_trigger_sort(index)


func _trigger_sort(sort_type: int = _sort_by):
	if sort_type == SORT_BY_DATE:
		_history_nodes_list.sort_custom(self, "_sort_by_date")
	else:
		_history_nodes_list.sort_custom(self, "_sort_by_path")
	_reorganise_nodes()
	_sort_by = sort_type


func _sort_by_date(a, b):
	return a.timestamp < b.timestamp


func _sort_by_path(a, b):
	return a.source_file > b.source_file


func _reorganise_nodes():
	for entry in _history_nodes_list:
		grid.move_child(entry.source_path_node, INITIAL_GRID_INDEX + 1)
		grid.move_child(entry.output_path_node, INITIAL_GRID_INDEX + 2)
		grid.move_child(entry.import_date_node, INITIAL_GRID_INDEX + 3)
		grid.move_child(entry.actions_node, INITIAL_GRID_INDEX + 4)
