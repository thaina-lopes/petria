extends CharacterBody2D

# Velocidade de movimento do inimigo
const SPEED = 15.0
# Força do empurrão que o inimigo dá no player ao encostar nele
const KNOCKBACK_FORCE = Vector2(80, -80)

# Direção que o inimigo está olhando/andando (-1 é esquerda, 1 é direita)
var facing_direction = -1
# O RayCast2D que detecta se há chão a frente (para não cair em buracos)
var ledge_raycast: RayCast2D
var dead = false

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	anim.play("walk")
	
	# Reconecta o sinal de dano que havia sido removido na limpeza do usuário
	if not $HitArea.body_entered.is_connected(_on_hit_body_entered):
		$HitArea.body_entered.connect(_on_hit_body_entered)
	
	_setup_nodes()
	_setup_shader()

func _setup_nodes() -> void:
	# Cria dinamicamente o detector de bordas
	ledge_raycast = RayCast2D.new()
	ledge_raycast.target_position = Vector2(0, 20)
	ledge_raycast.collision_mask = 1
	add_child(ledge_raycast)
	
	# Adiciona a luz do inimigo
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0)
	tex.width = 60
	tex.height = 60
	light.texture = tex
	light.color = Color(1.0, 0.2, 0.2) # Luz vermelha
	light.energy = 0.8
	light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(light)
	
	var sfx_death = AudioStreamPlayer2D.new()
	sfx_death.stream = preload("res://sound/splash.ogg")
	sfx_death.name = "SfxDeath"
	add_child(sfx_death)

func _setup_shader() -> void:
	# Cria um material de shader para permitir que o inimigo pisque branco ao morrer
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	uniform float white_progress : hint_range(0.0, 1.0) = 0.0;
	void fragment() {
		vec4 color = texture(TEXTURE, UV);
		COLOR = mix(color, vec4(1.0, 1.0, 1.0, color.a), white_progress);
	}
	"""
	var mat = ShaderMaterial.new()
	mat.shader = shader
	anim.material = mat

func _physics_process(delta: float) -> void:
	# Se o inimigo já morreu (levou pisão), ignora o resto da física
	if dead: return
	
	# Aplica a gravidade caso não esteja no chão
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Posiciona o sensor de buraco um pouco a frente da direção atual
	ledge_raycast.position.x = facing_direction * 15
	ledge_raycast.force_raycast_update()
	
	# Garante que ele só tenta virar se estiver indo para a direção que está olhando
	# (Evita que ele fique tremendo infinitamente se continuar encostado na parede enquanto freia)
	var is_moving_forward = sign(velocity.x) == facing_direction or velocity.x == 0
	
	if is_moving_forward:
		# Se bateu na parede OU (está no chão mas o sensor não acha chão a frente)
		if is_on_wall() or (is_on_floor() and not ledge_raycast.is_colliding()):
			facing_direction *= -1
			
			# Se chegou num buraco, freia instantaneamente pra não escorregar pra fora da plataforma
			if not ledge_raycast.is_colliding():
				velocity.x = 0
		
	# Aplica a velocidade de forma suave (move_toward) para criar o efeito de frear e arrancar
	var target_speed = facing_direction * SPEED
	velocity.x = move_toward(velocity.x, target_speed, 120.0 * delta)
	
	# Atualiza o sprite para olhar para o lado certo
	anim.flip_h = facing_direction < 0

	move_and_slide()

func _on_hit_body_entered(body: Node2D) -> void:
	# Impede interações se já está morto
	if dead: return
	
	# Se o objeto que tocou for o Player
	if body.is_in_group("player"):
		# Verifica se o player está caindo (velocity.y > 0) e está vindo de cima (pos Y menor)
		var hit_from_above = body.velocity.y > 0 and body.global_position.y < global_position.y - 12
		
		# Se foi um pisão na cabeça
		if hit_from_above and body.has_method("bounce"):
			dead = true # Marca como morto
			body.bounce() # Faz o player dar um mini-pulo
			
			if has_node("SfxDeath"):
				get_node("SfxDeath").play()
			
			# Desliga as colisões para não causar mais dano
			$CollisionShape2D.set_deferred("disabled", true)
			$HitArea/CollisionShape2D.set_deferred("disabled", true)
			velocity = Vector2.ZERO # Para o movimento do inimigo
			anim.stop() # Congela a animação no frame atual
			
			# Cria um Tween para piscar o inimigo de branco de forma mais lenta antes de sumir
			var tween = create_tween()
			for i in range(2):
				# Fica branco em 0.15 seg, e volta ao normal em 0.15 seg
				tween.tween_method(func(v): anim.material.set_shader_parameter("white_progress", v), 0.0, 1.0, 0.15)
				tween.tween_method(func(v): anim.material.set_shader_parameter("white_progress", v), 1.0, 0.0, 0.15)
			
			await tween.finished
			queue_free() # Deleta o inimigo da memória
			
		# Se não foi pisão, significa que o inimigo machucou o player
		elif body.has_method("take_damage"):
			var direction = sign(body.global_position.x - global_position.x)
			if direction == 0:
				direction = 1
			# Calcula o impulso (knockback) baseado em qual lado o player está
			var knockback = Vector2(KNOCKBACK_FORCE.x * direction, KNOCKBACK_FORCE.y)
			body.take_damage(knockback)
