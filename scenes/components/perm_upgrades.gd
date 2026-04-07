extends Control

@onready var currency_label: Label = $Root/Panel/Margin/VBox/Currency
@onready var status_label: Label = $Root/Panel/Margin/VBox/Status

@onready var hp_info: Label = $Root/Panel/Margin/VBox/Rows/HPRow/Info
@onready var hp_button: Button = $Root/Panel/Margin/VBox/Rows/HPRow/Buy

@onready var crit_info: Label = $Root/Panel/Margin/VBox/Rows/CritRow/Info
@onready var crit_button: Button = $Root/Panel/Margin/VBox/Rows/CritRow/Buy

@onready var speed_info: Label = $Root/Panel/Margin/VBox/Rows/SpeedRow/Info
@onready var speed_button: Button = $Root/Panel/Margin/VBox/Rows/SpeedRow/Buy

func _ready() -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	currency_label.text = "Legacy Shards: %d" % RunManager.get_meta_currency()
	_update_row("max_health", hp_info, hp_button, "+5 Max HP per level")
	_update_row("crit_chance", crit_info, crit_button, "+1% Crit Chance per level")
	_update_row("move_speed", speed_info, speed_button, "+3% Move Speed per level")

func _update_row(upgrade_id: String, info_label: Label, buy_button: Button, description: String) -> void:
	var level: int = RunManager.get_permanent_upgrade_level(upgrade_id)
	var cost: int = RunManager.get_permanent_upgrade_cost(upgrade_id)
	if cost < 0:
		info_label.text = "%s | Lv %d (MAX)" % [description, level]
		buy_button.disabled = true
		buy_button.text = "MAX"
		return
	info_label.text = "%s | Lv %d | Cost %d" % [description, level, cost]
	buy_button.disabled = not RunManager.can_purchase_permanent_upgrade(upgrade_id)
	buy_button.text = "Buy"

func _attempt_purchase(upgrade_id: String, success_message: String) -> void:
	if RunManager.purchase_permanent_upgrade(upgrade_id):
		status_label.text = success_message
	else:
		status_label.text = "Not enough shards or upgrade already maxed."
	_refresh_ui()

func _on_buy_hp_pressed() -> void:
	_attempt_purchase("max_health", "Purchased +5 permanent Max HP.")

func _on_buy_crit_pressed() -> void:
	_attempt_purchase("crit_chance", "Purchased +1% permanent Crit Chance.")

func _on_buy_speed_pressed() -> void:
	_attempt_purchase("move_speed", "Purchased +3% permanent Move Speed.")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
