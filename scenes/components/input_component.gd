class_name InputComponent
extends Node

var input_horizontal: float = 0.00

func _process(_delta: float) -> void:
	input_horizontal = Input.get_axis("move_left", "move_right")

func get_jump_input() -> bool:
	return Input.is_action_just_pressed("jump")

func is_jump_held() -> bool:
	return Input.is_action_pressed("jump")
	
func is_sprinting() -> bool:
	return Input.is_action_pressed("sprint")
	
