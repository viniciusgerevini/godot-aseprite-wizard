@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")

var config = preload("../config/config.gd").new()
#var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()
var _aseprite = preload("../aseprite/aseprite.gd").new()
#var _sf_creator = preload("../creators/sprite_frames/sprite_frames_creator.gd").new()
#var file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()


# TODO remove split option from main importer

var file_system_helper

func _init(fs_helper) -> void:
	file_system_helper = fs_helper


func _get_importer_name():
	return "aseprite_wizard.plugin.spriteframes-split"


func _get_visible_name():
	return "Aseprite SpriteFrames (Split By Layer)"


func _get_recognized_extensions():
	return ["aseprite", "ase"]


func _get_save_extension():
	return "json"


func _get_resource_type():
	return "JSON"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_SPRITEFRAMES_SPLIT_NAME else 1.0


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
		{"name": "animation/round_fps", "default_value": true},
		{
			"name": "output/layers_resources_folder",
			"default_value": "",
			"property_hint": PROPERTY_HINT_DIR,
		}
	]


func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var exception_pattern = options.get('layer/exclude_layers_pattern', "")
	var should_include_only_visibles = options.get('layer/only_visible_layers', false)
	
	var absolute_source_file = ProjectSettings.globalize_path(source_file)

	var layers = _aseprite.list_valid_layers(
		absolute_source_file,
		exception_pattern,
		should_include_only_visibles
	)
	
	var layers_resources_folder = options["output/layers_resources_folder"]

	var import_options = {
		"source": source_file,
		"sheet_type": options["sheet/sheet_type"],
		"sheet_columns": options["sheet/sheet_columns"],
		"should_round_fps": options["animation/round_fps"],
	}

	var base_name = source_file.get_basename()
	
	if layers_resources_folder != "":
		if not DirAccess.dir_exists_absolute(layers_resources_folder):
			DirAccess.make_dir_recursive_absolute(layers_resources_folder)
		base_name = "%s/%s" % [layers_resources_folder, base_name.get_file()]

	for layer in layers:
		var layer_save_path = "%s_l_%s.ase_layer" % [base_name, layer]
		var file = FileAccess.open(layer_save_path, FileAccess.WRITE)
		file.store_string(JSON.stringify({
			"layer": layer,
			"import_options": import_options,
		}))

	var data_to_save = {
		"layers": layers
	}

	var json = JSON.new()
	json.data = data_to_save

	var exit_code = ResourceSaver.save(json, "%s.%s" % [save_path, _get_save_extension()])

	# TODO should implement cleanup?
	# - idea:
	#     - save generated layers path to this file
	#     - on import load it (if it still exists
	#     - on importing new, check which ones are not in the new list anymore and remove them

	file_system_helper.schedule_file_system_scan()

	return exit_code
