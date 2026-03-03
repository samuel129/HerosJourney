extends CharacterBody2D

@export_subgroup("Nodes")
@export var gravity_component: GravityComponent
@export var input_component: InputComponent
@export var movement_component: MovementComponent
@export var animation_component: AnimationComponent
@export var jump_component: JumpComponent
@export var health_component: HealthComponent
@export var attack_component: AttackComponent

var controls_locked: bool = true
var facing_dir: float

func _ready() -> void:
	if RunManager.run_data == null:
		RunManager.start_new_run()
	initialize_from_run_data()
	
	if RunManager.run_data != null:
		controls_locked = true
		await get_tree().process_frame
		animation_component.play_spawn_animation()
		animation_component.spawn_finished.connect(_on_spawn_finished, CONNECT_ONE_SHOT)
		animation_component.attack_finished.connect(_on_attack_finished)

func _on_spawn_finished() -> void:
	controls_locked = false

func _on_attack_finished() -> void:
	controls_locked = false

func initialize_from_run_data() -> void:
	if RunManager.run_data == null:
		return
	var rd = RunManager.run_data
	
	# Movement Speed
	if movement_component:
		movement_component.speed = movement_component.speed * rd.stats["move_speed"]
	
	# Jump Strength
	if jump_component:
		jump_component.jump_velocity = jump_component.jump_velocity * rd.stats["jump_power"]
	
	# Health
	if has_node("HealthComponent"):
		var hc = $HealthComponent
		hc.initialize_from_stats(rd.stats["max_health"])

func _physics_process(delta: float) -> void:
	var horizontal = 0 if controls_locked else input_component.input_horizontal
	var jump = false if controls_locked else input_component.get_jump_input()
	
	var fast_falling = input_component.is_fast_falling()
	var dir = horizontal
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
		attack_component.handle_attack(facing_dir, self)
		animation_component.handle_attack_animation()
		if self.is_on_floor():
			controls_locked = true
	
	move_and_slide()
