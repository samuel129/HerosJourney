class_name RunData

var stats: Dictionary
var resources: Dictionary
var perks: Array
var inventory: Array
var flags: Dictionary
var stage: int
var cleared_stages: int
var map_history: Array
var run_seed: int

func _init() -> void:
	stats = {
		# Health
		"max_health": 100,
		"health": 100,
		
		# Combat
		"attack": 10,
		"crit_chance": .05,
		"crit_damage": 1.5,
		
		# Movement
		"move_speed": 1.0,
		"jump_power": 1.0,
		
		# Utility
		"defense": 0,
	}
	
	resources = {
		"gold": 0,
		# Progression
		"level": 1,
		"experience": 0,
		"exp_to_next": 100,
		# Combat resources
		"special": 0,
		"special_max": 100,
	}
	
	# Random perks gained during run (new moves/abilities, stat buffs)
	perks = []
	# Consumable items, shop(?) items, items the player has stored
	inventory = []
	# Run-specific events that impact rest of run
	flags = {}
	stage = 1
	cleared_stages = 0
	map_history = []
	run_seed = 0
