@tool
extends "../base_inspector_dock.gd"

const AnimationCreator = preload("../../../creators/animation_player/animation_creator.gd")
const SpriteAnimationCreator = preload("../../../creators/animation_player/sprite_animation_creator.gd")
const TextureRectAnimationCreator = preload("../../../creators/animation_player/texture_rect_animation_creator.gd")
const StaticTextureCreator = preload("../../../creators/static_texture/texture_creator.gd")

enum ImportMode {
	ANIMATION = 0,
	IMAGE = 1
}

var animation_creator: AnimationCreator
var static_texture_creator: StaticTextureCreator

var _import_mode = -1
var _animation_player_path: String

@onready var _import_mode_options_field := $dock_fields/VBoxContainer/modes/options as OptionButton
@onready var _animation_player_field := $dock_fields/VBoxContainer/animation_player/options as OptionButton
@onready var _animation_player_container := $dock_fields/VBoxContainer/animation_player as HBoxContainer

# animation
@onready var _animation_section := $dock_fields/VBoxContainer/extra/sections/animation as VBoxContainer
@onready var _animation_section_header := $dock_fields/VBoxContainer/extra/sections/animation/section_header as Button
@onready var _animation_section_container := $dock_fields/VBoxContainer/extra/sections/animation/section_content as MarginContainer
@onready var _cleanup_hide_unused_nodes :=  $dock_fields/VBoxContainer/extra/sections/animation/section_content/content/auto_visible_track/CheckBox as CheckBox
@onready var _keep_length :=  $dock_fields/VBoxContainer/extra/sections/animation/section_content/content/keep_length/CheckBox as CheckBox

const INTERFACE_SECTION_KEY_ANIMATION = "animation_section"


func _pre_setup():
	_expandable_sections[INTERFACE_SECTION_KEY_ANIMATION] = { "header": _animation_section_header, "content": _animation_section_container}


func _setup():
	if target_node is Sprite2D || target_node is Sprite3D:
		animation_creator = SpriteAnimationCreator.new()
	if target_node is TextureRect:
		animation_creator = TextureRectAnimationCreator.new()

	static_texture_creator = StaticTextureCreator.new()

	_setup_animation_fields_listeners()


func _load_config(cfg):
	if cfg.has("player"):
		_animation_player_field.clear()
		_set_animation_player(cfg.player)

	_cleanup_hide_unused_nodes.button_pressed = cfg.get("set_vis_track", config.is_set_visible_track_automatically_enabled())
	_keep_length.button_pressed = cfg.get("keep_anim_length", false)
	_set_import_mode(int(cfg.get("i_mode", 0)))


func _load_default_config():
	_cleanup_hide_unused_nodes.button_pressed = config.is_set_visible_track_automatically_enabled()


func _set_animation_player(player):
	_animation_player_path = player
	_animation_player_field.add_item(_animation_player_path)


func _set_import_mode(import_mode):
	if _import_mode == import_mode:
		return

	_import_mode = import_mode
	var index = _import_mode_options_field.get_item_index(import_mode)
	_import_mode_options_field.select(index)
	_handle_import_mode()


func _handle_import_mode():
	match _import_mode:
		ImportMode.ANIMATION:
			_animation_player_container.show()
			_animation_section.show()
		ImportMode.IMAGE:
			_animation_player_container.hide()
			_animation_section.hide()


func _setup_animation_fields_listeners():
	_animation_section_header.button_down.connect(_on_animation_header_button_down)
	_animation_player_field.node_dropped.connect(_on_animation_player_node_dropped)
	_animation_player_field.button_down.connect(_on_animation_player_button_down)
	_animation_player_field.item_selected.connect(_on_animation_player_item_selected)

	_import_mode_options_field.item_selected.connect(_on_modes_item_selected)


func _on_animation_player_button_down():
	_refresh_animation_players()


