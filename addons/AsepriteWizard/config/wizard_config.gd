@tool
extends RefCounted

const WIZARD_CONFIG_META_NAME = "_aseprite_wizard_config_"
const WIZARD_INTERFACE_CONFIG_META_NAME = "_aseprite_wizard_interface_config_"
const SOURCE_FILE_HASH_META_NAME = "_aseprite_wizard_source_file_hash_"


static func load_config(node: Object):
	if node.has_meta(WIZARD_CONFIG_META_NAME):
		return node.get_meta(WIZARD_CONFIG_META_NAME)

	return {}


static func save_config(node: Object, cfg: Dictionary):
	node.set_meta(WIZARD_CONFIG_META_NAME, cfg)


static func has_config(node: Object) -> bool:
	return node.has_meta(WIZARD_CONFIG_META_NAME)


static func load_interface_config(node: Node, default: Dictionary = {}) -> Dictionary:
	if node.has_meta(WIZARD_INTERFACE_CONFIG_META_NAME):
		return node.get_meta(WIZARD_INTERFACE_CONFIG_META_NAME)
	return default


static func save_interface_config(node: Node, cfg:Dictionary) -> void:
	node.set_meta(WIZARD_INTERFACE_CONFIG_META_NAME, cfg)


static func set_source_hash(node: Object, hash: String) -> void:
	node.set_meta(SOURCE_FILE_HASH_META_NAME, hash)


static func get_source_hash(node: Object) -> String:
	if node.has_meta(SOURCE_FILE_HASH_META_NAME):
		return node.get_meta(SOURCE_FILE_HASH_META_NAME)
	return ""
