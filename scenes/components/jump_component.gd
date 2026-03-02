class_name JumpComponent
extends Node

@export_subgroup("Settings")
@export var jump_velocity: float = -350.0
var coyote_time: float = 0.15
var coyote_timer: float = 0.0

var is_jumping: bool = false

func handle_jump(body: CharacterBody2D, delta: float, want_to_jump: bool, holding_jump: bool) -> void:
	if body.is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0, coyote_timer - delta)
	if want_to_jump and (body.is_on_floor() or coyote_timer > 0):
		body.velocity.y = jump_velocity
		coyote_timer = 0
	if not holding_jump and body.velocity.y < 0:
		body.velocity.y = 0
	is_jumping = body.velocity.y < 0 and not body.is_on_floor()
