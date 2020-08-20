tool
extends EditorPlugin

const WizardWindow = preload("ASWizardWindow.tscn")
const menu_item_name = "Aseprite Spritesheet Wizard"
const CONFIG_FILE_PATH = 'user://aseprite_wizard.cfg'

var config: ConfigFile = ConfigFile.new()
var window: WindowDialog

func _enter_tree():
  add_tool_menu_item(menu_item_name, self, "_open_window")
  config = ConfigFile.new()
  config.load(CONFIG_FILE_PATH)

func _exit_tree():
  remove_tool_menu_item(menu_item_name)
  config = null

func _open_window(_ud):
  window = WizardWindow.instance()
  window.init(config)
  _add_to_editor(window)
  window.popup_centered()
  window.connect("popup_hide", self, "_on_window_closed")

func _on_window_closed():
  if window:
    window.queue_free()
    window = null
    config.save(CONFIG_FILE_PATH)

func _add_to_editor(element):
  var editor_interface = get_editor_interface()
  var base_control = editor_interface.get_base_control()
  base_control.add_child(element)
