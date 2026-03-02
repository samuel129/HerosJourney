extends CharacterBody2D

@export_subgroup("Nodes")
@export var gravity_component: GravityComponent
@export var input_component: InputComponent
@export var movement_component: MovementComponent
@export var animation_component: AnimationComponent
@export var jump_component: JumpComponent

func _physics_process(delta: float) -> void:
	gravity_component.handle_gravity(self, delta)
	
	var dir = input_component.input_horizontal
	var sprinting = input_component.is_sprinting()
	
	movement_component.handle_horizontal_movement(self, dir, sprinting)
	jump_component.handle_jump(self, delta, input_component.get_jump_input(), input_component.is_jump_held())	
	if not jump_component.is_jumping and not gravity_component.is_falling:
		animation_component.handle_move_animation(dir, sprinting)
	animation_component.handle_jump_animation(jump_component.is_jumping, gravity_component.is_falling)
	
	
	move_and_slide()
