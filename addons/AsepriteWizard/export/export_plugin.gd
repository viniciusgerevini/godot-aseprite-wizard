## This export plugin makes sure all textures are included in
## the exported game and also remove any metadata that could
## potentially leak information about paths in the host system. 
extends EditorExportPlugin

const wizard_config = preload("../config/wizard_config.gd")

func _get_name():
	return "aseprite_wizard_metadata_export_plugin"


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	match type:
		"PackedScene":
			_cleanup_scene(path, type)
		"SpriteFrames":
			_handle_spriteframes(path, type)


func _cleanup_scene(path: String, type: String):
	var scene : PackedScene =  ResourceLoader.load(path, type, ResourceLoader.CACHE_MODE_IGNORE)
	var scene_changed := false
	var root_node := scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var nodes := [root_node]

	#remove_at metadata from scene
	while not nodes.is_empty():
		var node : Node = nodes.pop_front()

		for child in node.get_children():
			nodes.push_back(child)

		if _remove_meta(node):
			scene_changed = true

	#save scene if changed
	if scene_changed:
		var filtered_scene := PackedScene.new()
		if filtered_scene.pack(root_node) != OK:
			print("Error updating scene")
			return

		var content := _get_scene_content(path, filtered_scene)

		add_file(path, content, true)

	root_node.free()


func _remove_meta(node: Object) -> bool:
	if node.has_meta(wizard_config.WIZARD_CONFIG_META_NAME):
		node.remove_meta(wizard_config.WIZARD_CONFIG_META_NAME)
		return true

	return false


func _get_scene_content(path:String, scene:PackedScene) -> PackedByteArray:
	var tmp_path = OS.get_cache_dir()  + "tmp_scene." + path.get_extension()
	ResourceSaver.save(scene, tmp_path)

	var tmp_file = FileAccess.open(tmp_path, FileAccess.READ)
	var content : PackedByteArray = tmp_file.get_buffer(tmp_file.get_length())
	tmp_file.close()

	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)

	return content

## As of today, Godot only includes in the export the resources
## directly referenced by the import plugin.
## To make the generated textures available, I need to explicitly
## add them to the exported package.
func _import_extra_textures(node: SpriteFrames):
	# check if this is a wizard import
	if not node.has_meta("imported_via_aw"):
		return

	var animations = node.get_animation_names()
	var textures = []
	for animation in animations:
		var frame_count = node.get_frame_count(animation)
		for idx in range(frame_count):
			var atlas = node.get_frame_texture(animation, idx)
			if atlas == null:
				continue
			var tex = atlas.atlas
			if tex == null:
				continue
			if not textures.has(tex.resource_path):
				textures.push_back(tex.resource_path)

	for texture_path in textures:
		var file = FileAccess.open(texture_path, FileAccess.READ)
		var content : PackedByteArray = file.get_buffer(file.get_length())
		add_file(texture_path, content, false)


func _handle_spriteframes(path: String, type: String):
	var resource : SpriteFrames = ResourceLoader.load(path, type, ResourceLoader.CACHE_MODE_IGNORE)
	_import_extra_textures(resource)
	if _remove_meta(resource):
		var content := _create_temp_resource(path, resource)
		add_file(path, content, true)


func _create_temp_resource(path: String, resource: SpriteFrames) -> PackedByteArray:
	var tmp_path = OS.get_cache_dir() + "tmp_spriteframes_resource." + path.get_extension()
	ResourceSaver.save(resource, tmp_path)

	var tmp_file = FileAccess.open(tmp_path, FileAccess.READ)
	var content : PackedByteArray = tmp_file.get_buffer(tmp_file.get_length())
	tmp_file.close()

	if FileAccess.file_exists(tmp_path):
		DirAccess.remove_absolute(tmp_path)

	return content
