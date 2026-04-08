extends Area2D

@export var chunk_root: Node2D

var triggered := false

func _on_body_entered(body):
	if triggered:
		return
	if not body.is_in_group("player"):
		return

	triggered = true
	chunk_root.activate_arena()
