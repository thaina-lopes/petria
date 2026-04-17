extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $StaticBody2D/CollisionShape2D

var ativa := false

func _ready() -> void:
	collision.disabled = true
	anim.visible = false
	anim.play("materializar")
	anim.stop()
	anim.frame = 0

func ativar() -> void:
	anim.visible = true
	anim.speed_scale = 1.0
	anim.play("materializar")

func desativar() -> void:
	collision.disabled = true
	anim.speed_scale = -1.0
	anim.play("materializar")
	
func brilho_magico() -> void:
	var tween = create_tween()
	
	# brilho mágico mais azulado
	tween.tween_property(anim, "modulate", Color(1.1, 1.2, 1.4, 1), 0.08)
	tween.tween_property(anim, "modulate", Color(1, 1, 1, 1), 0.2)

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.speed_scale > 0:
		ativa = true
		collision.disabled = false
		
		brilho_magico()

func _process(_delta: float) -> void:
	if anim.speed_scale < 0 and anim.frame == 0:
		anim.stop()
		anim.visible = false
		ativa = false
		collision.disabled = true
		
