@tool
extends PanelContainer

const wizard_config = preload("../config/wizard_config.gd")
const result_code = preload("../config/result_codes.gd")
var animation_creator = preload("animation_creator.gd").new()

var scene: Node
var sprite: Sprite2D

var config
var file_system: EditorFileSystem

var _layer: String = ""
var _source: String = ""
var _animation_player_path: String
var _file_dialog_aseprite: FileDialog
var _output_folder_dialog: FileDialog
var _importing := false

var _output_folder := ""
var _out_folder_default := "[Same as scene]"

@onready var _options_field = $margin/VBoxContainer/animation_player/options
@onready var _source_field = $margin/VBoxContainer/source/button
@onready var _layer_field = $margin/VBoxContainer/layer/options
@onready var _options_title = $margin/VBoxContainer/options_title/options_title
@onready var _options_container = $margin/VBoxContainer/options
@onready var _out_folder_field = $margin/VBoxContainer/options/out_folder/button
@onready var _out_filename_field = $margin/VBoxContainer/options/out_filename/LineEdit
@onready var _visible_layers_field =  $margin/VBoxContainer/options/visible_layers/CheckButton
@onready var _ex_pattern_field = $margin/VBoxContainer/options/ex_pattern/LineEdit

func _ready():
	var cfg = wizard_config.decode(sprite.editor_description)

	if cfg == null:
		_load_default_config()
	else:
		_load_config(cfg)

	animation_creator.init(config, file_system)


func _load_config(cfg):
	if cfg.has("source"):
		_set_source(cfg.source)

	if cfg.has("player"):
		_set_animation_player(cfg.player)

	if cfg.get("layer", "") != "":
		_set_layer(cfg.layer)

	_output_folder = cfg.get("o_folder", "")
	_out_folder_field.text = _output_folder if _output_folder != "" else _out_folder_default
	_out_filename_field.text = cfg.get("o_name", "")
	_visible_layers_field.button_pressed = cfg.get("only_visible", "") == "True"
	_ex_pattern_field.text = cfg.get("o_ex_p", "")

	_set_options_visible(cfg.get("op_exp", "false") == "True")


func _load_default_config():
	_ex_pattern_field.text = config.get_default_exclusion_pattern()
	_set_options_visible(false)


func _set_source(source):
	_source = source
	_source_field.text = _source
	_source_field.hint_tooltip = _source


func _set_animation_player(player):
	_animation_player_path = player
	_options_field.add_item(_animation_player_path)


func _set_layer(layer):
	_layer = layer
	_layer_field.add_item(_layer)


func _on_options_pressed():
	var animation_players = []
	var root = get_tree().get_edited_scene_root()
	_find_animation_players(root, root, animation_players)

	var current = 0
	_options_field.clear()
	_options_field.add_item("[empty]")

	for ap in animation_players:
		_options_field.add_item(ap)
		if ap == NodePath(_animation_player_path):
			current = _options_field.get_item_count() - 1

	_options_field.select(current)


func _find_animation_players(root: Node, node: Node, players: Array):
	if node is AnimationPlayer:
		players.push_back(root.get_path_to(node))

	for c in node.get_children():
		_find_animation_players(root, c, players)


func _on_options_item_selected(index):
	if index == 0:
		_animation_player_path = ""
		return
	_animation_player_path = _options_field.get_item_text(index)
	_save_config()


func _on_layer_pressed():
	if _source == "":
		_show_message("Please. Select source file first.")
		return

	var layers = animation_creator.list_layers(ProjectSettings.globalize_path(_source))
	var current = 0
	_layer_field.clear()
	_layer_field.add_item("[all]")

	for l in layers:
		if l == "":
			continue

		_layer_field.add_item(l)
		if l == _layer:
			current = _layer_field.get_item_count() - 1
	_layer_field.select(current)


func _on_layer_item_selected(index):
	if index == 0:
		_layer = ""
		return
	_layer = _layer_field.get_item_text(index)
	_save_config()


func _on_source_pressed():
	_open_source_dialog()


func _on_import_pressed():
	if _importing:
		return
	_importing = true

	var root = get_tree().get_edited_scene_root()

	if _animation_player_path == "" or not root.has_node(_animation_player_path):
		_show_message("AnimationPlayer not found")
		_importing = false
		return

	if _source == "":
		_show_message("Aseprite file not selected")
		_importing = false
		return

	var options = {
		"source": ProjectSettings.globalize_path(_source),
		"output_folder": _output_folder if _output_folder != "" else root.scene_file_path.get_base_dir(),
		"exception_pattern": _ex_pattern_field.text,
		"only_visible_layers": _visible_layers_field.button_pressed,
		"output_filename": _out_filename_field.text,
		"layer": _layer
	}

	_save_config()

	animation_creator.create_animations(sprite, root.get_node(_animation_player_path), options)
	_importing = false


func _save_config():
	sprite.editor_description = wizard_config.encode({
		"player": _animation_player_path,
		"source": _source,
		"layer": _layer,
		"op_exp": _options_title.button_pressed,
		"o_folder": _output_folder,
		"o_name": _out_filename_field.text,
		"only_visible": _visible_layers_field.button_pressed,
		"o_ex_p": _ex_pattern_field.text
	})


func _open_source_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != "":
		_file_dialog_aseprite.current_dir = _source.get_base_dir()
	_file_dialog_aseprite.popup_centered_ratio()


func _create_aseprite_file_selection():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected", _on_aseprite_file_selected)
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
	_warning_dialog.connect("popup_hide", _warning_dialog.queue_free)


func _on_options_title_toggled(button_pressed):
	_set_options_visible(button_pressed)
	_save_config()


func _set_options_visible(is_visible):
	_options_container.visible = is_visible
	_options_title.icon = config.get_icon_arrow_down() if is_visible else config.get_icon_arrow_right()


func _on_out_folder_pressed():
	_output_folder_dialog = _create_output_folder_selection()
	get_parent().add_child(_output_folder_dialog)
	if _output_folder != _out_folder_default:
		_output_folder_dialog.current_dir = _output_folder
	_output_folder_dialog.popup_centered_ratio()


func _create_output_folder_selection():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.connect("dir_selected", _on_output_folder_selected)
	return file_dialog


func _on_output_folder_selected(path):
	_output_folder = path
	_out_folder_field.text = _output_folder if _output_folder != "" else _out_folder_default
	_output_folder_dialog.queue_free()
