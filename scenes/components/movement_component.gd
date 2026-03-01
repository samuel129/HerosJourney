class_name MovementComponent
extends Node

@export_subgroup("Settings")
@export var speed: float = 100
@export var sprint_speed: float = 160

func handle_horizontal_movement(body: CharacterBody2D, direction: float, sprinting: bool) -> void:
	var current_speed = sprint_speed if sprinting else speed
	body.velocity.x = direction * current_speed
