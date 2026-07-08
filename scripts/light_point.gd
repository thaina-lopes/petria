extends Node2D

@export var light_color: Color = Color(0.95, 0.65, 0.2)
@export var light_scale: float = 1.0
@export var light_energy: float = 0.6
@export var flicker: bool = false
@export var flicker_speed: float = 8.0
@export var flicker_intensity: float = 0.15

var point_light: PointLight2D
var time_passed := 0.0

func _ready() -> void:
	# Cria a textura do gradiente para a luz com uma transição bem suave
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.8)) # Centro menos estourado
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.4, Color(1, 1, 1, 0.3)) # Decaimento suave
	
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.7, 0.7) # Borda mais difusa
	
	# Tamanho base reduzido para ser menor e mais contido
	tex.width = int(48 * light_scale)
	tex.height = int(48 * light_scale)
	
	# Configura a luz
	point_light = PointLight2D.new()
	point_light.texture = tex
	point_light.color = light_color
	point_light.energy = light_energy
	point_light.blend_mode = Light2D.BLEND_MODE_ADD
	
	add_child(point_light)
	
	# Oculta o pixel guia (usado apenas no editor) durante o jogo
	if has_node("Pixel"):
		$Pixel.visible = false

func _process(delta: float) -> void:
	if flicker and point_light:
		time_passed += delta * flicker_speed
		var flicker_val = sin(time_passed) * flicker_intensity + sin(time_passed * 2.5) * (flicker_intensity * 0.5) + randf_range(-0.02, 0.02)
		point_light.energy = light_energy + flicker_val
