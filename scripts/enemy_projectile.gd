extends Area2D
class_name EnemyProjectile

@export var speed: float = 170.0
@export var lifetime: float = 2.5
@export var damage: int = 10
@export var pierce: bool = false
@export var destroy_on_world_collision: bool = true

var direction: Vector2 = Vector2.RIGHT
var source_enemy: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func launch(
	dir: Vector2,
	launch_speed: float,
	hit_damage: int,
	source: Node = null
) -> void:
	direction = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
	speed = launch_speed
	damage = hit_damage
	source_enemy = source
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var next_position: Vector2 = global_position + direction * speed * delta
	if _resolve_swept_collision(next_position):
		return

	global_position = next_position
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _resolve_swept_collision(next_position: Vector2) -> bool:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, next_position)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	if source_enemy is CollisionObject2D:
		query.exclude.append((source_enemy as CollisionObject2D).get_rid())

	var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false

	var hit_position: Vector2 = next_position
	var hit_position_value: Variant = hit.get("position", next_position)
	if hit_position_value is Vector2:
		hit_position = hit_position_value
	global_position = hit_position
	var collider_value: Variant = hit.get("collider", null)
	var collider: Node = collider_value as Node
	return _handle_collision(collider)

func _on_body_entered(body: Node) -> void:
	_handle_collision(body)

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("attack_hitbox"):
		queue_free()
		return

	_handle_collision(area)

func _handle_collision(collider: Node) -> bool:
	if collider == null:
		return false
	if source_enemy != null and collider == source_enemy:
		return false
	if collider.is_in_group("enemies"):
		return false

	if collider.is_in_group("player"):
		if collider.has_method("receive_damage"):
			collider.receive_damage(damage)
		if not pierce:
			queue_free()
			return true
		return false

	if destroy_on_world_collision:
		queue_free()
		return true

	return false
