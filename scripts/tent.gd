extends Node2D

var door_light: PointLight2D
var window_light: PointLight2D
var time_passed := 0.0

func _ready() -> void:
	# Criação da textura base para a luz (gradiente suave)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.2, Color(1, 1, 1, 0.7))
	gradient.add_point(0.5, Color(1, 1, 1, 0.2))
	
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.8, 0.8)
	
	# === LUZ DA PORTA ===
	door_light = PointLight2D.new()
	door_light.texture = tex
	# Aumentar tamanho para a porta
	door_light.texture.width = 128
	door_light.texture.height = 128
	door_light.color = Color(0.95, 0.65, 0.2) # Laranja quente (fogo)
	door_light.energy = 1.2
	door_light.blend_mode = Light2D.BLEND_MODE_ADD
	
	# Posição da porta (movida um pouco mais para a esquerda)
	door_light.position = Vector2(200.0, 170.5)
	add_child(door_light)
	
	# === LUZ DA JANELA ===
	window_light = PointLight2D.new()
	window_light.texture = tex.duplicate()
	# Luz menor para a janela
	window_light.texture.width = 96
	window_light.texture.height = 96
	window_light.color = Color(0.95, 0.65, 0.2)
	window_light.energy = 0.9
	window_light.blend_mode = Light2D.BLEND_MODE_ADD
	
	# Posição estimada da janela (movida mais para a direita)
	window_light.position = Vector2(230.0, 160.0)
	add_child(window_light)

func _process(delta: float) -> void:
	time_passed += delta * 8.0
	
	# A mesma vela gera a luz, então a matemática básica do 'flicker' (tremulação) deve ser a mesma
	var flicker_base = sin(time_passed) * 0.15 + sin(time_passed * 2.5) * 0.08 + randf_range(-0.02, 0.02)
	
	# Aplica a tremulação exata na porta
	if door_light:
		door_light.energy = 1.2 + flicker_base
		
	# Aplica a mesma tremulação sincronizada na janela (proporcionalmente menor devido à intensidade)
	if window_light:
		var window_flicker = flicker_base * (0.9 / 1.2)
		window_light.energy = 0.9 + window_flicker
