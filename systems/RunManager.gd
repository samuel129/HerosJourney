extends Node

var run_data: RunData = null
var is_run_active: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var meta_currency: int = 0
var permanent_upgrades: Dictionary = {
	"max_health": 0,
	"crit_chance": 0,
	"move_speed": 0,
}

const META_SAVE_PATH := "user://meta_progress.cfg"
const RUN_SAVE_PATH := "user://active_run.dat"
const PERMANENT_UPGRADE_DATA := {
	"max_health": {
		"name": "Max HP",
		"base_cost": 25,
		"cost_step": 15,
		"value_step": 5.0,
		"max_level": 8,
	},
	"crit_chance": {
		"name": "Crit Chance",
		"base_cost": 30,
		"cost_step": 20,
		"value_step": 0.01,
		"max_level": 8,
	},
	"move_speed": {
		"name": "Move Speed",
		"base_cost": 24,
		"cost_step": 16,
		"value_step": 0.03,
		"max_level": 8,
	},
}

const DEFAULT_BRANCH_COUNT = 3
const NODE_PROFILES = [
	{
		"id": "path_combat",
		"title": "Skirmish Path",
		"description": "Balanced fights and steady rewards.",
		"weight": 4.0,
		"chunk_offset": 0,
		"enemy_multiplier": 1.0,
		"gold_reward": 12,
		"heal_percent": 0.0,
	},
	{
		"id": "path_elite",
		"title": "Elite Gauntlet",
		"description": "Harder enemies, better payout.",
		"weight": 2.0,
		"chunk_offset": 1,
		"enemy_multiplier": 1.35,
		"gold_reward": 25,
		"heal_percent": 0.0,
	},
	{
		"id": "path_recovery",
		"title": "Sanctuary Route",
		"description": "Shorter route with healing.",
		"weight": 2.5,
		"chunk_offset": -1,
		"enemy_multiplier": 0.75,
		"gold_reward": 6,
		"heal_percent": 0.25,
	},
	{
		"id": "path_treasure",
		"title": "Treasure Route",
		"description": "Standard danger, extra gold.",
		"weight": 1.7,
		"chunk_offset": 0,
		"enemy_multiplier": 1.1,
		"gold_reward": 40,
		"heal_percent": 0.0,
	},
]
const MINI_BOSS_PROFILE = {
	"id": "path_miniboss",
	"title": "Mini-Boss Arena",
	"description": "A dangerous champion blocks your path.",
	"weight": 0.0,
	"chunk_offset": -1,
	"enemy_multiplier": 0.0,
	"gold_reward": 45,
	"heal_percent": 0.0,
	"stage_type": "mini_boss",
	"mini_boss_stage": true,
}

signal run_started(data: RunData)
signal run_ended()
signal world_map_choices_generated(choices: Array)
signal world_map_choice_selected(choice: Dictionary)
signal stage_advanced(new_stage: int)

func _ready() -> void:
	_rng.randomize()
	_load_meta_progress()

func start_new_run(seed: int = -1) -> void:
	run_data = RunData.new()
	is_run_active = true
	if seed < 0:
		_rng.randomize()
		run_data.run_seed = int(_rng.randi())
	else:
		run_data.run_seed = seed
	_rng.seed = run_data.run_seed
	run_data.stage = 1
	run_data.cleared_stages = 0
	_apply_permanent_upgrades_to_run()
	run_data.stats["health"] = run_data.stats["max_health"]
	run_data.flags["stage"] = run_data.stage
	run_data.flags["stages_cleared"] = run_data.cleared_stages
	run_data.flags["world_map_choices"] = []
	run_data.flags["map_history"] = []
	run_data.flags["pending_level_config"] = _build_level_config_from_profile(
		NODE_PROFILES[0], run_data.stage
	)
	emit_signal("run_started", run_data)

func end_run() -> void:
	if run_data != null:
		var run_gold: int = int(run_data.resources.get("gold", 0))
		# Convert run gold into persistent currency for permanent upgrades.
		if run_gold > 0:
			meta_currency += int(floor(float(run_gold) * 0.5))
			_save_meta_progress()
		delete_saved_run()
	run_data = null
	is_run_active = false
	emit_signal("run_ended")

func get_meta_currency() -> int:
	return meta_currency

func get_permanent_upgrade_level(upgrade_id: String) -> int:
	if not permanent_upgrades.has(upgrade_id):
		return 0
	return int(permanent_upgrades[upgrade_id])

