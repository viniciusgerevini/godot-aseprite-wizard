@tool
extends Panel

const wizard_config = preload("../../config/wizard_config.gd")

var _import_helper = preload("./import_helper.gd").new()

@onready var _resource_tree = $MarginContainer/VBoxContainer/HSplitContainer/VBoxContainer/Tree
@onready var _details = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer

@onready var _nothing_container = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/nothing
@onready var _single_item_container = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item
@onready var _multiple_items_container = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/multiple_items

@onready var _name = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/name_value
@onready var _type = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/type_value
@onready var _path = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/path_value

@onready var _source = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/source_file_value
@onready var _layer = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/layer_value
@onready var _slice = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/slice_value
@onready var _o_name = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/o_name_value

@onready var _source_label = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/source_file_label
@onready var _layer_label = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/layer_label
@onready var _slice_label = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/slice_label
@onready var _o_name_label = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/GridContainer/o_name_label

@onready var _resource_buttons = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/resource_buttons
@onready var _dir_buttons = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/dir_buttons
@onready var _file_buttons = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/scene_buttons

@onready var _multiple_import_message = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/multiple_items/multiple
@onready var _multiple_import_button = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/multiple_items/buttons/import_selected

@onready var _confirmation_warning_container = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/confirmation_warning
@onready var _confirmation_warning_message = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/confirmation_warning/MarginContainer/warning_message

@onready var _tree_buttons = $MarginContainer/VBoxContainer/HSplitContainer/VBoxContainer/buttons

@onready var _source_change_warning = $MarginContainer/VBoxContainer/HSplitContainer/MarginContainer/VBoxContainer/single_item/source_changed_warning

@onready var _option_fields = [
	_source,
	_layer,
	_slice,
	_o_name,
	_source_label,
	_layer_label,
	_slice_label,
	_o_name_label,
]

const supported_types = [
	"Sprite2D",
	"Sprite3D",
	"AnimatedSprite2D",
	"AnimatedSprite3D",
	"TextureRect",
]

var _selection_count = 0
var _current_buttons_container
var _resources_to_process

var _should_save_in = 0

func _ready():
	_set_empty_details_state()
	_configure_source_warning()

	var file_tree = _get_file_tree("res://")
	_setup_tree(file_tree)


# Unfortunately godot throws some nasty warnings when trying to save after
# multiple import operations. I implemented this late save as a workaround
func _process(delta):
	if _should_save_in > 0:
		_should_save_in -= delta
		if _should_save_in <= 0:
			_should_save_in = 0
			_save_all_scenes()


func _configure_source_warning():
	var sb = _source_change_warning.get_theme_stylebox("panel")
	var color = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
	color.a = 0.2
	sb.bg_color = color
	_source_change_warning.get_node("MarginContainer/HBoxContainer/Icon").texture = get_theme_icon("NodeInfo", "EditorIcons")
	_source_change_warning.hide()


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
		elif file_name.ends_with(".tscn"):
			var file_path = dir_path.path_join(file_name)
			var metadata = _get_aseprite_metadata(file_path)
			if not metadata.is_empty():
				dir_data.children.push_back({
					"name": file_name,
					"path": file_path,
					"resources": metadata,
					"type": "file",
				})

		file_name = dir.get_next()

	return dir_data


func _is_importable_folder(dir_path: String, dir_name: String) -> bool:
	return dir_path != "res://" or dir_name != "addons"


func _setup_tree(resource_tree: Dictionary) -> void:
	_resource_tree.set_column_title(0, "Resource")

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

			"file":
				item.set_icon(0, get_theme_icon("PackedScene", "EditorIcons"))
				_add_items_to_tree(item, node.resources)

			"resource":
				item.set_icon(0, get_theme_icon(node.node_type, "EditorIcons"))
				if node.has_changes:
					item.set_text(0, "%s (*)" % node.name)


func _get_aseprite_metadata(file_path: String) -> Array:
	var scene: PackedScene = load(file_path)
	var root = scene.instantiate()
	var state = scene.get_state()

	var resources = []
	for i in range(state.get_node_count()):
		var node_type = state.get_node_type(i)
		if _is_supported_type(node_type):
			var node_path = state.get_node_path(i)
			var target_node = root.get_node(node_path)
			var meta = wizard_config.load_config(target_node)
			if meta != null:
				resources.push_back({
					"type": "resource",
					"node_type": node_type,
					"name": node_path,
					"node_path": node_path,
					"node_name": state.get_node_name(i),
					"meta": meta,
					"scene_path": file_path,
					"has_changes": _has_source_changes(target_node, meta.get("source"))
				})

	return resources


