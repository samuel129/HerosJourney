extends CanvasLayer

@onready var rect = $ColorRect
@onready var mat = rect.material

func _ready():
	add_to_group("transition_layer")
	rect.visible = false
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

var enabled: bool = true
var current_tween: Tween = null

func play_out():
	if current_tween:
		current_tween.kill()
	if not enabled:
		rect.visible = false
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	rect.visible = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	mat.set("shader_parameter/luminance_cutoff", 0.0)
	current_tween = create_tween()
	current_tween.tween_property(mat, "shader_parameter/luminance_cutoff", 1.0, 0.8)
	await current_tween.finished

func play_in():
	if current_tween:
		current_tween.kill()
	if not enabled:
		rect.visible = false
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	mat.set("shader_parameter/luminance_cutoff", 1.0)
	current_tween = create_tween()
	current_tween.tween_property(mat, "shader_parameter/luminance_cutoff", 0.0, 0.8)
	await current_tween.finished
	rect.visible = false
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
