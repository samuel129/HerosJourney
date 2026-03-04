class_name AttackComponent
extends Node

@export var combo_fast_hitbox_offset = Vector2(31, 0)
@export var active_timer: Timer
@export var cooldown_timer: Timer
@export var attack_damage := 10
@export var knockback_strength: float = 180.0
@export var knockback_up: float = 40.0
var can_attack = true
var is_attacking = false
var hit_targets := []
var attacker_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	$AttackHitbox.monitoring = false

func handle_hitbox_flip(direction: int, body_position: Vector2) -> void:
	$AttackHitbox.global_position = (direction * combo_fast_hitbox_offset) + body_position
	print(direction * combo_fast_hitbox_offset)

func handle_attack(direction: int, body: CharacterBody2D) -> void:
	can_attack = false
	is_attacking = true
	attacker_pos = body.global_position
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
	hit_targets.clear()

func _on_cooldown_timer_timeout():
	can_attack = true
	is_attacking = false

func _on_attack_hitbox_body_entered(target: Node2D) -> void:
	if target.is_in_group("enemies") and target not in hit_targets:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)
		hit_targets.append(target)
		if target is CharacterBody2D:
			var enemy := target as CharacterBody2D
			var dir : int = sign(enemy.global_position.x - attacker_pos.x)
			if dir == 0:
				dir = 1
			enemy.apply_knockback(Vector2(dir * knockback_strength, -knockback_up))
