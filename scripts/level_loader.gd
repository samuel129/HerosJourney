extends Node

var chunk_start: PackedScene = preload("res://scenes/level_chunks/chunk_start.tscn")
var chunk_scenes: Array[PackedScene] = [
	preload("res://scenes/level_chunks/chunk_01.tscn"),
	preload("res://scenes/level_chunks/chunk_02.tscn")
]
var chunk_end: PackedScene = preload("res://scenes/level_chunks/chunk_end.tscn")
var chunk_count: int = 5

# Theme Settings
const ROW_HEIGHT := 2
const NUM_THEMES := 5

func generate_level(level_config: Dictionary = {}) -> Node2D:
	var level_root = Node2D.new()
	level_root.name = "GeneratedLevel"
	var total_chunks := int(level_config.get("chunk_count", chunk_count))
	total_chunks = clampi(total_chunks, 1, 12)

	var theme_row := int(level_config.get("theme_row", -1))
	if theme_row < 0:
		theme_row = randi() % NUM_THEMES
	theme_row = clampi(theme_row, 0, NUM_THEMES - 1)

	level_root.set_meta("level_config", level_config.duplicate(true))
	level_root.set_meta("chunk_count", total_chunks)
	level_root.set_meta("theme_row", theme_row)

	var previous_chunk: Node2D = null
	var start = chunk_start.instantiate()
	level_root.add_child(start)
	start.global_position = Vector2.ZERO
	_apply_theme_to_chunk(start, theme_row)
	previous_chunk = start
	# Generate Chain (Normal Chunks)
	for i in range(total_chunks):
		var chunk_scene = chunk_scenes.pick_random()
		var new_chunk = chunk_scene.instantiate()
		level_root.add_child(new_chunk)
		var prev_exit = previous_chunk.get_node("Exit") as Marker2D
		var new_entry = new_chunk.get_node("Entry") as Marker2D
		new_chunk.global_position = prev_exit.global_position - new_entry.position
		_apply_theme_to_chunk(new_chunk, theme_row)
		previous_chunk = new_chunk
	# End Chunk
	var end_chunk = chunk_end.instantiate()
	level_root.add_child(end_chunk)
	var prev_exit = previous_chunk.get_node("Exit") as Marker2D
	var end_entry = end_chunk.get_node("Entry") as Marker2D
	end_chunk.global_position = prev_exit.global_position - end_entry.position
	_apply_theme_to_chunk(end_chunk, theme_row)
	return level_root

func _apply_theme_to_chunk(chunk: Node2D, theme_row: int) -> void:
	var tilemap := chunk.get_node_or_null("Foreground") as TileMapLayer
	if tilemap == null:
		return
	var used_cells = tilemap.get_used_cells()
	for cell in used_cells:
		var source_id = tilemap.get_cell_source_id(cell)
		var atlas_coords = tilemap.get_cell_atlas_coords(cell)
		if source_id == -1: continue
		var new_coords = Vector2i(atlas_coords.x, atlas_coords.y + theme_row * ROW_HEIGHT)
		tilemap.set_cell(cell, source_id, new_coords)