func _has_source_changes(target_node: Node, source_path: String) -> bool:
	if not source_path or source_path == "":
		return false
	var saved_hash = wizard_config.get_source_hash(target_node)
	if saved_hash == "":
		return false
	var current_hash = FileAccess.get_md5(source_path)

	return saved_hash != current_hash


func _is_supported_type(node_type: String) -> bool:
	return supported_types.has(node_type)


func _open_scene(item: TreeItem) -> void:
	var meta = item.get_meta("node")
	if meta:
		EditorInterface.open_scene_from_path(meta.path)


func _trigger_import(meta: Dictionary) -> void:
	# A more elegant way would have been to change the PackedScene directly, however
	# during my attempts changing external resources this way was buggy. I decided
	# to open and edit the scene via editor with the caveat of having to keep it open afterwards.
	EditorInterface.open_scene_from_path(meta.scene_path)

	var root_node = EditorInterface.get_edited_scene_root()

	if not root_node:
		printerr("couldn´t open scene %s" % meta.scene_path)

	await _import_helper.import_node(root_node, meta)

	print("Import complete: %s (%s) node from %s" % [ meta.node_path, meta.meta.source, meta.scene_path])


func _on_tree_multi_selected(_item: TreeItem, _column: int, selected: bool) -> void:
	_confirmation_warning_container.hide()
	_resources_to_process = null
	if _current_buttons_container != null:
		_current_buttons_container.show()

	if selected:
		_selection_count += 1
	else:
		_selection_count -= 1

	_nothing_container.hide()
	_single_item_container.hide()
	_multiple_items_container.hide()

	match _selection_count:
		0:
			_nothing_container.show()
		1:
			_single_item_container.show()
			_set_item_details(_resource_tree.get_selected())
		_:
			_multiple_items_container.show()
			_multiple_import_message.text = "%2d items selected" % _selection_count
			_current_buttons_container = _multiple_import_button


func _set_item_details(item: TreeItem) -> void:
	if not item.has_meta("node"):
		return
	var data = item.get_meta("node")

	_dir_buttons.hide()
	_resource_buttons.hide()
	_file_buttons.hide()

	match data.type:
		"dir":
			_name.text = data.name
			_type.text = "Folder"
			_path.text = data.path
			_hide_option_fields()
			_dir_buttons.show()
			_current_buttons_container = _dir_buttons
		"file":
			_name.text = data.name
			_type.text = "File"
			_path.text = data.path
			_hide_option_fields()
			_file_buttons.show()
			_current_buttons_container = _file_buttons
		"resource":
			_name.text = data.node_name
			_type.text = data.node_type
			_path.text = data.node_path

			var meta = data.meta
			_source.text = meta.source
			_layer.text = "All" if meta.get("layer", "") == "" else meta.layer
			_slice.text = "All" if meta.get("slice", "") == "" else meta.slice

			var folder = data.scene_path.get_base_dir() if meta.get("o_folder", "") == "" else meta.o_folder
			var file_name = "" if meta.get("o_name", "") == "" else meta.o_name

			if _layer.text != "All":
				file_name += _layer.text
			elif file_name == "":
				file_name = meta.source.get_basename().get_file()
			_o_name.text = "%s/%s.png" % [folder, file_name]

			_show_option_fields()
			_resource_buttons.show()
			_current_buttons_container = _resource_buttons
			
			_source_change_warning.visible = data.has_changes


func _hide_option_fields() -> void:
	for o in _option_fields:
		o.hide()


func _show_option_fields() -> void:
	for o in _option_fields:
		o.show()


func _on_import_pressed():
	await _trigger_import(_resource_tree.get_selected().get_meta("node"))
	_set_tree_item_as_saved(_resource_tree.get_selected())
	_source_change_warning.hide()
	EditorInterface.save_scene()


func _on_import_all_pressed():
	var selected_item = _resource_tree.get_selected()
	var all_resources = []
	var scenes_to_open = _set_all_resources(selected_item.get_meta("node"), all_resources)
	_resources_to_process = all_resources
	_show_confirmation_message(scenes_to_open, all_resources.size())


