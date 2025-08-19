extends Node2D

var color: Color = Color.BLACK
var brush_size: float = 5.0
var strokes: Array = []
var has_last_pos: bool = false
var last_pos: Vector2
var drawable: bool = true
var erasing: bool = false
var mouse_pos: Vector2

func _on_control_mouse_entered() -> void:
	drawable = true

func _on_control_mouse_exited() -> void:
	drawable = false

func _on_black_color_pressed() -> void:
	color = Color.BLACK
	erasing = false

func _on_white_color_pressed() -> void:
	erasing = true
	color = Color.WHITE

func _on_blue_color_pressed() -> void:
	color = Color.BLUE
	erasing = false

func _on_green_color_pressed() -> void:
	color = Color.GREEN
	erasing = false

func _on_red_color_pressed() -> void:
	color = Color.RED
	erasing = false

func _on_clear_pressed() -> void:
	strokes = []
	queue_redraw()

func _on_brush_size_value_changed(value: float) -> void:
	brush_size = value

func _process(delta: float) -> void:
	mouse_pos = get_global_mouse_position()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if drawable:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					last_pos = event.position
					has_last_pos = true
					if not erasing:
						strokes.append({"pos": last_pos, "size": brush_size, "color": color})
						queue_redraw()
				else:
					has_last_pos = false

		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if erasing:
				strokes = strokes.filter(func(s):
					return s.pos.distance_to(event.position) > brush_size
				)
				queue_redraw()
				return
			if has_last_pos:
				var distance = last_pos.distance_to(event.position)
				var steps = int(distance / 2)
				for i in range(steps):
					var t = float(i) / steps
					var interp_pos = last_pos.lerp(event.position, t)
					strokes.append({"pos": interp_pos, "size": brush_size, "color": color})
			strokes.append({"pos": event.position, "size": brush_size, "color": color})
			last_pos = event.position
			has_last_pos = true
			queue_redraw()

func _draw() -> void:
	for stroke in strokes:
		draw_circle(stroke.pos, stroke.size, stroke.color)

	if drawable:
		draw_circle(mouse_pos, brush_size, color, false, 2.0)
