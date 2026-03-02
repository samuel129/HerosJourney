class_name RunManager
extends Node

var run_data: RunData = null
var is_run_active: bool = false

func start_new_run():
	run_data = RunData.new()
	is_run_active = true
	
	run_data.stats["health"] = run_data.stats["max_health"]

func end_run():
	run_data = null
	is_run_active = false

func get_stat(stat_name: String) -> float:
	if run_data and run_data.stats.has(stat_name):
		return run_data.stats[stat_name]
	return 0.0

func add_stat(stat_name: String, amount: float) -> void:
	if run_data and run_data.stats.has(stat_name):
		run_data.stats[stat_name] += amount
