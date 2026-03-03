extends Node

var level_scenes := [
	"res://scenes/levels/green_level.tscn"
]

func pick_random_level() -> String:
	return level_scenes[randi() % level_scenes.size()]
