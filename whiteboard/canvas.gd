extends Node2D

@onready var pick_image_file_dialog = $"../LoadImage"
@onready var pick_save_location_dialog = $"../SaveDialog"
var color: Color = Color.BLACK
var brush_size: float = 50.0
var strokes: Array = []
var has_last_pos: bool = false
var last_pos: Vector2
var start_pos: Vector2
var second_pos : Vector2 #for the line specifically
var drawable: bool = true
var erasing: bool = false
var shift : bool = false
var filled : bool = false
var mode = 'pen'
var distance: Vector2
var mouse_pos: Vector2
var texture : Texture2D = load("res://circle.png")
var default_bg : Texture2D = load("res://blank.jpeg")
var bg : Texture2D = default_bg
var history : Array = []
var undo_index = 0
var pencil_texture = preload("res://buttons/Pencil.png")
var glowpencil_texture = preload("res://buttons/GlowPencil.png")

func _on_canvas_viewport_mouse_entered() -> void:
	drawable = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_canvas_viewport_mouse_exited() -> void:
	drawable = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func update_buttons():
	%Undo.disabled = (undo_index == 0)
	%Redo.disabled = (undo_index == history.size()-1)

func _ready():
	# Set default directory and filename for the save
	pick_save_location_dialog.current_file = "save.png"
	pick_save_location_dialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	pick_save_location_dialog.access = FileDialog.ACCESS_FILESYSTEM	
	pick_save_location_dialog.filters = ["*.png,*.jpeg,*.jpg ; Image Files"]
	history.append(default_bg) #init the undo history
	update_buttons()

func flatten() -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	bg = ImageTexture.create_from_image(img)
	while undo_index<history.size()-1: # if you draw after undo, clear the other stuff
		history.pop_back()
	history.append(bg) 
	if not has_last_pos: #only save/update when youre done drawing
		if history.size()>25: # limit to 25 elements for now
			history.remove_at(0)
		else:
			undo_index += 1
		update_buttons()
	queue_redraw()

func distance_to(v1,v2):
	return Vector2(v1.x-v2.x,v1.y-v2.y)
	
func get_magnitude(p1,p2):	
	return ((p1.x-p2.x)**2+(p1.y-p2.y)**2)**.5

func _input(event: InputEvent) -> void:	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Z and event.ctrl_pressed:
			_on_undo_pressed()
		if event.keycode == KEY_Y and event.ctrl_pressed:
			_on_redo_pressed()
	if drawable:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT: 
				if event.pressed:
					has_last_pos = true
					last_pos = event.position
					start_pos = event.position
					if mode == 'pen':
						strokes.append({"type":'brush',"pos": last_pos, "size": brush_size, "color": color})
					queue_redraw()
				else:
					flatten()
					if mode == 'rect':
						distance = distance_to(last_pos,start_pos)
						strokes.append({"type":'rect', "pos": start_pos, "size": distance, "color": color})
					elif mode == 'line':
						strokes.append({"type":'line', "pos": start_pos, "size": get_magnitude(start_pos,last_pos), "color": color})
					elif mode == 'circle':
						strokes.append({"type":'circle', "pos": start_pos, "size": get_magnitude(start_pos,last_pos), "color": color})
					has_last_pos = false
		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): 
			if has_last_pos:
				if mode == 'rect':
					distance = distance_to(last_pos,start_pos)
				elif mode == 'pen':
					strokes.append({"type":'brush', "pos": last_pos, "size": brush_size, "color": color})
				last_pos = event.position
				
			has_last_pos = true
			queue_redraw()
	if event is InputEventKey:
		if event.keycode == KEY_SHIFT and event.pressed:
			shift = true
		else:
			shift = false
	queue_redraw() 

