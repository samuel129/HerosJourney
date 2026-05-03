extends Control
class_name WorldMapSceneArt

const PIXEL: float = 2.0

var _route_types: Array[String] = []
var _selected_index: int = 0

func configure(route_types: Array[String], selected_index: int) -> void:
	_route_types = route_types.duplicate()
	_selected_index = selected_index
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return

	_draw_ocean()
	_draw_main_landmass()
	_draw_route_paths()
	_draw_route_landmarks()
	_draw_start_camp()

func _draw_ocean() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.16, 0.22, 1.0))
	for index in range(18):
		var x: float = 8.0 + float((index * 29) % int(maxf(size.x - 16.0, 16.0)))
		var y: float = 8.0 + float((index * 17) % int(maxf(size.y - 16.0, 16.0)))
		_px_rect(Vector2(x, y), Vector2(10.0, 2.0), Color(0.13, 0.28, 0.34, 0.72))
		_px_rect(Vector2(x + 4.0, y + 2.0), Vector2(8.0, 2.0), Color(0.1, 0.22, 0.29, 0.64))

func _draw_main_landmass() -> void:
	var land: Color = Color(0.32, 0.43, 0.25, 1.0)
	var light_grass: Color = Color(0.43, 0.57, 0.31, 1.0)
	var dark_grass: Color = Color(0.22, 0.31, 0.18, 1.0)
	var cliff: Color = Color(0.23, 0.17, 0.11, 1.0)

	var tiles: Array[Vector2i] = [
		Vector2i(6, 7), Vector2i(7, 6), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 4), Vector2i(11, 4),
		Vector2i(12, 4), Vector2i(13, 5), Vector2i(14, 5), Vector2i(15, 6), Vector2i(16, 7), Vector2i(17, 7),
		Vector2i(18, 8), Vector2i(19, 9), Vector2i(18, 10), Vector2i(17, 11), Vector2i(16, 12), Vector2i(15, 13),
		Vector2i(14, 13), Vector2i(13, 14), Vector2i(12, 14), Vector2i(11, 13), Vector2i(10, 13), Vector2i(9, 12),
		Vector2i(8, 12), Vector2i(7, 11), Vector2i(6, 10), Vector2i(5, 9), Vector2i(5, 8)
	]

	for tile in tiles:
		var tile_pos: Vector2 = _tile_to_pos(tile)
		_px_rect(tile_pos + Vector2(0, 10), Vector2(16, 6), cliff)
		_px_rect(tile_pos, Vector2(16, 12), land)
		_px_rect(tile_pos + Vector2(2, 2), Vector2(6, 2), light_grass)
		if (tile.x + tile.y) % 3 == 0:
			_px_rect(tile_pos + Vector2(10, 6), Vector2(4, 2), dark_grass)

	_draw_map_border()
	_draw_pixel_mountains(Vector2(size.x * 0.18, size.y * 0.24))
	_draw_pixel_forest(Vector2(size.x * 0.72, size.y * 0.72))
	_draw_pixel_ruins(Vector2(size.x * 0.45, size.y * 0.76))

func _draw_map_border() -> void:
	var border: Color = Color(0.78, 0.66, 0.38, 1.0)
	_px_rect(Vector2(0, 0), Vector2(size.x, 2), border)
	_px_rect(Vector2(0, size.y - 2), Vector2(size.x, 2), Color(0.16, 0.1, 0.05, 1.0))
	_px_rect(Vector2(0, 0), Vector2(2, size.y), border.darkened(0.35))
	_px_rect(Vector2(size.x - 2, 0), Vector2(2, size.y), border.darkened(0.45))

func _draw_route_paths() -> void:
	var count: int = _route_types.size()
	if count <= 0:
		return

	var start_point: Vector2 = _get_start_point()
	var points: Array[Vector2] = _get_layout_points(count)
	for index in range(points.size()):
		var route_point: Vector2 = _to_field_position(points[index])
		_draw_pixel_path(start_point, route_point, index)

