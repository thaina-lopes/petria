extends Node2D

var transitioning := false

func _ready() -> void:
	if has_node("TransitionLayer/FadeRect"):
		$TransitionLayer/FadeRect.color.a = 1.0
	if has_node("TransitionLayer/AnimationPlayer"):
		$TransitionLayer/AnimationPlayer.play("fade_in")
		
	if has_node("Music"):
		$Music.volume_db = -80
		$Music.play()
		fade_in_musica()
		
	if has_node("Tent/Area2D"):
		var area = get_node("Tent/Area2D")
		if not area.body_entered.is_connected(_on_tent_body_entered):
			area.body_entered.connect(_on_tent_body_entered)

func _on_tent_body_entered(body: Node2D) -> void:
	if transitioning:
		return
		
	if body.name == "Player":
		transitioning = true
		
		# Trava o jogador para ele não se mover mais
		body.pode_mover = false
		body.velocity = Vector2.ZERO
		
		# Pega a posição central da porta da tenda
		var door_x = get_node("Tent/Area2D/CollisionShape2D").global_position.x
		
		# Cria um tween para dar a ilusão de que o Player está entrando (indo para o fundo)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(body, "global_position:x", door_x, 0.5)
		tween.tween_property(body, "modulate", Color(0, 0, 0, 0), 0.5)
		
		# Espera um pouco da animação acontecer antes de começar o fade real da tela
		await get_tree().create_timer(0.3).timeout
		
		if has_node("TransitionLayer/AnimationPlayer"):
			$TransitionLayer/AnimationPlayer.play("fade_out")
		fade_out_musica()

		if has_node("TransitionLayer/AnimationPlayer"):
			await $TransitionLayer/AnimationPlayer.animation_finished
		get_tree().change_scene_to_file("res://scenes/inside_tent.tscn")

func fade_in_musica() -> void:
	if not has_node("Music"): return
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -25.0, 1.0)

func fade_out_musica() -> void:
	if not has_node("Music"): return
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -80.0, 0.5)
