extends Control

func _on_start_pressed() -> void:
	await TransitionLayer.play_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/select_game.tscn")
	await TransitionLayer.play_in()

func _on_controls_pressed() -> void:
	await TransitionLayer.play_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/controls.tscn")
	await TransitionLayer.play_in()

func _on_upgrades_pressed() -> void:
	await TransitionLayer.play_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/perm_upgrades.tscn")
	await TransitionLayer.play_in()
	
func _on_restart_data_pressed() -> void:
	RunManager.reset_all_saved_data()


func _on_quit_pressed() -> void:
	RunManager.end_run()
	get_tree().quit()
