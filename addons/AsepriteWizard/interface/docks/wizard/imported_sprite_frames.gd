@tool
extends PanelContainer

signal import_success(fields)

const result_code = preload("../../../config/result_codes.gd")
const wizard_config = preload("../../../config/wizard_config.gd")
var _import_helper = preload("./wizard_import_helper.gd").new()

@onready var _tree_container = $MarginContainer/HSplitContainer/tree
@onready var _resource_tree = _tree_container.get_resource_tree()
@onready var _nothing_container = $MarginContainer/HSplitContainer/MarginContainer/VBoxContainer/nothing
@onready var _single_item_container = $MarginContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item
@onready var _multiple_items_container = $MarginContainer/HSplitContainer/MarginContainer/VBoxContainer/multiple_items
@onready var _confirmation_warning_container = $MarginContainer/HSplitContainer/MarginContainer/VBoxContainer/confirmation_warning

var _selection_count = 0

var _current_container = null
var _resources_to_process = null

var _is_loaded = false

var _groups = {}

func init_resources():
	if _is_loaded:
		return
	_is_loaded = true
	var file_tree = _get_file_tree("res://")
	_setup_tree(file_tree)


func _get_file_tree(base_path: String, dir_name: String = "") -> Dictionary:
	var dir_path = base_path.path_join(dir_name)
	var dir = DirAccess.open(dir_path)
	var dir_data = { "path": dir_path, "name": dir_name, "children": [], "type": "dir", }
	if not dir:
		return dir_data

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if dir.current_is_dir() and _is_importable_folder(dir_path, file_name):
			var child_data = _get_file_tree(dir_path, file_name)
			if not child_data.children.is_empty():
				dir_data.children.push_back(child_data)
		elif file_name.ends_with(".res"):
			var resource_path = dir_path.path_join(file_name)
			var resource = ResourceLoader.load(resource_path)
			if resource is SpriteFrames:
				if resource.has_meta(wizard_config.WIZARD_CONFIG_META_NAME):
					var meta = resource.get_meta(wizard_config.WIZARD_CONFIG_META_NAME)
					var parent_node = dir_data

					if meta.group != "":
						var group
						if _groups.has(meta.group):
							group = _groups[meta.group]
						else:
							group = { "folders": {} }
							_groups[meta.group] = group

						if not group.folders.has(dir_path):
							group.folders[dir_path] = {
								"node": {
									"type": "group",
									"name": "Split: %s" % meta.fields.source_file.get_file(),
									"has_moved": meta.fields.output_location != dir_path,
									"path": meta.fields.source_file,
									"folder": dir_path,
									"has_changes": _has_source_changes(resource, meta),
									"children": [],
								}
							}
							parent_node.children.push_back(group.folders[dir_path].node)

						parent_node = group.folders[dir_path].node

					parent_node.children.push_back({
						"type": "resource",
						"resource_type": "SpriteFrames",
						"name": resource.resource_path.get_file(),
						"path": resource.resource_path,
						"meta": meta,
						"has_changes": _has_source_changes(resource, meta),
						"has_moved": meta.fields.output_location != dir_path,
					})

		file_name = dir.get_next()

	return dir_data


func _is_importable_folder(dir_path: String, dir_name: String) -> bool:
	return dir_path != "res://" or dir_name != "addons"


func _setup_tree(resource_tree: Dictionary) -> void:
	var root = _resource_tree.create_item()
	_add_items_to_tree(root, resource_tree.children)


func _add_items_to_tree(root: TreeItem, children: Array):
	for node in children:
		var item: TreeItem = _resource_tree.create_item(root)
		item.set_text(0, node.name)
		item.set_meta("node", node)
		match node.type:
			"dir":
				item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
				_add_items_to_tree(item, node.children)
#
			"group":
				item.set_icon(0, get_theme_icon("CompressedTexture2D", "EditorIcons"))
				_add_items_to_tree(item, node.children)
				if node.has_changes:
					item.set_text(0, "%s (*)" % node.name)
				if node.has_moved:
					item.set_suffix(0, "(moved)")
			"resource":
				item.set_icon(0, get_theme_icon(node.resource_type, "EditorIcons"))
				if node.has_changes:
					item.set_text(0, "%s (*)" % node.name)
				if node.meta.group != "":
					item.set_custom_color(0, item.get_icon_modulate(0).darkened(0.5))
					item.set_selectable(0, false)
				elif node.has_moved:
					item.set_suffix(0, "(moved)")


func _has_source_changes(resource: Object, meta: Dictionary) -> bool:
	var current_hash = FileAccess.get_md5(meta.fields.source_file)
	var saved_hash = wizard_config.get_source_hash(resource)

	return saved_hash != current_hash


func _is_supported_type(resource_type: String) -> bool:
	return resource_type == "SpriteFrames"