func _draw() -> void:
	var rect
	var pos = Vector2(0,0)
	var next
	var curr
	
	draw_texture(bg,pos)
	
	for i in range(strokes.size()-1): #leaves one
		curr = strokes[i]
		next = strokes[i+1]
		if mode == 'pen': # separate draw functions
			draw_line(curr.pos,next.pos,curr.color,curr.size/2)
			draw_circle(curr.pos,curr.size/4,curr.color)
	if strokes.size()>0: #grab the only/last element (last point in stroke, rectangles, lines, etc.)
		curr = strokes[-1]
		if mode == 'pen':
			draw_circle(curr.pos,curr.size/4,curr.color)
		elif mode == 'rect':
			if shift:
				var width = (last_pos.x-start_pos.x)
				var height = (last_pos.y-start_pos.y)
				var length = abs(width if abs(width) < abs(height) else height)
				var size = Vector2(length*(width/abs(width)),length*(height/abs(height)))
				rect = Rect2(start_pos,size) 
			else:
				rect = Rect2(curr.pos,distance)
			if filled or abs(distance.x)<brush_size or abs(distance.y)<brush_size:
				draw_rect(rect, curr.color, true, brush_size)
			else:
				rect = rect.abs()				# we need it to be pos in all dimensions
				rect = rect.grow(-brush_size/4) # this gives necessary offset for the size
				draw_rect(rect, curr.color, false, brush_size/2)
		elif mode == 'line':
			if shift:
				var mag = get_magnitude(start_pos,last_pos)
				var theta = start_pos.angle_to_point(last_pos)
				theta = snapped(theta,PI/12)
				second_pos = Vector2(mag*cos(theta)+start_pos.x,mag*sin(theta)+start_pos.y)
			else:
				second_pos = last_pos
			draw_line(start_pos,second_pos,color,brush_size/2)
			draw_circle(start_pos,brush_size/4,color,true)
			draw_circle(second_pos,brush_size/4,color,true)
		elif mode == 'circle':
			if filled:
				draw_circle(curr.pos,get_magnitude(start_pos,last_pos),curr.color,true)
			else:
				draw_circle(curr.pos,get_magnitude(start_pos,last_pos)-brush_size/4, curr.color,false,brush_size/2)
	
	if not has_last_pos:
		strokes.clear()
	elif strokes.size()>150: # eliminate lag by periodically flattening so you cant melt your gpu anymore
		flatten()
		strokes.clear()
		strokes.append(next)

func _on_load_pressed() -> void: #bring up dialog box
	pick_image_file_dialog.show()

func _on_save_pressed() -> void:
	pick_save_location_dialog.show()
	
func _on_pick_image_file_dialog_file_selected(path: String) -> void: #load up image
	var img = Image.load_from_file(path)
	if img == null:
		return
	bg = ImageTexture.create_from_image(img)
	queue_redraw()
	
func _on_pick_save_location_dialog_file_selected(path: String) -> void: # save that image
	if path[-2] == 'n': # .png has n at -2
		get_viewport().get_texture().get_image().save_png(path)		
	else:
		get_viewport().get_texture().get_image().save_jpg(path)
			
	pass
	
func _on_undo_pressed() -> void:
	if undo_index > 0: 
		undo_index -= 1
	bg = history[undo_index]
	update_buttons()
	queue_redraw()
	
func _on_redo_pressed() -> void:
	if undo_index < history.size()-1:
		undo_index += 1
	bg = history[undo_index]
	update_buttons()
	queue_redraw()

func _on_black_color_pressed() -> void:
	color = Color.BLACK
	%Pen.modulate = Color.BLACK
	%RectButton.modulate = Color.GRAY

func _on_white_color_pressed() -> void:
	color = Color.WHITE
	%Pen.modulate = Color.WHITE
	%RectButton.modulate = Color.WHITE

func _on_blue_color_pressed() -> void:
	color = Color.BLUE
	%Pen.modulate = Color.BLUE
	%RectButton.modulate = Color.BLUE

func _on_green_color_pressed() -> void:
	color = Color.GREEN
	%Pen.modulate = Color.GREEN
	%RectButton.modulate = Color.GREEN

func _on_red_color_pressed() -> void:
	color = Color.RED
	%Pen.modulate = Color.RED
	%RectButton.modulate = Color.RED
	 
func _on_clear_button_pressed() -> void:
	if shift:
		_clear()
	else:
		%ClearDialog.popup_centered()

func _on_clear_dialog_confirmed() -> void:
	_clear()

func _clear() -> void:
	bg = default_bg # get rid of that disgusting drawing by blanking it
	flatten()
	queue_redraw()

func _on_rect_button_pressed() -> void:
	mode = 'rect'
	%GlowPencil.visible = false
	%GlowRectangle.visible = true

func _on_brush_size_value_changed(value: float) -> void:
	brush_size = value

func _on_pen_pressed() -> void:
	mode = 'pen'
	%GlowPencil.visible = true
	%GlowRectangle.visible = false
	
func _on_line_button_pressed() -> void:
	mode = 'line'

func _on_circle_pressed() -> void:
	mode = 'circle'

func _on_filled_pressed() -> void:
	filled = not filled
