extends Node
class_name SpecialMeterComponent

signal special_changed(current: int, max_value: int)

# Fixed cap (what you wanted)
@export var max_special: int = 100

# Optional regen (leave 0 if you don't want regen)
@export var regen_per_sec: float = 0.0

var special: int = 0

# --- Compatibility (so your existing game.gd / HUD code works) ---
var current_meter: int:
	get: return special

var max_meter: int:
	get: return max_special
# ---------------------------------------------------------------

func _ready() -> void:
	special = clamp(special, 0, max_special)
	special_changed.emit(special, max_special)

func _process(delta: float) -> void:
	if regen_per_sec > 0.0 and special < max_special:
		add_special(int(regen_per_sec * delta))

func initialize_from_run_data(run_data: Dictionary = {}) -> void:
	# Accept either the whole run_data or just the resources dict
	var resources := run_data
	if run_data.has("resources") and typeof(run_data["resources"]) == TYPE_DICTIONARY:
		resources = run_data["resources"]

	# Only load current special (cap is fixed at 100)
	special = int(resources.get("special", special))
	special = clamp(special, 0, max_special)

	special_changed.emit(special, max_special)

func export_to_run_data(run_data: Dictionary) -> void:
	if not run_data.has("resources") or typeof(run_data["resources"]) != TYPE_DICTIONARY:
		run_data["resources"] = {}
	var resources: Dictionary = run_data["resources"]

	# Only store current special
	resources["special"] = special

func set_special(value: int) -> void:
	special = clamp(value, 0, max_special)
	special_changed.emit(special, max_special)

func add_special(amount: int) -> void:
	if amount == 0:
		return
	set_special(special + amount)

func spend(cost: int) -> bool:
	if cost <= 0:
		return true
	if special < cost:
		return false
	set_special(special - cost)
	return true
