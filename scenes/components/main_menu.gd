extends Node2D

func _on_start_pressed() -> void:
	RunManager.start_new_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/controls.tscn")

func _on_quit_pressed() -> void:
	RunManager.end_run()
	get_tree().quit()
