class_name DashComponent
extends Node

@export var active_timer: Timer
@export var cooldown_timer: Timer
var can_dash = true
var is_dashing = false
var dashes = 1
var max_dashes = 1
signal dash_complete

func _ready() -> void:
	return

func handle_dash() -> void:
	if dashes <= 0:
		return
	can_dash = false
	is_dashing = true
	
	cooldown_timer.wait_time = .25
	cooldown_timer.stop()
	cooldown_timer.start()
	active_timer.wait_time = .18
	active_timer.stop()
	active_timer.start()

func decrement_dashes() -> void:
	dashes -= 1
	if dashes <= 0:
		can_dash = false

func _on_active_timer_timeout():
	is_dashing = false
	dash_complete.emit()
	return

func reset_dashes() -> void:
	dashes = max_dashes
	can_dash = true

func _on_cooldown_timer_timeout() -> void:
	if dashes > 0:
		can_dash = true
