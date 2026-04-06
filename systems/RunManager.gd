extends Node

var run_data: RunData = null
var is_run_active: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

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
	run_data = null
	is_run_active = false
	emit_signal("run_ended")

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
