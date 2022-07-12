tool
extends Reference

# GLOBAL CONFIGS
const CONFIG_FILE_PATH = 'user://aseprite_wizard.cfg'
const _CONFIG_SECTION_KEY = 'aseprite'
const _COMMAND_KEY = 'command'
const _IMPORTER_ENABLE_KEY = 'is_importer_enabled'
const _REMOVE_SOURCE_FILES_KEY = 'remove_source_files'
const _LOOP_ENABLED = 'loop_enabled'
const _LOOP_EXCEPTION_PREFIX = 'loop_config_prefix'
const _DEFAULT_LOOP_EX_PREFIX = '_'
const _DEFAULT_EXCLUSION_PATTERN_KEY = 'default_layer_ex_pattern'
const _IMPORT_PRESET_ENABLED = 'is_import_preset_enabled'


# IMPORT CONFIGS
const _IMPORT_SECTION_KEY = 'file_locations'
const _I_LAST_SOURCE_PATH_KEY = 'source'
const _I_LAST_OUTPUT_DIR_KEY = 'output'
const _I_SHOULD_SPLIT_LAYERS_KEY = 'split_layers'
const _I_EXCEPTIONS_KEY = 'exceptions_key'
const _I_ONLY_VISIBLE_LAYERS_KEY = 'only_visible_layers'
const _I_CUSTOM_NAME_KEY = 'custom_name'
const _I_DO_NOT_CREATE_RES_KEY = 'disable_resource_creation'

# PROJECT SETTINGS
const PIXEL_2D_PRESET_CFG = 'res://addons/AsepriteWizard/config/2d_pixel_preset.cfg'
const ASEPRITE_PROJECT_SETTINGS_IMPORT_PRESET = 'aseprite/import/preset'

# INTERFACE CONFIGS
var _icon_arrow_down: Texture
var _icon_arrow_right: Texture

var _config := ConfigFile.new()


func load_config() -> void:
	_config = ConfigFile.new()
	_config.load(CONFIG_FILE_PATH)


func save() -> void:
	_config.save(CONFIG_FILE_PATH)


func _create_import_preset_setting() -> void:
	if ProjectSettings.has_setting(ASEPRITE_PROJECT_SETTINGS_IMPORT_PRESET) && (ProjectSettings.get_setting(ASEPRITE_PROJECT_SETTINGS_IMPORT_PRESET) as Dictionary).size() > 0:
		return

	var preset := ConfigFile.new()
	preset.load(PIXEL_2D_PRESET_CFG)

	var dict = {}
	for key in preset.get_section_keys("preset"):
		dict[key] = preset.get_value("preset", key)		

	ProjectSettings.set(ASEPRITE_PROJECT_SETTINGS_IMPORT_PRESET, dict)
	ProjectSettings.add_property_info( {
		"name": ASEPRITE_PROJECT_SETTINGS_IMPORT_PRESET,
		"type": TYPE_DICTIONARY,
		"hint_string": "this value is equvivalent to the values stored in Importer Defaults"
	})
	ProjectSettings.set_initial_value(ASEPRITE_PROJECT_SETTINGS_IMPORT_PRESET, {})
	ProjectSettings.save()

#######################################################
# GLOBAL CONFIGS
######################################################

func default_command() -> String:
	return 'aseprite'


func get_command() -> String:
	var command = _config.get_value(_CONFIG_SECTION_KEY, _COMMAND_KEY, "")
	return command if command != "" else default_command()


func set_command(aseprite_command: String) -> void:
	if aseprite_command == "":
		_config.set_value(_CONFIG_SECTION_KEY, _COMMAND_KEY, default_command())
	else:
		_config.set_value(_CONFIG_SECTION_KEY, _COMMAND_KEY, aseprite_command)


func is_importer_enabled() -> bool:
	return _config.get_value(_CONFIG_SECTION_KEY, _IMPORTER_ENABLE_KEY, false)


func set_importer_enabled(is_enabled: bool) -> void:
	_config.set_value(_CONFIG_SECTION_KEY, _IMPORTER_ENABLE_KEY, is_enabled)


func should_remove_source_files() -> bool:
	return _config.get_value(_CONFIG_SECTION_KEY, _REMOVE_SOURCE_FILES_KEY, true)


func set_remove_source_files(should_remove: bool) -> void:
	_config.set_value(_CONFIG_SECTION_KEY, _REMOVE_SOURCE_FILES_KEY, should_remove)


