extends CharacterBody2D

signal estatua_criada
signal morreu

enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	PETRIFY,
	DEAD
}

const SPEED = 80.0
const JUMP_VELOCITY = -260.0
const MAX_ESTATUAS = 2
const FALL_LIMIT_Y = 320.0

var cena_estatua = preload("res://scenes/statue.tscn")
var estatuas_criadas = 0
var pode_mover = true
var state: PlayerState = PlayerState.IDLE

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _physics_process(delta: float) -> void:
	if global_position.y > FALL_LIMIT_Y:
		morrer()
		return
		
	if Input.is_action_just_pressed("reset_level"):
		get_tree().reload_current_scene()
		return

	if Input.is_action_just_pressed("petrify"):
		criar_estatua()
		return
		
	if not pode_mover:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")
	update_flip(direction)
	update_horizontal_movement(direction)
	update_state(direction)
	update_animation()

	move_and_slide()


func morrer() -> void:
	if not pode_mover:
		return

	pode_mover = false
	velocity = Vector2.ZERO
	state = PlayerState.DEAD
	morreu.emit()


func criar_estatua() -> void:
	if estatuas_criadas >= MAX_ESTATUAS:
		print("Limite de estátuas atingido!")
		return
		
	pode_mover = false
	velocity = Vector2.ZERO
	state = PlayerState.PETRIFY
	
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
	if state == PlayerState.DEAD or state == PlayerState.PETRIFY:
		return

	if not is_on_floor():
		state = PlayerState.JUMP
		return

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
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
