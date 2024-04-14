@tool
extends PanelContainer

signal request_edit(import_cfg)
signal request_import(import_cfg)

const SourcePathField = preload("./wizard_nodes/source_path.tscn")
const OutputPathField = preload("./wizard_nodes/output_path.tscn")
const ImportDateField = preload("./wizard_nodes/import_date.tscn")
const ItemActions = preload("./wizard_nodes/list_actions.tscn")
const DetailsField = preload("./wizard_nodes/details.tscn")

const SORT_BY_DATE := 0
const SORT_BY_PATH := 1
const INITIAL_GRID_INDEX := 4

var _config = preload("../../../config/config.gd").new()
var _history: Array
var _history_nodes := {}
var _history_nodes_list := []
var _is_busy := false
var _import_requested_for := -1
var _sort_by = SORT_BY_DATE

@onready var grid = $MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var loading_warning = $MarginContainer/VBoxContainer/loading_warning
@onready var no_history_warning = $MarginContainer/VBoxContainer/no_history_warning


func reload():
	if _history:
		return

	if _config.has_old_history():
		_migrate_history()

	_history = _config.get_import_history()

	for index in range(_history.size()):
		var entry = _history[index]
		_create_node_list_entry(entry, index)

	loading_warning.hide()
	if _history.is_empty():
		no_history_warning.show()
	else:
		grid.get_parent().show()


func _create_node_list_entry(entry: Dictionary, index: int):
	_add_to_node_list(entry, _create_nodes(entry, index))


func _create_nodes(entry: Dictionary, index: int) -> Dictionary:
	var import_date = ImportDateField.instantiate()
	import_date.set_date(entry.import_date)

	var source_path = SourcePathField.instantiate()
	source_path.set_entry(entry)

	var output_path = OutputPathField.instantiate()
	output_path.text = entry.output_location
	output_path.tooltip_text = entry.output_location

	var details = DetailsField.instantiate()
	details.set_details(entry)

	var actions = ItemActions.instantiate()
	actions.history_index = index
	actions.connect("import_clicked",Callable(self,"_on_entry_reimport_clicked"))
	actions.connect("edit_clicked",Callable(self,"_on_entry_edit_clicked"))
	actions.connect("removed_clicked",Callable(self,"_on_entry_remove_clicked"))


	grid.get_child(INITIAL_GRID_INDEX).add_sibling(import_date)
	import_date.add_sibling(source_path)
	source_path.add_sibling(output_path)
	output_path.add_sibling(details)
	details.add_sibling(actions)

	return {
		"history_index": index,
		"timestamp": entry.import_date,
		"source_file": entry.source_file,
		"source_path_node": source_path,
		"output_path_node": output_path,
		"import_date_node": import_date,
		"actions_node": actions,
		"details_node": details,
	}


func _add_to_node_list(entry: Dictionary, node: Dictionary):
	if not _history_nodes.has(entry.source_file):
		_history_nodes[entry.source_file] = []
	_history_nodes[entry.source_file].push_front(node)
	_history_nodes_list.push_front(node)


func add_entry(file_settings: Dictionary):
	if _history == null:
		reload()
#
	var dt = Time.get_datetime_dict_from_system()
	file_settings["import_date"] = "%04d-%02d-%02d %02d:%02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second]
#
	if _import_requested_for != -1:
		_remove_item(_import_requested_for)
		_import_requested_for = -1
	elif _history.size() > _config.get_history_max_entries():
		_remove_entries(_history[0].source_file, 0)
#
	_history.push_back(file_settings)
	_config.save_import_history(_history)
	_create_node_list_entry(file_settings, _history.size() - 1)

	if _sort_by == SORT_BY_PATH:
		_trigger_sort()

	no_history_warning.hide()
	loading_warning.hide()
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

	if (_history.is_empty()):
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

	_history.remove_at(entry_index)


func _free_entry_nodes(entry_history_node: Dictionary):
	entry_history_node.source_path_node.queue_free()
	entry_history_node.output_path_node.queue_free()
	entry_history_node.import_date_node.queue_free()
	entry_history_node.actions_node.queue_free()
	entry_history_node.details_node.queue_free()


func _on_SortOptions_item_selected(index):
	if index == _sort_by:
		return

	_trigger_sort(index)


func _trigger_sort(sort_type: int = _sort_by):
	if sort_type == SORT_BY_DATE:
		_history_nodes_list.sort_custom(Callable(self,"_sort_by_date"))
	else:
		_history_nodes_list.sort_custom(Callable(self,"_sort_by_path"))
	_reorganise_nodes()
	_sort_by = sort_type


func _sort_by_date(a, b):
	return a.timestamp < b.timestamp


func _sort_by_path(a, b):
	return a.source_file > b.source_file


func _reorganise_nodes():
	for entry in _history_nodes_list:
		grid.move_child(entry.import_date_node, INITIAL_GRID_INDEX + 1)
		grid.move_child(entry.source_path_node, INITIAL_GRID_INDEX + 2)
		grid.move_child(entry.output_path_node, INITIAL_GRID_INDEX + 3)
		grid.move_child(entry.details_node, INITIAL_GRID_INDEX + 4)
		grid.move_child(entry.actions_node, INITIAL_GRID_INDEX + 5)


func _migrate_history():
	var history = _config.get_old_import_history()
	var new_history = []

	for index in range(history.size()):
		var entry = history[index]
		new_history.push_back({
			"split_layers": true if entry.options.export_mode else false,
			"only_visible_layers": entry.options.only_visible_layers,
			"layer_exclusion_pattern": entry.options.exception_pattern,
			"output_name": entry.options.output_filename,
			"source_file": entry.source_file,
			"do_not_create_resource": entry.options.do_not_create_resource,
			"output_location": entry.output_location,
			"import_date": entry.import_date,
		})

	_config.save_import_history(new_history)
	_config.remove_old_history_setting()
