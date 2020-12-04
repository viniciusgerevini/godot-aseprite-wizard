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
		{"name": "import_texture_strip", "default_value": false},
		{"name": "import_sprite_frames", "default_value": true},
		{"name": "import_texture_atlas", "default_value": false},
		{"name": "import_animated_texture", "default_value": false},
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
		if file_name != ".." and file_name != ".":
			var path = save_path + "/" + file_name
				
			if file_name.ends_with(".res"): 
				var sprite_frames : SpriteFrames = ResourceLoader.load(path, 'SpriteFrames', true)
				
				if options["import_sprite_frames"]:
					var res = sprite_frames
					ResourceSaver.save(source_path + "/" + file_name, res)
				
				if options["import_texture_atlas"]:
					var atlas_texture = null
					for anim in sprite_frames.animations:
						var i=0
						for frame in anim.frames:
							if not atlas_texture:
								atlas_texture = (frame as AtlasTexture).atlas
								var atlas_name = "%s/%sAtlas.tres" % [source_path, file_name.substr(0, file_name.length() - 4)]
								ResourceSaver.save(atlas_name, atlas_texture)
								atlas_texture.take_over_path(atlas_name)
							
							frame.atlas = atlas_texture
							
							var resource_name = "%s/%sAtlas_%s_%s.res" % [source_path, file_name.substr(0, file_name.length() - 4), anim.name, i]
							i+=1
							ResourceSaver.save(resource_name, frame)
							
				if options["import_animated_texture"]:
					
					for anim in sprite_frames.animations:
						var tex : AnimatedTexture = AnimatedTexture.new()
						tex.frames = anim.frames.size()
						
						var i=0
						for frame in anim.frames:
							var atlas_tex = frame as AtlasTexture
							var image : Image = atlas_tex.atlas.get_data()
							var single_image = Image.new()
							single_image.create(atlas_tex.get_width(), atlas_tex.get_height(), false, image.get_format())
							single_image.blit_rect(image, atlas_tex.region, Vector2.ZERO)
							
							var resource_name = "%s/%s_%s_%s.res" % [source_path, file_name.substr(0, file_name.length() - 4), anim.name, i]
							
							var res = ImageTexture.new()
							res.create_from_image(single_image)
							res.flags = atlas_tex.flags
							ResourceSaver.save(resource_name, res)
							res.take_over_path(resource_name)
							
							tex.set_frame_texture(i, res)
							
							i+=1
							
						var resource_name = "%s/%s_%s.res" % [source_path, file_name.substr(0, file_name.length() - 4), anim.name]
						ResourceSaver.save(resource_name, tex)
																
			elif options['import_texture_strip'] and file_name.ends_with(".png"):
				var img = Image.new()
				img.load(path)
				var res = ImageTexture.new()
				res.create_from_image(img)
				ResourceSaver.save(source_path + "/" + file_name, res)
				
		file_name = dir.get_next()
	return OK
