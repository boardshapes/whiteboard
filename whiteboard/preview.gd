extends Node2D

var last_pos: Vector2
var start_pos: Vector2
var rectangle_preview = {"type":'rect',"pos": [0,0], "size": [0,0], "color":color}
var color : Color = Color.BLACK
var rectangle_mode : bool = false
var brush_size: float = 50.0
var has_last_pos : bool = false
var dimensions : Array
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
		# clear preview
		rectangle_preview = {"type":'rect',"pos": [0,0], "size": [0,0], "color": color}
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
				else:					
					rectangle_preview = {"type":'rect',"pos": [0,0], "size": [0,0], "color": color}
					#preview_node.redraw()
					has_last_pos = false
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if has_last_pos:
				if rectangle_mode:
					dimensions = [event.position[0]-start_pos[0],event.position[1]-start_pos[1]] #wxh
					rectangle_preview = {"type":'rect',"pos": start_pos, "size": dimensions, "color": color}
				last_pos = event.position
			
		has_last_pos = true
		queue_redraw()
	mouse_pos = event.position
	queue_redraw()
					
func _draw() -> void:
	var rect = Rect2(
		rectangle_preview.pos[0],
		rectangle_preview.pos[1],
		rectangle_preview.size[0],
		rectangle_preview.size[1]
	)
	rect = Rect2(rectangle_preview.pos[0],rectangle_preview.pos[1],rectangle_preview.size[0],rectangle_preview.size[1])	
	draw_rect(rect,rectangle_preview.color, false, 1)
	
	draw_circle(mouse_pos, brush_size/4, color, false, 2.0)
