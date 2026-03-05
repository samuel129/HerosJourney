extends CanvasLayer

@onready var hp_bar: ProgressBar = $Control/VBoxContainer/HPBar
@onready var special_bar: ProgressBar = $Control/VBoxContainer/SpecialBar
@onready var exp_bar: ProgressBar = $Control/VBoxContainer/ExpBar
@onready var hp_label: Label = $Control/VBoxContainer/HPLabel
@onready var special_label: Label = $Control/VBoxContainer/SpecialLabel
@onready var exp_label: Label = $Control/VBoxContainer/ExpLabel
var crit_label: Label = null

# Smooth animation targets
var target_hp: float = 0.0
var target_special: float = 0.0
var target_exp: float = 0.0

# How fast bars ease toward the target (bigger = snappier)
@export var bar_lerp_speed: float = 10.0

# Player reference (so we can apply upgrades on level up)
var player_ref: Node = null

# Level up popup UI (created in code)
var levelup_panel: PanelContainer
var levelup_title: Label
var levelup_desc: Label
var levelup_buttons: Array[Button] = []
var pending_level: int = 1

# Optional nicer popup animation bits (if you already added them elsewhere)
var popup_tween: Tween = null
var dimmer: ColorRect = null

func _ready() -> void:
	# Keep HUD updating even if we pause the game for the level-up popup
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_levelup_popup()
	# Create crit label if it doesn't exist yet
	if crit_label == null:
		crit_label = Label.new()
		crit_label.text = "CRIT 0%"
		$Control/VBoxContainer.add_child(crit_label)

func bind_player(p: Node) -> void:
	player_ref = p

# --- Public API called by game.gd ---
func set_hp(value: int, max_value: int) -> void:
	hp_bar.max_value = max_value
	target_hp = float(value)
	hp_label.text = "HP %d / %d" % [value, max_value]

func set_special(value: int, max_value: int) -> void:
	special_bar.max_value = max_value
	target_special = float(value)
	special_label.text = "Special %d / %d" % [value, max_value]

func set_exp(value: int, max_value: int) -> void:
	exp_bar.max_value = max_value
	target_exp = float(value)
	exp_label.text = "EXP %d / %d" % [value, max_value]

func show_level_up(new_level: int) -> void:
	pending_level = new_level
	levelup_title.text = "LEVEL UP!  (Level %d)" % new_level
	levelup_desc.text = "Choose one upgrade:"
	levelup_panel.visible = true
	if dimmer:
		dimmer.visible = true

	# Pause gameplay, keep UI responsive
	get_tree().paused = true

	# Optional: fade/scale in if you’re using tween + dimmer
	if popup_tween and popup_tween.is_running():
		popup_tween.kill()
	levelup_panel.modulate = Color(1, 1, 1, 0)
	levelup_panel.scale = Vector2(0.92, 0.92)
	if dimmer:
		dimmer.color = Color(0, 0, 0, 0.0)

	popup_tween = create_tween()
	popup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	popup_tween.tween_property(levelup_panel, "modulate", Color(1, 1, 1, 1), 0.12)
	popup_tween.parallel().tween_property(levelup_panel, "scale", Vector2(1, 1), 0.12)
	if dimmer:
		popup_tween.parallel().tween_property(dimmer, "color", Color(0, 0, 0, 0.55), 0.12)

# --- Smooth bar fill ---
func _process(delta: float) -> void:
	hp_bar.value = lerp(float(hp_bar.value), target_hp, bar_lerp_speed * delta)
	special_bar.value = lerp(float(special_bar.value), target_special, bar_lerp_speed * delta)
	exp_bar.value = lerp(float(exp_bar.value), target_exp, bar_lerp_speed * delta)

# --- Popup UI creation (no .tscn changes needed) ---
func _build_levelup_popup() -> void:
	# Optional dim background
	dimmer = ColorRect.new()
	dimmer.visible = false
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.color = Color(0, 0, 0, 0.0)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	levelup_panel = PanelContainer.new()
	levelup_panel.visible = false
	levelup_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(levelup_panel)

	# Center it
	levelup_panel.set_anchors_preset(Control.PRESET_CENTER)
	levelup_panel.offset_left = -220
	levelup_panel.offset_right = 220
	levelup_panel.offset_top = -120
	levelup_panel.offset_bottom = 120

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	levelup_panel.add_child(root_vbox)

	levelup_title = Label.new()
	levelup_title.text = "LEVEL UP!"
	levelup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(levelup_title)

	levelup_desc = Label.new()
	levelup_desc.text = "Choose one upgrade:"
	levelup_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_vbox.add_child(levelup_desc)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	root_vbox.add_child(btn_row)

	# 3 upgrade buttons
	for i in range(3):
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text = "Upgrade %d" % (i + 1)
		btn_row.add_child(b)
		levelup_buttons.append(b)

		# IMPORTANT: capture the index so each button calls the right choice
		var idx := i
		b.pressed.connect(func(): _on_upgrade_chosen(idx))

	_refresh_upgrade_text()

func _refresh_upgrade_text() -> void:
	levelup_buttons[0].text = "+10 Max HP"
	levelup_buttons[1].text = "+10% Move Speed"
	levelup_buttons[2].text = "+5% Critical Chance"

# --- Apply upgrades ---
func _on_upgrade_chosen(choice: int) -> void:
	_apply_upgrade(choice)

	# Animate out
	if popup_tween and popup_tween.is_running():
		popup_tween.kill()

	popup_tween = create_tween()
	popup_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	popup_tween.tween_property(levelup_panel, "modulate", Color(1, 1, 1, 0), 0.12)
	popup_tween.parallel().tween_property(levelup_panel, "scale", Vector2(0.92, 0.92), 0.12)
	if dimmer:
		popup_tween.parallel().tween_property(dimmer, "color", Color(0, 0, 0, 0.0), 0.12)

	# ✅ FIXED: func(): (no space)
	popup_tween.finished.connect(func():
		levelup_panel.visible = false
		if dimmer:
			dimmer.visible = false
		get_tree().paused = false
	)

func _apply_upgrade(choice: int) -> void:
	if player_ref == null:
		return

	match choice:
		0:
			# +10 Max HP (and heal +10)
			var hc = player_ref.get_node_or_null("HealthComponent")
			if hc:
				hc.max_health += 10
				hc.current_health = min(hc.current_health + 10, hc.max_health)

				# Update HUD immediately if signal exists
				if hc.has_signal("health_changed"):
					hc.health_changed.emit(hc.current_health, hc.max_health)

		1:
			# +10% Move Speed
			var mv = player_ref.get_node_or_null("MovementComponent")
			if mv != null:
				# MovementComponent.gd has "speed"
				mv.speed *= 1.10

		2:
			# +5% Critical Chance
			var current := 0.0
			if player_ref.has_meta("crit_chance"):
				current = float(player_ref.get_meta("crit_chance"))

			current = min(current + 0.05, 1.0)
			player_ref.set_meta("crit_chance", current)

			# Update HUD label
			if crit_label:
				crit_label.text = "CRIT %d%%" % int(current * 100)


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