func reload_tree():
	_confirmation_warning_container.hide()
	_resources_to_process = null
	if _current_container != null:
		_current_container.show_buttons()
		_current_container = null

	_groups = {}
	_selection_count = 0
	_resource_tree.clear()
	var file_tree = _get_file_tree("res://")
	_setup_tree(file_tree)


func _set_empty_details_state():
	_nothing_container.show()
	_single_item_container.hide()
	_multiple_items_container.hide()


func _on_tree_multi_selected(item: TreeItem, column: int, selected: bool):
	_confirmation_warning_container.hide()
	_resources_to_process = null
	if _current_container != null:
		_current_container.show_buttons()
#
	if selected:
		_selection_count += 1
	else:
		_selection_count -= 1
#
	_nothing_container.hide()
	_single_item_container.hide()
	_multiple_items_container.hide()
#
	match _selection_count:
		0:
			_nothing_container.show()
		1:
			_single_item_container.show()
			_set_item_details(_resource_tree.get_selected())
			_current_container = _single_item_container
		_:
			_multiple_items_container.show()
			_multiple_items_container.set_selected_count(_selection_count)
			_current_container = _multiple_items_container


func _set_item_details(item: TreeItem) -> void:
	if not item.has_meta("node"):
		return
	var data = item.get_meta("node")
	_single_item_container.set_resource_details(data)


func _on_single_item_import_triggered():
	var selected = _resource_tree.get_selected()
	var meta = selected.get_meta("node")

	match meta.type:
		"dir":
			var selected_item = _resource_tree.get_selected()
			var all_resources = []
			var scenes_to_open = _set_all_resources(selected_item.get_meta("node"), all_resources)
			_resources_to_process = all_resources
			_show_confirmation_message(all_resources.size())
		"resource":
			var code = await _do_import(meta.path, meta.meta)
			_set_tree_item_as_saved(_resource_tree.get_selected())
			_single_item_container.hide_source_change_warning()
			if code == OK:
				EditorInterface.get_resource_filesystem().scan()
		"group":
			var first_item = meta.children[0]
			var code = await _do_import(first_item.path, first_item.meta)
			_set_tree_item_as_saved(selected)
			_single_item_container.hide_source_change_warning()
			if code == OK:
				EditorInterface.get_resource_filesystem().scan()
				_on_tree_refresh_triggered()


func _on_confirmation_warning_warning_confirmed():
	_confirmation_warning_container.hide()
	_current_container.show_buttons()

	for resource in _resources_to_process:
		await _do_import(resource.path, resource.meta)

	_resources_to_process = null
	EditorInterface.get_resource_filesystem().scan()
	_on_tree_refresh_triggered()


func _on_confirmation_warning_warning_declined():
	_confirmation_warning_container.hide()
	_current_container.show_buttons()
	_resources_to_process = null


func _on_tree_refresh_triggered():
	_set_empty_details_state()
	reload_tree()


func _set_tree_item_as_saved(item: TreeItem) -> void:
	var meta = item.get_meta("node")
	meta.has_changes = false
	meta.has_moved = false
	item.set_meta("node", meta)
	item.set_text(0, meta.name)
	item.set_suffix(0, "")


func _do_import(resource_path: String, metadata: Dictionary) -> int:
	var resource_base_dir = resource_path.get_base_dir()

	if resource_base_dir != metadata.fields.output_location:
		print("Resource has moved. Changing output folder from %s to %s" % [resource_base_dir, metadata.fields.output_location])
		metadata.fields.output_location = resource_base_dir

	var exit_code := await _import_helper.import_and_create_resources(metadata.fields.source_file, metadata.fields)

	if exit_code == OK:
		print("Import complete: %s" % resource_path)
		import_success.emit(metadata.fields)
	else:
		printerr("Failed to import %s. Error: %s" % [resource_path, result_code.get_error_message(exit_code)])

	return exit_code


func _set_all_resources(meta: Dictionary, resources: Array):
	match meta.type:
		"dir":
			for c in meta.children:
				_set_all_resources(c, resources)
		"resource":
			if not resources.has(meta):
				resources.push_back(meta)
		"group":
			var first_item = meta.children[0]
			resources.push_back(first_item)


func _show_confirmation_message(resources: int):
	_current_container.hide_buttons()
	_confirmation_warning_container.set_message("You are about to re-import %s resources. Do you wish to continue?" % resources)
	_confirmation_warning_container.show()


func _on_multiple_items_import_triggered():
	var selected_item = _resource_tree.get_next_selected(null)
	var all_resources = []

	while selected_item != null:
		_set_all_resources(selected_item.get_meta("node"), all_resources)
		selected_item = _resource_tree.get_next_selected(selected_item)

	_resources_to_process = all_resources
	_show_confirmation_message(all_resources.size())
