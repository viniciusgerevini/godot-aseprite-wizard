@tool
extends PanelContainer

const wizard_config = preload("../../../config/wizard_config.gd")
const result_code = preload("../../../config/result_codes.gd")
var _aseprite_file_exporter = preload("../../../aseprite/file_exporter.gd").new()

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

var scene: Node
var target_node: Node

var config
var file_system: EditorFileSystem

var _import_mode = -1

var _layer: String = ""
var _slice: String = ""
var _source: String = ""
var _animation_player_path: String
var _file_dialog_aseprite: EditorFileDialog
var _output_folder_dialog: EditorFileDialog
var _importing := false

var _output_folder := ""
var _out_folder_default := "[Same as scene]"
var _layer_default := "[all]"

@onready var _section_title: Button = $margin/VBoxContainer/title
# general
@onready var _import_mode_options_field = $margin/VBoxContainer/modes/options
@onready var _animation_player_field = $margin/VBoxContainer/animation_player/options
@onready var _animation_player_container = $margin/VBoxContainer/animation_player
@onready var _source_field = $margin/VBoxContainer/source/button
# layers
@onready var _layer_section_header = $margin/VBoxContainer/extra/sections/layers/section_header
@onready var _layer_section_container = $margin/VBoxContainer/extra/sections/layers/section_content
@onready var _layer_field = $margin/VBoxContainer/extra/sections/layers/section_content/content/layer/options
@onready var _visible_layers_field =  $margin/VBoxContainer/extra/sections/layers/section_content/content/visible_layers/CheckBox
@onready var _ex_pattern_field = $margin/VBoxContainer/extra/sections/layers/section_content/content/ex_pattern/LineEdit
# slice
@onready var _slice_section_header = $margin/VBoxContainer/extra/sections/slices/section_header
@onready var _slice_section_container = $margin/VBoxContainer/extra/sections/slices/section_content
@onready var _slice_field = $margin/VBoxContainer/extra/sections/slices/section_content/content/slice/options
# animation
@onready var _animation_section = $margin/VBoxContainer/extra/sections/animation
@onready var _animation_section_header = $margin/VBoxContainer/extra/sections/animation/section_header
@onready var _animation_section_container = $margin/VBoxContainer/extra/sections/animation/section_content
@onready var _cleanup_hide_unused_nodes_container =  $margin/VBoxContainer/extra/sections/animation/section_content/content/auto_visible_track
@onready var _cleanup_hide_unused_nodes =  $margin/VBoxContainer/extra/sections/animation/section_content/content/auto_visible_track/CheckBox
@onready var _keep_length_container =  $margin/VBoxContainer/extra/sections/animation/section_content/content/keep_length
@onready var _keep_length =  $margin/VBoxContainer/extra/sections/animation/section_content/content/keep_length/CheckBox
# output
@onready var _output_section_header = $margin/VBoxContainer/extra/sections/output/section_header
@onready var _output_section_container = $margin/VBoxContainer/extra/sections/output/section_content
@onready var _out_folder_field = $margin/VBoxContainer/extra/sections/output/section_content/content/out_folder/button
@onready var _out_filename_field = $margin/VBoxContainer/extra/sections/output/section_content/content/out_filename/LineEdit

var _interface_section_state
const INTERFACE_SECTION_KEY_LAYER = "layer_section"
const INTERFACE_SECTION_KEY_SLICE = "slice_section"
const INTERFACE_SECTION_KEY_ANIMATION = "animation_section"
const INTERFACE_SECTION_KEY_OUTPUT = "output_section"


@onready var _expandable_sections = {
	INTERFACE_SECTION_KEY_LAYER: { "header": _layer_section_header, "content": _layer_section_container},
	INTERFACE_SECTION_KEY_SLICE: { "header": _slice_section_header, "content": _slice_section_container},
	INTERFACE_SECTION_KEY_ANIMATION: { "header": _animation_section_header, "content": _animation_section_container},
	INTERFACE_SECTION_KEY_OUTPUT: { "header": _output_section_header, "content": _output_section_container},
}

func _ready():
	_setup_interface()
	var cfg = wizard_config.load_config(target_node)
	if cfg == null:
		_load_default_config()
	else:
		_load_config(cfg)

	if target_node is Sprite2D || target_node is Sprite3D:
		animation_creator = SpriteAnimationCreator.new()
	if target_node is TextureRect:
		animation_creator = TextureRectAnimationCreator.new()

	static_texture_creator = StaticTextureCreator.new()

	animation_creator.init(config)
	_aseprite_file_exporter.init(config)
	static_texture_creator.init(config)


