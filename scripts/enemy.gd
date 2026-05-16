extends CharacterBody2D

enum EnemyState { IDLE, PATROL, CHASE, ATTACK }

const PATROL_SPEED    := 40.0
const CHASE_SPEED     := 75.0
const DETECTION_RANGE := 110.0
const ATTACK_RANGE    := 18.0
const PATROL_DISTANCE := 64.0
const CHASE_TIMEOUT   := 4.0

var state: EnemyState = EnemyState.IDLE
var patrol_direction: int = 1
var patrol_start_x: float = 0.0
var patrol_timer: float = 0.0
var patrol_wait: float = 2.0
var attack_timer: float = 0.0
var chase_timer: float = 0.0
var player: CharacterBody2D = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea


func _ready() -> void:
	patrol_start_x = global_position.x
	patrol_wait = randf_range(1.5, 3.0)

	# Enemy body on layer 2 so it doesn't physically block the player,
	# mask 1 so it still stands on world tiles (layer 1).
	collision_layer = 2
	collision_mask = 1

	$DamageArea.collision_layer = 0
	$DamageArea.collision_mask = 1

	_setup_sprite_frames()
	anim.play("idle")

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	damage_area.body_entered.connect(_on_body_entered)


# ---------------------------------------------------------------------------
# Physics
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if global_position.y > 340.0:
		queue_free()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	_update_ai(delta)
	move_and_slide()
	_update_animation()


# ---------------------------------------------------------------------------
# AI
# ---------------------------------------------------------------------------

func _update_ai(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	var dist: float = global_position.distance_to(player.global_position)

	match state:
		EnemyState.IDLE:
			velocity.x = 0.0
			patrol_timer += delta
			if patrol_timer >= patrol_wait:
				patrol_timer = 0.0
				patrol_wait = randf_range(1.5, 3.0)
				patrol_start_x = global_position.x
				state = EnemyState.PATROL
			if dist < DETECTION_RANGE:
				chase_timer = 0.0
				state = EnemyState.CHASE

		EnemyState.PATROL:
			velocity.x = patrol_direction * PATROL_SPEED
			if abs(global_position.x - patrol_start_x) >= PATROL_DISTANCE:
				patrol_direction *= -1
				state = EnemyState.IDLE
				patrol_timer = 0.0
			if dist < DETECTION_RANGE:
				chase_timer = 0.0
				state = EnemyState.CHASE

		EnemyState.CHASE:
			chase_timer += delta
			if chase_timer >= CHASE_TIMEOUT:
				_return_to_patrol()
				return
			if dist <= ATTACK_RANGE:
				state = EnemyState.ATTACK
				attack_timer = 0.0
				anim.play("attack")
				return
			velocity.x = sign(player.global_position.x - global_position.x) * CHASE_SPEED

		EnemyState.ATTACK:
			velocity.x = 0.0
			attack_timer += delta
			if attack_timer >= 0.7:
				state = EnemyState.CHASE


func _return_to_patrol() -> void:
	chase_timer = 0.0
	patrol_start_x = global_position.x
	patrol_timer = 0.0
	patrol_wait = randf_range(1.5, 3.0)
	state = EnemyState.PATROL


# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------

func _update_animation() -> void:
	match state:
		EnemyState.IDLE:
			if anim.animation != "idle":
				anim.play("idle")
		EnemyState.PATROL:
			if anim.animation != "walk":
				anim.play("walk")
			anim.flip_h = velocity.x < 0.0
		EnemyState.CHASE:
			if anim.animation != "walk":
				anim.play("walk")
			anim.flip_h = player != null and player.global_position.x < global_position.x
		EnemyState.ATTACK:
			if anim.animation != "attack":
				anim.play("attack")


# ---------------------------------------------------------------------------
# Damage
# ---------------------------------------------------------------------------

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("morrer"):
		body.morrer()


# ---------------------------------------------------------------------------
# Sprite generation (simple pixel art, no external assets needed)
# ---------------------------------------------------------------------------

func _setup_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 3.0)

	frames.add_animation(&"walk")
	frames.set_animation_loop(&"walk", true)
	frames.set_animation_speed(&"walk", 7.0)

	frames.add_animation(&"attack")
	frames.set_animation_loop(&"attack", false)
	frames.set_animation_speed(&"attack", 6.0)

	for i in 2:
		frames.add_frame(&"idle", _make_idle_frame(i))
	for i in 4:
		frames.add_frame(&"walk", _make_walk_frame(i))
	for i in 3:
		frames.add_frame(&"attack", _make_attack_frame(i))

	anim.sprite_frames = frames


