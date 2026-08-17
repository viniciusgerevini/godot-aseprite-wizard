@tool
extends "./static_texture_import_plugin_base.gd"


##
## Static texture importer.
## Imports first frame from Aseprite file as texture
##

func _get_importer_name():
	return "aseprite_wizard.plugin.static-texture"


func _get_visible_name():
	return "Aseprite Texture"


func _get_recognized_extensions():
	return ["aseprite", "ase"]


func _get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_STATIC_TEXTURE_NAME else 0.8


func _get_import_options(_path, _i):
	return [
		{"name": "layer/exclude_layers_pattern", "default_value": config.get_default_exclusion_pattern()},
		{"name": "layer/only_visible_layers", "default_value": false},
		{"name": "layer/split_layers", "default_value": false},
		{"name": "first_frame_only", "default_value": true},
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
			"name": "sheet/scale",
			"default_value": 1,
		},
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

func _import(source_file, save_path, options, platform_variants, gen_files):
	var bake_result = _handle_bake_fallback(source_file, save_path)

	if bake_result != CONTINUE_STATUS_CODE:
		return bake_result

	var absolute_source_file = ProjectSettings.globalize_path(source_file)
	var source_path = source_file.get_base_dir()

	var aseprite_opts = {
		"exception_pattern": options['layer/exclude_layers_pattern'],
		"only_visible_layers": options['layer/only_visible_layers'],
		"split_layers": options.get('layer/split_layers', false),
		"output_filename": '',
		"output_folder": source_path,
		"scale": str(options["sheet/scale"]),
	}

	if options['first_frame_only']:
		aseprite_opts['first_frame_only'] = options['first_frame_only']
	else:
		aseprite_opts['sheet_type'] = options["sheet/sheet_type"]
		aseprite_opts['sheet_columns'] = options["sheet/sheet_columns"]

	var result = _generate_texture(absolute_source_file, aseprite_opts)

	if not result.is_ok:
		logger.error("Could not import aseprite file: %s" % result_codes.get_error_message(result.code), source_file)
		return FAILED

	var sprite_sheet = result.content.sprite_sheet
	var data = result.content.data

	return _save_resource(source_file, sprite_sheet, save_path, result.content.data_file, data.meta.size, {
		"generate": options.get("normalmap/generate", false),
		"params": {
			"emboss_height": options.get("normalmap/emboss_height", 0.1),
			"bump_height": options.get("normalmap/bump_height", 0.3),
			"blur": options.get("normalmap/blur", 5),
			"bump": options.get("normalmap/bump", 60),
		},
		"save_debug_png": options.get("normalmap/save_debug_png", false),
	})
