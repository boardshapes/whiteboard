extends Node2D

var mi_pos:Array = []

func _input(event:InputEvent):
 if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
  return
 mi_pos.append(event.position)
 queue_redraw()

func _draw():
 for point in mi_pos:
  draw_circle(point,5,Color.BLACK)
