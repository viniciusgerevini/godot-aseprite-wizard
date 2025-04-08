@tool
extends "./multiple_import_plugin_base.gd"


func _get_importer_name():
	return "aseprite_wizard.plugin.static-texture-split"


func _get_visible_name():
	return "Aseprite Texture (Split By Layer)"


func _get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_STATIC_TEXTURE_SPLIT_NAME else 1.0


func _get_import_options(_path, _i):
	return [
		{"name": "first_frame_only", "default_value": true},
		{"name": "layer/exclude_layers_pattern", "default_value": config.get_default_exclusion_pattern()},
		{"name": "layer/only_visible_layers",    "default_value": false},
		{"name": "layer/merge_duplicate_layers", "default_value": false},
		{"name": "sheet/trim_cels", "default_value": false},
		{
			"name": "output/layers_resources_folder",
			"default_value": "",
			"property_hint": PROPERTY_HINT_DIR,
		}
	]


func _layer_extension() -> String:
	return "ase_layer_tex"


func _get_base_import_options(options: Dictionary):
	return  {
		"trim_cels": options["sheet/trim_cels"],
		"first_frame_only": options["first_frame_only"],
	}