func _on_import_selected_pressed():
	var selected_item = _resource_tree.get_next_selected(null)
	var all_resources = []
	var scenes_to_open = 0

	while selected_item != null:
		scenes_to_open += _set_all_resources(selected_item.get_meta("node"), all_resources)
		selected_item = _resource_tree.get_next_selected(selected_item)

	_resources_to_process = all_resources
	_show_confirmation_message(scenes_to_open, all_resources.size())


func _on_show_dir_in_fs_pressed():
	var selected_item = _resource_tree.get_selected()
	var meta = selected_item.get_meta("node")
	EditorInterface.get_file_system_dock().navigate_to_path(meta.path)


func _on_open_scene_pressed():
	var selected_item = _resource_tree.get_selected()
	var meta = selected_item.get_meta("node")
	if meta.type == "file":
		EditorInterface.open_scene_from_path(meta.path)
	else:
		EditorInterface.open_scene_from_path(meta.scene_path)


func _set_all_resources(meta: Dictionary, resources: Array):
	var scenes_to_open = 0
	match meta.type:
		"dir":
			for c in meta.children:
				scenes_to_open += _set_all_resources(c, resources)
		"file":
			scenes_to_open += 1
			for r in meta.resources:
				if not resources.has(r):
					resources.push_back(r)
		"resource":
			if not resources.has(meta):
				resources.push_back(meta)
	return scenes_to_open


func _on_import_confirm_pressed():
	_confirmation_warning_container.hide()
	_current_buttons_container.show()

	for resource in _resources_to_process:
		await _trigger_import(resource)
		EditorInterface.mark_scene_as_unsaved()
	_resources_to_process = null

	_should_save_in = 1
	

func _save_all_scenes():
	EditorInterface.save_all_scenes()
	_reload_tree()


func _on_import_cancel_pressed():
	_confirmation_warning_container.hide()
	_current_buttons_container.show()
	_resources_to_process = null


func _show_confirmation_message(scenes: int, resources: int):
	_current_buttons_container.hide()
	if scenes > 1:
		_confirmation_warning_message.text = "You are about to open %s scenes and re-import %s resources. Do you wish to continue?" % [scenes, resources]
	else:
		_confirmation_warning_message.text = "You are about to re-import %s resources. Do you wish to continue?" % resources

	_confirmation_warning_container.show()


func _on_expand_all_pressed():
	var tree_root: TreeItem = _resource_tree.get_root()
	tree_root.set_collapsed_recursive(false)


func _on_collapse_all_pressed():
	var tree_root: TreeItem = _resource_tree.get_root()
	tree_root.set_collapsed_recursive(true)
	tree_root.collapsed = false


func _on_refresh_tree_pressed():
	_set_empty_details_state()
	_reload_tree()


func _reload_tree():
	_confirmation_warning_container.hide()
	_resources_to_process = null
	if _current_buttons_container != null:
		_current_buttons_container.show()
		_current_buttons_container = null

	_selection_count = 0
	_resource_tree.clear()
	var file_tree = _get_file_tree("res://")
	_setup_tree(file_tree)


func _set_empty_details_state():
	_nothing_container.show()
	_single_item_container.hide()
	_multiple_items_container.hide()


func _on_tree_filter_change_finished(text: String):
	var tree_root: TreeItem = _resource_tree.get_root()

	if text == "":
		tree_root.call_recursive("set", "visible", true)
		return
	tree_root.call_recursive("set", "visible", false)

	_make_matching_children_visible(tree_root, text.to_lower())

func _make_matching_children_visible(tree_root: TreeItem, text: String) -> void:
	for c in tree_root.get_children():
		if c.get_text(0).to_lower().contains(text):
			c.visible = true
			_ensure_parent_visible(c)
		_make_matching_children_visible(c, text)


func _ensure_parent_visible(tree_item: TreeItem) -> void:
	var node_parent = tree_item.get_parent()
	if node_parent != null and not node_parent.visible:
		node_parent.visible = true
		_ensure_parent_visible(node_parent)


func _set_tree_item_as_saved(item: TreeItem) -> void:
	var meta = item.get_meta("node")
	meta.has_changes = false
	item.set_meta("node", meta)
	item.set_text(0, meta.name)
