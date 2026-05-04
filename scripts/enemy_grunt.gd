extends CharacterBody2D

enum ThreatTier {
	BASIC,
	MINI_BOSS,
	BOSS
}

@export var threat_tier: ThreatTier = ThreatTier.BASIC

@export var move_speed: float = 40.0
@export var gravity: float = 900.0
@export var chase_range: float = 70.0
@export var patrol_distance: float = 56.0
@export var max_health: int = 30
@export var attack_damage: int = 10
@export var attack_range: float = 20.0
@export var attack_vertical_range: float = 24.0
@export var attack_windup: float = 0.22
@export var attack_cooldown_time: float = 0.9
@export var enable_ranged_attack: bool = false
@export var ranged_projectile_scene: PackedScene
@export var ranged_attack_range: float = 210.0
@export var ranged_attack_min_range: float = 36.0
@export var ranged_attack_vertical_range: float = 60.0
@export var ranged_windup: float = 0.32
@export var ranged_cooldown_time: float = 1.6
@export_range(0.0, 1.0, 0.01) var ranged_point_blank_chance: float = 0.2
@export var projectile_speed: float = 170.0
@export var projectile_damage: int = 10
@export var ranged_projectile_count: int = 1
@export var ranged_projectile_spread_degrees: float = 0.0

# Rewards
@export var xp_reward: int = -1
@export var gold_reward: int = -1
@export_range(0.0, 1.0, 0.01) var drop_chance: float = 0.0
@export var drop_scene: PackedScene

var facing: int = 1
var spawn_position: Vector2
var health_bar: ProgressBar
var attack_cooldown: float = 0.0
var attack_windup_timer: float = 0.0
var attack_queued: bool = false
var ranged_cooldown: float = 0.0
var ranged_windup_timer: float = 0.0
var ranged_attack_queued: bool = false
var target_player: Node2D = null
var knockback_timer: float = 0.0
var base_body_color: Color = Color(0.55, 0.12, 0.12, 1.0)

var lava_damage_cooldown: float = 0.0

var health_component: HealthComponent

func _ready() -> void:
	add_to_group("enemies")
	spawn_position = global_position
	_cache_base_body_color()

	if xp_reward < 0:
		xp_reward = _get_default_xp_reward()
	if gold_reward < 0:
		gold_reward = _get_default_gold_reward()

	_ensure_health_component()
	_setup_health_bar()
	_update_health_bar()

func _ensure_health_component() -> void:
	var existing: HealthComponent = get_node_or_null("HealthComponent") as HealthComponent
	if existing:
		health_component = existing
	else:
		health_component = HealthComponent.new()
		health_component.name = "HealthComponent"
		add_child(health_component)

	health_component.max_health = max_health
	health_component.current_health = max_health

	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)

	health_component.health_changed.emit(
		health_component.current_health,
		health_component.max_health
	)

func _physics_process(delta: float) -> void:
	lava_damage_cooldown = maxf(0.0, lava_damage_cooldown - delta)

	if lava_damage_cooldown <= 0.0 and _is_in_lava():
		take_damage(10)
		lava_damage_cooldown = 0.5
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_windup_timer = maxf(0.0, attack_windup_timer - delta)
	ranged_cooldown = maxf(0.0, ranged_cooldown - delta)
	ranged_windup_timer = maxf(0.0, ranged_windup_timer - delta)
	knockback_timer = maxf(0.0, knockback_timer - delta)

	if not is_on_floor():
		velocity.y += gravity * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	if knockback_timer > 0.0:
		move_and_slide()
		return

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

	target_player = player
	var target_direction: float = float(facing)

	if attack_queued:
		velocity.x = 0.0
		if attack_windup_timer <= 0.0:
			_perform_attack()
		move_and_slide()
		return
	if ranged_attack_queued:
		velocity.x = 0.0
		if ranged_windup_timer <= 0.0:
			_perform_ranged_attack()
		move_and_slide()
		return

	if player != null:
		var dx: float = player.global_position.x - global_position.x
		var dy: float = player.global_position.y - global_position.y
		var can_melee: bool = absf(dx) <= attack_range and absf(dy) <= attack_vertical_range and attack_cooldown <= 0.0

		if can_melee:
			facing = 1 if dx >= 0.0 else -1
			$Body.scale.x = -1.0 if facing < 0 else 1.0
			if _should_use_ranged_in_melee():
				_start_ranged_attack()
			else:
				_start_attack()
			move_and_slide()
			return

		if _can_use_ranged_attack(dx, dy):
			facing = 1 if dx >= 0.0 else -1
			$Body.scale.x = -1.0 if facing < 0 else 1.0
			_start_ranged_attack()
			move_and_slide()
			return

		if absf(dx) <= chase_range:
			target_direction = signf(dx)
			if target_direction == 0.0:
				target_direction = float(facing)
		else:
			target_direction = 0.0
	else:
		target_direction = _get_patrol_direction()

	facing = 1 if target_direction >= 0.0 else -1
	$Body.scale.x = -1.0 if facing < 0 else 1.0
	var target_speed = target_direction * move_speed
	#velocity.x = move_toward(velocity.x, target_speed, 200 * delta)
	velocity.x = target_speed
	move_and_slide()

