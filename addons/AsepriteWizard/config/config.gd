@tool
extends RefCounted

# GLOBAL SETTINGS
const _CONFIG_SECTION_KEY = 'aseprite'
const _COMMAND_KEY = 'aseprite/general/command_path'

# PROJECT SETTINGS

# animation import defaults
const _DEFAULT_EXCLUSION_PATTERN_KEY = 'aseprite/animation/layers/exclusion_pattern'
const _DEFAULT_LOOP_EX_PREFIX = '_'
const _LOOP_ENABLED = 'aseprite/animation/loop/enabled'
const _LOOP_EXCEPTION_PREFIX = 'aseprite/animation/loop/exception_prefix'
const _USE_METADATA = 'aseprite/animation/storage/use_metadata'

# custom preset
const _IMPORT_PRESET_ENABLED = 'aseprite/import/preset/enable_custom_preset'
const _IMPORT_PRESET_KEY = 'aseprite/import/preset/preset'
const _PIXEL_2D_PRESET_CFG = 'res://addons/AsepriteWizard/config/2d_pixel_preset.cfg'

# cleanup
const _REMOVE_SOURCE_FILES_KEY = 'aseprite/import/cleanup/remove_json_file'
const _SET_VISIBLE_TRACK_AUTOMATICALLY = 'aseprite/import/cleanup/automatically_hide_sprites_not_in_animation'


# automatic importer
const _IMPORTER_ENABLE_KEY = 'aseprite/import/import_plugin/enable_automatic_importer'
const _DEFAULT_IMPORTER_KEY = 'aseprite/import/import_plugin/default_automatic_importer'

const IMPORTER_SPRITEFRAMES_NAME = "SpriteFrames"
const IMPORTER_NOOP_NAME = "No Import"

# wizard history
const _HISTORY_CONFIG_FILE_CFG_KEY = 'aseprite/wizard/history/cache_file_path'
const _HISTORY_SINGLE_ENTRY_KEY = 'aseprite/wizard/history/keep_one_entry_per_source_file'
const _DEFAULT_HISTORY_CONFIG_FILE_PATH = 'res://.aseprite_wizard_history'

# IMPORT SETTINGS
const _I_LAST_SOURCE_PATH_KEY = 'i_source'
const _I_LAST_OUTPUT_DIR_KEY = 'i_output'
const _I_SHOULD_SPLIT_LAYERS_KEY = 'i_split_layers'
const _I_EXCEPTIONS_KEY = 'i_exceptions_key'
const _I_ONLY_VISIBLE_LAYERS_KEY = 'i_only_visible_layers'
const _I_CUSTOM_NAME_KEY = 'i_custom_name'
const _I_DO_NOT_CREATE_RES_KEY = 'i_disable_resource_creation'

# export
const _EXPORTER_ENABLE_KEY = 'aseprite/animation/storage/enable_metadata_removal_on_export'

var _editor_settings: EditorSettings

# INTERFACE SETTINGS
var _plugin_icons: Dictionary

#######################################################
# GLOBAL CONFIGS
######################################################

func default_command() -> String:
	return 'aseprite'


func is_command_or_control_pressed() -> String:
	var command = _editor_settings.get(_COMMAND_KEY) if _editor_settings.has_setting(_COMMAND_KEY) else ""
	return command if command != "" else default_command()


#######################################################
# PROJECT SETTINGS
######################################################

# remove this config in the next major version
func is_importer_enabled() -> bool:
	return _get_project_setting(_IMPORTER_ENABLE_KEY, false)


func get_default_importer() -> String:
	return _get_project_setting(_DEFAULT_IMPORTER_KEY, IMPORTER_SPRITEFRAMES_NAME if is_importer_enabled() else IMPORTER_NOOP_NAME)


func is_exporter_enabled() -> bool:
	return _get_project_setting(_EXPORTER_ENABLE_KEY, true)
	

func should_remove_source_files() -> bool:
	return _get_project_setting(_REMOVE_SOURCE_FILES_KEY, true)


func is_default_animation_loop_enabled() -> bool:
	return _get_project_setting(_LOOP_ENABLED, true)


