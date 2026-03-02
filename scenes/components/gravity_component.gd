class_name GravityComponent
extends Node

@export_subgroup("Settings")
@export var gravity: float = 1000.0
@export var fast_fall_multiplier: float = 2.0

var is_falling = false
var fast_falling: bool = false

func handle_gravity(body: CharacterBody2D, delta: float, fast_falling_input: bool) -> void:
	fast_falling = fast_falling_input
	if not body.is_on_floor():
		var grav = gravity
		# Fast Falling
		if fast_falling and body.velocity.y > 0:
			grav *= fast_fall_multiplier
		body.velocity.y += grav * delta
		
	# Detect Falling
	is_falling = body.velocity.y > 0 and not body.is_on_floor()

func is_near_ground(body: CharacterBody2D) -> bool:
	var rc: RayCast2D = body.get_node("ground_check")
	return rc.is_colliding()
