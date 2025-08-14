extends Node2D

var color: Color = Color.BLACK
var brush_size: float = 5.0
var strokes: Array = []
var has_last_pos: bool = false
var last_pos: Vector2
var drawable: bool = true

func _on_control_mouse_entered() -> void:
	drawable = true

func _on_control_mouse_exited() -> void:
	drawable = false


func _on_black_color_pressed() -> void:
	color = Color.BLACK

func _on_white_color_pressed() -> void:
	color = Color.WHITE

func _on_blue_color_pressed() -> void:
	color = Color.BLUE

func _on_green_color_pressed() -> void:
	color = Color.GREEN

func _on_red_color_pressed() -> void:
	color = Color.RED

func _on_brush_size_value_changed(value: float) -> void:
	brush_size = value

func _on_button_mouse_entered() -> void:
	#if InputEventMouseButton:
		color = Color(0,0,0,0)

func _input(event: InputEvent) -> void:
	if drawable:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					last_pos = event.position
					has_last_pos = true
					strokes.append({"pos": last_pos, "size": brush_size, "color": color})
					queue_redraw()
				else:
					has_last_pos = false

		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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
