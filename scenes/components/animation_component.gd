class_name AnimationComponent
extends Node

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D

func _ready() -> void:
	if not sprite.animation_finished.is_connected(_on_anim_finished):
		sprite.animation_finished.connect(_on_anim_finished)

func play_if_new(anim: String) -> void:
	if sprite.animation != anim:
		sprite.play(anim)

func handle_horizontal_flip(move_direction: float) -> void:
	if move_direction == 0:
		return

	sprite.flip_h = false if move_direction > 0 else true
	

func handle_move_animation(move_direction: float, sprinting: bool) -> void:
	handle_horizontal_flip(move_direction)
	
	if move_direction == 0:
		play_if_new("idle")
	elif sprinting:
		play_if_new("run")
	else:
		play_if_new("walk")
		

func handle_jump_animation(is_jumping: bool, is_falling: bool) -> void:
	if is_jumping:
		play_if_new("jump")
	elif is_falling:
		if sprite.animation != "fall" and sprite.animation != "fall_loop":
			play_if_new("fall")
		
func _on_anim_finished() -> void:
	if sprite.animation == "fall":
		sprite.play("fall_loop")
		
