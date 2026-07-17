extends CharacterBody2D

signal estatua_criada
signal morreu
signal vida_alterada(qtd)

enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	PETRIFY,
	DEAD,
	HURT,
	SIT
}

const SPEED = 110.0
const ACCELERATION = 900.0
const FRICTION = 1200.0
const JUMP_VELOCITY = -300.0
const MAX_ESTATUAS = 2
const FALL_LIMIT_Y = 320.0
const COYOTE_TIME = 0.15
const JUMP_BUFFER_TIME = 0.1

var cena_estatua = preload("res://scenes/statue.tscn")
var estatuas_criadas = 0
var pode_mover = true
var state: PlayerState = PlayerState.IDLE
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var has_jumped = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D

var sfx_hurt: AudioStreamPlayer2D

func _ready() -> void:
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.3, Color(1, 1, 1, 0.3))
	gradient.add_point(0.6, Color(1, 1, 1, 0.05))
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0)
	tex.width = 128
	tex.height = 128
	light.texture = tex
	light.color = Color(0.8, 0.9, 1.0) # Luz levemente azulada/mágica
	light.energy = 0.5
	light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(light)

	# Sons gerados via código reutilizando os assets do projeto
	sfx_hurt = AudioStreamPlayer2D.new()
	sfx_hurt.stream = preload("res://sound/hurt.ogg")
	sfx_hurt.volume_db = -5.0
	sfx_hurt.bus = "SFX"
	add_child(sfx_hurt)

func _physics_process(delta: float) -> void:
	if global_position.y > FALL_LIMIT_Y:
		if state != PlayerState.DEAD:
			GameManager.vidas = 0
			vida_alterada.emit(GameManager.vidas)
			morrer()
		return
		
	if Input.is_action_just_pressed("reset_level"):
		GameManager.vidas = 3
		GameManager.registrar_morte()
		await get_tree().create_timer(0.40).timeout
		get_tree().reload_current_scene()
		return

	if Input.is_action_just_pressed("petrify"):
		if state == PlayerState.SIT:
			stand_up()
		else:
			criar_estatua()
		return
		
	# Sai do banco se apertar pulo ou se mover
	if state == PlayerState.SIT:
		if Input.is_action_just_pressed("jump") or Input.get_axis("move_left", "move_right") != 0:
			stand_up()
		return
		
	if not pode_mover and state != PlayerState.HURT:
		return

	if state == PlayerState.HURT:
		if not is_on_floor():
			var grav = get_gravity()
			# Removido multiplicador de queda pesada (grav *= 1.5) para manter consistência
			velocity += grav * delta
		move_and_slide()
		return

	# Atualiza timers de movimento
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		has_jumped = false
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# Processa o pulo ANTES de move_and_slide() e da gravidade.
	# Isso corrige o bug do "pulo duplo no ar" garantindo que is_on_floor() 
	# seja atualizado corretamente no próximo frame.
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not has_jumped:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		has_jumped = true

	# Aplica gravidade
	if not is_on_floor():
		var grav = get_gravity()
		# Mantém a gravidade menor no ápice do pulo se segurar o botão (sensação de controle)
		if abs(velocity.y) < 60.0 and Input.is_action_pressed("jump"):
			grav *= 0.8
		# Removido multiplicador de queda pesada (grav *= 1.5) para queda mais natural
		velocity += grav * delta

	var direction := Input.get_axis("move_left", "move_right")
	
	# Sobrescreve a direção com o joystick virtual, caso esteja em uso
	var virtual_joystick = get_tree().get_first_node_in_group("virtual_joystick")
	if virtual_joystick and virtual_joystick.is_visible_in_tree() and virtual_joystick.output != 0.0:
		direction = virtual_joystick.output

	update_flip(direction)
	update_horizontal_movement(direction, delta)
	
	# Só aplica snap ao chão se não estiver subindo (pulando)
	# para evitar ser puxado de volta ao chão imediatamente
	if direction != 0 and velocity.y >= 0:
		apply_floor_snap()

	move_and_slide()
	
	update_state(direction)
	update_animation()


func take_damage(knockback_force: Vector2) -> void:
	if state == PlayerState.DEAD or state == PlayerState.HURT or state == PlayerState.PETRIFY:
		return
		
	state = PlayerState.HURT
	pode_mover = false
	velocity = knockback_force
	
	GameManager.vidas -= 1
	vida_alterada.emit(GameManager.vidas)
	sfx_hurt.play()
	
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(self, "modulate:a", 0.2, 0.05)
		tween.tween_property(self, "modulate:a", 1.0, 0.05)
	
	await get_tree().create_timer(0.35).timeout
	
	if GameManager.vidas <= 0:
		morrer()
	else:
		state = PlayerState.IDLE
		pode_mover = true


func bounce() -> void:
	velocity.y = JUMP_VELOCITY * 0.8
	state = PlayerState.JUMP
	pode_mover = true
	has_jumped = true


func morrer() -> void:
	if state == PlayerState.DEAD:
		return

	pode_mover = false
	velocity = Vector2.ZERO
	state = PlayerState.DEAD
	
	# Se acabaram as vidas, faz um efeito do player sumindo
	if GameManager.vidas <= 0:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		await tween.finished
		
	morreu.emit()


