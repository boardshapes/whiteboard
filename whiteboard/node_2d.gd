extends Node2D

var color: Color = Color.BLACK
var brush_size: float = 50.0
var strokes: Array = []
var has_last_pos: bool = false
var last_pos: Vector2
var start_pos: Vector2
var drawable: bool = true
var erasing: bool = false
var rectangle_mode: bool = false
var rectangle_preview = {"type":'rect',"pos": [0,0], "size": [0,0], "color": color}
var dimensions: Array
var mouse_pos: Vector2
var texture : Texture2D = load("res://circle.png")

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
	
func _on_rectangle_pressed() -> void:
	if rectangle_mode:
		rectangle_mode = false
		# clear preview
		rectangle_preview = {"type":'rect',"pos": [0,0], "size": [0,0], "color": color}
	else:
		rectangle_mode = true

func _on_brush_size_value_changed(value: float) -> void:
	brush_size = value

func _process(delta: float) -> void:
	mouse_pos = get_global_mouse_position()

func _input(event: InputEvent) -> void:		
	if drawable:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT: 
				if event.pressed:
					has_last_pos = true
					last_pos = event.position
					print(last_pos)
					start_pos = event.position
					if not erasing:
						if not rectangle_mode:
							strokes.append({"type":'brush',"pos": last_pos, "size": brush_size, "color": color})
						queue_redraw()
				else:
					if rectangle_mode:
						dimensions = [event.position[0]-start_pos[0],event.position[1]-start_pos[1]] #wxh
						strokes.append({"type":'rect', "pos": start_pos, "size": dimensions, "color": color})
					# clear preview
					rectangle_preview = {"type":'rect',"pos": [0,0], "size": [0,0], "color": color}
					has_last_pos = false
		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): 
			if erasing:
				strokes = strokes.filter(func(s):
					return s.pos.distance_to(event.position) > brush_size/4
				)
				queue_redraw()
				return
			if has_last_pos:
				if rectangle_mode:
					dimensions = [event.position[0]-start_pos[0],event.position[1]-start_pos[1]] #wxh
					rectangle_preview = {"type":'rect',"pos": start_pos, "size": dimensions, "color": color}					
				else:
					var distance = last_pos.distance_to(event.position)
					var steps = int(distance/2)
					for i in range(steps):
						var t = float(i) / steps
						var interp_pos = last_pos.lerp(event.position, t)
						strokes.append({"type":'brush', "pos": interp_pos, "size": brush_size, "color": color})
				last_pos = event.position
				
			has_last_pos = true
			queue_redraw() 

func _draw() -> void:
	var rect
	
	for stroke in strokes:
		if stroke.type == 'rect': # seprate draw functions
			rect = Rect2(stroke.pos[0],stroke.pos[1],stroke.size[0],stroke.size[1])
			draw_rect(rect,stroke.color)
		else:
			var size = Vector2(stroke.size, stroke.size)  
			rect = Rect2(stroke.pos - size/2, size)  
			draw_texture_rect(texture, rect, false, stroke.color)
			
	#preview rect as your draw	
	rect = Rect2(rectangle_preview.pos[0],rectangle_preview.pos[1],rectangle_preview.size[0],rectangle_preview.size[1])	
	draw_rect(rect,rectangle_preview.color)
	

	if drawable:
		draw_circle(mouse_pos, brush_size/4, color, false, 2.0)
	if erasing:
		draw_circle(mouse_pos, brush_size/4, color, false, 2.0)
