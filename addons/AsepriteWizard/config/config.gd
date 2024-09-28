@tool
extends RefCounted

# GLOBAL SETTINGS
const _CONFIG_SECTION_KEY = 'aseprite'
const _COMMAND_KEY = 'aseprite/general/command_path'

# PROJECT SETTINGS

# animation import defaults
const _DEFAULT_EXCLUSION_PATTERN_KEY = 'aseprite/animation/layers/exclusion_pattern'
const _DEFAULT_ONLY_VISIBLE_LAYERS = 'aseprite/animation/layers/only_include_visible_layers_by_default'
const _DEFAULT_LOOP_EX_PREFIX = '_'
const _LOOP_ENABLED = 'aseprite/animation/loop/enabled'
const _LOOP_EXCEPTION_PREFIX = 'aseprite/animation/loop/exception_prefix'
const _USE_METADATA = 'aseprite/animation/storage/use_metadata'

# cleanup
const _REMOVE_SOURCE_FILES_KEY = 'aseprite/import/cleanup/remove_json_file'
const _SET_VISIBLE_TRACK_AUTOMATICALLY = 'aseprite/import/cleanup/automatically_hide_sprites_not_in_animation'

# automatic importer
const _IMPORTER_ENABLE_KEY = 'aseprite/import/import_plugin/enable_automatic_importer'
const _DEFAULT_IMPORTER_KEY = 'aseprite/import/import_plugin/default_automatic_importer'

const IMPORTER_SPRITEFRAMES_NAME = "SpriteFrames"
const IMPORTER_NOOP_NAME = "No Import"
const IMPORTER_TILESET_TEXTURE_NAME = "Tileset Texture"
const IMPORTER_STATIC_TEXTURE_NAME = "Static Texture"

# wizard history
const _WIZARD_HISTORY = "wizard_history"
const _HISTORY_MAX_ENTRIES = 'aseprite/wizard/history/max_history_entries'
const _HISTORY_DEFAULT_MAX_ENTRIES = 100

# SpriteFrames import last config
const _STANDALONE_SPRITEFRAMES_LAST_IMPORT_CFG = "standalone_sf_last_import_cfg"

# export
const _EXPORTER_ENABLE_KEY = 'aseprite/animation/storage/enable_metadata_removal_on_export'

var _editor_settings: EditorSettings = EditorInterface.get_editor_settings()

#######################################################
# GLOBAL CONFIGS
######################################################

func default_command() -> String:
	match OS.get_name():
		"Windows":
			return "C:\\\\Steam\\steamapps\\common\\Aseprite\\aseprite.exe"
		"macOS":
			return "/Applications/Aseprite.app/Contents/MacOS/aseprite"
		_:
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


func should_include_only_visible_layers_by_default() -> bool:
	return _get_project_setting(_DEFAULT_ONLY_VISIBLE_LAYERS, false)


func get_history_max_entries() -> int:
	return _get_project_setting(_HISTORY_MAX_ENTRIES, _HISTORY_DEFAULT_MAX_ENTRIES)


func get_import_history() -> Array:
	return get_plugin_metadata(_WIZARD_HISTORY, [])


func is_set_visible_track_automatically_enabled() -> bool:
	return _get_project_setting(_SET_VISIBLE_TRACK_AUTOMATICALLY, false)


func save_import_history(history: Array):
	set_plugin_metadata(_WIZARD_HISTORY, history)


#=========================================================
# IMPORT CONFIGS
#=========================================================
## Return config for last import done via standalone SpriteFrames import dock
func get_standalone_spriteframes_last_import_config() -> Dictionary:
	return get_plugin_metadata(_STANDALONE_SPRITEFRAMES_LAST_IMPORT_CFG, {})

## Set config for last import done via standalone SpriteFrames import dock
func set_standalone_spriteframes_last_import_config(data: Dictionary) -> void:
	set_plugin_metadata(_STANDALONE_SPRITEFRAMES_LAST_IMPORT_CFG, data)


func clear_standalone_spriteframes_last_import_config() -> void:
	set_plugin_metadata(_STANDALONE_SPRITEFRAMES_LAST_IMPORT_CFG, {})


func get_plugin_metadata(key: String, default: Variant = null) -> Variant:
	return _editor_settings.get_project_metadata(_CONFIG_SECTION_KEY, key, default)


func set_plugin_metadata(key: String, data: Variant):
	_editor_settings.set_project_metadata(_CONFIG_SECTION_KEY, key, data)


#######################################################
# INITIALIZATION
######################################################
func initialize_project_settings():
	_initialize_project_cfg(_DEFAULT_EXCLUSION_PATTERN_KEY, "", TYPE_STRING)
	_initialize_project_cfg(_DEFAULT_ONLY_VISIBLE_LAYERS, false, TYPE_BOOL)
	_initialize_project_cfg(_LOOP_ENABLED, true, TYPE_BOOL)
	_initialize_project_cfg(_LOOP_EXCEPTION_PREFIX, _DEFAULT_LOOP_EX_PREFIX, TYPE_STRING)
	_initialize_project_cfg(_USE_METADATA, true, TYPE_BOOL)

	_initialize_project_cfg(_REMOVE_SOURCE_FILES_KEY, true, TYPE_BOOL)
	_initialize_project_cfg(
		_DEFAULT_IMPORTER_KEY,
		IMPORTER_SPRITEFRAMES_NAME if is_importer_enabled() else IMPORTER_NOOP_NAME,
		TYPE_STRING,
		PROPERTY_HINT_ENUM,
		"%s,%s,%s,%s" % [IMPORTER_NOOP_NAME, IMPORTER_SPRITEFRAMES_NAME, IMPORTER_TILESET_TEXTURE_NAME, IMPORTER_STATIC_TEXTURE_NAME]
	)

	_initialize_project_cfg(_EXPORTER_ENABLE_KEY, true, TYPE_BOOL)

	_initialize_project_cfg(_HISTORY_MAX_ENTRIES, _HISTORY_DEFAULT_MAX_ENTRIES, TYPE_INT)

	_initialize_project_cfg(_SET_VISIBLE_TRACK_AUTOMATICALLY, false, TYPE_BOOL)

	ProjectSettings.save()

	_initialize_editor_cfg(_COMMAND_KEY, default_command(), TYPE_STRING)


func clear_project_settings():
	var _all_settings = [
		_DEFAULT_EXCLUSION_PATTERN_KEY,
		_LOOP_ENABLED,
		_LOOP_EXCEPTION_PREFIX,
		_USE_METADATA,
		_REMOVE_SOURCE_FILES_KEY,
		_DEFAULT_IMPORTER_KEY,
		_EXPORTER_ENABLE_KEY,
		_HISTORY_MAX_ENTRIES,
		_SET_VISIBLE_TRACK_AUTOMATICALLY,
		_DEFAULT_ONLY_VISIBLE_LAYERS,
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


func _initialize_editor_cfg(key: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE):
	if not _editor_settings.has_setting(key):
		_editor_settings.set(key, default_value)
	_editor_settings.set_initial_value(key, default_value, false)
	_editor_settings.add_property_info({
		"name": key,
		"type": type,
		"hint": hint,
	})
