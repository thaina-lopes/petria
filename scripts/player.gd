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
	HURT
}

const SPEED = 100.0
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
		criar_estatua()
		return
		
	if not pode_mover and state != PlayerState.HURT:
		return

	if state == PlayerState.HURT:
		if not is_on_floor():
			var grav = get_gravity()
			if velocity.y > 0.0:
				grav *= 1.5
			velocity += grav * delta
		move_and_slide()
		return

	if is_on_floor():
		coyote_timer = COYOTE_TIME
		has_jumped = false
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	if not is_on_floor():
		var grav = get_gravity()
		if abs(velocity.y) < 60.0 and Input.is_action_pressed("jump"):
			grav *= 0.5
		elif velocity.y > 0.0:
			grav *= 1.5
		velocity += grav * delta

	var direction := Input.get_axis("move_left", "move_right")
	update_flip(direction)
	update_horizontal_movement(direction)
	if direction != 0:
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


func update_horizontal_movement(direction: float) -> void:
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func update_state(direction: float) -> void:
	if state == PlayerState.DEAD or state == PlayerState.PETRIFY or state == PlayerState.HURT:
		return

	if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not has_jumped:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		has_jumped = true
		state = PlayerState.JUMP
		return

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
		PlayerState.PETRIFY:
			if anim.animation != "petrify":
				anim.play("petrify")
		PlayerState.DEAD:
			pass