# Returns the cost of the next lvl of specified upgrade, or -1 if upgrade maxed out
func get_permanent_upgrade_cost(upgrade_id: String) -> int:
	if not PERMANENT_UPGRADE_DATA.has(upgrade_id):
		return -1
	var data: Dictionary = PERMANENT_UPGRADE_DATA[upgrade_id]
	var level: int = get_permanent_upgrade_level(upgrade_id)
	var max_level: int = int(data.get("max_level", 1))
	if level >= max_level:
		return -1
	return int(data.get("base_cost", 0)) + int(data.get("cost_step", 0)) * level

# Returns true if the specified upgrade can be purchased with current meta currency, false if not (either due to cost or already maxed out)
func can_purchase_permanent_upgrade(upgrade_id: String) -> bool:
	var cost: int = get_permanent_upgrade_cost(upgrade_id)
	if cost < 0:
		return false
	return meta_currency >= cost

# Attempts to purchase a specific upgrade. True if successful, false if not
func purchase_permanent_upgrade(upgrade_id: String) -> bool:
	if not can_purchase_permanent_upgrade(upgrade_id):
		return false
	var cost: int = get_permanent_upgrade_cost(upgrade_id)
	meta_currency -= cost
	permanent_upgrades[upgrade_id] = get_permanent_upgrade_level(upgrade_id) + 1
	_save_meta_progress()
	return true

# Returns an array of dictionaries containing info about each permanent upgrade for UI display
func get_permanent_upgrade_catalog() -> Array:
	var entries: Array = []
	for upgrade_id in PERMANENT_UPGRADE_DATA.keys():
		var data: Dictionary = PERMANENT_UPGRADE_DATA[upgrade_id]
		var level: int = get_permanent_upgrade_level(upgrade_id)
		var value_step: float = float(data.get("value_step", 0.0))
		entries.append({
			"id": upgrade_id,
			"name": String(data.get("name", upgrade_id)),
			"level": level,
			"max_level": int(data.get("max_level", 1)),
			"cost": get_permanent_upgrade_cost(upgrade_id),
			"total_bonus": value_step * level,
		})
	return entries

# Applies the effects of all purchased permanent upgrades to the current run's stats. Called at the start of each run
func _apply_permanent_upgrades_to_run() -> void:
	if run_data == null:
		return
	var stats: Dictionary = run_data.stats

	var hp_level: int = get_permanent_upgrade_level("max_health")
	if hp_level > 0:
		var hp_bonus: int = int(hp_level * float(PERMANENT_UPGRADE_DATA["max_health"]["value_step"]))
		stats["max_health"] = int(stats.get("max_health", 100)) + hp_bonus

	var crit_level: int = get_permanent_upgrade_level("crit_chance")
	if crit_level > 0:
		var crit_bonus: float = float(crit_level) * float(PERMANENT_UPGRADE_DATA["crit_chance"]["value_step"])
		stats["crit_chance"] = min(float(stats.get("crit_chance", 0.05)) + crit_bonus, 1.0)

	var speed_level: int = get_permanent_upgrade_level("move_speed")
	if speed_level > 0:
		var speed_bonus: float = float(speed_level) * float(PERMANENT_UPGRADE_DATA["move_speed"]["value_step"])
		stats["move_speed"] = float(stats.get("move_speed", 1.0)) + speed_bonus


# Loads meta progress from disk. If no save file exists, starts with default values.
func _load_meta_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(META_SAVE_PATH)
	if err != OK:
		return
	meta_currency = int(cfg.get_value("progress", "meta_currency", 0))
	for upgrade_id in permanent_upgrades.keys():
		permanent_upgrades[upgrade_id] = int(cfg.get_value("upgrades", upgrade_id, 0))

func _save_meta_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "meta_currency", meta_currency)
	for upgrade_id in permanent_upgrades.keys():
		cfg.set_value("upgrades", upgrade_id, int(permanent_upgrades[upgrade_id]))
	cfg.save(META_SAVE_PATH)

func reset_all_saved_data() -> void:
	meta_currency = 0
	for upgrade_id in permanent_upgrades.keys():
		permanent_upgrades[upgrade_id] = 0

	if has_saved_run():
		delete_saved_run()

	if FileAccess.file_exists(META_SAVE_PATH):
		DirAccess.remove_absolute(META_SAVE_PATH)

	var had_active_run: bool = is_run_active
	run_data = null
	is_run_active = false
	if had_active_run:
		emit_signal("run_ended")

func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)

func save_current_run() -> bool:
	if run_data == null:
		return false
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_var(_serialize_run_data(run_data), true)
	return true

