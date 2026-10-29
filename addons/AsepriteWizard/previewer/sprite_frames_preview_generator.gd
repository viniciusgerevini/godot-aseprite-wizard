extends EditorResourcePreviewGenerator


func _generate(resource: Resource, size: Vector2i, metadata: Dictionary) -> Texture2D:
	match resource.resource_path.get_extension():
		"aseprite", "ase":
			var anim: SpriteFrames = resource
			var frame_atlas: AtlasTexture = anim.get_frame_texture(anim.get_animation_names()[0], 0)
			var atlas: Image = frame_atlas.get_image()
			var image: Image = atlas.get_region(frame_atlas.region)

			if !image:
				return null
			image.clear_mipmaps()
			var new_size : Vector2 = image.get_size()
			if new_size.x > size.x:
				new_size.x = size.x
				new_size.y *= size.x / new_size.x
			if new_size.y > size.y:
				new_size.y = size.y
				new_size.x *= size.y / new_size.y
			var new_size_i := Vector2i(new_size).maxi(1);
			image.resize(new_size_i.x, new_size_i.y, Image.INTERPOLATE_NEAREST)
			return ImageTexture.create_from_image(image)
	return null


func _generate_small_preview_automatically() -> bool:
	return true


func _handles(type: String) -> bool:
	return ClassDB.is_parent_class(type, "SpriteFrames")
