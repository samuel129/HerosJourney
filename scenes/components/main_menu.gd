extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	RunManage.start_new_run()
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/controls.tscn")

func _on_quit_pressed() -> void:
	RunManage.end_run()
	get_tree().quit()
