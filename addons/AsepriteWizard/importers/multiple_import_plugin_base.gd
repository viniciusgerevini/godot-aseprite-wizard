@tool
extends EditorImportPlugin

const result_codes = preload("../config/result_codes.gd")
const logger = preload("../config/logger.gd")

var config = preload("../config/config.gd").new()
var _aseprite = preload("../aseprite/aseprite.gd").new()
var _bakery = preload("./helpers/bakery.gd").new()
var _aseprite_file_exporter = preload("../aseprite/file_exporter.gd").new()

var file_system_helper

func _init(fs_helper) -> void:
	file_system_helper = fs_helper


func _get_recognized_extensions():
	return ["aseprite", "ase"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "PortableCompressedTexture2D"


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

	if not _aseprite.test_command():
		if config.should_generate_bake_files() && _bakery.has_bake_file(source_file):
			logger.warn("Aseprite command failed. Falling back to baked file. No changes will be made to children resources", source_file)
			return _bakery.load_bake_file(source_file, "%s.%s" % [save_path, _get_save_extension()])
		else:
			return ERR_UNCONFIGURED

	var exception_pattern = options.get('layer/exclude_layers_pattern', "")
	var should_include_only_visibles = options.get('layer/only_visible_layers', false)
	var should_merge_duplicates = options.get('layer/merge_duplicate_layers', false)

	var absolute_source_file = ProjectSettings.globalize_path(source_file)

	var layers = _aseprite.list_valid_layers(
		absolute_source_file,
		exception_pattern,
		should_include_only_visibles,
		should_merge_duplicates,
		true
	)

	var layers_resources_folder = options["output/layers_resources_folder"]

	if layers_resources_folder.is_relative_path():
		var source_base_dir = source_file.get_base_dir()
		layers_resources_folder = source_base_dir.path_join(layers_resources_folder).simplify_path()

	var base_name = source_file.get_basename()

	if layers_resources_folder != "":
		if not DirAccess.dir_exists_absolute(layers_resources_folder):
			DirAccess.make_dir_recursive_absolute(layers_resources_folder)
		base_name = "%s/%s" % [layers_resources_folder, base_name.get_file()]

	var import_options = _get_base_import_options(options)

	var aseprite_opts = {
		"layers": layers,
		"split_layers": true,
		"output_filename": '',
		"output_folder": source_file.get_base_dir()
	}
	aseprite_opts.merge(import_options, true)

	var export_result = _aseprite_file_exporter.generate_aseprite_file(absolute_source_file, aseprite_opts)
	if not export_result.is_ok:
		logger.error("Could not import aseprite file: %s" % result_codes.get_error_message(export_result.code), source_file)
		return FAILED

	var json_result = _aseprite_file_exporter.load_json_content(export_result.content.data_file)
	if not json_result.is_ok:
		logger.error("Could not read JSON: '%s'" % result_codes.get_error_message(json_result.code), source_file)
		return FAILED

	var sprite_sheet_abs = ProjectSettings.globalize_path(export_result.content.sprite_sheet)
	var atlas_image = Image.load_from_file(sprite_sheet_abs)
	if atlas_image == null:
		logger.error("Could not load image", source_file)
		return FAILED

	var atlas_tex = PortableCompressedTexture2D.new()
	atlas_tex.create_from_image(atlas_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	var frames_by_layer = _group_frames_by_layer(json_result.content)

	for layer in layers:
		if not frames_by_layer.has(layer):
			continue
		var flat_layer_name = (layer as String).replace("/", "_")
		var resource = _create_layer_resource(layer, atlas_tex, frames_by_layer[layer], json_result.content, options)
		var res_path = "%s_%s.res" % [base_name, flat_layer_name]
		ResourceSaver.save(resource, res_path)
		gen_files.push_back(res_path)

	var exit_code = ResourceSaver.save(atlas_tex, "%s.%s" % [save_path, _get_save_extension()])

	if config.should_generate_bake_files():
		var bake_code = _bakery.save_bake_file(source_file, atlas_tex)
		if bake_code != OK:
			logger.error('Bake file creation failed (%s) ' % bake_code, source_file)

	if config.should_remove_source_files():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(export_result.content.data_file))
		DirAccess.remove_absolute(sprite_sheet_abs)

	_cleanup_old_layers(old_data, layers)

	file_system_helper.schedule_file_system_scan()

	return exit_code

func _get_base_import_options(options: Dictionary):
	return {}


func _create_layer_resource(_layer: String, atlas_tex: PortableCompressedTexture2D, layer_frames: Array, _json_content: Dictionary, _options: Dictionary) -> Resource:
	var f = layer_frames[0].frame
	var at := AtlasTexture.new()
	at.atlas = atlas_tex
	at.region = Rect2(f.x, f.y, f.w, f.h)
	return at

func _group_frames_by_layer(json_content: Dictionary) -> Dictionary:
	var regex = RegEx.new()
	regex.compile("(?<=\\().*(?=\\))")

	var groups = {}
	for frame in _aseprite.get_content_frames(json_content):
		var m = regex.search(frame.filename)
		if m == null:
			continue
		var layer_name: String = m.get_string()
		if not groups.has(layer_name):
			groups[layer_name] = []
		groups[layer_name].append(frame)
	return groups


func _load_old_data(source_file: String):
	var old_data = {}

	if ResourceLoader.exists(source_file):
		var d = ResourceLoader.load(source_file)
		# handling JSON to keep it backwards compatible
		# remove it in the next major version
		if d is JSON:
			old_data = d.data.layers
		elif d is PackedDataContainer:
			if d["layers"] != null:
				old_data = _packed_container_to_dictionary(d["layers"])

	return old_data


func _packed_container_to_dictionary(packed):
	var dic = {}
	for k in packed:
		if packed[k] is PackedDataContainerRef:
			dic[k] = _packed_container_to_dictionary(packed[k])
		else:
			dic[k] = packed[k]
	return dic


func _cleanup_old_layers(old_data: Dictionary, layers: Array):
	var old_layers = old_data.keys()

	for old_layer in old_layers:
		if not layers.has(old_layer):
			var file = old_data[old_layer]
			if FileAccess.file_exists(file):
				DirAccess.remove_absolute(file)
