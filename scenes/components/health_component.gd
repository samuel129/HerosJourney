class_name HealthComponent
extends Node

var max_health := 1
var current_health := 1

signal died
signal health_changed(new_health, max_health)

func initialize_from_stats(max_hp: int) -> void:
	max_health = max_hp
	current_health = max_hp
	health_changed.emit(current_health, max_health)
	_sync_run_data()

func take_damage(amount: int) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	_sync_run_data()
	
	if current_health <= 0:
		died.emit()

func _sync_run_data() -> void:
	if RunManager.is_run_active and RunManager.run_data:
		RunManager.run_data.stats["health"] = current_health
