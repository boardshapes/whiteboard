extends Node2D

var last_pos: Vector2
var start_pos: Vector2
var default_pos = Vector2(0,0)
var color : Color = Color.BLACK
var rectangle_mode : bool = false
var brush_size: float = 50.0
var has_last_pos : bool = false
var dimensions : Vector2
var mouse_pos : Vector2


func _on_black_color_pressed() -> void:
	color = Color.BLACK

func _on_white_color_2_pressed() -> void:
	color = Color.WHITE

func _on_blue_color_2_pressed() -> void:
	color = Color.BLUE

func _on_green_color_pressed() -> void:
	color = Color.GREEN

func _on_red_color_2_pressed() -> void:
	color = Color.RED
	

func _on_rect_button_pressed() -> void:
	if rectangle_mode:
		rectangle_mode = false
	else:
		rectangle_mode = true

func _on_brush_size_value_changed(value: float) -> void:
	brush_size = value

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT: 
				if event.pressed:
					start_pos = event.position
					last_pos = event.position
				else: #reset points
					has_last_pos = false
					last_pos = default_pos
					start_pos = default_pos
					dimensions = default_pos
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if has_last_pos:
				dimensions = Vector2((event.position.x-start_pos.x),(event.position.y-start_pos.y)) #wxh
				last_pos = event.position
			
		has_last_pos = true
		queue_redraw()
	if not event is InputEventKey:
		mouse_pos = event.position
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SHIFT:
			
			pass
	queue_redraw()
					
func _draw() -> void:
	var rect : Rect2
	if rectangle_mode:
		rect = Rect2(start_pos,dimensions)	
		draw_rect(rect,color, false, 1)
	else:
		draw_circle(mouse_pos, brush_size/4, color, false, 2.0)