func criar_estatua() -> void:
	if estatuas_criadas >= MAX_ESTATUAS:
		print("Limite de estátuas atingido!")
		return
		
	pode_mover = false
	velocity = Vector2.ZERO
	state = PlayerState.PETRIFY
	
	# --- Efeitos Mágicos e Partículas (Visual Melhorado) ---
	var flash_light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.4, Color(1, 1, 1, 0.4))
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	# Previne o aspecto quadrado garantindo que o gradiente pare antes da borda
	tex.fill_to = Vector2(0.8, 0.8)
	tex.width = 160
	tex.height = 160
	flash_light.texture = tex
	flash_light.color = Color(0.9, 0.4, 0.7) # Rosa/Magenta mágico
	flash_light.energy = 0.0
	flash_light.blend_mode = Light2D.BLEND_MODE_ADD
	get_parent().add_child(flash_light)
	flash_light.global_position = global_position
	
	var light_tween = create_tween()
	light_tween.tween_property(flash_light, "energy", 1.0, 0.15)
	light_tween.tween_property(flash_light, "energy", 0.0, 0.6)
	light_tween.tween_callback(flash_light.queue_free)

	# ------------------------------------
	
	anim.play("petrify")
	sfx.play()
	await anim.animation_finished

	var estatua = cena_estatua.instantiate()
	estatua.global_position = global_position
	estatua.get_node("Estatua").flip_h = anim.flip_h
	get_parent().add_child(estatua)

	estatuas_criadas += 1
	estatua_criada.emit(estatuas_criadas)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.08)
	await tween.finished

	if anim.flip_h:
		global_position = estatua.global_position + Vector2(20, -2)
	else:
		global_position = estatua.global_position + Vector2(-20, -2)

	velocity = Vector2.ZERO
	anim.play("idle")
	modulate.a = 0.0

	var tween2 = create_tween()
	tween2.tween_property(self, "modulate:a", 1.0, 0.12)
	await tween2.finished

	pode_mover = true
	state = PlayerState.IDLE


func update_flip(direction: float) -> void:
	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true


func update_horizontal_movement(direction: float, delta: float) -> void:
	var effective_speed = SPEED
	if get_tree().current_scene and get_tree().current_scene.name == "insideTent":
		effective_speed = SPEED * 0.8 # Caminha a 40% da velocidade normal na tenda

	if DisplayServer.is_touchscreen_available():
		# --- MOBILE: Movimentação Arcade Instantânea ---
		# O dedo do jogador (que arrasta no joystick) dita a velocidade perfeitamente
		if direction != 0:
			velocity.x = direction * effective_speed
		else:
			# Pequena desaceleração rápida ao invés de frear a seco em 1 frame
			velocity.x = move_toward(velocity.x, 0, FRICTION * 1.5 * delta)
	else:
		# --- DESKTOP: Movimentação com Inércia e Aceleração ---
		if direction != 0:
			var target_speed = direction * effective_speed
			var current_accel = ACCELERATION
			
			# Melhoria de responsividade 
			if sign(direction) != sign(velocity.x) and velocity.x != 0:
				current_accel = ACCELERATION * 3.0 # Turnaround rápido
			elif abs(velocity.x) < 15.0:
				current_accel = ACCELERATION * 3.5 # Arranque forte
				
			velocity.x = move_toward(
				velocity.x,
				target_speed,
				current_accel * delta
			)
		else:
			velocity.x = move_toward(
				velocity.x,
				0,
				FRICTION * delta
			)


func update_state(direction: float) -> void:
	if state == PlayerState.DEAD or state == PlayerState.PETRIFY or state == PlayerState.HURT or state == PlayerState.SIT:
		return

	# A lógica de impulso do pulo agora ocorre em _physics_process
	if not is_on_floor():
		state = PlayerState.JUMP
		return

	if direction != 0:
		state = PlayerState.WALK
	else:
		state = PlayerState.IDLE


func update_animation() -> void:
	match state:
		PlayerState.IDLE:
			if anim.animation != "idle":
				anim.play("idle")
		PlayerState.WALK:
			if anim.animation != "walk":
				anim.play("walk")
		PlayerState.JUMP:
			if anim.animation != "jump":
				anim.play("jump")
			
			anim.pause()
			if velocity.y < 0:
				anim.frame = 0
			else:
				anim.frame = 1
		PlayerState.PETRIFY:
			if anim.animation != "petrify":
				anim.play("petrify")
		PlayerState.SIT:
			if anim.animation != "sit":
				if anim.sprite_frames.has_animation("sit"):
					anim.play("sit")
				else:
					anim.play("idle")
					anim.pause()
		PlayerState.DEAD:
			pass

func sit_on_bench(bench_pos: Vector2) -> void:
	pode_mover = false
	velocity = Vector2.ZERO
	state = PlayerState.SIT
	
	# Centraliza no banco (ajustando o Y se precisar)
	global_position.x = bench_pos.x + 1
	global_position.y = bench_pos.y - 11
	
	update_animation()

func stand_up() -> void:
	state = PlayerState.IDLE
	pode_mover = true
	anim.play("idle")
