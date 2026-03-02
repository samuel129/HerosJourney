class_name JumpComponent
extends Node

@export_subgroup("Nodes")
@export var jump_buffer_timer: Timer

@export_subgroup("Settings")
@export var jump_velocity: float = -350.0
var coyote_time: float = 0.15
var coyote_timer: float = 0.0

var is_jumping: bool = false

func handle_jump(body: CharacterBody2D, delta: float, want_to_jump: bool, holding_jump: bool) -> void:
	# Update Coyote Time
	if body.is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(0, coyote_timer - delta)
	# Check for Buffer
	handle_jump_buffer(body, want_to_jump)
	handle_variable_jump_height(body, holding_jump)
	# Jump Logic
	if want_to_jump and (body.is_on_floor() or coyote_timer > 0):
		jump(body)
	is_jumping = body.velocity.y < 0 and not body.is_on_floor()
	
func handle_jump_buffer(body: CharacterBody2D, want_to_jump: bool) -> void:
	if want_to_jump and not body.is_on_floor():
		jump_buffer_timer.start()
	if body.is_on_floor() and not jump_buffer_timer.is_stopped():
		jump(body)
		
func handle_variable_jump_height(body: CharacterBody2D, holding_jump: bool):
	if not holding_jump and body.velocity.y < 0:
		body.velocity.y = 0
		
func jump(body: CharacterBody2D) -> void:
	body.velocity.y = jump_velocity
	coyote_timer = 0
	jump_buffer_timer.stop()
