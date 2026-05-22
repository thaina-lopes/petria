extends Control

# Configurações do Joystick
@export var max_distance := 40.0
@export var deadzone := 5.0
@export var base_color := Color(1.0, 1.0, 1.0, 0.15)
@export var handle_color := Color(1.0, 1.0, 1.0, 0.6)

var output := 0.0
var touch_id: int = -1
var is_active := false

var center := Vector2.ZERO
var handle_pos := Vector2.ZERO

func _ready():
	add_to_group("virtual_joystick")
	# Mudar para IGNORE já que usaremos _input global
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw():
	if not is_active:
		return
		
	# Desenha uma linha guia horizontal sutil para indicar o eixo do movimento
	draw_line(center - Vector2(max_distance, 0), center + Vector2(max_distance, 0), base_color, 2.0)
	
	# Base central (referência fininha de onde o dedo tocou originalmente)
	draw_circle(center, 3.0, base_color)
	
	# Bolinha (Handle - acompanha o dedo)
	draw_circle(handle_pos, 16.0, handle_color)
	draw_circle(handle_pos, 12.0, Color(1.0, 1.0, 1.0, 0.9))

func _input(event: InputEvent):
	if not is_visible_in_tree():
		return
		
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			# Verifica se o toque foi na metade esquerda da tela
			if event.position.x <= get_viewport_rect().size.x / 2.0:
				touch_id = event.index
				is_active = true
				center = event.position
				handle_pos = center
				output = 0.0
				queue_redraw()
				get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == touch_id:
			_reset_joystick()
			
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()

func _update_joystick(local_pos: Vector2):
	var dir_x = local_pos.x - center.x
	
	# Aplica deadzone para evitar tremedeiras (movimento involuntário)
	if abs(dir_x) < deadzone:
		dir_x = 0.0
	
	# Limita o arrasto horizontal ao max_distance
	if abs(dir_x) > max_distance:
		dir_x = sign(dir_x) * max_distance
		
	handle_pos = center + Vector2(dir_x, 0)
	
	# Calcula output normalizado (-1 a 1)
	if abs(dir_x) > 0:
		output = dir_x / max_distance
	else:
		output = 0.0
		
	queue_redraw()

func _reset_joystick():
	touch_id = -1
	is_active = false
	handle_pos = center
	output = 0.0
	queue_redraw()
