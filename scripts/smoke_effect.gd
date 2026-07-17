extends Node2D

@export var smoke_color: Color = Color(0.85, 0.85, 0.85, 0.8) # Cor da fumaça
@export var amount: int = 60 # MUITO mais partículas para formar uma "coluna" unida e não bolhas separadas
@export var lifetime: float = 1.5 # Tempo de vida mais curto para manter o rastro contínuo
@export var spread: float = 10.0 # Espalhamento menor para ficar um fio de fumaça coeso
@export var gravity: Vector2 = Vector2(0, -30) # Sobe mais reto e constante
@export var initial_velocity: float = 5.0 # Menos "explosão" inicial, mais subida fluida
@export var scale_min: float = 2.0 # Tamanho mínimo base
@export var scale_max: float = 4.0 # Tamanho máximo base

var particles: CPUParticles2D

func _ready() -> void:
	particles = CPUParticles2D.new()
	
	# Configurações básicas
	particles.amount = amount
	particles.lifetime = lifetime
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT # Nasce exatamente do centro, para não espalhar
	particles.local_coords = false # IMPORTANTE: Desconecta a fumaça do movimento do cachimbo, para ela não "descer" se o velho balançar
	
	# Movimentação e gravidade
	particles.direction = Vector2(0, -1)
	particles.spread = spread
	particles.gravity = gravity
	particles.initial_velocity_min = initial_velocity * 0.7
	particles.initial_velocity_max = initial_velocity * 1.3
	
	# Estilo visual de Pixel Art
	particles.scale_amount_min = scale_min
	particles.scale_amount_max = scale_max
	
	# Faz começar maior e ir diminuindo até sumir
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0)) # Nasce com 100% do tamanho
	scale_curve.add_point(Vector2(1.0, 0.0)) # Morre com 0% do tamanho
	particles.scale_amount_curve = scale_curve
	
	# Transição de cor (vai sumindo gradualmente)
	var color_ramp = Gradient.new()
	color_ramp.set_color(0, smoke_color)
	var end_color = smoke_color
	end_color.a = 0.0 # Define a transparência final como 0 (invisível)
	color_ramp.set_color(1, end_color)
	particles.color_ramp = color_ramp
	
	add_child(particles)
	
	# Oculta o pixel guia (usado apenas no editor para ajudar a posicionar) durante o jogo
	if has_node("Pixel"):
		$Pixel.visible = false

# Se quiser mudar os valores dinamicamente no jogo:
func update_smoke(new_amount: int) -> void:
	if particles:
		particles.amount = new_amount
