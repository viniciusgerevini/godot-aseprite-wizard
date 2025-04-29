@tool
extends EditorImportPlugin

const result_codes = preload("../../config/result_codes.gd")

var config = preload("../../config/config.gd").new()
var _aseprite = preload("../../aseprite/aseprite.gd").new()
var _sf_creator = preload("../../creators/sprite_frames/sprite_frames_creator.gd").new()


func _get_importer_name():
	return "aseprite_wizard.plugin.spriteframes-split-layer"


func _get_visible_name():
	return "Aseprite Layer SpriteFrames"


func _get_recognized_extensions():
	return ["ase_layer"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "SpriteFrames"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_priority():
	return 1.0


func _get_import_order():
	return 1


func _get_import_options(_path, _i):
	return []


func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	var source_path = source_file.get_base_dir()

	var absolute_source_file = ProjectSettings.globalize_path(data.import_options.source)
	
	var export_options = {
		"sheet_type": data.import_options.sheet_type,
		"frame_padding": data.import_options.frame_padding,
		"sheet_columns": data.import_options.sheet_columns,
		"should_round_fps": data.import_options.should_round_fps,
	}
	
	var source_files = _aseprite.export_file_with_layers(
		absolute_source_file,
		[data.layer],
		source_path,
		export_options,
	)

	if source_files.is_empty():
		printerr("ERROR - Could not import aseprite file. Layer not found.")
		return FAILED
#
	var resources = _sf_creator.create_resources([source_files], {
		"should_round_fps": data.import_options.should_round_fps,
		"should_create_portable_texture": true,
		"sheet_base_path": save_path,
	})

	if not resources.is_ok:
		printerr("ERROR - Could not import aseprite file: %s" % result_codes.get_error_message(resources.code))
		return FAILED

	var resource = resources.content[0]
	resource.resource.set_meta("imported_via_aw", true)

	var resource_path = "%s.res" % save_path
	var exit_code = ResourceSaver.save(resource.resource, resource_path)
	resource.resource.take_over_path(resource_path)

	for extra_file in resource.extra_gen_files:
		gen_files.push_back(extra_file)
#
	if config.should_remove_source_files():
		_remove_source_files(source_files)

	if exit_code != OK:
		printerr("ERROR - Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code))
		return FAILED

	return OK


func _remove_source_files(source_files: Dictionary):
	DirAccess.remove_absolute(source_files.data_file)
	DirAccess.remove_absolute(source_files.sprite_sheet)