func _setup_interface():
	var cfg = wizard_config.load_interface_config(target_node)
	_interface_section_state = cfg

	_section_title.add_theme_stylebox_override("normal", _section_title.get_theme_stylebox("hover"))

	for key in _expandable_sections:
		_adjust_section_visibility(key)


func _load_config(cfg):
	if cfg.has("source"):
		_set_source(cfg.source)

	if cfg.has("player"):
		_animation_player_field.clear()
		_set_animation_player(cfg.player)

	if cfg.get("layer", "") != "":
		_layer_field.clear()
		_set_layer(cfg.layer)

	if cfg.get("slice", "") != "":
		_slice_field.clear()
		_set_slice(cfg.slice)

	_set_out_folder(cfg.get("o_folder", ""))
	_out_filename_field.text = cfg.get("o_name", "")
	_visible_layers_field.button_pressed = cfg.get("only_visible", false)
	_ex_pattern_field.text = cfg.get("o_ex_p", "")
	_cleanup_hide_unused_nodes.button_pressed = cfg.get("set_vis_track", config.is_set_visible_track_automatically_enabled())
	_keep_length.button_pressed = cfg.get("keep_anim_length", false)

	_set_import_mode(int(cfg.get("i_mode", 0)))


func _load_default_config():
	_ex_pattern_field.text = config.get_default_exclusion_pattern()
	_visible_layers_field.button_pressed = config.should_include_only_visible_layers_by_default()
	_cleanup_hide_unused_nodes.button_pressed = config.is_set_visible_track_automatically_enabled()
	#_set_options_visible(false)


func _set_source(source):
	_source = source
	_source_field.text = _source
	_source_field.tooltip_text = _source


func _set_animation_player(player):
	_animation_player_path = player
	_animation_player_field.add_item(_animation_player_path)


func _set_layer(layer):
	_layer = layer
	_layer_field.add_item(_layer)


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


func _on_options_button_down():
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


func _on_options_item_selected(index):
	if index == 0:
		_animation_player_path = ""
		return
	_animation_player_path = _animation_player_field.get_item_text(index)
	_save_config()


func _on_layer_button_down():
	if _source == "":
		_show_message("Please. Select source file first.")
		return

	var layers = animation_creator.list_layers(ProjectSettings.globalize_path(_source))
	_populate_options_field(_layer_field, layers, _layer)


func _on_layer_item_selected(index):
	if index == 0:
		_layer = ""
		return
	_layer = _layer_field.get_item_text(index)
	_save_config()


func _set_slice(slice):
	_slice = slice
	_slice_field.add_item(_slice)


func _on_slice_item_selected(index):
	if index == 0:
		_slice = ""
		return
	_slice = _slice_field.get_item_text(index)
	_save_config()


func _on_slice_button_down():
	if _source == "":
		_show_message("Please, select source file first.")
		return

	var slices = animation_creator.list_slices(ProjectSettings.globalize_path(_source))
	var current = 0
	_slice_field.clear()
	_slice_field.add_item(_layer_default)

	for s in slices:
		if s == "":
			continue

		_slice_field.add_item(s)
		if s == _slice:
			current = _slice_field.get_item_count() - 1
	_slice_field.select(current)



func _on_source_pressed():
	_open_source_dialog()


func _on_import_pressed():
	if _importing:
		return
	_importing = true

	if _import_mode == ImportMode.IMAGE:
		_import_static()
		return

	_import_for_animation_player()

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

	if _source == "":
		_show_message("Aseprite file not selected")
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

	_handle_cleanup(aseprite_output.content)

##
## Import first frame from aseprite file as node texture
##
func _import_static():
	if _source == "":
		_show_message("Aseprite file not selected")
		_importing = false
		return

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
	_handle_cleanup(aseprite_output.content)


##
## Save current import options to node metadata
##
func _save_config():
	var cfg := {
		"i_mode": _import_mode,
		"player": _animation_player_path,
		"source": _source,
		"layer": _layer,
		"slice": _slice,
		#"op_exp": _options_title.button_pressed,
		"o_folder": _output_folder,
		"o_name": _out_filename_field.text,
		"only_visible": _visible_layers_field.button_pressed,
		"o_ex_p": _ex_pattern_field.text,
		"keep_anim_length": _keep_length.button_pressed,
	}

	if _cleanup_hide_unused_nodes.button_pressed != config.is_set_visible_track_automatically_enabled():
		cfg["set_vis_track"] = _cleanup_hide_unused_nodes.button_pressed

	wizard_config.save_config(target_node, config.is_use_metadata_enabled(), cfg)


