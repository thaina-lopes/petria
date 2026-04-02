extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -260.0
const MAX_ESTATUAS = 2

var cena_estatua = preload("res://scene/statue.tscn")
var estatuas_criadas = 0

var pode_mover = true

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("reset_level"):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed("petrify"):
		criar_estatua()
		
	if not pode_mover:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func criar_estatua():
	if estatuas_criadas >= MAX_ESTATUAS:
		print("Limite de estátuas atingido!")
		return
		
	pode_mover = false

	var estatua = cena_estatua.instantiate()
	estatua.global_position = global_position
	get_parent().add_child(estatua)

	estatuas_criadas += 1
	await get_tree().create_timer(0.2).timeout

	pode_mover = true
	print("Estátuas criadas: ", estatuas_criadas)
