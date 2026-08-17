@tool
extends RefCounted
## CPU-based normal map generator.
## Ported from godot_normalMap_generator shaders (distance.gdshader + normalmap.gdshader).

const DEFAULT_PARAMS := {
	"emboss_height": 2.0,
	"bump_height": 8.0,
	"blur": 2,
	"bump": 150,
	"invert_x": false,
	"invert_y": false,
	"with_emboss": true,
	"with_distance": true,
}


static func generate_normal_map(source: Image, params: Dictionary = {}) -> Image:
	var p := DEFAULT_PARAMS.duplicate()
	p.merge(params, true)

	var width := source.get_width()
	var height := source.get_height()

	# Compute distance field from alpha edges
	var distance_field: PackedFloat32Array
	if p.with_distance:
		distance_field = _compute_distance_field(source, width, height)
	else:
		distance_field = PackedFloat32Array()
		distance_field.resize(width * height)
		distance_field.fill(0.0)

	# Precompute grayscale for emboss
	var grayscale: PackedFloat32Array
	if p.with_emboss:
		grayscale = _compute_grayscale(source, width, height)
	else:
		grayscale = PackedFloat32Array()
		grayscale.resize(width * height)
		grayscale.fill(0.0)

	# Build Gaussian kernel if blur > 0
	var kernel: PackedFloat32Array
	var kernel_size: int = 0
	var blur_val: int = int(p.blur)
	if blur_val > 0:
		kernel_size = blur_val * 2 + 1
		kernel = _build_gaussian_kernel(blur_val)
	else:
		kernel = PackedFloat32Array()

	var inv_x: float = -1.0 if p.invert_x else 1.0
	var inv_y: float = -1.0 if p.invert_y else 1.0
	var emboss_h: float = p.emboss_height
	var bump_h: float = p.bump_height
	var bump_val: int = maxi(int(p.bump), 1)
	var bump_factor: float = 255.0 / float(bump_val)
	var with_emboss: bool = p.with_emboss
	var with_distance: bool = p.with_distance

	var result := Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y in range(height):
		for x in range(width):
			var x0 := 0.0
			var x1 := 0.0
			var y0 := 0.0
			var y1 := 0.0
			var distx0 := 0.0
			var distx1 := 0.0
			var disty0 := 0.0
			var disty1 := 0.0

			if blur_val > 0:
				var blur_den := 0.0
				for j in range(-blur_val, blur_val + 1):
					for i in range(-blur_val, blur_val + 1):
						var ki := i + blur_val
						var kj := j + blur_val
						var coef: float = kernel[kj * kernel_size + ki]
						blur_den += coef

						if with_emboss:
							x0 += _sample_grayscale(grayscale, x - 1 + i, y + j, width, height) * coef
							x1 += _sample_grayscale(grayscale, x + 1 + i, y + j, width, height) * coef
							y0 += _sample_grayscale(grayscale, x + i, y - 1 + j, width, height) * coef
							y1 += _sample_grayscale(grayscale, x + i, y + 1 + j, width, height) * coef

						if with_distance:
							distx0 += _sample_field(distance_field, x - 1 + i, y + j, width, height) * coef
							distx1 += _sample_field(distance_field, x + 1 + i, y + j, width, height) * coef
							disty0 += _sample_field(distance_field, x + i, y - 1 + j, width, height) * coef
							disty1 += _sample_field(distance_field, x + i, y + 1 + j, width, height) * coef

				if blur_den > 0.0:
					var inv_den := 1.0 / blur_den
					x0 *= inv_den
					x1 *= inv_den
					y0 *= inv_den
					y1 *= inv_den
					distx0 *= inv_den
					distx1 *= inv_den
					disty0 *= inv_den
					disty1 *= inv_den
			else:
				if with_emboss:
					x0 = _sample_grayscale(grayscale, x - 1, y, width, height)
					x1 = _sample_grayscale(grayscale, x + 1, y, width, height)
					y0 = _sample_grayscale(grayscale, x, y - 1, width, height)
					y1 = _sample_grayscale(grayscale, x, y + 1, width, height)

				if with_distance:
					distx0 = _sample_field(distance_field, x - 1, y, width, height)
					distx1 = _sample_field(distance_field, x + 1, y, width, height)
					disty0 = _sample_field(distance_field, x, y - 1, width, height)
					disty1 = _sample_field(distance_field, x, y + 1, width, height)

			# Apply bump factor to distance values (matching shader)
			distx0 = minf(distx0 * bump_factor, 1.0)
			distx1 = minf(distx1 * bump_factor, 1.0)
			disty0 = minf(disty0 * bump_factor, 1.0)
			disty1 = minf(disty1 * bump_factor, 1.0)

			distx0 = 1.0 - absf(distx0 - 1.0)
			distx1 = 1.0 - absf(distx1 - 1.0)
			disty0 = 1.0 - absf(disty0 - 1.0)
			disty1 = 1.0 - absf(disty1 - 1.0)

			# Compute gradient
			# X uses (left - right) so the normal points away from the slope, matching Godot's
			# OpenGL normal map convention. Y uses (right - left) because Godot's import flips
			# the green channel, which cancels the inversion.
			var dx: float = inv_x * (x0 - x1) * 0.5
			var dy: float = inv_y * (-y0 + y1) * 0.5
			var bx: float = inv_x * (distx0 - distx1) * 0.5
			var by: float = inv_y * (-disty0 + disty1) * 0.5

			# Compute normals
			var ne := Vector3(dx * emboss_h, dy * emboss_h, 1.0).normalized()
			var nb := Vector3(bx * bump_h, by * bump_h, 1.0).normalized()
			var normal := (ne + nb).normalized()

			# Map from [-1,1] to [0,1]
			normal = normal * 0.5 + Vector3(0.5, 0.5, 0.5)

			# Preserve source alpha
			var src_alpha: float = source.get_pixel(x, y).a
			result.set_pixel(x, y, Color(normal.x, normal.y, normal.z, src_alpha))

	return result


