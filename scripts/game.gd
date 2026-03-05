extends Node2D

@onready var hud = $HUD
@onready var player = $Player

@onready var level_container: Node = $LevelContainer
@export var enemy_scene: PackedScene
@export var portal_scene: PackedScene
var current_level: Node = null
var active_enemies: Array[Node] = []
var current_level_index: int = -1
var current_stage: int = 1
var player_spawn_position: Vector2 = Vector2.ZERO
var stage_portal_root: Node2D = null
var transitioning_stage: bool = false

@export var respawn_delay: float = 1.0

func _process(_delta):

	if player.has_node("HealthComponent"):
		var hc: HealthComponent = player.get_node("HealthComponent")
		hud.set_hp(hc.current_health, hc.max_health)

	if player.has_node("SpecialMeterComponent"):
		var sm: SpecialMeterComponent = player.get_node("SpecialMeterComponent")
		hud.set_special(sm.special, sm.max_special)

	if player.has_node("ExperienceComponent"):
		var xp: ExperienceComponent = player.get_node("ExperienceComponent")
		hud.set_exp(xp.experience, xp.exp_to_next)

	_prune_active_enemies()
	_try_spawn_stage_portal()
	_try_manual_stage_advance()
		
func _ready():
	if enemy_scene == null:
		enemy_scene = load("res://scenes/enemies/enemy_grunt.tscn")
	if portal_scene == null:
		portal_scene = load("res://scenes/portal_anim.tscn")
	_bind_player_signals()
	var random_level = LevelLoader.pick_random_level()
	current_level_index = LevelLoader.level_scenes.find(random_level)
	if current_level_index < 0:
		current_level_index = 0
	load_level(random_level)
	_hook_hud_signals()

func load_level(level_path: String):
	# Remove previous level
	if current_level:
		current_level.queue_free()
		current_level = null
	clear_active_enemies()
	_clear_stage_portal()
	transitioning_stage = false

	# Instance new level
	var lvl = load(level_path).instantiate()
	level_container.add_child(lvl)
	current_level = lvl

	# Position player at spawn
	if lvl.has_node("PlayerSpawn"):
		var spawn = lvl.get_node("PlayerSpawn").global_position
		player_spawn_position = spawn
		var portal: Node2D = null
		if portal_scene:
			portal = portal_scene.instantiate()
			current_level.add_child(portal)
			portal.global_position = spawn + Vector2(-2, -24)
		player.global_position = spawn
		if player is CharacterBody2D:
			(player as CharacterBody2D).velocity = Vector2.ZERO
		$Camera2D.global_position = spawn
		spawn_enemies(spawn)

func clear_active_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

func _prune_active_enemies() -> void:
	var remaining: Array[Node] = []
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			remaining.append(enemy)
	active_enemies = remaining

func spawn_enemies(spawn: Vector2) -> void:
	if enemy_scene == null or current_level == null:
		return
	var spawn_container := current_level.get_node_or_null("EnemySpawns")
	if spawn_container == null:
		return
	var spawn_points := spawn_container.get_children()
	for marker in spawn_points:
		if marker is Marker2D:
			var enemy = enemy_scene.instantiate()
			current_level.call_deferred("add_child", enemy)
			enemy.global_position = marker.global_position
			active_enemies.append(enemy)

func _bind_player_signals() -> void:
	if player == null or not player.has_signal("player_died"):
		return
	var died_callable := Callable(self, "_on_player_died")
	if not player.is_connected("player_died", died_callable):
		player.connect("player_died", died_callable)

func _on_player_died() -> void:
	if transitioning_stage:
		return
	_handle_player_respawn()

func _handle_player_respawn() -> void:
	transitioning_stage = true
	await get_tree().create_timer(respawn_delay).timeout
	if not is_instance_valid(player):
		transitioning_stage = false
		return
	if player.has_method("respawn_at"):
		player.call("respawn_at", player_spawn_position)
	clear_active_enemies()
	spawn_enemies(player_spawn_position)
	_clear_stage_portal()
	transitioning_stage = false

func _try_spawn_stage_portal() -> void:
	if transitioning_stage:
		return
	if stage_portal_root != null:
		return
	if current_level == null:
		return
	if active_enemies.is_empty():
		_spawn_stage_portal()

func _spawn_stage_portal() -> void:
	if current_level == null:
		return
	stage_portal_root = Node2D.new()
	stage_portal_root.name = "StagePortal"
	current_level.add_child(stage_portal_root)

	var portal_position := _get_stage_portal_position()
	stage_portal_root.global_position = portal_position

	if portal_scene:
		var visuals = portal_scene.instantiate()
		stage_portal_root.add_child(visuals)

	var trigger := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	collision.shape = shape
	trigger.add_child(collision)
	trigger.body_entered.connect(_on_stage_portal_entered)
	stage_portal_root.add_child(trigger)

func _get_stage_portal_position() -> Vector2:
	if current_level and current_level.has_node("EnemySpawns"):
		var spawn_container := current_level.get_node("EnemySpawns")
		var farthest := player_spawn_position
		var max_distance := -1.0
		for child in spawn_container.get_children():
			if child is Marker2D:
				var marker := child as Marker2D
				var distance := marker.global_position.distance_squared_to(player_spawn_position)
				if distance > max_distance:
					max_distance = distance
					farthest = marker.global_position
		if max_distance >= 0.0:
			return farthest + Vector2(0, -24)
	return player_spawn_position + Vector2(220, -24)

func _on_stage_portal_entered(body: Node) -> void:
	if body == null or body != player:
		return
	advance_to_next_stage()

func _try_manual_stage_advance() -> void:
	if transitioning_stage:
		return
	if stage_portal_root == null or not is_instance_valid(stage_portal_root):
		return
	if player == null or not is_instance_valid(player):
		return
	if not Input.is_action_just_pressed("ui_accept"):
		return
	if player.global_position.distance_to(stage_portal_root.global_position) <= 40.0:
		advance_to_next_stage()

func advance_to_next_stage() -> void:
	if transitioning_stage:
		return
	transitioning_stage = true
	current_stage += 1
	if RunManager.is_run_active and RunManager.run_data:
		RunManager.run_data.flags["stage"] = current_stage

	var next_info = LevelLoader.get_next_level(current_level_index)
	var next_path: String = next_info["path"]
	current_level_index = int(next_info["index"])
	if next_path.is_empty():
		transitioning_stage = false
		return
	load_level(next_path)
	if player.has_method("respawn_at"):
		player.call("respawn_at", player_spawn_position)
	$Camera2D.reset_camera()
	transitioning_stage = false

func _clear_stage_portal() -> void:
	if stage_portal_root and is_instance_valid(stage_portal_root):
		stage_portal_root.queue_free()
	stage_portal_root = null

func _hook_hud_signals() -> void:
	# Let the HUD apply upgrades to the player
	if hud and hud.has_method("bind_player"):
		hud.bind_player(player)

	# EXP updates + level up popup
	var xp = player.get_node_or_null("ExperienceComponent")
	if xp:
		# keep the EXP bar accurate without polling (optional but nice)
		if xp.has_signal("exp_changed"):
			xp.exp_changed.connect(func(exp: int, exp_to_next: int, level: int) -> void:
				hud.set_exp(exp, exp_to_next)
			)

		# Level up popup
		if xp.has_signal("leveled_up"):
			xp.leveled_up.connect(func(new_level: int) -> void:
				hud.show_level_up(new_level)
			)	
			
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_L: # press L
		var xp = player.get_node_or_null("ExperienceComponent")
		if xp:
			xp.add_experience(200)
