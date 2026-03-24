extends Node2D

@onready var entry: Marker2D = $Entry
@onready var exit: Marker2D = $Exit
@onready var tilemap: TileMapLayer = $Foreground

@export var tile_size: int = 16

@export var chunk_type: String = "normal"
@export var weight: int = 1

@export var exit_tag: String = "right"
@export var allowed_next_tags: Array[String] = ["right"]

func _ready():
	@warning_ignore("integer_division")
	entry.position = Vector2(tile_size / 2, 0)
