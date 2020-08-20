tool
extends Node

enum {
  FILE_EXPORT_MODE,
  LAYERS_EXPORT_MODE
}

enum {
  SUCCESS,
  ERR_SOURCE_FILE_NOT_FOUND,
  ERR_OUTPUT_FOLDER_NOT_FOUND,
  ERR_ASEPRITE_EXPORT_FAILED,
  ERR_UNKNOWN_EXPORT_MODE,
  ERR_NO_VALID_LAYERS_FOUND,
  ERR_INVALID_ASEPRITE_SPRITESHEET
}

var default_command = 'aseprite'
var config: ConfigFile

func init(config_file: ConfigFile, default_cmd: String):
  config = config_file
  default_command = default_cmd

func _aseprite_command() -> String:
  var command
  if config.has_section_key('aseprite', 'command'):
    command = config.get_value('aseprite', 'command')

  if not command or command == "":
    return default_command
  return command

func _aseprite_list_layers(file_name: String, only_visible = false) -> Array:
  var output = []
  var arguments = ["-b", "--list-layers", file_name]

  if not only_visible:
    arguments.push_front("--all-layers")

  var exit_code = OS.execute(_aseprite_command(), arguments, true, output, true)

  if exit_code != 0:
    print('aseprite: failed listing layers')
    print(output)
    return []

  if output.empty():
    return output

  return output[0].split('\n')

func _aseprite_export_spritesheet(file_name: String, output_folder: String, options: Dictionary) -> Dictionary:
  var exception_pattern = options.get('exception_pattern', "")
  var only_visible_layers = options.get('only_visible_layers', false)
  var basename = _get_file_basename(file_name)
  var output_dir = output_folder.replace("res://", "./")
  var data_file = "%s/%s.json" % [output_dir, basename]
  var sprite_sheet = "%s/%s.png" % [output_dir, basename]
  var output = []

  var arguments = [
    "-b",
    "--list-tags",
    "--data",
    data_file,
    "--format",
    "json-array",
    "--sheet",
    sprite_sheet,
    file_name
  ]

  if not only_visible_layers:
    arguments.push_front("--all-layers")

  if exception_pattern != "":
    _add_ignore_layer_arguments(file_name, arguments, exception_pattern)

  var exit_code = OS.execute(_aseprite_command(), arguments, true, output, true)

  if exit_code != 0:
    print('aseprite: failed to export spritesheet')
    print(output)
    return {}
  return {
    'data_file': data_file.replace("./", "res://"),
    "sprite_sheet": sprite_sheet.replace("./", "res://")
  }


func _aseprite_export_layers_spritesheet(file_name: String, output_folder: String, options: Dictionary) -> Array:
  var exception_pattern = options.get('exception_pattern', "")
  var only_visible_layers = options.get('only_visible_layers', false)
  var basename = _get_file_basename(file_name)
  var output_dir = output_folder.replace("res://", "./")

  var layers = _aseprite_list_layers(file_name, only_visible_layers)

  var exception_regex

  if exception_pattern != "":
    exception_regex = RegEx.new()
    if exception_regex.compile(exception_pattern) != OK:
      print('exception regex error')
      exception_regex = null

  var output = []

  for layer in layers:
    if layer != "" and (not exception_regex or exception_regex.search(layer) == null):
      output.push_back(_aseprite_export_layer(file_name, layer, output_dir))

  return output

func _aseprite_export_layer(file_name: String, layer_name: String, output_folder: String) -> Dictionary:
  var data_file = "%s/%s.json" % [output_folder, layer_name]
  var sprite_sheet = "%s/%s.png" % [output_folder, layer_name]
  var output = []

  var arguments = [
    "-b",
    "--list-tags",
    "--layer",
    layer_name,
    "--data",
    data_file,
    "--format",
    "json-array",
    "--sheet",
    sprite_sheet,
    file_name
  ]

  var exit_code = OS.execute(_aseprite_command(), arguments, true, output, true)

  if exit_code != 0:
    print('aseprite: failed to export layer spritesheet')
    print(output)
    return {}

  return {
    'data_file': data_file.replace("./", "res://"),
    "sprite_sheet": sprite_sheet.replace("./", "res://")
  }

func _add_ignore_layer_arguments(file_name: String, arguments: Array, exception_pattern: String):
  var layers = _get_exception_layers(file_name, exception_pattern)
  if not layers.empty():
    for l in layers:
      arguments.push_front(l)
      arguments.push_front('--ignore-layer')

func _get_exception_layers(file_name: String, exception_pattern: String) -> Array:
  var layers = _aseprite_list_layers(file_name)
  var regex = RegEx.new()
  if regex.compile(exception_pattern) != OK:
    print('exception regex error')
    return []

  var exception_layers = []
  for layer in layers:
    if regex.search(layer) != null:
      exception_layers.push_back(layer)
  print('Layers ignored:')
  print(exception_layers)
  return exception_layers

