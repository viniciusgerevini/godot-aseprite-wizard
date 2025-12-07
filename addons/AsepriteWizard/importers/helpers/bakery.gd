@tool
extends RefCounted

const logger = preload("../../config/logger.gd")

func save_bake_file(source_path: String, resource: Resource) -> int:
	var bake_path = _bake_path(source_path)
	var hash = FileAccess.get_md5(source_path)

	resource.set_meta('source_hash', hash)

	var result = ResourceSaver.save(resource, bake_path)
	ResourceLoader.load(bake_path, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)

	return result


func has_bake_file(source_path: String) -> bool:
	var bake_path = _bake_path(source_path)
	return ResourceLoader.exists(bake_path)


func load_bake_file(source_path: String, target_path: String) -> int:
	var source_hash = FileAccess.get_md5(source_path)
	var bake_path = _bake_path(source_path)
	var bake = ResourceLoader.load(bake_path, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)

	if bake.get_meta('source_hash') != source_hash:
		logger.warn("baked file hash does not match current source file", source_path)

	var result = ResourceSaver.save(bake, target_path)

	ResourceLoader.load(target_path, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)

	return result


func load_bake_texture(source_path: String, target_path: String) -> int:
	var source_hash = FileAccess.get_md5(source_path)
	var bake_path = _bake_path(source_path)
	var bake: PortableCompressedTexture2D = ResourceLoader.load(bake_path, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)

	if bake.get_meta('source_hash') != source_hash:
		logger.warn("baked file hash does not match current source file", source_path)


	var tex := PortableCompressedTexture2D.new()
	tex.create_from_image(bake.get_image(), PortableCompressedTexture2D.COMPRESSION_MODE_LOSSLESS)

	var result = ResourceSaver.save(tex, target_path)
	ResourceLoader.load(target_path, "PortableCompressedTexture2D", ResourceLoader.CACHE_MODE_REPLACE_DEEP)

	return result


func delete_bake_file(source_path: String) -> int:
	return DirAccess.remove_absolute(_bake_path(source_path))


func move_bake_file(old_path: String, new_path: String) -> int:
	var old_bake_path = _bake_path(old_path)
	var new_bake_path = _bake_path(new_path)

	return DirAccess.rename_absolute(old_bake_path, new_bake_path)


func _bake_path(source_path: String) -> String:
	var file = source_path.get_file()
	var dir = source_path.get_base_dir()
	return dir.path_join(".%s.ase_bake.res" % file)
