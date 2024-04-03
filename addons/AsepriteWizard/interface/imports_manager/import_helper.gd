@tool
extends RefCounted

const wizard_config = preload("../../config/wizard_config.gd")
const result_code = preload("../../config/result_codes.gd")

var _sprite_animation_creator = preload("../../creators/animation_player/sprite_animation_creator.gd").new()
var _texture_rect_animation_creator = preload("../../creators/animation_player/texture_rect_animation_creator.gd").new()
var _static_texture_creator = preload("../../creators/static_texture/texture_creator.gd").new()
var _sprite_frames_creator = preload("../../creators/sprite_frames/sprite_frames_creator.gd").new()
var _aseprite_file_exporter = preload("../../aseprite/file_exporter.gd").new()
var _config = preload("../../config/config.gd").new()


func _init():
	_aseprite_file_exporter.init(_config)
	_sprite_frames_creator.init(_config)
	_sprite_animation_creator.init(_config)
	_texture_rect_animation_creator.init(_config)
	_static_texture_creator.init(_config)


func import_node(root_node: Node, meta: Dictionary) -> void:
	var node = root_node.get_node(meta.node_path)

	if node == null:
		printerr("Node not found: %s" % meta.node_path)
		return

	if node is AnimatedSprite2D or node is AnimatedSprite3D:
		await _sprite_frames_import(node, meta)
	else:
		await _animation_import(node, root_node, meta)


func _sprite_frames_import(node: Node, resource_config: Dictionary) -> void:
	var config = resource_config.meta
	if not config.source:
		printerr("Node config missing information.")
		return

	var source = ProjectSettings.globalize_path(config.source)
	var options = _parse_import_options(config, resource_config.scene_path.get_base_dir())

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_file(source, options)

	if not aseprite_output.is_ok:
		printerr(result_code.get_error_message(aseprite_output.code))
		return

	EditorInterface.get_resource_filesystem().scan()

	await EditorInterface.get_resource_filesystem().filesystem_changed

	_sprite_frames_creator.create_animations(node, aseprite_output.content, { "slice": options.slice })

	wizard_config.set_source_hash(node, FileAccess.get_md5(source))
	_handle_cleanup(aseprite_output.content)


func _animation_import(node: Node, root_node: Node, resource_config: Dictionary) -> void:
	if not resource_config.meta.source:
		printerr("Node config missing information.")
		return

	if resource_config.meta.get("i_mode", 0) == 0:
		await _import_to_animation_player(node, root_node, resource_config)
	else:
		await _import_static(node, resource_config)


func _import_to_animation_player(node: Node, root: Node, resource_config: Dictionary) -> void:
	var config = resource_config.meta
	var source = ProjectSettings.globalize_path(config.source)
	var options = _parse_import_options(config, resource_config.scene_path.get_base_dir())

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_file(source, options)
	if not aseprite_output.is_ok:
		printerr(result_code.get_error_message(aseprite_output.code))
		return

	EditorInterface.get_resource_filesystem().scan()
	await EditorInterface.get_resource_filesystem().filesystem_changed

	var anim_options = {
		"keep_anim_length": config.keep_anim_length,
		"cleanup_hide_unused_nodes": config.get("set_vis_track"),
		"slice": config.get("slice", ""),
	}
	var animation_creator = _texture_rect_animation_creator if node is TextureRect else _sprite_animation_creator
	animation_creator.create_animations(node, root.get_node(config.player), aseprite_output.content, anim_options)

	wizard_config.set_source_hash(node, FileAccess.get_md5(source))
	_handle_cleanup(aseprite_output.content)


func _import_static(node: Node, resource_config: Dictionary) -> void:
	var config = resource_config.meta
	var source = ProjectSettings.globalize_path(config.source)
	var options = _parse_import_options(config, resource_config.scene_path.get_base_dir())
	options["first_frame_only"] = true

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_file(source, options)

	if not aseprite_output.is_ok:
		printerr(result_code.get_error_message(aseprite_output.code))
		return

	EditorInterface.get_resource_filesystem().scan()
	await EditorInterface.get_resource_filesystem().filesystem_changed

	_static_texture_creator.load_texture(node, aseprite_output.content, { "slice": options.slice })

	wizard_config.set_source_hash(node, FileAccess.get_md5(source))
	_handle_cleanup(aseprite_output.content)


func _parse_import_options(config: Dictionary, scene_base_path: String) -> Dictionary:
	return {
		"output_folder": config.o_folder if config.o_folder != "" else scene_base_path,
		"exception_pattern": config.o_ex_p,
		"only_visible_layers": config.only_visible,
		"output_filename": config.o_name,
		"layer": config.get("layer"),
		"slice": config.get("slice", ""),
	}

func _handle_cleanup(aseprite_content):
	if _config.should_remove_source_files():
		DirAccess.remove_absolute(aseprite_content.data_file)
		EditorInterface.get_resource_filesystem().scan()