func load_saved_run() -> bool:
	if not has_saved_run():
		return false
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var payload = file.get_var(true)
	if typeof(payload) != TYPE_DICTIONARY:
		return false
	var loaded = _deserialize_run_data(payload as Dictionary)
	if loaded == null:
		return false
	run_data = loaded
	is_run_active = true
	_rng.seed = int(run_data.run_seed)
	emit_signal("run_started", run_data)
	return true

func delete_saved_run() -> void:
	if has_saved_run():
		DirAccess.remove_absolute(RUN_SAVE_PATH)

func _serialize_run_data(data: RunData) -> Dictionary:
	return {
		"stats": data.stats.duplicate(true),
		"resources": data.resources.duplicate(true),
		"perks": data.perks.duplicate(true),
		"inventory": data.inventory.duplicate(true),
		"flags": data.flags.duplicate(true),
		"stage": data.stage,
		"cleared_stages": data.cleared_stages,
		"map_history": data.map_history.duplicate(true),
		"run_seed": data.run_seed,
	}

func _deserialize_run_data(payload: Dictionary):
	var loaded := RunData.new()

	if payload.has("stats") and typeof(payload["stats"]) == TYPE_DICTIONARY:
		for key in (payload["stats"] as Dictionary).keys():
			loaded.stats[key] = payload["stats"][key]

	if payload.has("resources") and typeof(payload["resources"]) == TYPE_DICTIONARY:
		for key in (payload["resources"] as Dictionary).keys():
			loaded.resources[key] = payload["resources"][key]

	if payload.has("perks") and typeof(payload["perks"]) == TYPE_ARRAY:
		loaded.perks = (payload["perks"] as Array).duplicate(true)

	if payload.has("inventory") and typeof(payload["inventory"]) == TYPE_ARRAY:
		loaded.inventory = (payload["inventory"] as Array).duplicate(true)

	if payload.has("flags") and typeof(payload["flags"]) == TYPE_DICTIONARY:
		loaded.flags = (payload["flags"] as Dictionary).duplicate(true)

	if payload.has("map_history") and typeof(payload["map_history"]) == TYPE_ARRAY:
		loaded.map_history = (payload["map_history"] as Array).duplicate(true)

	loaded.stage = int(payload.get("stage", loaded.stage))
	loaded.cleared_stages = int(payload.get("cleared_stages", loaded.cleared_stages))
	loaded.run_seed = int(payload.get("run_seed", loaded.run_seed))

	loaded.flags["stage"] = loaded.stage
	loaded.flags["stages_cleared"] = loaded.cleared_stages
	loaded.flags["map_history"] = loaded.map_history.duplicate(true)
	return loaded

func get_stat(stat_name: String) -> float:
	if run_data and run_data.stats.has(stat_name):
		return run_data.stats[stat_name]
	return 0.0

func add_stat(stat_name: String, amount: float) -> void:
	if run_data and run_data.stats.has(stat_name):
		run_data.stats[stat_name] += amount

func get_current_stage() -> int:
	if run_data == null:
		return 1
	return max(run_data.stage, 1)

func get_current_level_config() -> Dictionary:
	if run_data == null:
		return {}
	if run_data.flags.has("pending_level_config"):
		return (run_data.flags["pending_level_config"] as Dictionary).duplicate(true)
	return _build_level_config_from_profile(NODE_PROFILES[0], run_data.stage)

func mark_current_stage_cleared() -> void:
	if run_data == null:
		return
	run_data.cleared_stages += 1
	run_data.flags["stages_cleared"] = run_data.cleared_stages
	run_data.resources["gold"] = int(run_data.resources.get("gold", 0)) + 5
	save_current_run()

func generate_world_map_choices(choice_count: int = DEFAULT_BRANCH_COUNT) -> Array:
	if run_data == null:
		return []

	var next_stage: int = run_data.stage + 1
	if _is_mini_boss_stage(next_stage):
		var forced_choice: Dictionary = _build_world_map_choice(MINI_BOSS_PROFILE, next_stage, 0)
		var forced_choices: Array = [forced_choice]
		run_data.flags["world_map_choices"] = forced_choices.duplicate(true)
		emit_signal("world_map_choices_generated", forced_choices)
		return forced_choices

	var target_count: int = maxi(choice_count, 2)
	var choices: Array = []
	var picked_ids: Dictionary = {}
	var safeguard: int = 0

	while choices.size() < target_count and safeguard < 32:
		safeguard += 1
		var profile: Dictionary = _pick_node_profile()
		var profile_id: String = String(profile.get("id", "path_combat"))
		if picked_ids.has(profile_id):
			continue
		picked_ids[profile_id] = true
		choices.append(_build_world_map_choice(profile, next_stage, choices.size()))

	run_data.flags["world_map_choices"] = choices.duplicate(true)
	emit_signal("world_map_choices_generated", choices)
	return choices