func _refresh_animation_players():
	var animation_players = []
	var root = get_tree().get_edited_scene_root()
	_find_animation_players(root, root, animation_players)

	var current = 0
	_animation_player_field.clear()
	_animation_player_field.add_item("[empty]")

	for ap in animation_players:
		_animation_player_field.add_item(ap)
		if ap.get_concatenated_names() == _animation_player_path:
			current = _animation_player_field.get_item_count() - 1

	_animation_player_field.select(current)


func _find_animation_players(root: Node, node: Node, players: Array):
	if node is AnimationPlayer:
		players.push_back(root.get_path_to(node))

	for c in node.get_children():
		_find_animation_players(root, c, players)


func _on_animation_player_item_selected(index):
	if index == 0:
		_animation_player_path = ""
		return
	_animation_player_path = _animation_player_field.get_item_text(index)
	#_save_config()
	_update_pending_fields()


func _do_import():
	if _import_mode == ImportMode.IMAGE:
		await _import_static()
		return

	await _import_for_animation_player()

##
## Import aseprite animations to target AnimationPlayer and set
## spritesheet as the node's texture
##
func _import_for_animation_player():
	var root = get_tree().get_edited_scene_root()

	if _animation_player_path == "" or not root.has_node(_animation_player_path):
		_show_message("AnimationPlayer not found")
		_importing = false
		return

	var source_path = ProjectSettings.globalize_path(_source)

	var options = _get_import_options(root.scene_file_path.get_base_dir())

	_save_config()

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_file(source_path, options)

	if not aseprite_output.is_ok:
		_notify_aseprite_error(aseprite_output.code)
		return

	file_system.scan()
	await file_system.filesystem_changed

	var anim_options = {
		"keep_anim_length": _keep_length.button_pressed,
		"cleanup_hide_unused_nodes": _cleanup_hide_unused_nodes.button_pressed,
		"slice": _slice,
	}

	animation_creator.create_animations(target_node, root.get_node(_animation_player_path), aseprite_output.content, anim_options)
	_importing = false

	wizard_config.set_source_hash(target_node, FileAccess.get_md5(source_path))
	_handle_cleanup(aseprite_output.content)

##
## Import first frame from aseprite file as node texture
##
func _import_static():
	var source_path = ProjectSettings.globalize_path(_source)
	var root = get_tree().get_edited_scene_root()

	var options = _get_import_options(root.scene_file_path.get_base_dir())
	options["first_frame_only"] = true

	_save_config()

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_file(source_path, options)

	if not aseprite_output.is_ok:
		_notify_aseprite_error(aseprite_output.code)
		return

	file_system.scan()
	await file_system.filesystem_changed

	static_texture_creator.load_texture(target_node, aseprite_output.content, { "slice": _slice })

	_importing = false
	wizard_config.set_source_hash(target_node, FileAccess.get_md5(source_path))
	_handle_cleanup(aseprite_output.content)


func _get_current_field_values() -> Dictionary:
	var cfg := {
		"i_mode": _import_mode,
		"player": _animation_player_path,
		"keep_anim_length": _keep_length.button_pressed,
	}

	if _cleanup_hide_unused_nodes.button_pressed != config.is_set_visible_track_automatically_enabled():
		cfg["set_vis_track"] = _cleanup_hide_unused_nodes.button_pressed

	return cfg


func _get_available_layers(global_source_path: String) -> Array:
	return animation_creator.list_layers(global_source_path)


func _get_available_slices(global_source_path: String) -> Array:
	return animation_creator.list_slices(global_source_path)


func _on_animation_player_node_dropped(node_path):
	var node = get_node(node_path)
	var root = get_tree().get_edited_scene_root()

	_animation_player_path = root.get_path_to(node)

	for i in range(_animation_player_field.get_item_count()):
		if _animation_player_field.get_item_text(i) == _animation_player_path:
			_animation_player_field.select(i)
			break
	#_save_config()
	_update_pending_fields()


func _on_modes_item_selected(index):
	var id = _import_mode_options_field.get_item_id(index)
	_import_mode = id
	_handle_import_mode()


func _on_animation_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_ANIMATION)


func _show_specific_fields():
	_import_mode_options_field.get_parent().show()
	_animation_player_container.show()
	_animation_section.show()
