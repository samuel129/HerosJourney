extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func setup_from_sprite(source: AnimatedSprite2D) -> void:
	var lifetime: float = 0.18
	global_position = source.global_position
	scale = source.global_scale
	rotation = source.global_rotation

	sprite.sprite_frames = source.sprite_frames
	sprite.animation = source.animation
	sprite.frame = source.frame
	sprite.flip_h = source.flip_h
	sprite.offset = source.offset
	sprite.centered = source.centered
	sprite.pause()

	sprite.modulate = Color(0.4, 0.75, 1.0, 0.55)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)
