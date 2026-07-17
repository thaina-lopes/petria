extends Node2D

var transitioning := false
var player_in_range := false
var current_player: Node2D = null

func _ready() -> void:
	if has_node("TransitionLayer/FadeRect"):
		$TransitionLayer/FadeRect.color.a = 1.0
	if has_node("TransitionLayer/AnimationPlayer"):
		$TransitionLayer/AnimationPlayer.play("fade_in")
		
	if has_node("Music"):
		$Music.volume_db = -80
		$Music.play()
		fade_in_musica()
		
	if has_node("Area2D"):
		var area = get_node("Area2D")
		if not area.body_entered.is_connected(_on_tent_body_entered):
			area.body_entered.connect(_on_tent_body_entered)
		if not area.body_exited.is_connected(_on_tent_body_exited):
			area.body_exited.connect(_on_tent_body_exited)
			
		# Procura um Label na Area2D e oculta no início
		for child in area.get_children():
			if child is Label:
				child.visible = false
				
				# Aplica um material unshaded para garantir que não fique escuro
				var mat = CanvasItemMaterial.new()
				mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
				child.material = mat
				
		# Cria um StaticBody2D para bloquear o jogador como uma parede
		var collision_shape = null
		for child in area.get_children():
			if child is CollisionShape2D:
				collision_shape = child
				break
				
		if collision_shape:
			var static_body = StaticBody2D.new()
			var new_collision = CollisionShape2D.new()
			new_collision.shape = collision_shape.shape
			
			# Faz o bloqueio um pouco menor na largura para o player entrar na área,
			# e bem mais alto para evitar que pule por cima
			if new_collision.shape is RectangleShape2D:
				var dup_shape = new_collision.shape.duplicate()
				dup_shape.size.x *= 0.5 
				dup_shape.size.y += 600.0 # Aumenta a altura consideravelmente
				new_collision.shape = dup_shape
			elif new_collision.shape is CircleShape2D:
				var dup_shape = new_collision.shape.duplicate()
				dup_shape.radius *= 0.5
				new_collision.shape = dup_shape
				
			static_body.add_child(new_collision)
			static_body.position = collision_shape.position
			area.call_deferred("add_sibling", static_body)

func _input(event: InputEvent) -> void:
	if player_in_range and not transitioning and event is InputEventKey:
		if event.pressed and event.keycode == KEY_Q:
			enter_tent()

func _on_tent_body_entered(body: Node2D) -> void:
	if transitioning:
		return
		
	if body.name == "Player":
		player_in_range = true
		current_player = body
		var area = get_node_or_null("Area2D")
		if area:
			for child in area.get_children():
				if child is Label:
					child.visible = true

func _on_tent_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		if current_player == body:
			current_player = null
		var area = get_node_or_null("Area2D")
		if area:
			for child in area.get_children():
				if child is Label:
					child.visible = false

func enter_tent() -> void:
	if transitioning or not current_player:
		return
		
	transitioning = true
	
	# Trava o jogador para ele não se mover mais
	current_player.pode_mover = false
	current_player.velocity = Vector2.ZERO
	
	# Oculta o label ao entrar
	var area = get_node_or_null("Area2D")
	if area:
		for child in area.get_children():
			if child is Label:
				child.visible = false
	
	# Pega a posição central da porta da tenda
	var door_x = current_player.global_position.x
	if area and area.has_node("CollisionShape2D"):
		door_x = area.get_node("CollisionShape2D").global_position.x
		
	# Ajusta a animação para "andando" e vira o personagem para a direção certa
	if current_player.has_node("AnimatedSprite2D"):
		var anim = current_player.get_node("AnimatedSprite2D")
		anim.play("walk")
		if door_x > current_player.global_position.x:
			anim.flip_h = false
		elif door_x < current_player.global_position.x:
			anim.flip_h = true
		
	# Cria um tween para dar a ilusão de que o Player está entrando (indo para o fundo)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(current_player, "global_position:x", door_x, 0.5)
	tween.tween_property(current_player, "modulate", Color(0, 0, 0, 0), 0.5)
	
	# Espera um pouco da animação acontecer antes de começar o fade real da tela
	await get_tree().create_timer(0.3).timeout
	
	if has_node("TransitionLayer/AnimationPlayer"):
		$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	if has_node("TransitionLayer/AnimationPlayer"):
		await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/cutscene.tscn")

func fade_in_musica() -> void:
	if not has_node("Music"): return
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -25.0, 1.0)

func fade_out_musica() -> void:
	if not has_node("Music"): return
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -80.0, 0.5)
