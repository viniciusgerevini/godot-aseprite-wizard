extends EditorExportPlugin

const wizard_config = preload("../config/wizard_config.gd")

func _export_file(path: String, type: String, features: PoolStringArray) -> void:
	if type != "PackedScene": return

	var scene : PackedScene =  ResourceLoader.load(path, type, true)
	var scene_changed := false
	var root_node := scene.instance(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var nodes := [root_node]

	#remove metadata from scene
	while not nodes.empty():
		var node : Node = nodes.pop_front()

		for child in node.get_children():
			nodes.push_back(child)

		if _remove_meta(node, path):
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
	
func _remove_meta(node:Node, path: String) -> bool:
	if node.has_meta(wizard_config.WIZARD_CONFIG_META_NAME):
		node.remove_meta(wizard_config.WIZARD_CONFIG_META_NAME)
		print("Removed metadata from scene %s" % path)
		return true
		
	return false
	
func _get_scene_content(path:String, scene:PackedScene) -> PoolByteArray:
	var tmp_path = OS.get_cache_dir()  + "tmp_scene." + path.get_extension()
	ResourceSaver.save(tmp_path, scene)

	var tmp_file = File.new()
	tmp_file.open(tmp_path,File.READ)
	var content : PoolByteArray = tmp_file.get_buffer(tmp_file.get_len())
	tmp_file.close()
	
	var dir = Directory.new()

	if dir.file_exists(tmp_path):
		dir.remove(tmp_path)

	return content
