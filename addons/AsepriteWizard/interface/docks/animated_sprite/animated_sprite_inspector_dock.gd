@tool
extends "../base_inspector_dock.gd"

var sprite_frames_creator = preload("../../../creators/sprite_frames/sprite_frames_creator.gd").new()

@onready var _animation_section := $dock_fields/VBoxContainer/extra/sections/animation_sf as VBoxContainer
@onready var _animation_section_header := $dock_fields/VBoxContainer/extra/sections/animation_sf/section_header as Button
@onready var _animation_section_container := $dock_fields/VBoxContainer/extra/sections/animation_sf/section_content as MarginContainer
@onready var _round_fps :=  $dock_fields/VBoxContainer/extra/sections/animation_sf/section_content/content/round_fps/CheckBox as CheckBox
const INTERFACE_SECTION_KEY_ANIMATION = "animation_section"


func _pre_setup():
	_expandable_sections[INTERFACE_SECTION_KEY_ANIMATION] = { "header": _animation_section_header, "content": _animation_section_container}


func _setup():
	_animation_section_header.button_down.connect(_on_animation_header_button_down)


func _load_config(cfg):
	_round_fps.button_pressed = cfg.get("should_round_fps", true)


func _get_available_layers(global_source_path: String) -> Array:
	return sprite_frames_creator.list_layers(global_source_path)


func _get_available_slices(global_source_path: String) -> Array:
	return sprite_frames_creator.list_slices(global_source_path)


func _do_import():
	var root = get_tree().get_edited_scene_root()

	var source_path = ProjectSettings.globalize_path(_source)
	var options = _get_import_options(root.scene_file_path.get_base_dir())

	_save_config()

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_file(source_path, options)

	if not aseprite_output.is_ok:
		var error = result_code.get_error_message(aseprite_output.code)
		printerr(error)
		_show_message(error)
		return

	file_system.scan()
	await file_system.filesystem_changed

	sprite_frames_creator.create_animations(target_node, aseprite_output.content, {
		"slice": _slice,
		"should_round_fps": _round_fps.button_pressed,
		"should_create_portable_texture": _embed_field.button_pressed,
	})

	wizard_config.set_source_hash(target_node, FileAccess.get_md5(source_path))

	_handle_cleanup(aseprite_output.content, _embed_field.button_pressed)


func _show_specific_fields():
	_animation_section.show()


func _get_current_field_values() -> Dictionary:
	return {
		"should_round_fps": _round_fps.button_pressed,
	}


func _on_animation_header_button_down():
	_toggle_section_visibility(INTERFACE_SECTION_KEY_ANIMATION)
