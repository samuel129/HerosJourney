extends CanvasLayer

@onready var root: Control = $Root
@onready var stats_label: Label = $Root/VBoxContainer/Stats

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.modulate.a = 0.0
	visible = false

func show_game_over(run_data, shards_earned: int):
	visible = true
	_build_stats(run_data, shards_earned)
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate:a", 1.0, 0.5)

func _build_stats(data, shards_earned: int):
	if data == null:
		stats_label.text = "No run data"
		return

	var stats_text := ""

	# Stage progress
	stats_text += "Stage Reached: %d\n" % data.stage
	stats_text += "Stages Cleared: %d\n" % data.cleared_stages

	# Resources
	stats_text += "Gold Collected: %d\n" % data.resources.get("gold", 0)
	stats_text += "Level Reached: %d\n" % data.resources.get("level", 1)

	# Shards
	stats_text += "Legacy Shards Earned: %d" % shards_earned

	# Display Stats
	stats_label.text = stats_text

func _on_new_game_button_pressed() -> void:
	get_tree().paused = false
	RunManager.end_run()
	RunManager.start_new_run()
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	RunManager.end_run()
	await TransitionLayer.play_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	await TransitionLayer.play_in()
