extends Node2D

@onready var pick_image_file_dialog = $"../LoadImage"
@onready var pick_save_location_dialog = $"../SaveDialog"
var color: Color = Color.BLACK
var brush_size: float = 50.0
var strokes: Array = []
var has_last_pos: bool = false
var last_pos: Vector2
var start_pos: Vector2
var drawable: bool = true
var erasing: bool = false
var rectangle_mode: bool = false
var distance: Vector2
var mouse_pos: Vector2
var texture : Texture2D = load("res://circle.png")
var default_bg : Texture2D = load("res://blank.jpeg")
var bg : Texture2D = default_bg
var history : Array = []
var undo_index = 0

func _on_canvas_viewport_mouse_entered() -> void:
	drawable = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_canvas_viewport_mouse_exited() -> void:
	drawable = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func update_buttons():
	%undo.disabled = (undo_index == 0)
	%redo.disabled = (undo_index == history.size()-1)

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

func _process(delta: float) -> void:
	mouse_pos = get_global_mouse_position()



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
					if not rectangle_mode:
						strokes.append({"type":'brush',"pos": last_pos, "size": brush_size, "color": color})
					queue_redraw()
				else:
					flatten()
					if rectangle_mode:
						distance = distance_to(last_pos,start_pos)
						strokes.append({"type":'rect', "pos": start_pos, "size": distance, "color": color})
					has_last_pos = false
		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): 
			if has_last_pos:
				if rectangle_mode:
					distance = distance_to(last_pos,start_pos)
				else:
					strokes.append({"type":'brush', "pos": last_pos, "size": brush_size, "color": color})
				last_pos = event.position
				
			has_last_pos = true
			queue_redraw()
			
	queue_redraw() 

func _draw() -> void:
	var rect
	var pos = Vector2(0,0)
	var next
	var curr
	
	draw_texture(bg,pos)
	
	for i in range(strokes.size()-1):
		curr = strokes[i]
		next = strokes[i+1]
		if not curr.type == 'rect': # separate draw functions
			draw_line(curr.pos,next.pos,curr.color,curr.size/2)
			draw_circle(curr.pos,curr.size/4,curr.color)
	if strokes.size()>0:
		curr = strokes[-1]
		if curr.type == 'rect':
			rect = Rect2(curr.pos,distance)
			draw_rect(rect,curr.color)
		else:
			draw_circle(curr.pos,curr.size/4,curr.color)
	
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

func _on_white_color_pressed() -> void:
	color = Color.WHITE

func _on_blue_color_pressed() -> void:
	color = Color.BLUE

func _on_green_color_pressed() -> void:
	color = Color.GREEN

func _on_red_color_pressed() -> void:
	color = Color.RED

func _on_clear_pressed() -> void:
	bg = default_bg # get rid of that disgusting drawing by blanking it
	queue_redraw()

func _on_rect_button_pressed() -> void:
	if rectangle_mode:
		rectangle_mode = false
	else:
		rectangle_mode = true

func _on_brush_size_value_changed(value: float) -> void:
	brush_size = value
