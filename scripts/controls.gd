extends CanvasLayer

const VIRTUAL_JOYSTICK = preload("res://scenes/virtual_joystick.tscn")
const MOBILE_TUTORIAL = preload("res://scenes/mobile_tutorial.tscn")

func _ready():
	if DisplayServer.is_touchscreen_available():
		show()
		
		var left_btn = get_node_or_null("Left")
		if left_btn:
			left_btn.queue_free()
			
		var right_btn = get_node_or_null("Right")
		if right_btn:
			right_btn.queue_free()
			
		var joystick = VIRTUAL_JOYSTICK.instantiate()
		add_child(joystick)
		
		# Injetar o tutorial se for o Level 1 e ainda não foi visto
		if get_tree().current_scene and get_tree().current_scene.name == "Level1":
			if not GameManager.tutorial_movimento_visto:
				GameManager.tutorial_movimento_visto = true
				var tutorial = MOBILE_TUTORIAL.instantiate()
				# Posiciona no canto esquerdo inferior, indicando o gesto do joystick
				tutorial.position = Vector2(90, 155)
				add_child(tutorial)
	else:
		hide()
