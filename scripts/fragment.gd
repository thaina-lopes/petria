extends Area2D

signal coletado

@onready var anim = $AnimatedSprite2D
@onready var sfx = $AudioStreamPlayer2D

func _ready() -> void:
	anim.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		sfx.play()
		emit_signal("coletado")
		
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		
		await sfx.finished
		queue_free()
