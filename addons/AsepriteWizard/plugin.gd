tool
extends EditorPlugin

const WizardWindow = preload("ASWizardWindow.tscn")
const ImportPlugin = preload("import_plugin.gd")
const menu_item_name = "Aseprite Spritesheet Wizard"
const CONFIG_FILE_PATH = 'user://aseprite_wizard.cfg'

var config: ConfigFile = ConfigFile.new()
var window: PopupPanel
var importPlugin : EditorImportPlugin

var _importer_enabled = false

func _enter_tree():
	add_tool_menu_item(menu_item_name, self, "_open_window")

	config = ConfigFile.new()
	config.load(CONFIG_FILE_PATH)

	if (_should_enable_importer()):
		importPlugin = ImportPlugin.new()
		add_import_plugin(importPlugin)
		_importer_enabled = true

func _exit_tree():
	remove_tool_menu_item(menu_item_name)
	if _importer_enabled:
		remove_import_plugin(importPlugin)
		_importer_enabled = false
	config = null

func _open_window(_ud):
	window = WizardWindow.instance()
	window.init(config, get_editor_interface().get_resource_filesystem())
	_add_to_editor(window)
	window.popup_centered()
	window.connect("popup_hide", self, "_on_window_closed")
	window.connect("importer_state_changed", self, "_on_importer_state_changed")

func _on_window_closed():
	if window:
		window.queue_free()
		window = null
		config.save(CONFIG_FILE_PATH)

func _on_importer_state_changed():
	if _importer_enabled:
		remove_import_plugin(importPlugin)
		_importer_enabled = false
	else:
		importPlugin = ImportPlugin.new()
		add_import_plugin(importPlugin)
		_importer_enabled = true

func _add_to_editor(element):
	var editor_interface = get_editor_interface()
	var base_control = editor_interface.get_base_control()
	base_control.add_child(element)

func _should_enable_importer():
	return config.get_value('aseprite', 'is_importer_enabled', true)
