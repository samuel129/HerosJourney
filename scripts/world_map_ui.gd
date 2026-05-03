extends CanvasLayer
class_name WorldMapUI

signal node_selected(choice_id: String)

@onready var title_label: Label = $MapRoot/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $MapRoot/Panel/Margin/VBox/SubTitle
@onready var panel: PanelContainer = $MapRoot/Panel
@onready var map_field: Control = $MapRoot/Panel/Margin/VBox/MapField
@onready var map_art: WorldMapSceneArt = $MapRoot/Panel/Margin/VBox/MapField/MapArt
@onready var map_nodes: Control = $MapRoot/Panel/Margin/VBox/MapField/Nodes
@onready var detail_label: Label = $MapRoot/Panel/Margin/VBox/Detail
@onready var hint_label: Label = $MapRoot/Panel/Margin/VBox/Hint

var _choices: Array[Dictionary] = []
var _button_refs: Array[Button] = []
var _selected_index: int = 0
var _is_open: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_style_panel()
	_style_labels()
	if not map_field.resized.is_connected(_on_map_field_resized):
		map_field.resized.connect(_on_map_field_resized)

func open_map(next_stage: int, choices: Array) -> void:
	_choices.clear()
	for raw_choice in choices:
		var choice: Dictionary = (raw_choice as Dictionary).duplicate(true)
		_choices.append(choice)

	_selected_index = 0
	_rebuild_nodes()
	title_label.text = "Route Map"
	subtitle_label.text = "The road splits toward Stage %d" % next_stage
	hint_label.text = "Left/Right to study routes, Enter to travel"
	visible = true
	_is_open = true
	_update_detail_text()
	_update_map_art()
	call_deferred("_focus_selected_node")
	call_deferred("_layout_node_positions")
	get_tree().paused = true

func close_map() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or _choices.is_empty():
		return

	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_move_selection(1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept"):
		_confirm_selected()
		get_viewport().set_input_as_handled()

func _move_selection(step: int) -> void:
	_selected_index = posmod(_selected_index + step, _choices.size())
	_focus_selected_node()
	_refresh_node_states()
	_update_detail_text()

func _confirm_selected() -> void:
	if _selected_index < 0 or _selected_index >= _choices.size():
		return
	var choice_id: String = String(_choices[_selected_index].get("id", ""))
	_emit_selection(choice_id)

func _on_node_pressed(index: int) -> void:
	if index < 0 or index >= _choices.size():
		return
	_selected_index = index
	_focus_selected_node()
	_refresh_node_states()
	_update_detail_text()
	_confirm_selected()

func _emit_selection(choice_id: String) -> void:
	if choice_id.is_empty():
		return
	close_map()
	emit_signal("node_selected", choice_id)

func _rebuild_nodes() -> void:
	for child in map_nodes.get_children():
		child.queue_free()
	_button_refs.clear()

	for idx in range(_choices.size()):
		var choice: Dictionary = _choices[idx]
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(44, 34)
		button.size = button.custom_minimum_size
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 8)
		button.text = ""
		button.tooltip_text = _format_tooltip(choice)
		_style_route_button(button, false)
		button.pressed.connect(_on_node_pressed.bind(idx))
		map_nodes.add_child(button)
		_button_refs.append(button)

	_refresh_node_states()
	_layout_node_positions()

func _refresh_node_states() -> void:
	for idx in range(_button_refs.size()):
		if idx == _selected_index:
			_button_refs[idx].modulate = Color(1.0, 1.0, 1.0, 1.0)
			_style_route_button(_button_refs[idx], true)
		else:
			_button_refs[idx].modulate = Color(1.0, 1.0, 1.0, 1.0)
			_style_route_button(_button_refs[idx], false)
	_update_map_art()

func _update_detail_text() -> void:
	if _choices.is_empty():
		detail_label.text = ""
		return
	if _selected_index < 0 or _selected_index >= _choices.size():
		detail_label.text = ""
		return
	detail_label.text = _format_choice_text(_choices[_selected_index])

func _focus_selected_node() -> void:
	if _selected_index < 0 or _selected_index >= _button_refs.size():
		return
	_button_refs[_selected_index].grab_focus()

func _layout_node_positions() -> void:
	if _button_refs.is_empty():
		return

	var points: Array[Vector2] = _get_layout_points(_button_refs.size())
	var field_size: Vector2 = map_field.size
	if field_size.x < 1.0 or field_size.y < 1.0:
		field_size = map_field.get_combined_minimum_size()

	for idx in range(_button_refs.size()):
		var button: Button = _button_refs[idx]
		var norm: Vector2 = points[idx]
		var size: Vector2 = button.custom_minimum_size
		var x: float = round((field_size.x * norm.x) - (size.x * 0.5))
		var y: float = round((field_size.y * norm.y) - (size.y * 0.5))
		button.position = Vector2(x, y)
	_update_map_art()

func _get_layout_points(count: int) -> Array[Vector2]:
	if count <= 1:
		return [Vector2(0.74, 0.48)]
	if count == 2:
		return [Vector2(0.48, 0.7), Vector2(0.78, 0.32)]
	if count == 3:
		return [Vector2(0.36, 0.7), Vector2(0.61, 0.3), Vector2(0.86, 0.62)]
	if count == 4:
		return [Vector2(0.28, 0.68), Vector2(0.5, 0.34), Vector2(0.7, 0.32), Vector2(0.9, 0.62)]

	var result: Array[Vector2] = []
	for idx in range(count):
		var t: float = 0.0 if count <= 1 else float(idx) / float(count - 1)
		var y: float = 0.45 + (sin(t * PI * 2.0) * 0.18)
		result.append(Vector2(0.22 + t * 0.72, y))
	return result

func _on_map_field_resized() -> void:
	_layout_node_positions()
	_update_map_art()

func _format_choice_text(choice: Dictionary) -> String:
	var title: String = String(choice.get("title", "Unknown Route"))
	var description: String = String(choice.get("description", "")).strip_edges()
	var reward_gold: int = int(choice.get("reward_gold", 0))
	var heal_percent: int = int(round(float(choice.get("heal_percent", 0.0)) * 100.0))

	var reward_text: String = "+%d Gold" % reward_gold
	if heal_percent > 0:
		reward_text += " | +%d%% HP" % heal_percent

	return "%s\n%s\n%s" % [title, description, reward_text]

func _format_tooltip(choice: Dictionary) -> String:
	return _format_choice_text(choice).replace("\n", " | ")

func _update_map_art() -> void:
	if map_art == null:
		return
	var route_types: Array[String] = []
	for raw_choice in _choices:
		var choice: Dictionary = raw_choice
		route_types.append(String(choice.get("node_type", "path_combat")))
	map_art.configure(route_types, _selected_index)

func _style_panel() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.045, 0.84)
	style.border_color = Color(0.67, 0.46, 0.23, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)

func _style_labels() -> void:
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.52, 1.0))
	subtitle_label.add_theme_color_override("font_color", Color(0.92, 0.76, 0.5, 1.0))
	detail_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.66, 1.0))
	hint_label.add_theme_color_override("font_color", Color(0.77, 0.64, 0.45, 1.0))

func _style_route_button(button: Button, selected: bool) -> void:
	var style: StyleBoxFlat = _make_invisible_button_style(selected)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_focus_color", Color.TRANSPARENT)

func _make_invisible_button_style(selected: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
	style.border_color = Color(1.0, 0.88, 0.42, 0.0 if not selected else 0.12)
	var border_width: int = 1 if selected else 0
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	return style