func _draw_pixel_path(start_point: Vector2, end_point: Vector2, route_index: int) -> void:
	var steps: int = 12
	var path_color: Color = Color(0.57, 0.43, 0.24, 1.0)
	var shadow_color: Color = Color(0.17, 0.11, 0.06, 0.85)
	for step in range(steps + 1):
		var t: float = float(step) / float(steps)
		var wave: float = sin(t * PI + float(route_index)) * 10.0
		var point: Vector2 = start_point.lerp(end_point, t) + Vector2(0.0, wave)
		_px_rect(point + Vector2(-2, 3), Vector2(6, 2), shadow_color)
		_px_rect(point + Vector2(-2, 0), Vector2(6, 4), path_color)

func _draw_route_landmarks() -> void:
	var count: int = _route_types.size()
	if count <= 0:
		return

	var points: Array[Vector2] = _get_layout_points(count)
	for index in range(points.size()):
		var point: Vector2 = _to_field_position(points[index])
		var selected: bool = index == _selected_index
		_draw_route_ground(point, _route_types[index], selected)
		match _route_types[index]:
			"path_elite":
				_draw_elite_fort(point, selected)
			"path_recovery":
				_draw_recovery_shrine(point, selected)
			"path_treasure":
				_draw_treasure_cave(point, selected)
			"path_miniboss":
				_draw_boss_gate(point, selected)
			_:
				_draw_combat_camp(point, selected)

func _draw_route_ground(point: Vector2, route_type: String, selected: bool) -> void:
	var color: Color = _get_route_ground_color(route_type)
	var width: float = 34.0 if selected else 28.0
	var height: float = 22.0 if selected else 18.0
	_px_rect(point + Vector2(-width * 0.5, 4.0), Vector2(width, height), Color(0.12, 0.08, 0.05, 0.7))
	_px_rect(point + Vector2(-width * 0.5, 0.0), Vector2(width, height), color)
	_px_rect(point + Vector2(-width * 0.5 + 4.0, 2.0), Vector2(width - 8.0, 2.0), color.lightened(0.25))
	if selected:
		_draw_selection_corners(point, width, height)

func _draw_selection_corners(point: Vector2, width: float, height: float) -> void:
	var color: Color = Color(1.0, 0.88, 0.42, 1.0)
	var left: float = point.x - width * 0.5 - 4.0
	var right: float = point.x + width * 0.5
	var top: float = point.y - 4.0
	var bottom: float = point.y + height + 2.0
	_px_rect(Vector2(left, top), Vector2(8, 2), color)
	_px_rect(Vector2(left, top), Vector2(2, 8), color)
	_px_rect(Vector2(right - 4.0, top), Vector2(8, 2), color)
	_px_rect(Vector2(right + 2.0, top), Vector2(2, 8), color)
	_px_rect(Vector2(left, bottom), Vector2(8, 2), color)
	_px_rect(Vector2(left, bottom - 6.0), Vector2(2, 8), color)
	_px_rect(Vector2(right - 4.0, bottom), Vector2(8, 2), color)
	_px_rect(Vector2(right + 2.0, bottom - 6.0), Vector2(2, 8), color)

func _draw_start_camp() -> void:
	var point: Vector2 = _get_start_point()
	_px_rect(point + Vector2(-13, 7), Vector2(30, 8), Color(0.18, 0.12, 0.07, 1.0))
	_px_rect(point + Vector2(-10, 3), Vector2(16, 8), Color(0.38, 0.21, 0.1, 1.0))
	_px_rect(point + Vector2(-12, -5), Vector2(20, 8), Color(0.67, 0.24, 0.12, 1.0))
	_px_rect(point + Vector2(-8, -9), Vector2(12, 4), Color(0.88, 0.45, 0.18, 1.0))
	_px_rect(point + Vector2(10, 0), Vector2(4, 8), Color(0.96, 0.54, 0.18, 1.0))
	_px_rect(point + Vector2(8, 8), Vector2(8, 2), Color(0.36, 0.18, 0.08, 1.0))

func _draw_combat_camp(point: Vector2, selected: bool) -> void:
	var y_offset: float = -9.0 if selected else -7.0
	_px_rect(point + Vector2(-8, y_offset), Vector2(4, 14), Color(0.15, 0.11, 0.08, 1.0))
	_px_rect(point + Vector2(4, y_offset), Vector2(4, 14), Color(0.15, 0.11, 0.08, 1.0))
	_px_rect(point + Vector2(-10, y_offset + 2), Vector2(20, 4), Color(0.53, 0.18, 0.12, 1.0))
	_px_rect(point + Vector2(-4, y_offset - 4), Vector2(8, 4), Color(0.8, 0.32, 0.18, 1.0))

