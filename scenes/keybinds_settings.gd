extends Control

@onready var input_button_Scene = preload("res://scenes/input_button.tscn")
@onready var action_list = $VBoxContainer/ScrollContainer/ActionList

var is_remapping = false
var action_to_remap = null
var remapping_button = null
var pending_changes: Dictionary = {}

var input_actions = {
	"jump": "Jump",
	"move_left": "Move Left",
	"move_down": "Move Down",
	"move_right": "Move Right",
	"combo_fast": "Attack",
	"dash": "Dash",
	"sprint": "Sprint",
}

func _ready() -> void:
	_create_action_list()

func _create_action_list():
	InputMap.load_from_project_settings()
	for item in action_list.get_children():
		item.queue_free()
	for action in input_actions:
		var button = input_button_Scene.instantiate()
		var action_label = button.find_child("LabelAction")
		var input_label = button.find_child("LabelInput")
		
		action_label.text = input_actions[action]
		
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			input_label.text = events[0].as_text().trim_suffix(" - Physical")
		else:
			input_label.text = ""
			
		action_list.add_child(button)
		button.pressed.connect(_on_input_button_pressed.bind(button, action))
		
func _on_input_button_pressed(button, action):
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.find_child("LabelInput").text = "Press a key..."
		
func _input(event):
	if is_remapping:
		if (
			event is InputEventKey ||
			(event is InputEventMouseButton && event.pressed)
		):
			if event is InputEventMouseButton && event.double_click:
				event.double_click = false
				
			pending_changes[action_to_remap] = event
				
			_update_action_list(remapping_button, event)
			
			is_remapping = false
			action_to_remap = null
			remapping_button = null
			accept_event()
			
func _update_action_list(button, event):
	button.find_child("LabelInput").text = event.as_text().trim_suffix(" (Physical)")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func apply_changes():
	for action in pending_changes:
		var existing_events = InputMap.action_get_events(action)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, pending_changes[action])
		for i in range(1, existing_events.size()):
			InputMap.action_add_event(action, existing_events[i])
	pending_changes.clear()

func _on_reset_button_pressed() -> void:
	pending_changes.clear()
	_create_action_list()
