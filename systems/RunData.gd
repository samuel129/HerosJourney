class_name RunData

var stats: Dictionary
var resources: Dictionary
var perks: Array
var inventory: Array
var flags: Dictionary

func _init() -> void:
	stats = {
		"max_health": 100,
		"health": 100,
		
		"attack": 10,
		"crit_chance": 0.05,
		"crit_damage": 1.5,
		
		"move_speed": 1.0,
		"jump_power": 1.0,
		
		"defense": 0,
	}
	
	resources = {
		"gold": 0,
		"experience": 0,
	}
	
	# Random perks gained during run (new moves/abilities, stat buffs_
	perks = []
	# Consumable items, shop(?) items, items the player has stored
	inventory = []
	# Run-specific events that impact rest of run
	flags = {}