func choose_world_map_node(choice_id: String) -> Dictionary:
	if run_data == null:
		return {}
	if not run_data.flags.has("world_map_choices"):
		return {}

	var choices: Array = run_data.flags["world_map_choices"] as Array
	for raw_choice in choices:
		var choice: Dictionary = raw_choice as Dictionary
		if String(choice.get("id", "")) != choice_id:
			continue
		var level_config: Dictionary = (choice.get("level_config", {}) as Dictionary).duplicate(true)
		run_data.stage += 1
		run_data.flags["stage"] = run_data.stage
		run_data.flags["pending_level_config"] = level_config.duplicate(true)
		run_data.flags["world_map_choices"] = []

		var selected_route: Dictionary = {
			"stage": run_data.stage,
			"id": String(choice.get("node_type", "")),
			"title": String(choice.get("title", "")),
			"reward_gold": int(choice.get("reward_gold", 0)),
			"heal_percent": float(choice.get("heal_percent", 0.0)),
		}
		run_data.map_history.append(selected_route)
		run_data.flags["map_history"] = run_data.map_history.duplicate(true)

		_apply_choice_rewards(choice)
		save_current_run()
		emit_signal("world_map_choice_selected", choice)
		emit_signal("stage_advanced", run_data.stage)
		return level_config

	return {}

func _pick_node_profile() -> Dictionary:
	var total_weight: float = 0.0
	for profile in NODE_PROFILES:
		total_weight += float(profile.get("weight", 1.0))

	if total_weight <= 0.0:
		return NODE_PROFILES[0]

	var roll: float = _rng.randf_range(0.0, total_weight)
	var cumulative: float = 0.0
	for profile in NODE_PROFILES:
		cumulative += float(profile.get("weight", 1.0))
		if roll <= cumulative:
			return profile
	return NODE_PROFILES[0]

func _build_world_map_choice(profile: Dictionary, next_stage: int, index: int) -> Dictionary:
	var profile_id: String = String(profile.get("id", "path_combat"))
	var choice_id: String = "%s_%d_%d" % [profile_id, next_stage, index]
	var level_config: Dictionary = _build_level_config_from_profile(profile, next_stage)
	level_config["choice_id"] = choice_id
	return {
		"id": choice_id,
		"title": String(profile.get("title", "Unknown Route")),
		"description": String(profile.get("description", "")),
		"reward_gold": int(profile.get("gold_reward", 0)),
		"heal_percent": float(profile.get("heal_percent", 0.0)),
		"node_type": profile_id,
		"stage_type": String(level_config.get("stage_type", "normal")),
		"level_config": level_config,
	}

func _is_mini_boss_stage(stage: int) -> bool:
	return stage > 0 and stage % 3 == 0

func _build_level_config_from_profile(profile: Dictionary, stage: int) -> Dictionary:
	var base_chunk_count: int = 4 + int(floor((stage - 1) * 0.5))
	var profile_chunk_offset: int = int(profile.get("chunk_offset", 0))
	var chunk_count: int = clampi(base_chunk_count + profile_chunk_offset, 3, 9)

	var stage_enemy_scale: float = 1.0 + (float(stage - 1) * 0.07)
	var enemy_multiplier: float = float(profile.get("enemy_multiplier", 1.0)) * stage_enemy_scale
	enemy_multiplier = clampf(enemy_multiplier, 0.5, 2.5)

	return {
		"stage": stage,
		"chunk_count": chunk_count,
		"theme_row": -1,
		"enemy_multiplier": enemy_multiplier,
		"stage_type": String(profile.get("stage_type", "normal")),
		"mini_boss_stage": bool(profile.get("mini_boss_stage", false)),
		"node_type": String(profile.get("id", "path_combat")),
		"display_name": String(profile.get("title", "Route")),
		"description": String(profile.get("description", "")),
	}

func _apply_choice_rewards(choice: Dictionary) -> void:
	if run_data == null:
		return
	var gold_gain: int = int(choice.get("reward_gold", 0))
	if gold_gain > 0:
		run_data.resources["gold"] = int(run_data.resources.get("gold", 0)) + gold_gain

	var heal_percent: float = float(choice.get("heal_percent", 0.0))
	if heal_percent <= 0.0:
		return
	var max_health: int = int(run_data.stats.get("max_health", 100))
	var current_health: int = int(run_data.stats.get("health", max_health))
	var heal_amount: int = int(round(max_health * heal_percent))
	run_data.stats["health"] = min(max_health, current_health + heal_amount)
