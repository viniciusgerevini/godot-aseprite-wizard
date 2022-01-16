tool
extends PanelContainer

var result_code = preload("../config/result_codes.gd")
var animation_creator = preload("animation_creator.gd").new()

# TODO options
# TODO load pre-saved config if option not availabel in cache

var scene: Node
var sprite: Sprite

var config
var file_system: EditorFileSystem

var _source: String = ""
var _animation_player_path: String
var _file_dialog_aseprite: FileDialog
var _output_folder_dialog: FileDialog
var _warning_dialog: AcceptDialog
var _importing := false

onready var _options_field = $VBoxContainer/animation_player/options
onready var _source_field = $VBoxContainer/source/button

func _ready():
	var description = _decode_config(sprite.editor_description)

	if _is_wizard_config(description):
		_load_config(description)

	animation_creator.init(config, file_system)


func _decode_config(editor_description: String) -> String:
	var description = ""
	if editor_description != "":
		description = Marshalls.base64_to_utf8(editor_description)
		if description == null:
			description = ""
	return description


func _is_wizard_config(description: String) -> bool:
	return description.begins_with("aseprite_wizard_config")


func _load_config(description):
	var cfg = description.split("\n")
	var config = {}
	for c in cfg:
		var parts = c.split("|=", 1)
		print(parts)
		if parts.size() == 2:
			config[parts[0].strip_edges()] = parts[1].strip_edges()

	if config.has("source"):
		_set_source(config.source)
	
	if config.has("player"):
		_set_animation_player(config.player)
	print(config)


func _set_source(source):
	_source = source
	_source_field.text = _source
	_source_field.hint_tooltip = _source


func _set_animation_player(player):
	_animation_player_path = player
	_options_field.add_item(_animation_player_path)


func _on_options_pressed():
	var animation_players = []
	var root = get_tree().get_edited_scene_root()
	_find_animation_players(root, root, animation_players)
	
	var current = 0
	_options_field.clear()
	_options_field.add_item("[empty]")

	for ap in animation_players:
		_options_field.add_item(ap)
		if ap == _animation_player_path:
			current = _options_field.get_item_count() - 1

	_options_field.select(current)


func _find_animation_players(root: Node, node: Node, players: Array):
	if node is AnimationPlayer:
		players.push_back(root.get_path_to(node))

	for c in node.get_children():
		_find_animation_players(root, c, players)


func _on_options_item_selected(index):
	print("selected")
	_animation_player_path = _options_field.get_item_text(index)
	print(_animation_player_path)
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
		"output_folder": root.filename.get_base_dir(),
#		"export_mode": export_mode,
		"exception_pattern": "",
		"only_visible_layers": false,
		"trim_images": false,
		"trim_by_grid": false,
		"output_filename": "something_new"
	}
	
	var exit_code = animation_creator.create_animations(sprite, root.get_node(_animation_player_path), options)
	if exit_code is GDScriptFunctionState:
		exit_code = yield(exit_code, "completed")
	
	if exit_code == 0:
		_show_message("Import completed")
	else:
		_show_message(result_code.get_error_message(exit_code))

	_importing = false



func _save_config():
	var text = "aseprite_wizard_config\n"
	if _animation_player_path != "":
		text += "player|= %s\n" % _animation_player_path
	if _source != "":
		text += "source|= %s\n" % _source
	sprite.editor_description = Marshalls.utf8_to_base64(text)


func _open_source_dialog():
	_file_dialog_aseprite = _create_aseprite_file_selection()
	get_parent().add_child(_file_dialog_aseprite)
	if _source != "":
		_file_dialog_aseprite.current_dir = _source.get_base_dir()
	_file_dialog_aseprite.popup_centered_ratio()


func _create_aseprite_file_selection():
	var file_dialog = FileDialog.new()
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.connect("file_selected", self, "_on_aseprite_file_selected")
	file_dialog.set_filters(PoolStringArray(["*.ase","*.aseprite"]))
	return file_dialog


func _on_aseprite_file_selected(path):
	_set_source(ProjectSettings.localize_path(path))
	_save_config()
	_file_dialog_aseprite.queue_free()


func _show_message(message: String):
	_warning_dialog = AcceptDialog.new()
	get_parent().add_child(_warning_dialog)
	_warning_dialog.dialog_text = message
	_warning_dialog.popup_centered()
	_warning_dialog.connect("popup_hide", _warning_dialog, "queue_free")
