class_name AnimationComponent
extends Node

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D

signal spawn_finished
signal attack_finished

var animation_locked: bool = false

func _ready() -> void:
	sprite.play("spawn")
	if not sprite.animation_finished.is_connected(_on_anim_finished):
		sprite.animation_finished.connect(_on_anim_finished)

func play_if_new(anim: String) -> void:
	if animation_locked:
		return
	if sprite.animation != anim:
		sprite.play(anim)

func handle_horizontal_flip(move_direction: float) -> void:
	if animation_locked:
		return
	if move_direction == 0:
		return

	sprite.flip_h = false if move_direction > 0 else true

func handle_move_animation(move_direction: float, sprinting: bool) -> void:
	if animation_locked:
		return
	handle_horizontal_flip(move_direction)
	
	if move_direction == 0:
		play_if_new("idle")
	elif sprinting:
		play_if_new("run")
	else:
		play_if_new("walk")
		
# FIX: When jump is cancelled, the animation should not cancel. 
# jump -> fall -> fall_loop should be the correct sequence of animations, no matter what.
func handle_jump_animation(is_jumping: bool, is_falling: bool) -> void:
	if animation_locked:
		return
	if is_jumping:
		play_if_new("jump")
	elif is_falling:
		if sprite.animation != "fall" and sprite.animation != "fall_loop":
			play_if_new("fall")
			
func handle_attack_animation() -> void:
	if animation_locked:
		return
	animation_locked = true
	sprite.play("combo_fast")
	
	
func _on_anim_finished() -> void:
	if sprite.animation == "combo_fast":
		animation_locked = false
		attack_finished.emit()
		return
	if animation_locked:
		return
	if sprite.animation == "fall":
		sprite.play("fall_loop")
		
func play_spawn_animation() -> void:
	animation_locked = true
	sprite.play("spawn")
	sprite.animation_finished.connect(_on_spawn_anim_finished, CONNECT_ONE_SHOT)

func _on_spawn_anim_finished() -> void:
	if sprite.animation == "spawn":
		animation_locked = false
		spawn_finished.emit()
