extends Area2D

signal coletado

@onready var anim = $AnimatedSprite2D
@onready var sfx = $AudioStreamPlayer2D

func _ready() -> void:
	anim.play("idle")
	body_entered.connect(_on_body_entered)
	
	var light = PointLight2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	# Adiciona pontos intermediários para suavizar a borda da luz (menos dura)
	gradient.add_point(0.3, Color(1, 1, 1, 0.3))
	gradient.add_point(0.6, Color(1, 1, 1, 0.1))
	var tex = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0)
	tex.width = 100
	tex.height = 100
	light.texture = tex
	light.color = Color(0.4, 1.0, 0.6) # Verde/ciano mágico
	light.energy = 0.8
	light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(light)
	
	# Faz a luz pulsar suavemente
	var tween = create_tween().set_loops()
	tween.tween_property(light, "energy", 1.2, 1.0)
	tween.tween_property(light, "energy", 0.6, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		sfx.play()
		emit_signal("coletado")
		
		visible = false
		$CollisionShape2D.set_deferred("disabled", true)
		
		await sfx.finished
		queue_free()