static func _compute_grayscale(img: Image, w: int, h: int) -> PackedFloat32Array:
	var data := PackedFloat32Array()
	data.resize(w * h)
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			data[y * w + x] = c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
	return data


static func _compute_distance_field(img: Image, w: int, h: int) -> PackedFloat32Array:
	# Two-pass approximate distance transform (Danielsson-style).
	# Computes normalized distance from each opaque pixel to nearest transparent edge.
	var INF_DIST := float(w + h)
	var dist := PackedFloat32Array()
	dist.resize(w * h)

	# Initialize: transparent pixels = 0, opaque pixels = INF
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a < 0.01:
				dist[y * w + x] = 0.0
			else:
				dist[y * w + x] = INF_DIST

	# Forward pass (top-left to bottom-right)
	for y in range(h):
		for x in range(w):
			var idx := y * w + x
			var d := dist[idx]
			if x > 0:
				d = minf(d, dist[idx - 1] + 1.0)
			if y > 0:
				d = minf(d, dist[(y - 1) * w + x] + 1.0)
			if x > 0 and y > 0:
				d = minf(d, dist[(y - 1) * w + x - 1] + 1.414)
			if x < w - 1 and y > 0:
				d = minf(d, dist[(y - 1) * w + x + 1] + 1.414)
			dist[idx] = d

	# Backward pass (bottom-right to top-left)
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var idx := y * w + x
			var d := dist[idx]
			if x < w - 1:
				d = minf(d, dist[idx + 1] + 1.0)
			if y < h - 1:
				d = minf(d, dist[(y + 1) * w + x] + 1.0)
			if x < w - 1 and y < h - 1:
				d = minf(d, dist[(y + 1) * w + x + 1] + 1.414)
			if x > 0 and y < h - 1:
				d = minf(d, dist[(y + 1) * w + x - 1] + 1.414)
			dist[idx] = d

	# Normalize to [0, 1] range by max possible distance
	var max_dist := 0.0
	for i in range(dist.size()):
		if dist[i] > max_dist and dist[i] < INF_DIST:
			max_dist = dist[i]

	if max_dist > 0.0:
		var inv_max := 1.0 / max_dist
		for i in range(dist.size()):
			dist[i] = minf(dist[i] * inv_max, 1.0)

	return dist


static func _build_gaussian_kernel(radius: int) -> PackedFloat32Array:
	var size := radius * 2 + 1
	var kernel := PackedFloat32Array()
	kernel.resize(size * size)
	var sigma := float(radius) / 3.0
	var two_sigma_sq := 2.0 * sigma * sigma

	for j in range(-radius, radius + 1):
		for i in range(-radius, radius + 1):
			var d_sq := float(i * i + j * j)
			var val := exp(-d_sq / two_sigma_sq) / (PI * two_sigma_sq)
			kernel[(j + radius) * size + (i + radius)] = val

	return kernel


static func _sample_grayscale(data: PackedFloat32Array, x: int, y: int, w: int, h: int) -> float:
	if x < 0 or x >= w or y < 0 or y >= h:
		return 0.0
	return data[y * w + x]


static func _sample_field(data: PackedFloat32Array, x: int, y: int, w: int, h: int) -> float:
	if x < 0 or x >= w or y < 0 or y >= h:
		return 0.0
	return data[y * w + x]
