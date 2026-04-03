extends Area2D

signal player_entrou

var aberto := false

@onready var anim = $AnimatedSprite2D
@onready var particles = $GPUParticles2D
@onready var collision = $CollisionShape2D

func _ready() -> void:
	anim.play("closed")
	particles.emitting = false
	body_entered.connect(_on_body_entered)

func abrir_portal() -> void:
	if aberto:
		return

	aberto = true
	anim.play("opening")
	await anim.animation_finished
	anim.play("open")
	particles.emitting = true

func _on_body_entered(body: Node2D) -> void:
	if aberto and body.name == "Player":
		emit_signal("player_entrou")