func get_animation_loop_exception_prefix() -> String:
	return _get_project_setting(_LOOP_EXCEPTION_PREFIX, _DEFAULT_LOOP_EX_PREFIX)
	
func is_use_metadata_enabled() -> bool:
	return _get_project_setting(_USE_METADATA, true)


func get_default_exclusion_pattern() -> String:
	return _get_project_setting(_DEFAULT_EXCLUSION_PATTERN_KEY, "")


func is_import_preset_enabled() -> bool:
	return _get_project_setting(_IMPORT_PRESET_ENABLED, false)


func is_single_file_history() -> bool:
	return ProjectSettings.get(_HISTORY_SINGLE_ENTRY_KEY) == true


func get_import_history() -> Array:
	var history = []
	var history_path := _get_history_file_path()

	if not FileAccess.file_exists(history_path):
		return history

	var file_object = FileAccess.open(history_path, FileAccess.READ)

	while not file_object.eof_reached():
		var line = file_object.get_line()
		if line:
			var test_json_conv = JSON.new()
			test_json_conv.parse(line)
			history.push_back(test_json_conv.get_data())

	return history


func is_set_visible_track_automatically_enabled() -> bool:
	return _get_project_setting(_SET_VISIBLE_TRACK_AUTOMATICALLY, false)

# history is saved and retrieved line-by-line so
# file becomes version control friendly
func save_import_history(history: Array):
	var file = FileAccess.open(_get_history_file_path(), FileAccess.WRITE)
	for entry in history:
		file.store_line(JSON.new().stringify(entry))
	file = null


func _get_history_file_path() -> String:
	return _get_project_setting(_HISTORY_CONFIG_FILE_CFG_KEY, _DEFAULT_HISTORY_CONFIG_FILE_PATH)


func create_import_preset_setting() -> void:
	if ProjectSettings.has_setting(_IMPORT_PRESET_KEY) && (ProjectSettings.get_setting(_IMPORT_PRESET_KEY) as Dictionary).size() > 0:
		return

	var preset := ConfigFile.new()
	preset.load(_PIXEL_2D_PRESET_CFG)

	var dict = {}
	for key in preset.get_section_keys("preset"):
		dict[key] = preset.get_value("preset", key)

	_initialize_project_cfg(_IMPORT_PRESET_KEY, dict, TYPE_DICTIONARY)


#######################################################
# IMPORT CONFIGS
######################################################
func get_last_source_path() -> String:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, _I_LAST_SOURCE_PATH_KEY, "")


func set_last_source_path(source_path: String) -> void:
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, _I_LAST_SOURCE_PATH_KEY, source_path)


func get_last_output_path() -> String:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, _I_LAST_OUTPUT_DIR_KEY, "")


func set_last_output_path(output_path: String) -> void:
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, _I_LAST_OUTPUT_DIR_KEY, output_path)


func should_split_layers() -> bool:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, _I_SHOULD_SPLIT_LAYERS_KEY, false)


func set_split_layers(should_split: bool) -> void:
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, _I_SHOULD_SPLIT_LAYERS_KEY, false)


func get_exception_pattern() -> String:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, _I_EXCEPTIONS_KEY, "")


func set_exception_pattern(pattern: String) -> void:
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, _I_EXCEPTIONS_KEY, pattern)


func should_include_only_visible_layers() -> bool:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, _I_ONLY_VISIBLE_LAYERS_KEY, false)


func set_include_only_visible_layers(include_only_visible: bool) -> void:
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, _I_ONLY_VISIBLE_LAYERS_KEY, include_only_visible)


func get_last_custom_name() -> String:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, _I_CUSTOM_NAME_KEY, "")


func set_custom_name(custom_name: String) -> void:
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, _I_CUSTOM_NAME_KEY, custom_name)


func should_not_create_resource() -> bool:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, _I_DO_NOT_CREATE_RES_KEY, false)


func set_do_not_create_resource(do_no_create: bool) -> void:
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, _I_DO_NOT_CREATE_RES_KEY, do_no_create)

#######################################################
# INTERFACE SETTINGS
######################################################

