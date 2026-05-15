extends Node2D

var total_estatuas := 2
var estatuas_usadas := 0

var total_fragmentos := 0
var coletados := 0

var fase_finalizada := false

func _ready() -> void:
	total_fragmentos = $Fragments.get_child_count()

	for fragment in $Fragments.get_children():
		fragment.coletado.connect(_on_fragmento_coletado)

	$Player.estatua_criada.connect(_on_estatua_criada)
	$Player.morreu.connect(_on_player_morreu)
	
	$Button.pressionado.connect(_on_button_pressionado)
	$Button.solto.connect(_on_button_solto)

	atualizar_hud()

	$TransitionLayer/FadeRect.color.a = 1.0
	$TransitionLayer/AnimationPlayer.play("fade_in")

	$Music.volume_db = -80
	$Music.play()
	fade_in_musica()

func _on_estatua_criada(qtd) -> void:
	estatuas_usadas = qtd
	atualizar_hud()

func _on_fragmento_coletado() -> void:
	if fase_finalizada:
		return

	coletados += 1
	atualizar_hud()

	if coletados >= total_fragmentos:
		fase_finalizada = true
		finalizar_fase()

func _on_player_morreu() -> void:
	if fase_finalizada:
		return
		
	GameManager.registrar_morte()

	$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().reload_current_scene()
	
func _on_button_pressionado() -> void:
	$MagicPlatform.ativar()

func _on_button_solto() -> void:
	$MagicPlatform.desativar()

func atualizar_hud() -> void:
	$CanvasLayer/HUD/FragmentsLabel.text = "Fragmentos: %d/%d" % [coletados, total_fragmentos]
	$CanvasLayer/HUD/EstatuesLabel.text = "Estátuas: %d/%d" % [estatuas_usadas, total_estatuas]

func finalizar_fase() -> void:
	$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/level_5.tscn")

func fade_in_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -25.0, 1.0)

func fade_out_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -80.0, 0.5)
