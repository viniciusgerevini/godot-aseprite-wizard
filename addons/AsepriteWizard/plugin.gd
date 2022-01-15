tool
extends EditorPlugin

const ConfigDialog = preload('config/config_dialog.tscn')
const WizardWindow = preload("animated_sprite/ASWizardWindow.tscn")
const ImportPlugin = preload("animated_sprite/import_plugin.gd")
const menu_item_name = "Aseprite Spritesheet Wizard"
const config_menu_item_name = "Aseprite Wizard Config"

var config = preload("config/config.gd").new()
var window: PanelContainer
var config_window: PopupPanel
var importPlugin : EditorImportPlugin

var _importer_enabled = false

func _enter_tree():
	add_tool_menu_item(menu_item_name, self, "_open_window")
	add_tool_menu_item(config_menu_item_name, self, "_open_config_dialog")
	config.load_config()

	if (config.is_importer_enabled()):
		importPlugin = ImportPlugin.new()
		add_import_plugin(importPlugin)
		_importer_enabled = true


func _exit_tree():
	remove_tool_menu_item(menu_item_name)
	remove_tool_menu_item(config_menu_item_name)

	if _importer_enabled:
		remove_import_plugin(importPlugin)
		_importer_enabled = false

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
	window.connect("close_requested", self, "_on_window_closed")
	add_control_to_bottom_panel(window, "Aseprite Wizard")
	make_bottom_panel_item_visible(window)


func _open_config_dialog(_ud):
	if is_instance_valid(config_window):
		config_window.queue_free()

	config_window = ConfigDialog.instance()
	config_window.init(config)
	config_window.connect("importer_state_changed", self, "_on_importer_state_changed")
	get_editor_interface().get_base_control().add_child(config_window)
	config_window.popup_centered()


func _on_window_closed():
	if window:
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
