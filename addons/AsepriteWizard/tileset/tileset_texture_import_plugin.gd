@tool
extends EditorImportPlugin

##
## Tileset texture importer.
## Imports Aseprite tileset layers as a AtlasTexture
##

const result_codes = preload("../config/result_codes.gd")

var _texture_creator = preload("tileset_texture_creator.gd").new()
var config
var file_system: EditorFileSystem


func _get_importer_name():
	return "aseprite_wizard.plugin.tileset-texture"


func _get_visible_name():
	return "Aseprite Tileset Texture"


func _get_recognized_extensions():
	return ["aseprite", "ase"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "AtlasTexture"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_priority():
	return 2.0 if config.get_default_importer() == config.TILESET_TEXTURE_NAME else 0.9


func _get_import_order():
	return 1


func _get_import_options(_path, _i):
	return [
		{"name": "exclude_layers_pattern", "default_value": config.get_default_exclusion_pattern()},
		{"name": "only_visible_layers",    "default_value": false},
	]


func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var absolute_source_file = ProjectSettings.globalize_path(source_file)
	var absolute_save_path = ProjectSettings.globalize_path(save_path)

	var source_path = source_file.substr(0, source_file.rfind('/'))
	var source_basename = source_file.substr(source_path.length()+1, -1)
	source_basename = source_basename.substr(0, source_basename.rfind('.'))

	_texture_creator.init(config, file_system)

	var aseprite_opts = {
		"exception_pattern": options['exclude_layers_pattern'],
		"only_visible_layers": options['only_visible_layers'],
		"output_filename": '',
		"output_folder": source_path,
	}

	var result = await _texture_creator.generate_aseprite_spritesheet(absolute_source_file, aseprite_opts)

	if not result.is_ok:
		printerr("ERROR - Could not import aseprite file: %s" % result_codes.get_error_message(result.code))
		return FAILED

	var sprite_sheet = result.content.sprite_sheet

	file_system.update_file(sprite_sheet)
	append_import_external_resource(sprite_sheet)

	var texture: CompressedTexture2D = ResourceLoader.load(sprite_sheet, "CompressedTexture2D", ResourceLoader.CACHE_MODE_REPLACE)
	var resource = AtlasTexture.new()
	resource.atlas = texture
	resource.region = Rect2(0, 0, result.content.data_content.meta.size.w, result.content.data_content.meta.size.h)

	var resource_path = "%s.res" % save_path
	var exit_code = ResourceSaver.save(resource, resource_path)
	resource.take_over_path(resource_path)

	if config.should_remove_source_files():
		DirAccess.remove_absolute(result.content.data_file)
		file_system.call_deferred("scan")

	if exit_code != OK:
		printerr("ERROR - Could not persist aseprite file: %s" % result_codes.get_error_message(exit_code))
		return FAILED
	return OK