func set_icons(plugin_icons: Dictionary) -> void:
	_plugin_icons = plugin_icons


func get_icon(icon_name: String) -> Texture2D:
	return _plugin_icons[icon_name]


#######################################################
# INITIALIZATION
######################################################
func initialize_project_settings():
	_initialize_project_cfg(_DEFAULT_EXCLUSION_PATTERN_KEY, "", TYPE_STRING)
	_initialize_project_cfg(_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_LOOP_EXCEPTION_PREFIX, _DEFAULT_LOOP_EX_PREFIX, TYPE_STRING)
	_initialize_project_cfg(_USE_METADATA, true, TYPE_BOOL)

	_initialize_project_cfg(_IMPORT_PRESET_ENABLED, false, TYPE_BOOL)

	_initialize_project_cfg(_REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)
	_initialize_project_cfg(
		_DEFAULT_IMPORTER_KEY,
		IMPORTER_NOOP_NAME if is_importer_enabled() else IMPORTER_SPRITEFRAMES_NAME,
		TYPE_STRING,
		PROPERTY_HINT_ENUM,
		"%s,%s" % [IMPORTER_NOOP_NAME, IMPORTER_SPRITEFRAMES_NAME]
	)
	
	_initialize_project_cfg(_EXPORTER_ENABLE_KEY, true, TYPE_BOOL)

	_initialize_project_cfg(_HISTORY_CONFIG_FILE_CFG_KEY, _DEFAULT_HISTORY_CONFIG_FILE_PATH, TYPE_STRING, PROPERTY_HINT_GLOBAL_FILE)
	_initialize_project_cfg(_HISTORY_SINGLE_ENTRY_KEY, false, TYPE_BOOL)

	_initialize_project_cfg(_SET_VISIBLE_TRACK_AUTOMATICALLY, false, TYPE_BOOL)

	ProjectSettings.save()

	_initialize_editor_cfg(_COMMAND_KEY, default_command(), TYPE_STRING)


func clear_project_settings():
	var _all_settings = [
		_DEFAULT_EXCLUSION_PATTERN_KEY,
		_LOOP_ENABLED,
		_LOOP_EXCEPTION_PREFIX,
		_USE_METADATA,
		_IMPORT_PRESET_ENABLED,
		_IMPORT_PRESET_KEY,
		_REMOVE_SOURCE_FILES_KEY,
		_DEFAULT_IMPORTER_KEY,
		_EXPORTER_ENABLE_KEY,
		_HISTORY_CONFIG_FILE_CFG_KEY,
		_HISTORY_SINGLE_ENTRY_KEY,
		_SET_VISIBLE_TRACK_AUTOMATICALLY
	]
	for key in _all_settings:
		ProjectSettings.clear(key)
	ProjectSettings.save()


func _initialize_project_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string = null):
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set(key, default_value)
	ProjectSettings.set_initial_value(key, default_value)
	ProjectSettings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	})


func _get_project_setting(key: String, default_value):
	if not ProjectSettings.has_setting(key):
		return default_value

	var p = ProjectSettings.get(key)
	return p if p != null else default_value


func create_import_file(data: Dictionary) -> void:
	if !ProjectSettings.has_setting(_IMPORT_PRESET_KEY):
		push_warning("no import settings found for 'aseprite_texture' in Project Settings")
		return

	var file_path := "%s.import" % [data.sprite_sheet]
	var import_file := ConfigFile.new()
	if import_file.load(file_path) == OK:
		return

	import_file.set_value("remap", "importer", "texture")
	import_file.set_value("remap", "type", "CompressedTexture2D")
	import_file.set_value("deps", "source_file", data.sprite_sheet)
	var preset: Dictionary = ProjectSettings.get_setting(_IMPORT_PRESET_KEY)
	for key in preset:
		import_file.set_value("params", key, preset[key])
	import_file.save(file_path)


func _initialize_editor_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE):
	if not _editor_settings.has_setting(key):
		_editor_settings.set(key, default_value)
	_editor_settings.set_initial_value(key, default_value, false)
	_editor_settings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
	})
