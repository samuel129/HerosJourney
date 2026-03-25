extends Node
class_name ExperienceComponent

signal exp_changed(current_exp: int, exp_to_next: int, level: int)
signal leveled_up(new_level: int)

@export var base_exp_per_level: int = 100

var level: int = 1
var experience: int = 0
var exp_to_next: int = 100

var current_exp: int:
	get: return experience

var exp_to_next_level: int:
	get: return exp_to_next

func _ready() -> void:
	_recompute_threshold()
	exp_changed.emit(experience, exp_to_next, level)

func _recompute_threshold() -> void:
	exp_to_next = max(base_exp_per_level * level, 1)

func initialize_from_run_data(run_data: Dictionary = {}) -> void:
	var resources := run_data
	if run_data.has("resources") and typeof(run_data["resources"]) == TYPE_DICTIONARY:
		resources = run_data["resources"]

	level = int(resources.get("level", level))
	experience = int(resources.get("experience", experience))

	level = max(level, 1)
	experience = max(experience, 0)

	_recompute_threshold()
	exp_changed.emit(experience, exp_to_next, level)

func export_to_run_data(run_data: Dictionary) -> void:
	if not run_data.has("resources") or typeof(run_data["resources"]) != TYPE_DICTIONARY:
		run_data["resources"] = {}
	var resources: Dictionary = run_data["resources"]

	resources["level"] = level
	resources["experience"] = experience

func add_experience(amount: int) -> void:
	if amount <= 0:
		return

	experience += amount

	while experience >= exp_to_next:
		experience -= exp_to_next
		level += 1
		_recompute_threshold()
		leveled_up.emit(level)

	exp_changed.emit(experience, exp_to_next, level)