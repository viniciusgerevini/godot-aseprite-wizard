tool
extends WindowDialog

var file_dialog_aseprite
var output_folder_dialog

var aseprite = preload("aseprite_cmd.gd").new()

func _ready():
  file_dialog_aseprite = _create_aseprite_file_selection()
  output_folder_dialog = _create_outuput_folder_selection()
  get_parent().add_child(file_dialog_aseprite)
  get_parent().add_child(output_folder_dialog)

func _exit_tree():
  file_dialog_aseprite.queue_free()
  output_folder_dialog.queue_free()

func _open_aseprite_file_selection_dialog():
  file_dialog_aseprite.popup_centered_ratio()

func _open_output_folder_selection_dialog():
  output_folder_dialog.popup_centered_ratio()

func _create_aseprite_file_selection():
  var file_dialog = FileDialog.new()
  file_dialog.mode = FileDialog.MODE_OPEN_FILE
  file_dialog.access = FileDialog.ACCESS_FILESYSTEM
  file_dialog.connect("file_selected", self, "_on_aseprite_file_selected")
  file_dialog.set_filters(PoolStringArray(["*.ase","*.aseprite"]))
  return file_dialog

func _create_outuput_folder_selection():
  var file_dialog = FileDialog.new()
  file_dialog.mode = FileDialog.MODE_OPEN_DIR
  file_dialog.access = FileDialog.ACCESS_RESOURCES
  file_dialog.connect("dir_selected", self, "_on_output_folder_selected")
  return file_dialog

func _on_aseprite_file_selected(path):
  $container/options/file_location/HBoxContainer/file_location_path.text = path

func _on_output_folder_selected(path):
  $container/options/output_folder/HBoxContainer/file_location_path.text = path

func _on_next_btn_up():
  var aseprite_file = $container/options/file_location/HBoxContainer/file_location_path.text
  var output_location = $container/options/output_folder/HBoxContainer/file_location_path.text
  var dir = Directory.new()

  if not dir.file_exists(aseprite_file):
    print('source file does not exist')
    return # TODO error dialog

  if not output_location or not dir.dir_exists(output_location):
    print('output location does not exist')
    return # TODO error dialog

  var exit_code = aseprite.create_sprite_frames_from_aseprite_file(aseprite_file, output_location)

  if exit_code != 0:
    pass # TODO show error dialog

  self.hide()

func _on_close_btn_up():
  self.hide()

# TODO grouped layers vs isolated layer
# TODO layer exception


