@tool
extends EditorPlugin

const ConfigDialog = preload('config/config_dialog.tscn')
const WizardWindow = preload("animated_sprite/docks/as_wizard_dock_container.tscn")
const SpriteFramesImportPlugin = preload("animated_sprite/import_plugin.gd")
const NoopImportPlugin = preload("noop_import_plugin.gd")
const ExportPlugin = preload("export/metadata_export_plugin.gd")
const AnimatedSpriteInspectorPlugin = preload("animated_sprite/inspector_plugin.gd")
const SpriteInspectorPlugin = preload("animation_player/inspector_plugin.gd")
const menu_item_name = "Aseprite Spritesheet Wizard"
const config_menu_item_name = "Aseprite Wizard Config"

var config = preload("config/config.gd").new()
var window: TabContainer
var config_window: PopupPanel
var sprite_frames_import_plugin : EditorImportPlugin
var noop_import_plugin : EditorImportPlugin
var export_plugin : EditorExportPlugin
var sprite_inspector_plugin: EditorInspectorPlugin
var animated_sprite_inspector_plugin: EditorInspectorPlugin

var _exporter_enabled = false


func _enter_tree():
	_load_config()
	_setup_menu_entries()
	_setup_importer()
	_setup_exporter()
	_configure_preset()
	_setup_animated_sprite_inspector_plugin()
	_setup_sprite_inspector_plugin()


func _disable_plugin():
	_remove_menu_entries()
	_remove_importer()
	_remove_exporter()
	_remove_wizard_dock()
	_remove_inspector_plugins()
	config.clear_project_settings()
	config.set_icons({})


func _load_config():
	var editor_gui = get_editor_interface().get_base_control()
	config._editor_settings = get_editor_interface().get_editor_settings()
	config.set_icons({
		"collapsed": editor_gui.get_theme_icon("GuiTreeArrowRight", "EditorIcons"),
		"expanded": editor_gui.get_theme_icon("GuiTreeArrowDown", "EditorIcons"),
	})
	config.initialize_project_settings()


func _setup_menu_entries():
	add_tool_menu_item(menu_item_name, _open_window)
	add_tool_menu_item(config_menu_item_name, _open_config_dialog)


func _remove_menu_entries():
	remove_tool_menu_item(menu_item_name)
	remove_tool_menu_item(config_menu_item_name)


func _setup_importer():
	sprite_frames_import_plugin = SpriteFramesImportPlugin.new()
	sprite_frames_import_plugin.file_system = get_editor_interface().get_resource_filesystem()
	sprite_frames_import_plugin.config = config
	add_import_plugin(sprite_frames_import_plugin)
	
	noop_import_plugin = NoopImportPlugin.new()
	noop_import_plugin.config = config
	add_import_plugin(noop_import_plugin)


func _configure_preset():
	if config.is_import_preset_enabled():
		config.create_import_preset_setting()


func _remove_importer():
	remove_import_plugin(sprite_frames_import_plugin)
	remove_import_plugin(noop_import_plugin)


func _setup_exporter():
	if config.is_exporter_enabled():
		export_plugin = ExportPlugin.new()
		add_export_plugin(export_plugin)
		_exporter_enabled = true


func _remove_exporter():
	if _exporter_enabled:
		remove_export_plugin(export_plugin)
		_exporter_enabled = false


func _setup_sprite_inspector_plugin():
	sprite_inspector_plugin = SpriteInspectorPlugin.new()
	sprite_inspector_plugin.file_system = get_editor_interface().get_resource_filesystem()
	sprite_inspector_plugin.config = config
	add_inspector_plugin(sprite_inspector_plugin)


func _setup_animated_sprite_inspector_plugin():
	animated_sprite_inspector_plugin = AnimatedSpriteInspectorPlugin.new()
	animated_sprite_inspector_plugin.file_system = get_editor_interface().get_resource_filesystem()
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


func _open_window():
	if window:
		make_bottom_panel_item_visible(window)
		return

	window = WizardWindow.instantiate()
	window.init(config, get_editor_interface().get_resource_filesystem())
	window.connect("close_requested",Callable(self,"_on_window_closed"))
	add_control_to_bottom_panel(window, "Aseprite Wizard")
	make_bottom_panel_item_visible(window)


func _open_config_dialog():
	if is_instance_valid(config_window):
		config_window.queue_free()

	config_window = ConfigDialog.instantiate()
	config_window.init(config)
	get_editor_interface().get_base_control().add_child(config_window)
	config_window.popup_centered()


func _on_window_closed():
	if window:
		remove_control_from_bottom_panel(window)
		window.queue_free()
		window = null
