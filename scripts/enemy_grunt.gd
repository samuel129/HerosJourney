extends CharacterBody2D

@export var move_speed: float = 40.0
@export var gravity: float = 900.0
@export var chase_range: float = 140.0
@export var patrol_distance: float = 56.0
@export var max_health: int = 30
@export var attack_damage: int = 10
@export var attack_range: float = 20.0
@export var attack_vertical_range: float = 24.0
@export var attack_windup: float = 0.22
@export var attack_cooldown_time: float = 0.9

var health: int = 1
var facing: int = 1
var spawn_position: Vector2
var health_bar: ProgressBar
var attack_cooldown: float = 0.0
var attack_windup_timer: float = 0.0
var attack_queued: bool = false
var target_player: Node2D = null
var knockback_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	spawn_position = global_position
	_setup_health_bar()
	_update_health_bar()

func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_windup_timer = maxf(0.0, attack_windup_timer - delta)
	knockback_timer = maxf(0.0, knockback_timer - delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y > 0:
		velocity.y = 0.0
		
	if knockback_timer > 0.0:
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	target_player = player
	var target_direction := float(facing)

	if attack_queued:
		velocity.x = 0.0
		if attack_windup_timer <= 0.0:
			_perform_attack()
		move_and_slide()
		return

	if player != null:
		var dx = player.global_position.x - global_position.x
		var dy = player.global_position.y - global_position.y
		if absf(dx) <= attack_range and absf(dy) <= attack_vertical_range and attack_cooldown <= 0.0:
			facing = 1 if dx >= 0.0 else -1
			$Body.scale.x = -1.0 if facing < 0 else 1.0
			_start_attack()
			move_and_slide()
			return
		if absf(dx) <= chase_range:
			target_direction = signf(dx)
			if target_direction == 0.0:
				target_direction = float(facing)
		else:
			target_direction = 0.0 # Disabled _get_patrol_direction() here
	else:
		target_direction = _get_patrol_direction()

	facing = 1 if target_direction >= 0.0 else -1
	$Body.scale.x = -1.0 if facing < 0 else 1.0
	velocity.x = target_direction * move_speed
	move_and_slide()

func _start_attack() -> void:
	attack_queued = true
	attack_windup_timer = attack_windup
	$Body.color = Color(0.92, 0.25, 0.25, 1.0)

func _perform_attack() -> void:
	attack_queued = false
	attack_cooldown = attack_cooldown_time
	$Body.color = Color(0.55, 0.12, 0.12, 1.0)

	if target_player == null or not is_instance_valid(target_player):
		return

	var dx = target_player.global_position.x - global_position.x
	var dy = target_player.global_position.y - global_position.y
	var in_front = signf(dx) == float(facing) or absf(dx) <= 4.0
	if absf(dx) > attack_range + 8.0 or absf(dy) > attack_vertical_range + 8.0 or not in_front:
		return

	if target_player.has_method("receive_damage"):
		target_player.receive_damage(attack_damage)
		return

	var player_health := target_player.get_node_or_null("HealthComponent")
	if player_health and player_health.has_method("take_damage"):
		player_health.take_damage(attack_damage)

func _get_patrol_direction() -> float:
	var left_limit = spawn_position.x - patrol_distance
	var right_limit = spawn_position.x + patrol_distance
	if global_position.x <= left_limit:
		facing = 1
	elif global_position.x >= right_limit:
		facing = -1
	return float(facing)

func _setup_health_bar() -> void:
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.custom_minimum_size = Vector2(24, 4)
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.position = Vector2(-12, -22)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.12, 0.85)
	health_bar.add_theme_stylebox_override("background", bg_style)

	var fg_style := StyleBoxFlat.new()
	fg_style.bg_color = Color(0.9, 0.2, 0.2, 1.0)
	health_bar.add_theme_stylebox_override("fill", fg_style)
	add_child(health_bar)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = health

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	_update_health_bar()
	if health <= 0:
		queue_free()
		
func apply_knockback(kb_vel: Vector2, duration: float = 0.12) -> void:
	velocity = kb_vel
	knockback_timer = duration
