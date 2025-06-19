@tool
extends Node

const wizard_meta = preload("../../../config/wizard_config.gd")
const result_code = preload("../../../config/result_codes.gd")
var _aseprite_file_exporter = preload("../../../aseprite/file_exporter.gd").new()
var _sf_creator = preload("../../../creators/sprite_frames/sprite_frames_creator.gd").new()
var _config = preload("../../../config/config.gd").new()

var _file_system: EditorFileSystem = EditorInterface.get_resource_filesystem()


# fields
# "split_layers"
# "only_visible_layers"
# "layer_exclusion_pattern"
# "output_name"
# "source_file"
# "do_not_create_resource"
# "output_location"
# "should_round_fps"
# "scale"
func import_and_create_resources(aseprite_file: String, fields: Dictionary) -> int:
	var export_mode = _aseprite_file_exporter.LAYERS_EXPORT_MODE if fields.split_layers else _aseprite_file_exporter.FILE_EXPORT_MODE
	var options = {
		"export_mode": export_mode,
		"exception_pattern": fields.layer_exclusion_pattern,
		"only_visible_layers": fields.only_visible_layers,
		"output_filename": fields.output_name,
		"do_not_create_resource": fields.do_not_create_resource,
		"output_folder": fields.output_location,
		"scale": fields.scale,
	}

	var aseprite_output = _aseprite_file_exporter.generate_aseprite_files(
		ProjectSettings.globalize_path(aseprite_file),
		options
	)

	if not aseprite_output.is_ok:
		return aseprite_output.code

	_file_system.scan()

	await _file_system.filesystem_changed

	var exit_code = OK

	if !options.get("do_not_create_resource", false):
		var resources = _sf_creator.create_resources(aseprite_output.content, { "should_round_fps": fields.get("should_round_fps", true) })
		if resources.is_ok:
			_add_metadata(resources.content, aseprite_file, fields, options)
			exit_code = _sf_creator.save_resources(resources.content)

	if _config.should_remove_source_files():
		_remove_source_files(aseprite_output.content)

	return exit_code


func _add_metadata(resources: Array, aseprite_file: String, fields: Dictionary, options: Dictionary) -> void:
	var source_hash = FileAccess.get_md5(aseprite_file)
	var group = str(ResourceUID.create_id()) if options.export_mode == _aseprite_file_exporter.LAYERS_EXPORT_MODE else ""

	for r in resources:
		wizard_meta.set_source_hash(r.resource, source_hash)
		wizard_meta.save_config(r.resource, { "fields": fields, "group": group })


func _remove_source_files(source_files: Array):
	for s in source_files:
		DirAccess.remove_absolute(s.data_file)