func _start_attack() -> void:
	attack_queued = true
	attack_windup_timer = attack_windup
	_set_body_color(Color(0.92, 0.25, 0.25, 1.0))

func _perform_attack() -> void:
	attack_queued = false
	attack_cooldown = attack_cooldown_time
	_set_body_color(base_body_color)

	if target_player == null or not is_instance_valid(target_player):
		return

	var dx: float = target_player.global_position.x - global_position.x
	var dy: float = target_player.global_position.y - global_position.y
	var in_front: bool = signf(dx) == float(facing) or absf(dx) <= 4.0

	if absf(dx) > attack_range + 8.0 or absf(dy) > attack_vertical_range + 8.0 or not in_front:
		return

	if target_player.has_method("receive_damage"):
		target_player.receive_damage(attack_damage)
		return

	var player_health: HealthComponent = target_player.get_node_or_null("HealthComponent") as HealthComponent
	if player_health and player_health.has_method("take_damage"):
		player_health.take_damage(attack_damage)

func _start_ranged_attack() -> void:
	ranged_attack_queued = true
	ranged_windup_timer = ranged_windup
	_set_body_color(Color(1.0, 0.55, 0.28, 1.0))

func _perform_ranged_attack() -> void:
	ranged_attack_queued = false
	ranged_cooldown = ranged_cooldown_time
	_set_body_color(base_body_color)

	if ranged_projectile_scene == null:
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	var spawn_position_local: Vector2 = global_position + Vector2(float(facing) * 14.0, -6.0)
	var direction_to_target: Vector2 = Vector2(float(facing), 0.0)
	if target_player and is_instance_valid(target_player):
		var candidate_direction: Vector2 = target_player.global_position - spawn_position_local
		if candidate_direction.length_squared() > 0.0001:
			direction_to_target = candidate_direction.normalized()

	var projectile_count: int = maxi(ranged_projectile_count, 1)
	var spread_radians: float = deg_to_rad(ranged_projectile_spread_degrees)
	for projectile_index in range(projectile_count):
		var shot_direction: Vector2 = direction_to_target
		if projectile_count > 1:
			var spread_alpha: float = 0.0 if projectile_count <= 1 else float(projectile_index) / float(projectile_count - 1)
			var angle_offset: float = lerpf(-spread_radians * 0.5, spread_radians * 0.5, spread_alpha)
			shot_direction = direction_to_target.rotated(angle_offset)

		var projectile: Node = ranged_projectile_scene.instantiate()
		parent_node.add_child(projectile)
		if projectile is Node2D:
			(projectile as Node2D).global_position = spawn_position_local

		if projectile.has_method("launch"):
			projectile.call("launch", shot_direction, projectile_speed, projectile_damage, self)

func _can_use_ranged_attack(dx: float, dy: float) -> bool:
	if not enable_ranged_attack:
		return false
	if ranged_projectile_scene == null:
		return false
	if ranged_cooldown > 0.0:
		return false
	var horizontal_distance: float = absf(dx)
	if horizontal_distance < ranged_attack_min_range:
		return false
	if horizontal_distance > ranged_attack_range:
		return false
	if absf(dy) > ranged_attack_vertical_range:
		return false
	if not _has_clear_ranged_line_of_sight():
		return false
	return true

