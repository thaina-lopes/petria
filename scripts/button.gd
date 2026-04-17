extends Area2D

signal pressionado
signal solto

var ativo := false
var sprite_y_inicial := 0.0

@onready var anim = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer = $PlatformSound

func _ready() -> void:
	sprite_y_inicial = anim.position.y
	anim.play("idle")

func _physics_process(_delta: float) -> void:
	var esta_pressionado := false

	for body in get_overlapping_bodies():
		if corpo_valido(body):
			esta_pressionado = true
			break

	if esta_pressionado and not ativo:
		ativo = true
		anim.position.y = sprite_y_inicial + 2
		
		sfx.play()
		
		emit_signal("pressionado")
		
	elif not esta_pressionado and ativo:
		ativo = false
		anim.position.y = sprite_y_inicial
		emit_signal("solto")

func corpo_valido(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("statues")
