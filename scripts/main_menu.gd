extends Control

@onready var click_sound: AudioStreamPlayer = $ClickSound

var iniciando_jogo := false

func _ready() -> void:
	$TransitionLayer/FadeRect.color.a = 1.0
	$TransitionLayer/AnimationPlayer.play("fade_in")

	$Music.volume_db = -100
	$Music.play()
	fade_in_musica()
	
	$StartButton.grab_focus()

func _on_start_button_pressed() -> void:
	if iniciando_jogo:
		return

	iniciando_jogo = true
	$StartButton.disabled = true

	$ClickSound.play()
	$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")

func fade_in_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -35.0, 1.0)

func fade_out_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -100.0, 0.5)
