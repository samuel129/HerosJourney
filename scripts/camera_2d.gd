extends Camera2D

@export var follow_target: CharacterBody2D
@export var gravity_component: GravityComponent

@export var base_offset: Vector2 = Vector2.ZERO

@export var look_ahead_distance: float = 80.0
@export var look_ahead_speed: float = 6.0

@export var fast_fall_look_distance: float = 40.0 # how far down the camera looks
@export var fast_fall_look_speed: float = 8.0 # how quickly it adjusts

var look_offset: Vector2 = Vector2.ZERO
var fall_look_offset_y: float = 0.0


func _process(delta: float) -> void:
	if follow_target == null:
		return

	# Horizontal lookahead
	var vel: Vector2 = follow_target.velocity
	var dir: float = sign(vel.x)

	var target_offset_x: float = look_ahead_distance * dir
	look_offset.x = lerp(look_offset.x, target_offset_x, delta * look_ahead_speed)

	# Vertical look when fast-falling
	var target_fall_offset_y: float = 0.0

	if gravity_component != null and gravity_component.fast_falling:
		target_fall_offset_y = fast_fall_look_distance

	fall_look_offset_y = lerp(fall_look_offset_y, target_fall_offset_y, delta * fast_fall_look_speed)

	# Final camera position
	var final_offset: Vector2 = base_offset + Vector2(look_offset.x, fall_look_offset_y)
	global_position = follow_target.global_position + final_offset
