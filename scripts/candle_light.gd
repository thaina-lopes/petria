extends Node2D

@export var light_color: Color = Color(0.95, 0.65, 0.2) # Laranja quente de fogo/vela
@export var light_scale: float = 1.0
@export var light_energy: float = 1.0
@export var flicker: bool = true
@export var flicker_speed: float = 8.0
@export var flicker_intensity: float = 0.15

var point_light: PointLight2D
var time_passed := 0.0

func _ready() -> void:
	# Cria a textura do gradiente com um brilho característico de vela
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
	
	# Tamanho base maior (160) apropriado para uma vela/fogueira
	tex.width = int(160 * light_scale)
	tex.height = int(160 * light_scale)
	
	# Configura a luz
	point_light = PointLight2D.new()
	point_light.texture = tex
	point_light.color = light_color
	point_light.energy = light_energy
	point_light.blend_mode = Light2D.BLEND_MODE_ADD
	point_light.range_z_max = 0 # Não ilumina objetos com z_index >= 1 (como o Player)
	
	add_child(point_light)
	
	# Oculta o pixel guia (usado apenas no editor) durante o jogo
	if has_node("Pixel"):
		$Pixel.visible = false

func _process(delta: float) -> void:
	if flicker and point_light:
		time_passed += delta * flicker_speed
		# Fórmula de oscilação mais agressiva para simular o bater do fogo
		var flicker_val = sin(time_passed) * flicker_intensity + sin(time_passed * 2.5) * (flicker_intensity * 0.5) + randf_range(-0.03, 0.03)
		point_light.energy = light_energy + flicker_val
