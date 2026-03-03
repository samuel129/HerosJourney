class_name AttackComponent
extends Node

@export var combo_fast_hitbox_offset = Vector2(31, 0)
@export var active_timer: Timer
@export var cooldown_timer: Timer
var can_attack = true
var is_attacking = false

func handle_hitbox_flip(direction: int, body_position: Vector2) -> void:
	$AttackHitbox.global_position = (direction * combo_fast_hitbox_offset) + body_position
	print(direction * combo_fast_hitbox_offset)

func handle_attack(direction: int, body: CharacterBody2D) -> void:
	can_attack = false
	is_attacking = true
	handle_hitbox_flip(direction, body.global_position)
	$AttackHitbox.monitoring = true
	
	active_timer.wait_time = .25
	cooldown_timer.wait_time = .40
	cooldown_timer.stop()
	active_timer.stop()
	cooldown_timer.start()
	active_timer.start()
	
func _on_active_timer_timeout():
	$AttackHitbox.monitoring = false

func _on_cooldown_timer_timeout():
	can_attack = true
	is_attacking = false
