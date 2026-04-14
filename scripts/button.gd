extends Area2D

var ativo := false
var sprite_y_inicial := 0.0

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	sprite_y_inicial = anim.position.y
	anim.play("idle")

func _physics_process(_delta: float) -> void:
	var pressionado := false

	for body in get_overlapping_bodies():
		if corpo_valido(body):
			pressionado = true
			break

	if pressionado and not ativo:
		ativo = true
		anim.position.y = sprite_y_inicial + 3
	elif not pressionado and ativo:
		ativo = false
		anim.position.y = sprite_y_inicial

func corpo_valido(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("statues")
