extends Control

@onready var rich_text_label = $RichTextLabel
@onready var animation_player = $TransitionLayer/AnimationPlayer
@onready var dialog_box = $TextureRect

var dialog_groups = [
	[
		"Os primeiros Fragmentos foram encontrados.",
		"Mas isso foi apenas o começo.",
		"O mundo permanece em silêncio."
	],
	[
		"Ainda existem lugares inalcançados.",
		"Memórias que já não podem ser lembradas.",
		"E verdades que não foram reveladas."
	],
	[
		"Há algo que ninguém mais parece notar.",
		"A cada Fragmento encontrado...",
		"...o silêncio parece diferente."
	],
	[
		"Continua..."
	]
]

var current_group_index = 0
var is_typing = true # começa true para bloquear input durante a introdução
var text_speed = 0.05
var arrow_label: Label

func _ready() -> void:
	arrow_label = Label.new()
	arrow_label.text = "▼"
	var font = rich_text_label.get_theme_font("normal_font")
	if font:
		arrow_label.add_theme_font_override("font", font)
	arrow_label.add_theme_font_size_override("font_size", 11)
	arrow_label.add_theme_color_override("font_color", Color("#3d2947"))
	add_child(arrow_label)
	# Posiciona no canto inferior direito da caixa de texto
	arrow_label.position = Vector2(rich_text_label.position.x + rich_text_label.size.x - 35, rich_text_label.position.y + rich_text_label.size.y - 16)
	arrow_label.hide()
	
	rich_text_label.text = ""
	
	# Esconde a caixa de diálogo inicialmente
	dialog_box.modulate.a = 0.0
	
	if has_node("TransitionLayer/FadeRect"):
		$TransitionLayer/FadeRect.color.a = 1.0
		$TransitionLayer/FadeRect.show()
	if animation_player:
		animation_player.play("fade_in")
		
	start_cinematic()

func start_cinematic() -> void:
	# Aguarda 1.5 segundos com apenas a imagem de fundo
	await get_tree().create_timer(1.5).timeout
	
	# Faz a caixa de diálogo surgir aos poucos (fade in)
	var tween = create_tween()
	tween.tween_property(dialog_box, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	# Libera para a primeira frase
	is_typing = false
	start_next_group()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"): # Espaço ou Enter
		if not is_typing and current_group_index < dialog_groups.size():
			arrow_label.hide()
			current_group_index += 1
			
			if current_group_index >= dialog_groups.size():
				finish_history()
			else:
				rich_text_label.text = "" # Limpa o texto
				
				start_next_group()

func start_next_group() -> void:
	if current_group_index >= dialog_groups.size(): return
	
	is_typing = true
	var group = dialog_groups[current_group_index]
	
	for phrase_index in range(group.size()):
		var phrase = group[phrase_index]
		
		if phrase_index > 0:
			rich_text_label.text += "\n"
		
		for i in range(phrase.length()):
			rich_text_label.text += phrase[i]
			await get_tree().create_timer(text_speed).timeout
		
		# Pequena pausa entre as linhas do mesmo grupo
		if phrase_index < group.size() - 1:
			await get_tree().create_timer(0.4).timeout
	
	arrow_label.show()
	is_typing = false

func finish_history() -> void:
	if animation_player:
		animation_player.play("fade_out")
		await animation_player.animation_finished
	# Vamos para a final_scene
	get_tree().change_scene_to_file("res://scenes/final_scene.tscn")
