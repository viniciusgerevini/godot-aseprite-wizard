@tool
extends "../static_texture_import_plugin_base.gd"

##
## Static texture importer (Split).
## Imports first frame from Aseprite file as texture in multiple resources
##

func _get_importer_name():
	return "aseprite_wizard.plugin.static-texture-split-layer"


func _get_visible_name():
	return "Aseprite Layer Texture"


func _get_recognized_extensions():
	return ["ase_layer_tex"]


func _get_priority():
	return 1.0


func _get_import_options(_path, _i):
	return []


func _import(source_file, save_path, options, platform_variants, gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	var i_data = JSON.parse_string(file.get_as_text())

	var source_path = source_file.get_base_dir()
	var absolute_source_file = ProjectSettings.globalize_path(i_data.import_options.source)

	var aseprite_opts = {
		"layer": i_data.layer,
		"output_filename": '',
		"output_folder": source_path,
		"first_frame_only": true,
	}

	var result = _generate_texture(absolute_source_file, aseprite_opts)

	if not result.is_ok:
		printerr("ERROR - Could not import aseprite file: %s" % result_codes.get_error_message(result.code))
		return FAILED

	var sprite_sheet = result.content.sprite_sheet
	var data = result.content.data

	return _save_resource(sprite_sheet, save_path, result.content.data_file, data.meta.size)
