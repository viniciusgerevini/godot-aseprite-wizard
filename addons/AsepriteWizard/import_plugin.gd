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
	return "SpriteFrames"

func get_preset_count():
	return 1

func get_preset_name(i):
	return "Default"

func get_import_options(i):
	return [
		{"name": "split_layers", "default_value": false},
		{"name": "exclude_layers_pattern", "default_value": ''},
		{"name": "only_visible_layers", "default_value": false},
		{"name": "ignore_empty_frames", "default_value": true},
		{"name": "trim_mode", "property_hint": PROPERTY_HINT_ENUM, "default_value": 0, "hint_string": "Disabled,Trim,Trim by grid" },

		{"name": "sprite_filename_pattern", "default_value": "{basename}.{layer}.{extension}"},

		{"name": "texture_strip/import_texture_strip", "default_value": false},
		{"name": "texture_strip/filename_pattern", "default_value": "{basename}.{layer}.Strip.{extension}"},

		{"name": "texture_atlas/import_texture_atlas", "default_value": false},
		{"name": "texture_atlas/filename_pattern", "default_value": "{basename}.{layer}.Atlas.{extension}"},
		{"name": "texture_atlas/frame_filename_pattern", "default_value": "{basename}.{layer}.{animation}.{frame}.Atlas.{extension}"},

		{"name": "animated_texture/import_animated_texture", "default_value": false},
		{"name": "animated_texture/filename_pattern", "default_value": "{basename}.{layer}.{animation}.Texture.{extension}"},
		{"name": "animated_texture/frame_filename_pattern", "default_value": "{basename}.{layer}.{animation}.{frame}.Texture.{extension}"},
		]

func get_option_visibility(option, options):
	return true

static func replace_vars(pattern : String, vars : Dictionary):
	var result = pattern;
	for k in vars:
		var v = vars[k]
		result = result.replace("{%s}" % k, v)
	return result

