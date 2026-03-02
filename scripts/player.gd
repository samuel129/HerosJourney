extends CharacterBody2D

@export_subgroup("Nodes")
@export var gravity_component: GravityComponent
@export var input_component: InputComponent
@export var movement_component: MovementComponent
@export var animation_component: AnimationComponent
@export var jump_component: JumpComponent

func _physics_process(delta: float) -> void:
	var fast_falling = input_component.is_fast_falling()
	var dir = input_component.input_horizontal
	var sprinting = input_component.is_sprinting()
	
	gravity_component.handle_gravity(self, delta, fast_falling)
	
	movement_component.handle_horizontal_movement(self, dir, sprinting)
	jump_component.handle_jump(self, delta, input_component.get_jump_input(), input_component.is_jump_held())	
	if not jump_component.is_jumping and not gravity_component.is_falling:
		animation_component.handle_move_animation(dir, sprinting)
	var really_falling = gravity_component.is_falling and not gravity_component.is_near_ground(self)
	animation_component.handle_jump_animation(jump_component.is_jumping, really_falling)
	
	
	move_and_slide()
