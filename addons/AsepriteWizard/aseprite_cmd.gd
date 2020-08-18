extends Node

const aseprite_command = 'aseprite'

func _aseprite_list_layers(file_name: String) -> Array:
  var output = []

  var exit_code = OS.execute(aseprite_command, ["-b", "--all-layers", "--list-layers", file_name], true, output, true)

  if exit_code != 0:
    print('aseprite: failed listing layers')
    print(output)
    return []

  if output.empty():
    return output

  return output[0].split('\n')

func _aseprite_export_spritesheet(file_name: String, output_folder: String) -> Dictionary:
  var basename = _get_file_basename(file_name)
  var output_dir = output_folder.replace("res://", "./")
  var data_file = "%s/%s.json" % [output_dir, basename]
  var sprite_sheet = "%s/%s.png" % [output_dir, basename]
  var output = []

  var arguments = [
    "-b",
    "--all-layers",
    "--list-tags",
    "--data",
    data_file,
    "--format",
    "json-array",
    "--sheet",
    sprite_sheet,
    file_name
  ]

  var exit_code = OS.execute(aseprite_command, arguments, true, output, true)

  if exit_code != 0:
    print('aseprite: failed to export spritesheet')
    print(output)
    return {}

  return {
    'data_file': data_file,
    "sprite_sheet": sprite_sheet
  }

func export_file_to_spritesheet(source_file: String, output_folder: String) -> int:
  var output = _aseprite_export_spritesheet(source_file, output_folder)

  if output.empty():
    return FAILED
  print(output)
  return OK

func create_sprite_frames_from_aseprite_file(source_file: String, output_folder: String) -> int:
  var output = _aseprite_export_spritesheet(source_file, output_folder)
  if output.empty():
    return FAILED
  return _import(output.data_file)

func _get_file_basename(file_path: String) -> String:
  return file_path.get_file().trim_suffix('.%s' % file_path.get_extension())

func _import(source_file) -> int:
  var file = File.new()
  var err = file.open(source_file, File.READ)
  if err != OK:
      return err
  var content =  parse_json(file.get_as_text())

  if not _is_valid_aseprite_spritesheet(content):
    return ERR_PARSE_ERROR

  var texture_path = _parse_texture_path(source_file, content)
  var resource = _create_sprite_frames_with_animations(content, texture_path)

  var save_path = "%s.%s" % [source_file.get_basename(), "res"]

  return ResourceSaver.save(save_path, resource, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)

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
  var texture = AtlasTexture.new()
  var frame = frame_data.frame
  texture.atlas = load(image)
  texture.region = Rect2(frame.x, frame.y, frame.w, frame.h)
  return texture