func _should_use_ranged_in_melee() -> bool:
	if not enable_ranged_attack:
		return false
	if ranged_projectile_scene == null:
		return false
	if ranged_cooldown > 0.0:
		return false
	if not _has_clear_ranged_line_of_sight():
		return false
	return randf() < ranged_point_blank_chance

func _has_clear_ranged_line_of_sight() -> bool:
	if target_player == null or not is_instance_valid(target_player):
		return false

	var shot_origin: Vector2 = global_position + Vector2(float(facing) * 14.0, -6.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(shot_origin, target_player.global_position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [get_rid()]

	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()

func _cache_base_body_color() -> void:
	var body_node: Node = get_node_or_null("Body")
	if body_node is Polygon2D:
		base_body_color = (body_node as Polygon2D).color

func _set_body_color(color: Color) -> void:
	var body_node: Node = get_node_or_null("Body")
	if body_node is Polygon2D:
		(body_node as Polygon2D).color = color

func _get_patrol_direction() -> float:
	var left_limit: float = spawn_position.x - patrol_distance
	var right_limit: float = spawn_position.x + patrol_distance

	if global_position.x <= left_limit:
		facing = 1
	elif global_position.x >= right_limit:
		facing = -1

	return float(facing)

func _setup_health_bar() -> void:
	var bar_width: float = 24.0
	var bar_y: float = -22.0
	match threat_tier:
		ThreatTier.MINI_BOSS:
			bar_width = 38.0
			bar_y = -34.0
		ThreatTier.BOSS:
			bar_width = 54.0
			bar_y = -44.0

	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = max_health
	health_bar.custom_minimum_size = Vector2(bar_width, 4)
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar.position = Vector2(-bar_width * 0.5, bar_y)

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.12, 0.12, 0.85)
	health_bar.add_theme_stylebox_override("background", bg_style)

	var fg_style: StyleBoxFlat = StyleBoxFlat.new()
	fg_style.bg_color = Color(0.9, 0.2, 0.2, 1.0)
	health_bar.add_theme_stylebox_override("fill", fg_style)

	add_child(health_bar)

func _update_health_bar() -> void:
	if health_bar and health_component:
		health_bar.max_value = health_component.max_health
		health_bar.value = health_component.current_health

func _on_health_changed(new_health: int, new_max_health: int) -> void:
	if health_bar:
		health_bar.max_value = new_max_health
		health_bar.value = new_health

func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)

func _on_died() -> void:
	_award_rewards()
	queue_free()

func _award_rewards() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var xp_component: Node = player.get_node_or_null("ExperienceComponent")
	if xp_component and xp_component.has_method("add_experience"):
		xp_component.add_experience(xp_reward)

	# Future gold support
	# if player.has_method("add_gold"):
	# 	player.add_gold(gold_reward)

	# Future item/drop support
	if drop_scene != null and randf() <= drop_chance:
		var drop_instance: Node = drop_scene.instantiate()
		if drop_instance:
			get_parent().add_child(drop_instance)
			if drop_instance is Node2D:
				(drop_instance as Node2D).global_position = global_position

func apply_knockback(kb_vel: Vector2, duration: float = 0.12) -> void:
	velocity = kb_vel
	knockback_timer = duration

func _get_default_xp_reward() -> int:
	match threat_tier:
		ThreatTier.BASIC:
			return 25
		ThreatTier.MINI_BOSS:
			return 100
		ThreatTier.BOSS:
			return 300
	return 25

func _get_default_gold_reward() -> int:
	match threat_tier:
		ThreatTier.BASIC:
			return 5
		ThreatTier.MINI_BOSS:
			return 25
		ThreatTier.BOSS:
			return 100
	return 5

func _is_in_lava() -> bool:
	var game = get_tree().get_first_node_in_group("game")
	if game == null or game.current_level == null:
		return false

	var feet_pos = global_position + Vector2(0, 10)

	for chunk in game.current_level.get_children():
		var lava = chunk.get_node_or_null("Lava")
		if lava == null:
			continue

		var local_pos = lava.to_local(feet_pos)
		var cell = lava.local_to_map(local_pos)

		var tile_data = lava.get_cell_tile_data(cell)

		if tile_data != null:
			return true

	return false
