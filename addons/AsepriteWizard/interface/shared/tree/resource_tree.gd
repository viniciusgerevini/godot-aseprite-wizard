@tool
extends VBoxContainer

signal refresh_triggered
signal multi_selected(item: TreeItem, column: int, selected: bool)

@onready var _tree: Tree = $Tree

func _on_tree_filter_change_finished(text):
	var tree_root: TreeItem = _tree.get_root()

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


func _on_expand_all_pressed():
	var tree_root: TreeItem = _tree.get_root()
	tree_root.set_collapsed_recursive(false)


func _on_collapse_all_pressed():
	var tree_root: TreeItem = _tree.get_root()
	tree_root.set_collapsed_recursive(true)
	tree_root.collapsed = false


func _on_refresh_tree_pressed():
	refresh_triggered.emit()


func _on_tree_multi_selected(item: TreeItem, column: int, selected: bool):
	multi_selected.emit(item, column, selected)


func get_resource_tree() -> Tree:
	return _tree
