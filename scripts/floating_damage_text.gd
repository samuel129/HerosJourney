extends Node2D
class_name FloatingDamageText

@export var rise_distance: float = 28.0
@export var duration: float = 0.5
@export var font_size: int = 18

var text_value: String = ""
var text_color: Color = Color.WHITE

func setup(value: String, color: Color, world_pos: Vector2) -> void:
	text_value = value
	text_color = color
	global_position = world_pos + Vector2(randf_range(-10.0, 10.0), -18.0)
	modulate = Color(1, 1, 1, 1)
	scale = Vector2(0.85, 0.85)
	queue_redraw()

func _ready() -> void:
	z_index = 500

	var target_pos: Vector2 = global_position + Vector2(0, -rise_distance)

	var tween: Tween = create_tween()
	tween.parallel().tween_property(self, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self, "scale", Vector2(1.05, 1.05), 0.12)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.finished.connect(queue_free)

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var text_width: float = font.get_string_size(
		text_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x

	draw_string(
		font,
		Vector2(-text_width / 2.0, 0.0),
		text_value,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		text_color
	)