tool
extends EditorPlugin

const ConfigDialog = preload('config/config_dialog.tscn')
const WizardWindow = preload("animated_sprite/ASWizardDockContainer.tscn")
const ImportPlugin = preload("animated_sprite/import_plugin.gd")
const AnimatedSpriteInspectorPlugin = preload("animated_sprite/inspector_plugin.gd")
const SpriteInspectorPlugin = preload("animation_player/inspector_plugin.gd")
const menu_item_name = "Aseprite Spritesheet Wizard"
const config_menu_item_name = "Aseprite Wizard Config"

var config = preload("config/config.gd").new()
var window: TabContainer
var config_window: PopupPanel
var import_plugin : EditorImportPlugin
var sprite_inspector_plugin: EditorInspectorPlugin
var animated_sprite_inspector_plugin: EditorInspectorPlugin

var _importer_enabled = false

var _plugin_icons

func _enter_tree():
	_load_config()
	_setup_menu_entries()
	_setup_importer()
	_configure_preset()
	_setup_animated_sprite_inspector_plugin()
	_setup_sprite_inspector_plugin()


func disable_plugin():
	_remove_menu_entries()
	_remove_importer()
	_remove_wizard_dock()
	_remove_inspector_plugins()
	config.clear_project_settings()
	_plugin_icons = null


func _load_config():
	var editor_gui = get_editor_interface().get_base_control()
	config.load_config()
	_plugin_icons = {
		"collapsed": editor_gui.get_icon("GuiTreeArrowRight", "EditorIcons"),
		"expanded": editor_gui.get_icon("GuiTreeArrowDown", "EditorIcons"),
	}
	config.initialize_project_settings()


func _setup_menu_entries():
	add_tool_menu_item(menu_item_name, self, "_open_window")
	add_tool_menu_item(config_menu_item_name, self, "_open_config_dialog")


func _remove_menu_entries():
	remove_tool_menu_item(menu_item_name)
	remove_tool_menu_item(config_menu_item_name)


func _setup_importer():
	if config.is_importer_enabled():
		import_plugin = ImportPlugin.new()
		add_import_plugin(import_plugin)
		_importer_enabled = true


func _configure_preset():
	if config.is_import_preset_enabled():
		config.create_import_preset_setting()


func _remove_importer():
	if _importer_enabled:
		remove_import_plugin(import_plugin)
		_importer_enabled = false


func _setup_sprite_inspector_plugin():
	sprite_inspector_plugin = SpriteInspectorPlugin.new()
	sprite_inspector_plugin.file_system = get_editor_interface().get_resource_filesystem()
	sprite_inspector_plugin.plugin_icons = _plugin_icons
	sprite_inspector_plugin.config = config
	add_inspector_plugin(sprite_inspector_plugin)


func _setup_animated_sprite_inspector_plugin():
	animated_sprite_inspector_plugin = AnimatedSpriteInspectorPlugin.new()
	animated_sprite_inspector_plugin.file_system = get_editor_interface().get_resource_filesystem()
	animated_sprite_inspector_plugin.plugin_icons = _plugin_icons
	animated_sprite_inspector_plugin.config = config
	add_inspector_plugin(animated_sprite_inspector_plugin)


func _remove_inspector_plugins():
	remove_inspector_plugin(sprite_inspector_plugin)
	remove_inspector_plugin(animated_sprite_inspector_plugin)


func _remove_wizard_dock():
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
	# TODO find a way to identify if importer was enabled when settings is changed
	# TODO same with preset
	#	config_window.connect("importer_state_changed", self, "_on_importer_state_changed")
	get_editor_interface().get_base_control().add_child(config_window)
	config_window.popup_centered()


func _on_window_closed():
	if window:
		remove_control_from_bottom_panel(window)
		window.queue_free()
		window = null


func _on_importer_state_changed():
	if _importer_enabled:
		remove_import_plugin(import_plugin)
		_importer_enabled = false
	else:
		import_plugin = ImportPlugin.new()
		add_import_plugin(import_plugin)
		_importer_enabled = true
