extends CharacterBody2D

signal estatua_criada
signal morreu

const SPEED = 80.0
const JUMP_VELOCITY = -260.0
const MAX_ESTATUAS = 2

var cena_estatua = preload("res://scenes/statue.tscn")
var estatuas_criadas = 0
var pode_mover = true

@onready var anim = $AnimatedSprite2D
@onready var sfx = $AudioStreamPlayer2D

	
func morrer():
	if not pode_mover:
		return

	pode_mover = false
	velocity = Vector2.ZERO
	morreu.emit()

func _physics_process(delta: float) -> void:
	if global_position.y > 320:
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

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	
	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# ANIMAÇÕES
	if not is_on_floor():
		if anim.animation != "jump":
			anim.play("jump")
	else:
		if direction != 0:
			if anim.animation != "walk":
				anim.play("walk")
		else:
			if anim.animation != "idle":
				anim.play("idle")

	move_and_slide()

func criar_estatua():
	if estatuas_criadas >= MAX_ESTATUAS:
		print("Limite de estátuas atingido!")
		return
		
	pode_mover = false
	velocity = Vector2.ZERO
	
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

	var offset_x := 20.0
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
