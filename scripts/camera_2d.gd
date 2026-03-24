extends Camera2D

@export var follow_target: CharacterBody2D

@export var base_offset: Vector2 = Vector2.ZERO

@export var look_ahead_distance: float = 80.0
@export var look_ahead_speed: float = 6.0

@export var normal_offset_y: float = -20.0
@export var fall_offset_y: float = 60.0
@export var vertical_blend_speed: float = 6.0

var look_offset_x: float = 0.0
var current_offset_y: float = 0.0

var look_offset: Vector2 = Vector2.ZERO
var fall_look_offset_y: float = 0.0

func _ready() -> void:
	reset_camera()

func _process(delta: float) -> void:
	if follow_target == null:
		return

	# Horizontal lookahead
	var vel: Vector2 = follow_target.velocity
	var dir: float = sign(vel.x)

	var target_offset_x: float = look_ahead_distance * dir
	look_offset_x = lerp(look_offset_x, target_offset_x, delta * look_ahead_speed)
	
	var target_offset_y := normal_offset_y
	if vel.y > 60:
		target_offset_y = fall_offset_y
	
	current_offset_y = lerp(current_offset_y, target_offset_y, delta * vertical_blend_speed)

	# Final camera position
	global_position = follow_target.global_position + Vector2(look_offset_x, current_offset_y)
	
func reset_camera() -> void:
	position_smoothing_enabled = false
	look_offset = Vector2.ZERO
	fall_look_offset_y = 0.0
	if follow_target:
		global_position = follow_target.global_position + base_offset
	await get_tree().process_frame
	position_smoothing_enabled = true
