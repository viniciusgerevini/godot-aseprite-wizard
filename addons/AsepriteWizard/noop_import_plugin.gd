@tool
extends EditorImportPlugin

##
## No-op importer to allow files to be seen and 
## managed, but without triggering a real import
##

var config
var file_system: EditorFileSystem

func _get_importer_name():
	return "aseprite_wizard.plugin.noop"


func _get_visible_name():
	return "Aseprite (No Import)"


func _get_recognized_extensions():
	return ["aseprite", "ase"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "PackedDataContainer"


func _get_preset_count():
	return 1


func _get_preset_name(i):
	return "Default"


func _get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_NOOP_NAME else 1.0


func _get_import_order():
	return 1


func _get_import_options(_path, _i):
	return []


func _get_option_visibility(path, option, options):
	return true


func _import(source_file, save_path, options, platform_variants, gen_files):
	var container = PackedDataContainer.new()
	return ResourceSaver.save(container, "%s.%s" % [save_path, _get_save_extension()])
