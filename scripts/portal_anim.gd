extends Node2D
class_name PortalAnim

signal appear_finished
signal disappear_finished

@export var sprite: AnimatedSprite2D

func _ready():
	add_to_group("spawn_portal")
	sprite.play("default")
	await get_tree().process_frame
	play_appear()

func play_appear():
	scale = Vector2(0.0, 1.6)  # stretched vertically
	modulate.a = 0.0

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(self, "scale", Vector2(1,1), 0.35)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.35)

	await tween.finished
	appear_finished.emit()

func play_disappear():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN)

	tween.parallel().tween_property(self, "scale", Vector2(0.0, 1.6), 0.35)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.35)

	await tween.finished
	disappear_finished.emit()
	queue_free()
