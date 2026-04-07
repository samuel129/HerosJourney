extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/select_game.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/controls.tscn")

func _on_upgrades_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/perm_upgrades.tscn")

func _on_restart_data_pressed() -> void:
	RunManager.reset_all_saved_data()


func _on_quit_pressed() -> void:
	RunManager.end_run()
	get_tree().quit()
