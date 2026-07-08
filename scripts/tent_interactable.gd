extends Area2D

var label: Label
var player_in_range := false

func _ready() -> void:
	# 1. Configura os sinais para detectar o player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 2. Cria um corpo físico para bloquear o player automaticamente
	var collision_shape = null
	for child in get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
			
	if collision_shape:
		var static_body = StaticBody2D.new()
		var new_collision = CollisionShape2D.new()
		new_collision.shape = collision_shape.shape
		
		# Faz o bloqueio físico um pouquinho menor que a área, 
		# assim o player consegue "entrar" na área de interação antes de bater na parede
		if new_collision.shape is RectangleShape2D:
			var dup_shape = new_collision.shape.duplicate()
			dup_shape.size *= 0.8 
			new_collision.shape = dup_shape
		elif new_collision.shape is CircleShape2D:
			var dup_shape = new_collision.shape.duplicate()
			dup_shape.radius *= 0.8
			new_collision.shape = dup_shape
			
		static_body.add_child(new_collision)
		static_body.position = collision_shape.position
		call_deferred("add_sibling", static_body)
		
	# 3. Procura o Label filho na cena
	for child in get_children():
		if child is Label:
			label = child
			break
			
	if label:
		label.visible = false # Esconde no início
	else:
		print("Nenhum Label encontrado no Area2D!")

func _input(event: InputEvent) -> void:
	# Verifica se o player está na área e apertou a tecla Q
	if player_in_range and event is InputEventKey:
		if event.pressed and event.keycode == KEY_Q:
			interact()

func interact() -> void:
	print("Interagiu com o objeto na tenda!")
	# Aqui você pode colocar a lógica que quiser (abrir diálogo, etc)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = true
		if label:
			label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_in_range = false
		if label:
			label.visible = false
