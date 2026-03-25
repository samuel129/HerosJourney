class_name HealthComponent
extends Node

signal died
signal health_changed(new_health: int, max_health: int)
signal damage_taken(amount: int)

var max_health: int = 1
var current_health: int = 1

func initialize_from_stats(max_hp: int) -> void:
	max_health = max_hp
	current_health = max_hp
	health_changed.emit(current_health, max_health)
	_sync_run_data()

func take_damage(amount: int) -> void:
	var old_health: int = current_health
	current_health = clamp(current_health - amount, 0, max_health)

	var actual_damage: int = old_health - current_health
	if actual_damage > 0:
		damage_taken.emit(actual_damage)
		_spawn_damage_text(actual_damage)

	health_changed.emit(current_health, max_health)
	_sync_run_data()

	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	health_changed.emit(current_health, max_health)
	_sync_run_data()

func _sync_run_data() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	# Only sync player health into run data
	if not parent_node.is_in_group("player"):
		return

	if RunManager.is_run_active and RunManager.run_data:
		RunManager.run_data.stats["health"] = current_health

func _spawn_damage_text(amount: int) -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	if not (parent_node is Node2D):
		return

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	var text_color: Color
	if parent_node.is_in_group("player"):
		# Player got hit = red
		text_color = Color(1.0, 0.3, 0.3, 1.0)
	else:
		# Enemy got hit = yellow/orange
		text_color = Color(1.0, 0.85, 0.2, 1.0)

	var popup: FloatingDamageText = FloatingDamageText.new()
	var world_pos: Vector2 = (parent_node as Node2D).global_position

	popup.setup(str(amount), text_color, world_pos)
	current_scene.add_child(popup)