func create_resource(source_file: String, output_folder: String, options = {}) -> int:
  var export_mode = options.get('export_mode', FILE_EXPORT_MODE)

  var dir = Directory.new()
  if not dir.file_exists(source_file):
    return ERR_SOURCE_FILE_NOT_FOUND

  if not dir.dir_exists(output_folder):
    return ERR_OUTPUT_FOLDER_NOT_FOUND

  match export_mode:
    FILE_EXPORT_MODE:
      return create_sprite_frames_from_aseprite_file(source_file, output_folder, options)
    LAYERS_EXPORT_MODE:
      return create_sprite_frames_from_aseprite_layers(source_file, output_folder, options)
    _:
      return ERR_UNKNOWN_EXPORT_MODE

func create_sprite_frames_from_aseprite_file(source_file: String, output_folder: String, options: Dictionary) -> int:
  var output = _aseprite_export_spritesheet(source_file, output_folder, options)
  if output.empty():
    return ERR_ASEPRITE_EXPORT_FAILED
  return _import(output.data_file)

func create_sprite_frames_from_aseprite_layers(source_file: String, output_folder: String, options: Dictionary) -> int:
  var output = _aseprite_export_layers_spritesheet(source_file, output_folder, options)
  if output.empty():
    return ERR_NO_VALID_LAYERS_FOUND

  var result = OK

  for o in output:
    if o.empty():
      result = ERR_ASEPRITE_EXPORT_FAILED
    else:
      result = _import(o.data_file)

  return result

func _get_file_basename(file_path: String) -> String:
  return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())

func _import(source_file) -> int:
  var file = File.new()
  var err = file.open(source_file, File.READ)
  if err != OK:
      return err
  var content =  parse_json(file.get_as_text())

  if not _is_valid_aseprite_spritesheet(content):
    return ERR_INVALID_ASEPRITE_SPRITESHEET

  var texture_path = _parse_texture_path(source_file, content)
  var resource = _create_sprite_frames_with_animations(content, texture_path)

  var save_path = "%s.%s" % [source_file.get_basename(), "res"]
  resource.take_over_path(save_path)
  return ResourceSaver.save(save_path, resource, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
#  return ResourceSaver.save(save_path, resource)


func _create_sprite_frames_with_animations(content, texture_path):
  var frames = _get_frames_from_content(content)
  var sprite_frames = SpriteFrames.new()
  sprite_frames.remove_animation("default")

  if content.meta.has("frameTags"):
    for tag in content.meta.frameTags:
      var selected_frames = frames.slice(tag.from, tag.to)
      _add_animation_frames(sprite_frames, tag.name, selected_frames, texture_path, tag.direction)
  else:
    _add_animation_frames(sprite_frames, "default", frames, texture_path)

  return sprite_frames

func _get_frames_from_content(content):
  return content.frames if typeof(content.frames) == TYPE_ARRAY  else content.frames.values()


func _add_animation_frames(sprite_frames, animation_name, frames, texture_path, direction = 'forward'):
    sprite_frames.add_animation(animation_name)

    var min_duration = _get_min_duration(frames)
    var fps = _calculate_fps(min_duration)

    if direction == 'reverse':
      frames.invert()

    for frame in frames:
      var atlas = _create_atlastexture_from_frame(texture_path, frame)
      var number_of_sprites = ceil(frame.duration / min_duration)
      for _i in range(number_of_sprites):
        sprite_frames.add_frame(animation_name, atlas)

    if direction == 'pingpong':
      frames.invert()

      for frame in frames:
        var atlas = _create_atlastexture_from_frame(texture_path, frame)
        var number_of_sprites = ceil(frame.duration / min_duration)
        for _i in range(number_of_sprites):
          sprite_frames.add_frame(animation_name, atlas)

    sprite_frames.set_animation_loop(animation_name, true)
    sprite_frames.set_animation_speed(animation_name, fps)

func _calculate_fps(min_duration: int) -> float:
  return ceil(1000 / min_duration)

func _get_min_duration(frames) -> int:
  var min_duration = 100000
  for frame in frames:
    if frame.duration < min_duration:
      min_duration = frame.duration
  return min_duration

func _parse_texture_path(source_file, content):
  return "%s/%s" % [source_file.get_base_dir(), content.meta.image]

func _is_valid_aseprite_spritesheet(content):
  return content.has("frames") and content.has("meta") and content.meta.has('image')

func _create_atlastexture_from_frame(image, frame_data):
  var atlas = AtlasTexture.new()
  var frame = frame_data.frame

  if ResourceLoader.has_cached(image):
    atlas.atlas = ResourceLoader.load(image, 'Image', true)
    atlas.atlas.take_over_path(image)
  else:
    var i = Image.new()
    i.load(image)
    var texture = ImageTexture.new()
    texture.create_from_image(i, 0)
    atlas.atlas = texture
  atlas.region = Rect2(frame.x, frame.y, frame.w, frame.h)
  return atlas