func _draw_elite_fort(point: Vector2, selected: bool) -> void:
	var y_offset: float = -14.0 if selected else -12.0
	_px_rect(point + Vector2(-12, y_offset + 8), Vector2(24, 14), Color(0.23, 0.18, 0.18, 1.0))
	_px_rect(point + Vector2(-16, y_offset + 4), Vector2(8, 18), Color(0.34, 0.26, 0.25, 1.0))
	_px_rect(point + Vector2(8, y_offset + 4), Vector2(8, 18), Color(0.34, 0.26, 0.25, 1.0))
	_px_rect(point + Vector2(-14, y_offset), Vector2(4, 4), Color(0.62, 0.18, 0.14, 1.0))
	_px_rect(point + Vector2(10, y_offset), Vector2(4, 4), Color(0.62, 0.18, 0.14, 1.0))
	_px_rect(point + Vector2(-4, y_offset + 14), Vector2(8, 8), Color(0.08, 0.05, 0.04, 1.0))

func _draw_recovery_shrine(point: Vector2, selected: bool) -> void:
	var y_offset: float = -13.0 if selected else -11.0
	_px_rect(point + Vector2(-10, y_offset + 13), Vector2(20, 8), Color(0.24, 0.36, 0.24, 1.0))
	_px_rect(point + Vector2(-6, y_offset + 3), Vector2(12, 14), Color(0.62, 0.76, 0.56, 1.0))
	_px_rect(point + Vector2(-2, y_offset - 5), Vector2(4, 24), Color(0.12, 0.3, 0.16, 1.0))
	_px_rect(point + Vector2(-8, y_offset + 3), Vector2(16, 4), Color(0.12, 0.3, 0.16, 1.0))
	_px_rect(point + Vector2(-4, y_offset + 7), Vector2(8, 2), Color(0.9, 1.0, 0.72, 1.0))

func _draw_treasure_cave(point: Vector2, selected: bool) -> void:
	var y_offset: float = -10.0 if selected else -8.0
	_px_rect(point + Vector2(-16, y_offset + 7), Vector2(32, 14), Color(0.2, 0.15, 0.1, 1.0))
	_px_rect(point + Vector2(-10, y_offset), Vector2(20, 10), Color(0.45, 0.33, 0.18, 1.0))
	_px_rect(point + Vector2(-6, y_offset + 8), Vector2(12, 12), Color(0.05, 0.04, 0.03, 1.0))
	_px_rect(point + Vector2(9, y_offset + 10), Vector2(8, 6), Color(0.89, 0.64, 0.18, 1.0))
	_px_rect(point + Vector2(11, y_offset + 8), Vector2(4, 2), Color(1.0, 0.86, 0.34, 1.0))

func _draw_boss_gate(point: Vector2, selected: bool) -> void:
	var y_offset: float = -17.0 if selected else -15.0
	_px_rect(point + Vector2(-16, y_offset + 6), Vector2(8, 26), Color(0.16, 0.08, 0.1, 1.0))
	_px_rect(point + Vector2(8, y_offset + 6), Vector2(8, 26), Color(0.16, 0.08, 0.1, 1.0))
	_px_rect(point + Vector2(-18, y_offset), Vector2(36, 8), Color(0.31, 0.12, 0.18, 1.0))
	_px_rect(point + Vector2(-6, y_offset + 17), Vector2(12, 15), Color(0.04, 0.02, 0.03, 1.0))
	_px_rect(point + Vector2(-2, y_offset + 9), Vector2(4, 4), Color(0.9, 0.28, 0.25, 1.0))

