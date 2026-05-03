extends Control
class_name VendorSceneArt

@export var art_mode: String = "camp"

func _draw() -> void:
	match art_mode:
		"map":
			_draw_map_preview()
		_:
			_draw_camp_scene()

func _draw_camp_scene() -> void:
	var area: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(area, Color(0.05, 0.07, 0.1, 0.94))

	var horizon_y: float = round(size.y * 0.58)
	draw_rect(Rect2(Vector2(0, horizon_y), Vector2(size.x, size.y - horizon_y)), Color(0.12, 0.1, 0.08, 0.9))
	draw_polygon(
		PackedVector2Array([Vector2(0, horizon_y), Vector2(size.x * 0.22, size.y * 0.34), Vector2(size.x * 0.48, horizon_y), Vector2(size.x * 0.72, size.y * 0.28), Vector2(size.x, horizon_y)]),
		PackedColorArray([Color(0.1, 0.13, 0.18, 1.0), Color(0.1, 0.13, 0.18, 1.0), Color(0.1, 0.13, 0.18, 1.0), Color(0.1, 0.13, 0.18, 1.0), Color(0.1, 0.13, 0.18, 1.0)])
	)

	for index in range(12):
		var x: float = 8.0 + float(index) * 26.0
		var y: float = 12.0 + float((index * 17) % 21)
		draw_rect(Rect2(Vector2(x, y), Vector2(1, 1)), Color(0.86, 0.74, 0.48, 0.7))

	_draw_vendor_stall()
	_draw_campfire()

func _draw_vendor_stall() -> void:
	var base_y: float = size.y - 30.0
	var stall_x: float = 28.0
	draw_rect(Rect2(Vector2(stall_x, base_y - 24.0), Vector2(76.0, 24.0)), Color(0.23, 0.13, 0.08, 1.0))
	draw_rect(Rect2(Vector2(stall_x + 6.0, base_y - 20.0), Vector2(64.0, 4.0)), Color(0.56, 0.34, 0.16, 1.0))
	draw_polygon(
		PackedVector2Array([Vector2(stall_x - 6.0, base_y - 24.0), Vector2(stall_x + 8.0, base_y - 52.0), Vector2(stall_x + 84.0, base_y - 52.0), Vector2(stall_x + 96.0, base_y - 24.0)]),
		PackedColorArray([Color(0.44, 0.11, 0.08, 1.0), Color(0.67, 0.22, 0.13, 1.0), Color(0.76, 0.39, 0.18, 1.0), Color(0.44, 0.11, 0.08, 1.0)])
	)
	draw_rect(Rect2(Vector2(stall_x + 16.0, base_y - 16.0), Vector2(8.0, 16.0)), Color(0.16, 0.09, 0.06, 1.0))
	draw_rect(Rect2(Vector2(stall_x + 60.0, base_y - 16.0), Vector2(8.0, 16.0)), Color(0.16, 0.09, 0.06, 1.0))

	draw_circle(Vector2(stall_x + 44.0, base_y - 34.0), 8.0, Color(0.13, 0.08, 0.07, 1.0))
	draw_rect(Rect2(Vector2(stall_x + 38.0, base_y - 26.0), Vector2(14.0, 18.0)), Color(0.19, 0.11, 0.08, 1.0))
	draw_rect(Rect2(Vector2(stall_x + 18.0, base_y - 30.0), Vector2(8.0, 8.0)), Color(0.82, 0.63, 0.25, 1.0))
	draw_rect(Rect2(Vector2(stall_x + 70.0, base_y - 31.0), Vector2(10.0, 9.0)), Color(0.25, 0.46, 0.44, 1.0))

func _draw_campfire() -> void:
	var fire_base: Vector2 = Vector2(size.x - 54.0, size.y - 26.0)
	draw_line(fire_base + Vector2(-12.0, 5.0), fire_base + Vector2(10.0, -2.0), Color(0.3, 0.16, 0.08, 1.0), 3.0)
	draw_line(fire_base + Vector2(12.0, 5.0), fire_base + Vector2(-10.0, -2.0), Color(0.3, 0.16, 0.08, 1.0), 3.0)
	draw_polygon(PackedVector2Array([fire_base + Vector2(-8.0, 2.0), fire_base + Vector2(0.0, -22.0), fire_base + Vector2(8.0, 2.0)]), PackedColorArray([Color(0.86, 0.18, 0.05, 0.95), Color(1.0, 0.65, 0.14, 0.95), Color(0.86, 0.18, 0.05, 0.95)]))
	draw_polygon(PackedVector2Array([fire_base + Vector2(-4.0, 1.0), fire_base + Vector2(2.0, -13.0), fire_base + Vector2(5.0, 1.0)]), PackedColorArray([Color(1.0, 0.82, 0.22, 1.0), Color(1.0, 0.95, 0.45, 1.0), Color(1.0, 0.82, 0.22, 1.0)]))

func _draw_map_preview() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.11, 0.1, 0.08, 0.96))
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.19, 0.16, 0.11, 0.82), false, 1.0)

	var points: Array[Vector2] = [
		Vector2(size.x * 0.14, size.y * 0.7),
		Vector2(size.x * 0.37, size.y * 0.48),
		Vector2(size.x * 0.62, size.y * 0.58),
		Vector2(size.x * 0.86, size.y * 0.32),
	]

	for index in range(points.size() - 1):
		draw_line(points[index], points[index + 1], Color(0.74, 0.54, 0.28, 0.95), 2.0)
		draw_line(points[index] + Vector2(0, 2), points[index + 1] + Vector2(0, 2), Color(0.08, 0.06, 0.04, 0.75), 1.0)

	for index in range(points.size()):
		var point: Vector2 = points[index]
		var node_color: Color = Color(0.34, 0.6, 0.48, 1.0)
		if index == points.size() - 1:
			node_color = Color(0.78, 0.31, 0.2, 1.0)
		draw_circle(point, 5.0, Color(0.06, 0.05, 0.04, 1.0))
		draw_circle(point, 3.5, node_color)

	draw_rect(Rect2(Vector2(size.x * 0.07, size.y * 0.2), Vector2(14, 8)), Color(0.34, 0.22, 0.11, 1.0))
	draw_polygon(PackedVector2Array([Vector2(size.x * 0.07, size.y * 0.2), Vector2(size.x * 0.14, size.y * 0.08), Vector2(size.x * 0.22, size.y * 0.2)]), PackedColorArray([Color(0.55, 0.23, 0.12, 1.0), Color(0.76, 0.37, 0.16, 1.0), Color(0.55, 0.23, 0.12, 1.0)]))
