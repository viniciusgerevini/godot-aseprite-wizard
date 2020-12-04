tool
extends EditorImportPlugin

const CONFIG_FILE_PATH = 'user://aseprite_wizard.cfg'

var aseprite = preload("aseprite_cmd.gd").new()

func get_error_message(code: int):
	match code:
		aseprite.ERR_ASEPRITE_CMD_NOT_FOUND:
			return 'Aseprite command failed. Please, check if the right command is in your PATH or configured through the "configuration" button.'
		aseprite.ERR_SOURCE_FILE_NOT_FOUND:
			return 'source file does not exist'
		aseprite.ERR_OUTPUT_FOLDER_NOT_FOUND:
			return 'output location does not exist'
		aseprite.ERR_ASEPRITE_EXPORT_FAILED:
			return 'unable to import file'
		aseprite.ERR_INVALID_ASEPRITE_SPRITESHEET:
			return 'aseprite generated bad data file'
		aseprite.ERR_NO_VALID_LAYERS_FOUND:
			return 'no valid layers found'
		_:
			return 'import failed with code %d' % code

func get_importer_name():
	return "aseprite.wizard.plugin"

func get_visible_name():
	return "Aseprite Importer"

func get_recognized_extensions():
	return ["aseprite", "ase"]

func get_save_extension():
	return "res"

func get_resource_type():
	return ""

func get_preset_count():
	return 1

func get_preset_name(i):
	return "Default"

func get_import_options(i):
	return [
		{"name": "split_layers", "default_value": true},
		{"name": "exception_pattern", "default_value": ''},
		{"name": "only_visible_layers", "default_value": false},
		{"name": "trim_images", "default_value": false},
		]

func import(source_file, save_path, options, platform_variants, gen_files):		
	var absolute_source_file = ProjectSettings.globalize_path(source_file)
	var absolute_save_path = ProjectSettings.globalize_path(save_path)
	
	var source_path = source_file.substr(0, source_file.find_last('/'))
	
	var config = ConfigFile.new()
	config.load(CONFIG_FILE_PATH)
	aseprite.init(config, 'aseprite')
	
	var dir = Directory.new()
	dir.make_dir(save_path)
	
	# Clear the directories contents
	dir.open(save_path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		print(file_name)
		dir.remove(file_name)
		file_name = dir.get_next()	
		
	var output_filename = '';

	var export_mode = aseprite.LAYERS_EXPORT_MODE if options['split_layers'] else aseprite.FILE_EXPORT_MODE

	var aseprite_opts = {
		"export_mode": export_mode,
		"exception_pattern": options['exception_pattern'],
		"only_visible_layers": options['only_visible_layers'],
		"trim_images": options['trim_images'],
		"output_filename": output_filename
	}
		
	var exit_code = aseprite.create_resource(absolute_source_file, absolute_save_path, aseprite_opts)
	if exit_code != 0:
		print("ERROR - Could not import aseprite file: %s" % get_error_message(exit_code))
		return FAILED
		
	dir.open(save_path)
	dir.list_dir_begin()
		
	file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".res") or file_name.ends_with(".png"):
			var res = load(save_path + "/" + file_name)
			ResourceSaver.save(source_path + "/" + file_name, res)
			
		file_name = dir.get_next()
		
	return OK
