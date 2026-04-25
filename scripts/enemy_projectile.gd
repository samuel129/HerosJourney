extends Area2D
class_name EnemyProjectile

@export var speed: float = 170.0
@export var lifetime: float = 2.5
@export var damage: int = 10
@export var pierce: bool = false

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
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if source_enemy != null and body == source_enemy:
		return
	if body.is_in_group("enemies"):
		return

	if body.is_in_group("player"):
		if body.has_method("receive_damage"):
			body.receive_damage(damage)
		if not pierce:
			queue_free()
		return

func _on_area_entered(area: Node) -> void:
	if area.is_in_group("attack_hitbox"):
		queue_free()

	if not pierce:
		queue_free()
