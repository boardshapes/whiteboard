extends Node2D

var default_pos = Vector2(-1000,-1000)
var last_pos: Vector2 = default_pos
var start_pos: Vector2 = default_pos
var second_pos : Vector2 = default_pos
var strokes : Array = []
var color : Color = Color.BLACK
var bg : Texture2D = load("res://blank.jpeg")
var mode = 'pen'
var brush_size: float = 50.0
var has_last_pos : bool = true
var shift : bool = false
var mouse_pos : Vector2 = default_pos
var draw_previews : bool = true
var i = 0
var canvas_updated : bool = false

signal drawing

func _on_canvas_viewport_mouse_entered() -> void:
	draw_previews = true
	
func _on_canvas_viewport_mouse_exited() -> void:
	draw_previews = false
	queue_redraw()
	
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

func _on_pen_pressed() -> void:
	mode ='pen'
	queue_redraw()
	
func _on_rect_button_pressed() -> void:
	mode ='rect'
	queue_redraw()
	
func _on_line_button_pressed() -> void:
	mode ='line'
	queue_redraw()
	
func _on_circle_pressed() -> void:
	mode = 'circle'
	queue_redraw()

func _on_brush_size_value_changed(value: float) -> void:
	brush_size = value

func _ready() -> void:
	$"../../drawingViewport/Canvas".canvas_drawn.connect(canvas_drawn)
	
func canvas_drawn(new_bg):
	bg = new_bg
	canvas_updated = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT: 
			if event.pressed:
				has_last_pos = true
				start_pos = event.position
				last_pos = event.position
				if mode == 'pen':
					strokes.append(last_pos)
			else: #reset points
				if strokes.size() == 1:
					drawing.emit(
						last_pos,
						start_pos,
						strokes
					)
				last_pos = default_pos
				start_pos = default_pos
				has_last_pos = false
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		last_pos = event.position
		if mode == 'pen':
			strokes.append(last_pos)
		drawing.emit(
			last_pos,
			start_pos,
			strokes
		)
		has_last_pos = true
	if not event is InputEventKey:
		mouse_pos = event.position
	else:
		if event.keycode == KEY_SHIFT and event.pressed:
			shift = true
		else:
			shift = false
			
	

	queue_redraw()

func get_magnitude(p1,p2):	
	return ((p1.x-p2.x)**2+(p1.y-p2.y)**2)**.5

func get_dimensions(p1,p2):
	return Vector2((p2.x-p1.x),(p2.y-p1.y))

func _draw() -> void:	
		#draw_texture(bg,Vector2(0,0))
		
		if mode == 'pen':
			draw_stroke_preview()
		elif mode == 'rect':
			draw_rect_preview()
		elif mode == 'line':
			draw_line_preview()
		elif mode == 'circle':
			draw_cricle_preview()
		
		if draw_previews:
			if mode == 'pen':
				draw_circle(mouse_pos, brush_size/4+1, color, false, 2.0)
				draw_circle(mouse_pos, brush_size/4, color, false, 2.0)
			else:
				# make a crosshair
				draw_circle(Vector2(mouse_pos.x+5,mouse_pos.y), 1, color, true)
				draw_circle(Vector2(mouse_pos.x-5,mouse_pos.y), 1, color, true)
				draw_circle(Vector2(mouse_pos.x,mouse_pos.y-5), 1, color, true)
				draw_circle(Vector2(mouse_pos.x,mouse_pos.y+5), 1, color, true) 
				
				#center 
				draw_circle(mouse_pos, 2, color.inverted(), true) #invert for contras
				draw_circle(mouse_pos, 1, color, true)
		
		
		if canvas_updated:
			if strokes.size()>150:
				var temp = strokes[-1]
				strokes.clear()
				strokes.append(temp)
			else:
				strokes.clear()
			has_last_pos = false
			canvas_updated = false

func draw_stroke_preview():
	var curr : Vector2
	var next : Vector2
	if strokes.size()>0:
		for s in range(strokes.size()-1):
			curr = strokes[s]
			next = strokes[s+1]
			draw_line(curr,next,color,brush_size/2)
			draw_circle(curr,brush_size/4, color)
	draw_circle(last_pos,brush_size/4,color)
	
func draw_rect_preview():
	var rect : Rect2
	if shift:	#make it square
		var width = (last_pos.x-start_pos.x)
		var height = (last_pos.y-start_pos.y)
		var length = abs(width if abs(width) > abs(height) else height)
		var size = Vector2(length*(width/abs(width)),length*(height/abs(height)))
		rect = Rect2(start_pos,size) 
	else:
		rect = Rect2(start_pos,get_dimensions(start_pos,last_pos))
	draw_rect(rect,color, false, 1)
	
func draw_line_preview():
	if shift:
		var mag = get_magnitude(start_pos,last_pos)
		var theta = start_pos.angle_to_point(last_pos)
		theta = snapped(theta,PI/12)
		second_pos = Vector2(mag*cos(theta)+start_pos.x,mag*sin(theta)+start_pos.y)
		print(theta)
	else:
		second_pos = last_pos
	draw_line(start_pos,second_pos,color,brush_size/2)
	draw_circle(start_pos,brush_size/4,color,true)
	draw_circle(second_pos,brush_size/4,color,true)

func draw_cricle_preview():
	if shift:
		draw_circle(start_pos,get_magnitude(start_pos,last_pos),color,false)
	else:
		draw_circle(last_pos,get_magnitude(start_pos,last_pos),color,false)
