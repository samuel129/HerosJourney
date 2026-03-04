extends CharacterBody2D

@export_subgroup("Nodes")
@export var gravity_component: GravityComponent
@export var input_component: InputComponent
@export var movement_component: MovementComponent
@export var animation_component: AnimationComponent
@export var jump_component: JumpComponent
@export var health_component: HealthComponent
@export var attack_component: AttackComponent
@export var special_meter_component: SpecialMeterComponent
@export var experience_component: ExperienceComponent
@export var Footstep: AudioStreamPlayer2D
@export var Sword_attack: AudioStreamPlayer2D


var controls_locked: bool = true
var facing_dir: float
var hurt_cooldown: float = 0.0
var _footsteps_on := false

func _ready() -> void:
	add_to_group("player")
	if RunManager.run_data == null:
		RunManager.start_new_run()
	_ensure_progression_components()
	initialize_from_run_data()
	
	if RunManager.run_data != null:
		controls_locked = true
		await get_tree().process_frame
		animation_component.play_spawn_animation()
		animation_component.spawn_finished.connect(_on_spawn_finished, CONNECT_ONE_SHOT)
		animation_component.attack_finished.connect(_on_attack_finished)

func _on_spawn_finished() -> void:
	controls_locked = false
	var portal = get_tree().get_first_node_in_group("spawn_portal")
	if portal:
		portal.play_disappear()

func _on_attack_finished() -> void:
	controls_locked = false

func initialize_from_run_data() -> void:
	# Get run data from RunManager
	if RunManager.run_data == null:
		return

	var rd = RunManager.run_data

	# --- Apply stat upgrades from the run ---
	if movement_component and rd.stats.has("move_speed"):
		movement_component.speed *= rd.stats["move_speed"]

	if jump_component and rd.stats.has("jump_strength"):
		jump_component.jump_velocity *= rd.stats["jump_strength"]

	# --- Health initialization ---
	if has_node("HealthComponent"):
		var hc: HealthComponent = $HealthComponent
		if rd.stats.has("max_health"):
			hc.initialize_from_stats(rd.stats["max_health"])

	# --- Progression resources (EXP + Special) ---
	var resources: Dictionary = {}

	if rd.resources != null:
		resources = rd.resources

	if experience_component:
		experience_component.initialize_from_run_data(resources)

	if special_meter_component:
		special_meter_component.initialize_from_run_data(resources)

func _ensure_progression_components() -> void:
	# Adds components at runtime so the HUD works without having to edit Player.tscn.
	if experience_component == null:
		var existing_xp = get_node_or_null("ExperienceComponent")
		if existing_xp:
			experience_component = existing_xp
		else:
			var xp_comp := ExperienceComponent.new()
			xp_comp.name = "ExperienceComponent"
			add_child(xp_comp)
			experience_component = xp_comp
	
	if special_meter_component == null:
		var existing_sm = get_node_or_null("SpecialMeterComponent")
		if existing_sm:
			special_meter_component = existing_sm
		else:
			var sm_comp := SpecialMeterComponent.new()
			sm_comp.name = "SpecialMeterComponent"
			add_child(sm_comp)
			special_meter_component = sm_comp

func _physics_process(delta: float) -> void:
	hurt_cooldown = maxf(0.0, hurt_cooldown - delta)
	var horizontal = 0 if controls_locked else input_component.input_horizontal
	var jump = false if controls_locked else input_component.get_jump_input()
	
	var fast_falling = input_component.is_fast_falling()
	var dir = horizontal
	var should_play_footsteps := (not controls_locked) and is_on_floor() and absf(dir) > 0.01
	
	if should_play_footsteps and not _footsteps_on:
		Footstep.play()
		_footsteps_on = true
	elif not should_play_footsteps and _footsteps_on:
		Footstep.stop()
		_footsteps_on = false
	if dir != 0:
		facing_dir = dir
	var sprinting = input_component.is_sprinting()
	
	gravity_component.handle_gravity(self, delta, fast_falling)
	
	movement_component.handle_horizontal_movement(self, dir, sprinting)
	jump_component.handle_jump(self, delta, jump, input_component.is_jump_held())	
	if not jump_component.is_jumping and not gravity_component.is_falling:
		animation_component.handle_move_animation(dir, sprinting)
	var really_falling = gravity_component.is_falling and not gravity_component.is_near_ground(self)
	animation_component.handle_jump_animation(jump_component.is_jumping, really_falling)
	
	var attack = false if controls_locked else input_component.get_attack_input()
	if attack_component.can_attack and attack:
		Sword_attack.play()
		attack_component.handle_attack(facing_dir, self)
		animation_component.handle_attack_animation()
		if self.is_on_floor():
			controls_locked = true
	
	move_and_slide()

func receive_damage(amount: int) -> void:
	if hurt_cooldown > 0.0:
		return
	if health_component == null:
		return
	health_component.take_damage(amount)
	hurt_cooldown = 0.4
