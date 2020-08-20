tool
extends WindowDialog

const CONFIG_SECTION_KEY = 'file_locations'
const LAST_SOURCE_PATH_KEY = 'source'
const LAST_OUTPUT_DIR_KEY = 'output'
const GROUP_MODE_KEY = 'group_mode'
const EXCEPTIONS_KEY = 'exceptions_key'
const ONLY_VISIBLE_LAYERS_KEY = 'only_visible_layers'
const TRIM_IMAGES_KEY = 'trim_images'

var config: ConfigFile

var file_dialog_aseprite: FileDialog
var output_folder_dialog: FileDialog
var warning_dialog: AcceptDialog
var config_window: WindowDialog

const config_dialog = preload('config_dialog.tscn')
var aseprite = preload("aseprite_cmd.gd").new()

func _ready():
  file_dialog_aseprite = _create_aseprite_file_selection()
  output_folder_dialog = _create_outuput_folder_selection()
  warning_dialog = AcceptDialog.new()
  config_window = config_dialog.instance()
  config_window.init(config)
  aseprite.init(config, config_window.get_default_command())

  get_parent().add_child(file_dialog_aseprite)
  get_parent().add_child(output_folder_dialog)
  get_parent().add_child(warning_dialog)
  get_parent().add_child(config_window)

  _load_persisted_config()

func _exit_tree():
  file_dialog_aseprite.queue_free()
  output_folder_dialog.queue_free()
  warning_dialog.queue_free()
  config_window.queue_free()

func _load_persisted_config():
  if config.has_section_key(CONFIG_SECTION_KEY, GROUP_MODE_KEY):
    _group_mode_field().pressed = config.get_value(CONFIG_SECTION_KEY, GROUP_MODE_KEY)

  if config.has_section_key(CONFIG_SECTION_KEY, ONLY_VISIBLE_LAYERS_KEY):
    _only_visible_layers_field().pressed = config.get_value(CONFIG_SECTION_KEY, ONLY_VISIBLE_LAYERS_KEY)

  if config.has_section_key(CONFIG_SECTION_KEY, TRIM_IMAGES_KEY):
    _trim_image_field().pressed = config.get_value(CONFIG_SECTION_KEY, TRIM_IMAGES_KEY)

  if config.has_section_key(CONFIG_SECTION_KEY, EXCEPTIONS_KEY):
    _exception_pattern_field().text = config.get_value(CONFIG_SECTION_KEY, EXCEPTIONS_KEY)

  if config.has_section_key(CONFIG_SECTION_KEY, LAST_SOURCE_PATH_KEY):
    _file_location_field().text = config.get_value(CONFIG_SECTION_KEY, LAST_SOURCE_PATH_KEY)

  if config.has_section_key(CONFIG_SECTION_KEY, LAST_OUTPUT_DIR_KEY):
    _output_folder_field().text = config.get_value(CONFIG_SECTION_KEY, LAST_OUTPUT_DIR_KEY)
  else:
    _output_folder_field().text = 'res://'

func _open_aseprite_file_selection_dialog():
  var current_selection = _file_location_field().text
  if current_selection != "":
    file_dialog_aseprite.current_dir = current_selection.get_base_dir()
  file_dialog_aseprite.popup_centered_ratio()

func _open_output_folder_selection_dialog():
  var current_selection = _output_folder_field().text
  if current_selection != "":
    output_folder_dialog.current_dir = current_selection
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
  _file_location_field().text = path
  config.set_value(CONFIG_SECTION_KEY, LAST_SOURCE_PATH_KEY, path)

func _on_output_folder_selected(path):
  _output_folder_field().text = path
  config.set_value(CONFIG_SECTION_KEY, LAST_OUTPUT_DIR_KEY, path)

func _on_next_btn_up():
  var aseprite_file = _file_location_field().text
  var output_location = _output_folder_field().text
  var group_layers = _group_mode_field().pressed

  var export_mode = aseprite.FILE_EXPORT_MODE if group_layers else aseprite.LAYERS_EXPORT_MODE
  var options = {
    "export_mode": export_mode,
    "exception_pattern": _exception_pattern_field().text,
    "only_visible_layers": _only_visible_layers_field().pressed,
    "trim_images": _trim_image_field().pressed
  }

  var exit_code = aseprite.create_resource(aseprite_file, output_location, options)
  if exit_code != 0:
    _show_error(exit_code)
    return
  _close_window()

func _on_close_btn_up():
  _close_window()

func _close_window():
  config.set_value(CONFIG_SECTION_KEY, GROUP_MODE_KEY, _group_mode_field().pressed)
  config.set_value(CONFIG_SECTION_KEY, EXCEPTIONS_KEY, _exception_pattern_field().text)
  config.set_value(CONFIG_SECTION_KEY, ONLY_VISIBLE_LAYERS_KEY, _only_visible_layers_field().pressed)
  config.set_value(CONFIG_SECTION_KEY, TRIM_IMAGES_KEY, _trim_image_field().pressed)

  self.hide()

func _on_config_button_up():
  config_window.popup_centered()

func _show_error(code: int):
  match code:
    aseprite.ERR_SOURCE_FILE_NOT_FOUND:
      _show_error_message('source file does not exist')
    aseprite.ERR_OUTPUT_FOLDER_NOT_FOUND:
      _show_error_message('output location does not exist')
    aseprite.ERR_ASEPRITE_EXPORT_FAILED:
      _show_error_message('unable to import file')
    aseprite.ERR_INVALID_ASEPRITE_SPRITESHEET:
      _show_error_message('aseprite generated bad data file')
    aseprite.ERR_NO_VALID_LAYERS_FOUND:
      _show_error_message('no valid layers found')
    _:
      _show_error_message('import failed with code %d' % code)

func _show_error_message(message: String):
  warning_dialog.dialog_text = "Error: %s" % message
  warning_dialog.popup_centered()

func _file_location_field() -> LineEdit:
  return $container/options/file_location/HBoxContainer/file_location_path as LineEdit

func _output_folder_field() -> LineEdit:
  return $container/options/output_folder/HBoxContainer/file_location_path as LineEdit

func _exception_pattern_field() -> LineEdit:
  return $container/options/exclude_pattern/pattern as LineEdit

func _group_mode_field() -> CheckBox:
  return $container/options/layer_importing_mode/group_layers as CheckBox

func _only_visible_layers_field() -> CheckBox:
  return $container/options/layer_importing_mode/visible_layers as CheckBox

func _trim_image_field() -> CheckBox:
  return $container/options/layer_importing_mode/trim_image as CheckBox

func init(config_file: ConfigFile):
  config = config_file
