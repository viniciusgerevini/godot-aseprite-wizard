tool
extends EditorImportPlugin

##
## No-op importer to allow files to be seen and
## managed, but without triggering a real import
##

var config
var file_system: EditorFileSystem

func get_importer_name():
	return "aseprite_wizard.plugin.noop"


func get_visible_name():
	return "Aseprite (No Import)"


func get_recognized_extensions():
	return ["aseprite", "ase"]


func get_save_extension():
	return "res"


func get_resource_type():
	return "PackedDataContainer"


func get_preset_count():
	return 1


func get_preset_name(_i):
	return "Default"


func get_import_options(_i):
	return []


func get_option_visibility(_option, _options):
	return true


func get_import_order():
	return 1


func get_priority():
	return 2.0 if config.get_default_importer() == config.IMPORTER_NOOP_NAME else 1.0


func import(source_file, save_path, options, platform_variants, gen_files):
	var container = PackedDataContainer.new()
	return ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], container)
