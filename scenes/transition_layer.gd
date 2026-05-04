extends CanvasLayer

@onready var rect = $ColorRect
@onready var mat = rect.material

func _ready():
	layer = 1000
	rect.visible = false
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func play_out():
	rect.visible = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	mat.set("shader_parameter/luminance_cutoff", 0.0)

	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/luminance_cutoff", 1.0, 0.8)
	await tween.finished


func play_in():
	mat.set("shader_parameter/luminance_cutoff", 1.0)

	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/luminance_cutoff", 0.0, 0.8)
	await tween.finished

	rect.visible = false
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