func import(source_file, save_path, options, platform_variants, gen_files):
	var absolute_source_file = ProjectSettings.globalize_path(source_file)
	var absolute_save_path = ProjectSettings.globalize_path(save_path)

	var source_path = source_file.substr(0, source_file.find_last('/'))
	var source_basename = source_file.substr(source_path.length()+1, -1)
	source_basename = source_basename.substr(0, source_basename.find_last('.'))

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
		if file_name != '.' and file_name != '..':
			dir.remove(file_name)
		file_name = dir.get_next()

	var export_mode = aseprite.LAYERS_EXPORT_MODE if options['split_layers'] else aseprite.FILE_EXPORT_MODE

	var aseprite_opts = {
		"export_mode": export_mode,
		"exception_pattern": options['exclude_layers_pattern'],
		"only_visible_layers": options['only_visible_layers'],
		"trim_images": options['trim_mode'] == 1,
		"trim_by_grid": options['trim_mode'] == 2,
		"ignore_empty": options['ignore_empty_frames'],
		"output_filename": ''
	}

	var exit_code = aseprite.create_resource(absolute_source_file, absolute_save_path, aseprite_opts)
	if exit_code != 0:
		print("ERROR - Could not import aseprite file: %s" % get_error_message(exit_code))
		return FAILED

	dir.open(save_path)
	dir.list_dir_begin()

	file_name = dir.get_next()

	var main_sprite_frame_saved = false

	var global_replacement_vars = {
		"basename": source_basename,
	}

	# Scan through the import directory and process the generated resources based on what options have been selected.
	while file_name != "":
		if file_name != ".." and file_name != ".":
			if file_name.ends_with(".res"):
				# This is a SpriteFrames resource generated for a layer.
				var local_replacement_vars = global_replacement_vars.duplicate()
				local_replacement_vars["layer"] = file_name.substr(0, file_name.length() - 4)

				if not main_sprite_frame_saved:
					# Save this resource as the main resource. We need to set something here or Godot won't stop
					# re-importing the resource. So this is either the SpriteFrames instance of the first layer
					# (alphabetically) found in the import directory.
					var sprite_frames : SpriteFrames = ResourceLoader.load("%s/%s" % [save_path, file_name], 'SpriteFrames', true)
					main_sprite_frame_saved = true
					var resource_path = "%s.res" % save_path;
					sprite_frames.take_over_path(resource_path)
					ResourceSaver.save(resource_path, sprite_frames)

				var sprite_frames : SpriteFrames = ResourceLoader.load("%s/%s" % [save_path, file_name], 'SpriteFrames', true)

				if options["split_layers"]:
					var sprite_replacement_vars = local_replacement_vars.duplicate()
					sprite_replacement_vars["extension"] = "res"

					var sprite_filename = "%s/%s" % [source_path, replace_vars(options["sprite_filename_pattern"], sprite_replacement_vars)]
					ResourceSaver.save(sprite_filename, sprite_frames)
					sprite_frames.take_over_path(sprite_filename)

				if options["texture_atlas/import_texture_atlas"]:
					# Create a TextureAtlas resource for this layer.
					var atlas_texture = null
					var replacement_vars = local_replacement_vars.duplicate()

					for anim in sprite_frames.animations:
						var i=0

						replacement_vars["animation"] = anim.name
						replacement_vars["extension"] = "res"

						for frame in anim.frames:
							replacement_vars["frame"] = i

							if not atlas_texture:
								atlas_texture = (frame as AtlasTexture).atlas

								var atlas_filename = "%s/%s" % [source_path, replace_vars(options["texture_atlas/filename_pattern"], replacement_vars)]
								ResourceSaver.save(atlas_filename, atlas_texture)
								atlas_texture.take_over_path(atlas_filename)

							frame.atlas = atlas_texture

							var frame_filename = "%s/%s" % [source_path, replace_vars(options["texture_atlas/frame_filename_pattern"], replacement_vars)]
							ResourceSaver.save(frame_filename, frame)
							i+=1

				if options["animated_texture/import_animated_texture"]:
					var replacement_vars = local_replacement_vars.duplicate()
					replacement_vars["extension"] = "res"

					for anim in sprite_frames.animations:
						replacement_vars["animation"] = anim.name

						var tex : AnimatedTexture = AnimatedTexture.new()
						tex.frames = anim.frames.size()

						var i=0
						for frame in anim.frames:
							replacement_vars["frame"] = i

							var atlas_tex = frame as AtlasTexture
							var image : Image = atlas_tex.atlas.get_data()
							var single_image = Image.new()
							single_image.create(atlas_tex.get_width(), atlas_tex.get_height(), false, image.get_format())
							single_image.blit_rect(image, atlas_tex.region, Vector2.ZERO)

							var frame_filename = "%s/%s" % [source_path, replace_vars(options["animated_texture/frame_filename_pattern"], replacement_vars)]

							var res = ImageTexture.new()
							res.create_from_image(single_image, 0)
							res.flags = atlas_tex.flags
							ResourceSaver.save(frame_filename, res)
							res.take_over_path(frame_filename)

							tex.set_frame_texture(i, res)

							i+=1

						var texture_filename = "%s/%s" % [source_path, replace_vars(options["animated_texture/filename_pattern"], replacement_vars)]
						ResourceSaver.save(texture_filename, tex)

			elif options['texture_strip/import_texture_strip'] and file_name.ends_with(".png"):
				var replacement_vars = global_replacement_vars.duplicate()
				replacement_vars["layer"] = file_name.substr(0, file_name.length() - 4)
				replacement_vars["extension"] = "png"

				var texture_filename = "%s/%s" % [source_path, replace_vars(options["texture_strip/filename_pattern"], replacement_vars)]

				var img : Image = Image.new()
				img.load("%s/%s" % [save_path, file_name])
				var res = ImageTexture.new()
				res.create_from_image(img, 0)
				ResourceSaver.save(texture_filename, res)

		file_name = dir.get_next()
	return OK