func is_default_animation_loop_enabled() -> bool:
	return _config.get_value(_CONFIG_SECTION_KEY, _LOOP_ENABLED, true)


func set_default_animation_loop(should_loop: bool) -> void:
	_config.set_value(_CONFIG_SECTION_KEY, _LOOP_ENABLED, should_loop)


func get_animation_loop_exception_prefix() -> String:
	return _config.get_value(_CONFIG_SECTION_KEY, _LOOP_EXCEPTION_PREFIX, _DEFAULT_LOOP_EX_PREFIX)


func set_animation_loop_exception_prefix(prefix: String) -> void:
	_config.set_value(_CONFIG_SECTION_KEY, _LOOP_EXCEPTION_PREFIX, prefix if prefix != "" else _DEFAULT_LOOP_EX_PREFIX)


func get_default_exclusion_pattern() -> String:
	return _config.get_value(_CONFIG_SECTION_KEY, _DEFAULT_EXCLUSION_PATTERN_KEY, "")


func set_default_exclusion_pattern(pattern: String) -> void:
	_config.set_value(_CONFIG_SECTION_KEY, _DEFAULT_EXCLUSION_PATTERN_KEY, pattern)


func is_import_preset_enabled() -> bool:
		return _config.get_value(_CONFIG_SECTION_KEY, _IMPORT_PRESET_ENABLED, false)
	
	
func set_import_preset_enabled(is_enabled: bool) -> void:
		_config.set_value(_CONFIG_SECTION_KEY, _IMPORT_PRESET_ENABLED, is_enabled)


#######################################################
# IMPORT CONFIGS
######################################################
func get_last_source_path() -> String:
	return _config.get_value(_IMPORT_SECTION_KEY, _I_LAST_SOURCE_PATH_KEY, "")


func set_last_source_path(source_path: String) -> void:
	_config.set_value(_IMPORT_SECTION_KEY, _I_LAST_SOURCE_PATH_KEY, source_path)


func get_last_output_path() -> String:
	return _config.get_value(_IMPORT_SECTION_KEY, _I_LAST_OUTPUT_DIR_KEY, "")


func set_last_output_path(output_path: String) -> void:
	_config.set_value(_IMPORT_SECTION_KEY, _I_LAST_OUTPUT_DIR_KEY, output_path)


func should_split_layers() -> bool:
	return _config.get_value(_IMPORT_SECTION_KEY, _I_SHOULD_SPLIT_LAYERS_KEY, false)


func set_split_layers(should_split: bool) -> void:
	_config.set_value(_IMPORT_SECTION_KEY, _I_SHOULD_SPLIT_LAYERS_KEY, false)


func get_exception_pattern() -> String:
	return _config.get_value(_IMPORT_SECTION_KEY, _I_EXCEPTIONS_KEY, "")


func set_exception_pattern(pattern: String) -> void:
	_config.set_value(_IMPORT_SECTION_KEY, _I_EXCEPTIONS_KEY, pattern)


func should_include_only_visible_layers() -> bool:
	return _config.get_value(_IMPORT_SECTION_KEY, _I_ONLY_VISIBLE_LAYERS_KEY, false)


func set_include_only_visible_layers(include_only_visible: bool) -> void:
	_config.set_value(_IMPORT_SECTION_KEY, _I_ONLY_VISIBLE_LAYERS_KEY, include_only_visible)


func get_last_custom_name() -> String:
	return _config.get_value(_IMPORT_SECTION_KEY, _I_CUSTOM_NAME_KEY, "")


func set_custom_name(custom_name: String) -> void:
	_config.set_value(_IMPORT_SECTION_KEY, _I_CUSTOM_NAME_KEY, custom_name)
	

func should_not_create_resource() -> bool:
	return _config.get_value(_IMPORT_SECTION_KEY, _I_DO_NOT_CREATE_RES_KEY, false)


func set_do_not_create_resource(do_no_create: bool) -> void:
	_config.set_value(_IMPORT_SECTION_KEY, _I_DO_NOT_CREATE_RES_KEY, do_no_create)


#######################################################
# INTERFACE CONFIGS
######################################################
func set_icon_arrow_down(icon: Texture) -> void:
	_icon_arrow_down = icon


func get_icon_arrow_down() -> Texture:
	return _icon_arrow_down


func set_icon_arrow_right(icon: Texture) -> void:
	_icon_arrow_right = icon


func get_icon_arrow_right() -> Texture:
	return _icon_arrow_right
