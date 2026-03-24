extends Node

var chunk_start: PackedScene = preload("res://scenes/level_chunks/chunk_start.tscn")
var chunk_scenes: Array[PackedScene] = [
	preload("res://scenes/level_chunks/chunk_01.tscn")
]
var chunk_count: int = 5

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

func generate_level() -> Node2D:
	var level_root = Node2D.new()
	level_root.name = "GeneratedLevel"
	var previous_chunk: Node2D = null
	var start = chunk_start.instantiate()
	level_root.add_child(start)
	start.global_position = Vector2.ZERO
	previous_chunk = start
	# Generate Chain
	for i in range(chunk_count):
		var chunk_scene = chunk_scenes.pick_random()
		var new_chunk = chunk_scene.instantiate()
		level_root.add_child(new_chunk)
		var prev_exit = previous_chunk.get_node("Exit") as Marker2D
		var new_entry = new_chunk.get_node("Entry") as Marker2D
		new_chunk.global_position = prev_exit.global_position - new_entry.position
		previous_chunk = new_chunk
	return level_root
