@tool
extends "./multiple_import_plugin_base.gd"

var _sf_creator = preload("../creators/sprite_frames/sprite_frames_creator.gd").new()

func _get_importer_name():
	return "aseprite_wizard.plugin.spriteframes-split"


func _get_visible_name():
	return "Aseprite SpriteFrames (Split By Layer)"


func _get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_SPRITEFRAMES_SPLIT_NAME else 1.0


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
		{
			"name": "output/layers_resources_folder",
			"default_value": "",
			"property_hint": PROPERTY_HINT_DIR,
		}
	]


func _create_layer_resource(_layer: String, atlas_tex: PortableCompressedTexture2D, layer_frames: Array, json_content: Dictionary, options: Dictionary) -> Resource:
	var layer_json = {
		"frames": layer_frames,
		"meta": json_content.meta,
	}
	return _sf_creator._create_sprite_frames_with_animations(layer_json, atlas_tex, _get_base_import_options(options))


func _get_base_import_options(options: Dictionary):
	return  {
		"sheet_type": options["sheet/sheet_type"],
		"frame_padding": options["sheet/frame_padding"],
		"sheet_columns": options["sheet/sheet_columns"],
		"should_round_fps": options["animation/round_fps"],
		"scale": str(options["sheet/scale"]),
	}