func _make_idle_frame(f: int) -> ImageTexture:
	# 16x24 canvas, body bobs 1px between frames
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dy := 0 if f == 0 else 1
	var body   := Color(0.50, 0.10, 0.12)
	var eyes   := Color(1.00, 0.90, 0.00)
	var dark   := Color(0.28, 0.04, 0.06)
	# shadow outline
	img.fill_rect(Rect2i(1, dy,      14, 9),  dark)
	img.fill_rect(Rect2i(2, 9 + dy,  12, 9),  dark)
	# head
	img.fill_rect(Rect2i(2, dy,      12, 8),  body)
	# body
	img.fill_rect(Rect2i(3, 8 + dy,  10, 8),  body)
	# eyes
	img.fill_rect(Rect2i(4, 2 + dy,   2, 2),  eyes)
	img.fill_rect(Rect2i(10, 2 + dy,  2, 2),  eyes)
	# legs (stay at fixed y so they touch the ground)
	img.fill_rect(Rect2i(3, 16,  3, 7), body)
	img.fill_rect(Rect2i(10, 16, 3, 7), body)
	return ImageTexture.create_from_image(img)


func _make_walk_frame(f: int) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var dy   := 0 if f % 2 == 0 else 1
	var body := Color(0.50, 0.10, 0.12)
	var eyes := Color(1.00, 0.90, 0.00)
	var dark := Color(0.28, 0.04, 0.06)
	img.fill_rect(Rect2i(1, dy,      14, 9), dark)
	img.fill_rect(Rect2i(2, 9 + dy,  12, 9), dark)
	img.fill_rect(Rect2i(2, dy,      12, 8), body)
	img.fill_rect(Rect2i(3, 8 + dy,  10, 8), body)
	img.fill_rect(Rect2i(4, 2 + dy,   2, 2), eyes)
	img.fill_rect(Rect2i(10, 2 + dy,  2, 2), eyes)
	# alternating leg positions
	match f:
		0:
			img.fill_rect(Rect2i(3, 16,  3, 7), body)
			img.fill_rect(Rect2i(10, 17, 3, 6), body)
		1:
			img.fill_rect(Rect2i(3, 17,  3, 6), body)
			img.fill_rect(Rect2i(10, 16, 3, 7), body)
		2:
			img.fill_rect(Rect2i(3, 16,  3, 7), body)
			img.fill_rect(Rect2i(10, 18, 3, 5), body)
		3:
			img.fill_rect(Rect2i(3, 18,  3, 5), body)
			img.fill_rect(Rect2i(10, 16, 3, 7), body)
	return ImageTexture.create_from_image(img)


func _make_attack_frame(f: int) -> ImageTexture:
	var img  := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var body := Color(0.80, 0.12, 0.12)  # brighter red on attack
	var eyes := Color(1.00, 0.10, 0.10)  # red eyes
	var dark := Color(0.40, 0.04, 0.04)
	match f:
		0:  # wind-up: lean slightly back
			img.fill_rect(Rect2i(2, 1,   12, 9), dark)
			img.fill_rect(Rect2i(2, 10,  12, 7), dark)
			img.fill_rect(Rect2i(3, 1,   10, 8), body)
			img.fill_rect(Rect2i(3, 9,   10, 7), body)
			img.fill_rect(Rect2i(5, 3,    2, 2), eyes)
			img.fill_rect(Rect2i(10, 3,   2, 2), eyes)
			img.fill_rect(Rect2i(3, 16,   3, 7), body)
			img.fill_rect(Rect2i(10, 16,  3, 7), body)
		1:  # lunge: shift body forward (right)
			img.fill_rect(Rect2i(3, 0,   13, 9), dark)
			img.fill_rect(Rect2i(3, 9,   12, 7), dark)
			img.fill_rect(Rect2i(4, 0,   11, 8), body)
			img.fill_rect(Rect2i(4, 8,   10, 7), body)
			img.fill_rect(Rect2i(6, 2,    2, 2), eyes)
			img.fill_rect(Rect2i(11, 2,   2, 2), eyes)
			# claw/arm extended
			img.fill_rect(Rect2i(13, 4,   3, 3), body)
			img.fill_rect(Rect2i(4, 15,   3, 8), body)
			img.fill_rect(Rect2i(10, 15,  3, 8), body)
		2:  # recover
			img.fill_rect(Rect2i(1, 1,   14, 9), dark)
			img.fill_rect(Rect2i(2, 10,  12, 7), dark)
			img.fill_rect(Rect2i(2, 1,   12, 8), body)
			img.fill_rect(Rect2i(3, 9,   10, 7), body)
			img.fill_rect(Rect2i(4, 3,    2, 2), eyes)
			img.fill_rect(Rect2i(10, 3,   2, 2), eyes)
			img.fill_rect(Rect2i(3, 16,   3, 7), body)
			img.fill_rect(Rect2i(10, 16,  3, 7), body)
	return ImageTexture.create_from_image(img)
