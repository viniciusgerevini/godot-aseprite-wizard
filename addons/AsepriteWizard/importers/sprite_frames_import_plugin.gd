@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")

var config = preload("../config/config.gd").new()
var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()
var _sf_creator = preload("../creators/sprite_frames/sprite_frames_creator.gd").new()
var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()


func _get_importer_name():
	return "aseprite_wizard.plugin.spriteframes"


func _get_visible_name():
	return "Aseprite SpriteFrames"


func _get_recognized_extensions():
	return ["aseprite", "ase"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "SpriteFrames"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_SPRITEFRAMES_NAME else 1.0


func _get_import_order():
	return 1


func _get_import_options(_path, _i):
	return [
		{"name": "layer/exclude_layers_pattern", "default_value": config.get_default_exclusion_pattern()},
		{"name": "layer/only_visible_layers",    "default_value": false},
		{
			"name": "sheet/sheet_type",
			"default_value": "packed",
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "columns,horizontal,vertical,packed",
		},
		{
			"name": "sheet/sheet_columns",
			"default_value": 12,
		},
		{
			"name": "sheet/frame_padding",
			"default_value": 0,
		},
		{
			"name": "sheet/scale",
			"default_value": 1,
		},
		{"name": "animation/round_fps", "default_value": true},
	]


func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var absolute_source_file = ProjectSettings.globalize_path(source_file)
	var absolute_save_path = ProjectSettings.globalize_path(save_path)

	var source_path = source_file.get_base_dir()
	var source_basename = source_file.substr(source_path.length()+1, -1)
	source_basename = source_basename.substr(0, source_basename.rfind('.'))

	var aseprite_opts = {
		"export_mode": _sf_creator.FILE_EXPORT_MODE,
		"exception_pattern": options['layer/exclude_layers_pattern'],
		"only_visible_layers": options['layer/only_visible_layers'],
		"output_filename": '',
		"output_folder": source_path,
		"sheet_type": options["sheet/sheet_type"],
		"frame_padding": options["sheet/frame_padding"],
		"sheet_columns": options["sheet/sheet_columns"],
		"scale": str(options["sheet/scale"]),
	}

	var source_files = _aseprite_file_exporter.generate_aseprite_files(absolute_source_file, aseprite_opts)
	if not source_files.is_ok:
		printerr("ERROR - Could not import aseprite file: %s" % result_codes.get_error_message(source_files.code))
		return FAILED

	var resources = _sf_creator.create_resources(source_files.content, {
		"should_round_fps": options["animation/round_fps"],
		"should_create_portable_texture": true,
		"sheet_base_path": save_path,
	})

	if not resources.is_ok:
		printerr("ERROR - Could not import aseprite file: %s" % result_codes.get_error_message(resources.code))
		return FAILED

	var resource: Dictionary = resources.content[0]
	resource.resource.set_meta("imported_via_aw", true)
	var resource_path = "%s.res" % save_path
	var exit_code = ResourceSaver.save(resource.resource, resource_path)
	resource.resource.take_over_path(resource_path)

	#for extra_file in resource.extra_gen_files:
		#gen_files.push_back(extra_file)

	if config.should_remove_source_files():
		_remove_source_files(source_files.content)

	if exit_code != OK:
		printerr("ERROR - Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code))
		return FAILED

	return OK


func _remove_source_files(source_files: Array):
	for s in source_files:
		DirAccess.remove_absolute(s.data_file)
		DirAccess.remove_absolute(s.sprite_sheet)