func _open_source_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != "":
		_file_dialog_aseprite.current_dir = ProjectSettings.globalize_path(_source.get_base_dir())
	_file_dialog_aseprite.popup_centered_ratio()


func _create_aseprite_file_selection():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected",Callable(self,"_on_aseprite_file_selected"))
	file_dialog.set_filters(PackedStringArray(["*.ase","*.aseprite"]))
	return file_dialog


func _on_aseprite_file_selected(path):
	_set_source(ProjectSettings.localize_path(path))
	_save_config()
	_file_dialog_aseprite.queue_free()


func _show_message(message: String):
	var _warning_dialog = AcceptDialog.new()
	get_parent().add_child(_warning_dialog)
	_warning_dialog.dialog_text = message
	_warning_dialog.popup_centered()
	_warning_dialog.connect("popup_hide",Callable(_warning_dialog,"queue_free"))


func _on_out_folder_pressed():
	_output_folder_dialog = _create_output_folder_selection()
	get_parent().add_child(_output_folder_dialog)
	if _output_folder != _out_folder_default:
		_output_folder_dialog.current_dir = _output_folder
	_output_folder_dialog.popup_centered_ratio()


func _create_output_folder_selection():
	var file_dialog = EditorFileDialog.new()
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	file_dialog.connect("dir_selected",Callable(self,"_on_output_folder_selected"))
	return file_dialog


func _on_output_folder_selected(path):
	_set_out_folder(path)
	_output_folder_dialog.queue_free()


func _on_source_aseprite_file_dropped(path):
	_set_source(path)
	_save_config()


func _on_animation_player_node_dropped(node_path):
	var node = get_node(node_path)
	var root = get_tree().get_edited_scene_root()

	_animation_player_path = root.get_path_to(node)

	for i in range(_animation_player_field.get_item_count()):
		if _animation_player_field.get_item_text(i) == _animation_player_path:
			_animation_player_field.select(i)
			break
	_save_config()


func _on_out_dir_dropped(path):
	_set_out_folder(path)


func _set_out_folder(path):
	_output_folder = path
	_out_folder_field.text = _output_folder if _output_folder != "" else _out_folder_default
	_out_folder_field.tooltip_text = _out_folder_field.text


func _on_modes_item_selected(index):
	var id = _import_mode_options_field.get_item_id(index)
	_import_mode = id
	_handle_import_mode()


## Helper method to populate field with values
func _populate_options_field(field: OptionButton, values: Array, current_name: String):
	var current = 0
	field.clear()
	field.add_item("[all]")

	for v in values:
		if v == "":
			continue

		field.add_item(v)
		if v == current_name:
			current = field.get_item_count() - 1
	field.select(current)


func _handle_cleanup(aseprite_content):
	if config.should_remove_source_files():
		DirAccess.remove_absolute(aseprite_content.data_file)
		file_system.call_deferred("scan")


func _notify_aseprite_error(aseprite_error_code):
	var error = result_code.get_error_message(aseprite_error_code)
	printerr(error)
	_show_message(error)


func _get_import_options(default_folder: String):
	return {
		"output_folder": _output_folder if _output_folder != "" else default_folder,
		"exception_pattern": _ex_pattern_field.text,
		"only_visible_layers": _visible_layers_field.button_pressed,
		"output_filename": _out_filename_field.text,
		"layer": _layer
	}


func _adjust_icon(section: Button, is_visible: bool = true) -> void:
	var icon_name = "GuiTreeArrowDown" if is_visible else "GuiTreeArrowRight"
	section.icon = get_theme_icon(icon_name, "EditorIcons")


func _on_layer_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_LAYER)


func _on_slice_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_SLICE)


func _on_animation_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_ANIMATION)


func _on_output_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_OUTPUT)


func _toggle_section_visibility(key: String) -> void:
	_interface_section_state[key] = not _interface_section_state.get(key, false)
	_adjust_section_visibility(key)
	wizard_config.save_interface_config(target_node, _interface_section_state)


func _adjust_section_visibility(key: String) -> void:
	var section = _expandable_sections[key]
	var is_visible = _interface_section_state.get(key, false)
	_adjust_icon(section.header, is_visible)
	section.content.visible = is_visible
