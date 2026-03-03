extends Node2D

@export var level_container: Node
var current_level: Node = null

func _ready():
	var random_level = LevelLoader.pick_random_level()
	load_level(random_level)

func load_level(level_path: String):
	# Remove previous level
	if current_level:
		current_level.queue_free()
		current_level = null

	# Instance new level
	var lvl = load(level_path).instantiate()
	level_container.add_child(lvl)
	current_level = lvl

	# Position player at spawn
	if lvl.has_node("PlayerSpawn"):
		var spawn = lvl.get_node("PlayerSpawn").global_position
		$Player.global_position = spawn
		$Camera2D.global_position = spawn
