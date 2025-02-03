@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")

var config = preload("../config/config.gd").new()
var _aseprite = preload("../aseprite/aseprite.gd").new()

var file_system_helper

func _init(fs_helper) -> void:
	file_system_helper = fs_helper


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


func _get_import_order():
	return 1


func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var old_data = _load_old_data(source_file)
	var exception_pattern = options.get('layer/exclude_layers_pattern', "")
	var should_include_only_visibles = options.get('layer/only_visible_layers', false)

	var absolute_source_file = ProjectSettings.globalize_path(source_file)

	var layers = _aseprite.list_valid_layers(
		absolute_source_file,
		exception_pattern,
		should_include_only_visibles
	)

	var layers_resources_folder = options["output/layers_resources_folder"]

	var import_options = _get_base_import_options(options)
	import_options["source"] = source_file

	var base_name = source_file.get_basename()
	
	if layers_resources_folder != "":
		if not DirAccess.dir_exists_absolute(layers_resources_folder):
			DirAccess.make_dir_recursive_absolute(layers_resources_folder)
		base_name = "%s/%s" % [layers_resources_folder, base_name.get_file()]

	var data_to_save = {
		"layers": {}
	}

	for layer in layers:
		var layer_save_path = "%s_l_%s.%s" % [base_name, layer, _layer_extension()]
		var file = FileAccess.open(layer_save_path, FileAccess.WRITE)
		file.store_string(JSON.stringify({
			"layer": layer,
			"import_options": import_options,
		}))
		data_to_save.layers[layer] = layer_save_path

	var json = JSON.new()
	json.data = data_to_save

	var exit_code = ResourceSaver.save(json, "%s.%s" % [save_path, _get_save_extension()])

	_cleanup_old_layers(old_data, layers)

	file_system_helper.schedule_file_system_scan()

	return exit_code


func _layer_extension() -> String:
	return ""

func _get_base_import_options(options: Dictionary):
	return {}


func _load_old_data(source_file: String):
	var old_data = {}

	if ResourceLoader.exists(source_file):
		var d = ResourceLoader.load(source_file)
		if d is JSON:
			old_data = d.data.layers

	return old_data


func _cleanup_old_layers(old_data: Dictionary, layers: Array):
	var old_layers = old_data.keys()
	for old_layer in old_layers:
		if not layers.has(old_layer):
			var file = old_data[old_layer]
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(file)
