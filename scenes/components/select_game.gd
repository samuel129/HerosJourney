extends Control

@onready var status_label: Label = $Root/Panel/Margin/VBox/Status
@onready var load_button: Button = $Root/Panel/Margin/VBox/LoadButton

func _ready() -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	var has_save: bool = RunManager.has_saved_run()
	load_button.disabled = not has_save
	if has_save:
		status_label.text = "Continue your active run."
	else:
		status_label.text = "No active run save found."

func _on_new_game_pressed() -> void:
	RunManager.start_new_run()
	RunManager.save_current_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_load_game_pressed() -> void:
	if not RunManager.load_saved_run():
		status_label.text = "Failed to load saved run."
		_refresh_ui()
		return
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_back_pressed() -> void:
	await TransitionLayer.play_out()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	await TransitionLayer.play_in()
