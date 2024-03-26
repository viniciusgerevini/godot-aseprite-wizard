@tool
extends EditorPlugin

# importers
const NoopImportPlugin = preload("importers/noop_import_plugin.gd")
const SpriteFramesImportPlugin = preload("importers/sprite_frames_import_plugin.gd")
const TilesetTextureImportPlugin = preload("importers/tileset_texture_import_plugin.gd")
const TextureImportPlugin = preload("importers/static_texture_import_plugin.gd")

# export
const ExportPlugin = preload("export/metadata_export_plugin.gd")
# interface
const ConfigDialog = preload('config/config_dialog.tscn')
const WizardWindow = preload("interface/docks/wizard/as_wizard_dock_container.tscn")
const AsepriteDockImportsWindow = preload('interface/imports_manager/aseprite_imports_manager.tscn')
const AnimatedSpriteInspectorPlugin = preload("interface/docks/animated_sprite/inspector_plugin.gd")
const SpriteInspectorPlugin = preload("interface/docks/sprite/inspector_plugin.gd")

const tool_menu_name = "Aseprite Wizard"
const menu_item_name = "Open Spritesheet Wizard Dock"
const config_menu_item_name = "Config..."
const import_menu_item_name = "Imports Manager..."

var config = preload("config/config.gd").new()
var window: TabContainer
var config_window: PopupPanel
var imports_list_window: Window
var export_plugin : EditorExportPlugin
var sprite_inspector_plugin: EditorInspectorPlugin
var animated_sprite_inspector_plugin: EditorInspectorPlugin

var _exporter_enabled = false

var _importers = []

func _enter_tree():
	_load_config()
	_setup_menu_entries()
	_setup_importer()
	_setup_exporter()
	_setup_animated_sprite_inspector_plugin()
	_setup_sprite_inspector_plugin()


func _disable_plugin():
	_remove_menu_entries()
	_remove_importer()
	_remove_exporter()
	_remove_wizard_dock()
	_remove_inspector_plugins()
	config.clear_project_settings()


func _load_config():
	var editor_gui = get_editor_interface().get_base_control()
	config._editor_settings = get_editor_interface().get_editor_settings()

	config.initialize_project_settings()


func _setup_menu_entries():
	var submenu = PopupMenu.new()
	add_tool_submenu_item(tool_menu_name, submenu)
	submenu.add_item(menu_item_name)
	submenu.add_item(import_menu_item_name)
	submenu.add_item(config_menu_item_name)
	submenu.index_pressed.connect(_on_tool_menu_pressed)


func _remove_menu_entries():
	remove_tool_menu_item(tool_menu_name)


func _setup_importer():
	_importers = [
		NoopImportPlugin.new(),
		SpriteFramesImportPlugin.new(),
		TilesetTextureImportPlugin.new(),
		TextureImportPlugin.new(),
	]

	for i in _importers:
		if not i is NoopImportPlugin:
			i.file_system = get_editor_interface().get_resource_filesystem()
		i.config = config
		add_import_plugin(i)


func _remove_importer():
	for i in _importers:
		remove_import_plugin(i)


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


func _open_import_list_dialog():
	if is_instance_valid(imports_list_window):
		imports_list_window.queue_free()

	imports_list_window = AsepriteDockImportsWindow.instantiate()
	#imports_list_window.init(config)
	get_editor_interface().get_base_control().add_child(imports_list_window)
	imports_list_window.popup_centered_ratio(0.5)


func _on_window_closed():
	if window:
		remove_control_from_bottom_panel(window)
		window.queue_free()
		window = null


func _on_tool_menu_pressed(index):
	match index:
		0: # wizard dock
			_open_window()
		1: # imports
			_open_import_list_dialog()
		2: # config
			_open_config_dialog()
