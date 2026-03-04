extends Node2D

@onready var hud = $HUD
@onready var player = $Player

@onready var level_container: Node = $LevelContainer
@export var enemy_scene: PackedScene
@export var portal_scene: PackedScene
var current_level: Node = null
var active_enemies: Array[Node] = []

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
		
func _ready():
	if enemy_scene == null:
		enemy_scene = load("res://scenes/enemies/enemy_grunt.tscn")
	if portal_scene == null:
		portal_scene = load("res://scenes/portal_anim.tscn")
	var random_level = LevelLoader.pick_random_level()
	load_level(random_level)
	_hook_hud_signals()

func load_level(level_path: String):
	# Remove previous level
	if current_level:
		current_level.queue_free()
		current_level = null
	clear_active_enemies()

	# Instance new level
	var lvl = load(level_path).instantiate()
	level_container.add_child(lvl)
	current_level = lvl

	# Position player at spawn
	if lvl.has_node("PlayerSpawn"):
		var spawn = lvl.get_node("PlayerSpawn").global_position
		var portal: Node2D = null
		if portal_scene:
			portal = portal_scene.instantiate()
			current_level.add_child(portal)
			portal.global_position = spawn + Vector2(-2, -24)
		$Player.global_position = spawn
		$Camera2D.global_position = spawn
		spawn_enemies(spawn)

func clear_active_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

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
			current_level.add_child(enemy)
			enemy.global_position = marker.global_position
			active_enemies.append(enemy)

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