func _draw_pixel_mountains(origin: Vector2) -> void:
	for index in range(3):
		var base: Vector2 = origin + Vector2(float(index) * 16.0, float(index % 2) * 6.0)
		_px_rect(base + Vector2(-8, 12), Vector2(24, 4), Color(0.2, 0.18, 0.16, 1.0))
		_px_rect(base + Vector2(-4, 8), Vector2(16, 4), Color(0.32, 0.29, 0.24, 1.0))
		_px_rect(base + Vector2(0, 4), Vector2(8, 4), Color(0.42, 0.38, 0.3, 1.0))
		_px_rect(base + Vector2(2, 0), Vector2(4, 4), Color(0.72, 0.72, 0.62, 1.0))

func _draw_pixel_forest(origin: Vector2) -> void:
	for index in range(7):
		var base: Vector2 = origin + Vector2(float(index % 4) * 10.0, float(index / 4) * 9.0)
		_px_rect(base + Vector2(2, 9), Vector2(4, 5), Color(0.21, 0.12, 0.06, 1.0))
		_px_rect(base + Vector2(-2, 5), Vector2(12, 5), Color(0.12, 0.3, 0.16, 1.0))
		_px_rect(base + Vector2(0, 1), Vector2(8, 5), Color(0.18, 0.43, 0.22, 1.0))
		_px_rect(base + Vector2(2, -3), Vector2(4, 5), Color(0.25, 0.56, 0.28, 1.0))

func _draw_pixel_ruins(origin: Vector2) -> void:
	_px_rect(origin + Vector2(-18, 4), Vector2(8, 24), Color(0.44, 0.39, 0.31, 1.0))
	_px_rect(origin + Vector2(8, -2), Vector2(8, 30), Color(0.35, 0.31, 0.25, 1.0))
	_px_rect(origin + Vector2(-20, 0), Vector2(40, 5), Color(0.54, 0.49, 0.38, 1.0))
	_px_rect(origin + Vector2(-14, 12), Vector2(4, 4), Color(0.22, 0.19, 0.16, 1.0))
	_px_rect(origin + Vector2(10, 9), Vector2(4, 4), Color(0.22, 0.19, 0.16, 1.0))

func _get_route_ground_color(route_type: String) -> Color:
	match route_type:
		"path_elite":
			return Color(0.45, 0.18, 0.14, 1.0)
		"path_recovery":
			return Color(0.25, 0.52, 0.29, 1.0)
		"path_treasure":
			return Color(0.62, 0.46, 0.17, 1.0)
		"path_miniboss":
			return Color(0.35, 0.18, 0.43, 1.0)
		_:
			return Color(0.32, 0.4, 0.45, 1.0)

func _get_start_point() -> Vector2:
	return Vector2(round(size.x * 0.1), round(size.y * 0.55))

func _to_field_position(norm: Vector2) -> Vector2:
	return Vector2(round(size.x * norm.x), round(size.y * norm.y))

func _tile_to_pos(tile: Vector2i) -> Vector2:
	return Vector2(float(tile.x) * 14.0, float(tile.y) * 6.0)

func _px_rect(position: Vector2, rect_size: Vector2, color: Color) -> void:
	var pixel_position: Vector2 = Vector2(round(position.x / PIXEL) * PIXEL, round(position.y / PIXEL) * PIXEL)
	var pixel_size: Vector2 = Vector2(maxf(PIXEL, round(rect_size.x / PIXEL) * PIXEL), maxf(PIXEL, round(rect_size.y / PIXEL) * PIXEL))
	draw_rect(Rect2(pixel_position, pixel_size), color)

func _get_layout_points(count: int) -> Array[Vector2]:
	if count <= 1:
		return [Vector2(0.74, 0.48)]
	if count == 2:
		return [Vector2(0.48, 0.7), Vector2(0.78, 0.32)]
	if count == 3:
		return [Vector2(0.36, 0.7), Vector2(0.61, 0.3), Vector2(0.86, 0.62)]
	if count == 4:
		return [Vector2(0.28, 0.68), Vector2(0.5, 0.34), Vector2(0.7, 0.32), Vector2(0.9, 0.62)]

	var result: Array[Vector2] = []
	for index in range(count):
		var progress: float = 0.0 if count <= 1 else float(index) / float(count - 1)
		var y: float = 0.45 + (sin(progress * PI * 2.0) * 0.18)
		result.append(Vector2(0.22 + progress * 0.72, y))
	return result
