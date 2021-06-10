tool
extends EditorPlugin

const WizardWindow = preload("ASWizardWindow.tscn")
const ImportPlugin = preload("import_plugin.gd")
const menu_item_name = "Aseprite Spritesheet Wizard"
const CONFIG_FILE_PATH = 'user://aseprite_wizard.cfg'

var config: ConfigFile = ConfigFile.new()
var window: PanelContainer
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

	if window:
		remove_control_from_bottom_panel(window)
		window.queue_free()
		window = null


func _open_window(_ud):
	if window:
		make_bottom_panel_item_visible(window)
		return

	window = WizardWindow.instance()
	window.init(config, get_editor_interface().get_resource_filesystem())
	window.connect("importer_state_changed", self, "_on_importer_state_changed")
	window.connect("close_requested", self, "_on_window_closed")
	add_control_to_bottom_panel(window, "Aseprite Wizard")
	make_bottom_panel_item_visible(window)


func _on_window_closed():
	if window:
		config.save(CONFIG_FILE_PATH)
		remove_control_from_bottom_panel(window)
		window.queue_free()
		window = null


func _on_importer_state_changed():
	if _importer_enabled:
		remove_import_plugin(importPlugin)
		_importer_enabled = false
	else:
		importPlugin = ImportPlugin.new()
		add_import_plugin(importPlugin)
		_importer_enabled = true


func _should_enable_importer():
	return config.get_value('aseprite', 'is_importer_enabled', true)

