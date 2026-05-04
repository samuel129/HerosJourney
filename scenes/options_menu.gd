extends Control

func _ready() -> void:
	var transition_on = RunManager.settings.get("screen_transition", true)
	$AudioOptions/VBoxContainer/ScreenTransitionHBoxContainer5/ScreenTransitionCheckButton.button_pressed = transition_on

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_confirm_pressed() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db($AudioOptions/VBoxContainer/MasterHBoxContainer/MasterSlider.value))
	AudioServer.set_bus_volume_db(1, linear_to_db($AudioOptions/VBoxContainer/SFXHBoxContainer2/SFXSlider.value))
	AudioServer.set_bus_volume_db(2, linear_to_db($AudioOptions/VBoxContainer/MusicHBoxContainer3/MusicSlider.value))
	
	var is_enabled = $AudioOptions/VBoxContainer/ScreenTransitionHBoxContainer5/ScreenTransitionCheckButton.button_pressed
	RunManager.settings["screen_transition"] = is_enabled
	var transition_layer = get_tree().get_first_node_in_group("transition_layer")
	if transition_layer:
		transition_layer.enabled = is_enabled
	$KeybindsSettings.apply_changes()
