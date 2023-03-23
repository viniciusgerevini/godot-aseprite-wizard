@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")

var config
var _sf_creator = preload("sprite_frames_creator.gd").new()
var file_system: EditorFileSystem

func _get_importer_name():
	return "aseprite_wizard.plugin"


func _get_visible_name():
	return "Aseprite SpriteFrames Importer"


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
	return 1.0


func _get_import_order():
	return 1


func _get_import_options(_path, _i):
	return [
		{"name": "split_layers",           "default_value": false},
		{"name": "exclude_layers_pattern", "default_value": config.get_default_exclusion_pattern()},
		{"name": "only_visible_layers",    "default_value": false},
		{
			"name": "sheet_type",
			"default_value": "Packed",
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": get_sheet_type_hint_string()
		},
	]


func _get_option_visibility(path, option, options):
	return true


static func replace_vars(pattern : String, vars : Dictionary):
	var result = pattern;
	for k in vars:
		var v = vars[k]
		result = result.replace("{%s}" % k, v)
	return result


static func get_sheet_type_hint_string() -> String:
	var hint_string := "Packed"
	for number in [2, 4, 8, 16, 32]:
		hint_string += ",%s columns" % number
	hint_string += ",Strip"
	return hint_string


func _import(source_file, save_path, options, platform_variants, gen_files):
	var absolute_source_file = ProjectSettings.globalize_path(source_file)
	var absolute_save_path = ProjectSettings.globalize_path(save_path)

	var source_path = source_file.substr(0, source_file.rfind('/'))
	var source_basename = source_file.substr(source_path.length()+1, -1)
	source_basename = source_basename.substr(0, source_basename.rfind('.'))

	_sf_creator.init(config, file_system)

	var export_mode = _sf_creator.LAYERS_EXPORT_MODE if options['split_layers'] else _sf_creator.FILE_EXPORT_MODE

	var aseprite_opts = {
		"export_mode": export_mode,
		"exception_pattern": options['exclude_layers_pattern'],
		"only_visible_layers": options['only_visible_layers'],
		"output_filename": '' if export_mode == _sf_creator.FILE_EXPORT_MODE else '%s_' % source_basename,
		"column_count" : int(options['sheet_type']) if options['sheet_type'] != "Strip" else 128,
		"output_folder": source_path,
	}

	var resources = await _sf_creator.create_resources(absolute_source_file, aseprite_opts)

	if not resources.is_ok:
		printerr("ERROR - Could not import aseprite file: %s" % result_codes.get_error_message(resources.code))
		return FAILED

	if export_mode == _sf_creator.LAYERS_EXPORT_MODE:
		# each layer is saved as one resource using base file name to prevent
		# collisions
		# the first layer will be saved in the default resource path to prevent
		# godot from keeping re-importing it
		for resource in resources.content:
			var resource_path = "%s.res" % resource.data_file.get_basename();
			var exit_code = ResourceSaver.save(resource.resource, resource_path)
			resource.resource.take_over_path(resource_path)

			if exit_code != OK:
				printerr("ERROR - Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code))
				return FAILED

	var resource = resources.content[0]
	var resource_path = "%s.res" % save_path
	var exit_code = ResourceSaver.save(resource.resource, resource_path)
	resource.resource.take_over_path(resource_path)

	if exit_code != OK:
		printerr("ERROR - Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code))
		return FAILED
	return OK
