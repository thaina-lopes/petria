extends Control

@onready var time_label = $TimeLabel
@onready var deaths_label = $DeathsLabel

var voltando_menu := false

func _ready() -> void:
	time_label.text = "Tempo: " + GameManager.formatar_tempo()
	deaths_label.text = "Tentativas: %d" % GameManager.mortes

	$TransitionLayer/FadeRect.color.a = 1.0
	$TransitionLayer/AnimationPlayer.play("fade_in")

	$Music.volume_db = -80
	$Music.play()
	fade_in_musica()

	$MenuButton.grab_focus()

func _on_menu_button_pressed() -> void:
	if voltando_menu:
		return

	voltando_menu = true
	$MenuButton.disabled = true

	$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func fade_in_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -25.0, 1.0)

func fade_out_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -80.0, 0.5)
