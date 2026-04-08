extends Node2D

@onready var entry: Marker2D = $Entry
@onready var exit: Marker2D = $Exit
@onready var tilemap: TileMapLayer = $Foreground

@export var tile_size: int = 16

@export var chunk_type: String = "normal"
@export var weight: int = 1

@export var exit_tag: String = "right"
@export var allowed_next_tags: Array[String] = ["right"]

# Mini Boss
@onready var arena_trigger: Area2D = get_node_or_null("ArenaTrigger")
@onready var left_wall: Node2D = get_node_or_null("BossEntryWall")
@onready var right_wall: Node2D = get_node_or_null("BossExitWall")
@onready var bottom_left: Marker2D = get_node_or_null("BottomLeft2")
@onready var top_right: Marker2D = get_node_or_null("TopRight2")
@onready var enemy_spawns: Node = get_node_or_null("EnemySpawns")
var arena_triggered := false
var boss_active := false
var boss_cleared := false

func _process(delta: float) -> void:
	if chunk_type != "mini_boss": return
	if boss_cleared: return
	var game = get_tree().get_first_node_in_group("game")
	if game == null: return
	if boss_active == true and game.active_enemies.is_empty():
		boss_cleared = true
		_on_boss_defeated()

func _ready():
	@warning_ignore("integer_division")
	entry.position = Vector2(tile_size / 2, 0)
	if left_wall:
		left_wall.visible = false
		left_wall.collision_enabled = false
	if right_wall:
		right_wall.visible = true
		right_wall.collision_enabled = true
	if chunk_type == "mini_boss" and arena_trigger:
		arena_trigger.body_entered.connect(_on_arena_entered)
	
func _on_arena_entered(body):
	if arena_triggered: return
	if not body.is_in_group("player"): return
	arena_triggered = true
	_activate_arena()

func _activate_arena():
	_close_arena()
	_update_camera_bounds()
	_snap_camera()
	await get_tree().create_timer(0.25).timeout
	var game = get_tree().get_first_node_in_group("game")
	if game and game._is_mini_boss_level():
		var spawn_entries = game._collect_spawn_entries()
		var markers = game._extract_markers_from_entries(spawn_entries)
		game._spawn_mini_boss_for_level(markers)
		boss_active = true

func _close_arena():
	if left_wall:
		left_wall.visible = true
		left_wall.collision_enabled = true

func _update_camera_bounds():
	var game = get_tree().get_first_node_in_group("game")
	if game == null: return
	var cam = game.get_node("Camera2D")
	if bottom_left:
		cam.limit_left = int(bottom_left.global_position.x)

func _snap_camera():
	var game = get_tree().get_first_node_in_group("game")
	if game == null:
		return

	var cam = game.get_node("Camera2D")

	cam.global_position.x = clamp(
		cam.global_position.x,
		cam.limit_left,
		cam.limit_right
	)

	cam.global_position.y = clamp(
		cam.global_position.y,
		cam.limit_top,
		cam.limit_bottom
	)

func _on_boss_defeated():
	_open_exit()
	_expand_camera_bounds()
	_snap_camera()

func _open_exit():
	right_wall.visible = false
	right_wall.collision_enabled = false

func _expand_camera_bounds():
	var game = get_tree().get_first_node_in_group("game")
	if game == null: return
	var cam = game.get_node("Camera2D")
	if top_right:
		cam.limit_right = int(top_right.global_position.x)
