@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")
const logger = preload("../config/logger.gd")

var config = preload("../config/config.gd").new()
var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()
var _sf_creator = preload("../creators/sprite_frames/sprite_frames_creator.gd").new()
var _bakery = preload("./helpers/bakery.gd").new()
var _normal_map_generator = preload("../normalmap/normal_map_generator.gd")
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
		{"name": "normalmap/generate", "default_value": config.is_normalmap_enabled()},
		{
			"name": "normalmap/emboss_height",
			"default_value": config.get_normalmap_emboss_height(),
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,100,0.01",
		},
		{
			"name": "normalmap/bump_height",
			"default_value": config.get_normalmap_bump_height(),
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,100,0.01",
		},
		{
			"name": "normalmap/blur",
			"default_value": config.get_normalmap_blur(),
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,10,1",
		},
		{
			"name": "normalmap/bump",
			"default_value": config.get_normalmap_bump(),
			"property_hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,500,1",
		},
		{"name": "normalmap/save_debug_png", "default_value": false},
	]


func _get_option_visibility(path, option, options):
	if option.begins_with("normalmap/") and option != "normalmap/generate":
		return options.get("normalmap/generate", false)
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var resource_path = "%s.res" % save_path
	var is_baking_enabled = config.should_generate_bake_files()

	if not _aseprite_file_exporter.is_aseprite_command_working():
		if is_baking_enabled && _bakery.has_bake_file(source_file):
			logger.warn("Aseprite command failed. Falling back to baked file...", source_file)
			return _bakery.load_bake_file(source_file, resource_path)
		else:
			return ERR_UNCONFIGURED

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
		logger.error("Could not import aseprite file: %s" % result_codes.get_error_message(source_files.code), source_file)
		return FAILED

	var resources = _sf_creator.create_resources(source_files.content, {
		"should_round_fps": options["animation/round_fps"],
		"should_create_portable_texture": true,
		"normalmap_generate": options.get("normalmap/generate", false),
		"normalmap_params": {
			"emboss_height": options.get("normalmap/emboss_height", 0.1),
			"bump_height": options.get("normalmap/bump_height", 0.3),
			"blur": options.get("normalmap/blur", 5),
			"bump": options.get("normalmap/bump", 60),
		},
	})

	if not resources.is_ok:
		logger.error("Could not import aseprite file: %s" % result_codes.get_error_message(resources.code), source_file)
		return FAILED

	var resource: Dictionary = resources.content[0]
	resource.resource.set_meta("imported_via_aw", true)
	var exit_code = ResourceSaver.save(resource.resource, resource_path)
	resource.resource.take_over_path(resource_path)
	ResourceLoader.load(resource_path, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)

	if is_baking_enabled:
		var bake_code = _bakery.save_bake_file(source_file, resource.resource)
		if bake_code != OK:
			logger.error('Bake file creation failed (%s)' % bake_code, source_file)


	if config.should_remove_source_files():
		_remove_source_files(source_files.content)

	# Save debug normal map PNGs if requested
	if options.get("normalmap/generate", false) and options.get("normalmap/save_debug_png", false):
		for s in source_files.content:
			var sheet_path: String = s.sprite_sheet
			var global_sheet = ProjectSettings.globalize_path(sheet_path)
			# Even if source files were removed, we still have the image in the resource.
			# Load from the original path if it still exists, otherwise skip.
			if FileAccess.file_exists(global_sheet) or FileAccess.file_exists(sheet_path):
				var img = Image.load_from_file(global_sheet)
				if img:
					var normal_img = _normal_map_generator.generate_normal_map(img, options.get("normalmap/params", {}))
					var base = sheet_path.get_basename()
					normal_img.save_png(ProjectSettings.globalize_path(base + "_n.png"))

	if exit_code != OK:
		logger.error("Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code), source_file)
		return FAILED

	return OK


func _remove_source_files(source_files: Array):
	for s in source_files:
		DirAccess.remove_absolute(s.data_file)
		DirAccess.remove_absolute(s.sprite_sheet)
