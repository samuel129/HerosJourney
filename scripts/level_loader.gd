extends Node

var level_scenes := [
	"res://scenes/levels/green_level.tscn",
	"res://scenes/levels/yellow_level.tscn"
]

func pick_random_level() -> String:
	return level_scenes[randi() % level_scenes.size()]

func get_next_level(current_index: int) -> Dictionary:
	if level_scenes.is_empty():
		return {"path": "", "index": 0}
	var next_index := posmod(current_index + 1, level_scenes.size())
	return {
		"path": level_scenes[next_index],
		"index": next_index
	}
