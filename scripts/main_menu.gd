extends Control

@onready var click_sound: AudioStreamPlayer = $ClickSound

var iniciando_jogo := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	$TransitionLayer/FadeRect.color.a = 1.0
	$TransitionLayer/AnimationPlayer.play("fade_in")

	$Music.volume_db = -100
	$Music.play()
	fade_in_musica()
	
	$StartButton.grab_focus()
	
	OptionsMenu.visibility_changed.connect(func(): $SettingsButton.button_pressed = OptionsMenu.visible)

func _input(event: InputEvent) -> void:
	if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo():
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			return
		if not OptionsMenu.visible:
			_on_start_button_pressed()

func _on_start_button_pressed() -> void:
	if iniciando_jogo:
		return

	GameManager.iniciar_jogo()
	iniciando_jogo = true
	$StartButton.disabled = true

	$ClickSound.play()
	$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/history.tscn")

func fade_in_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -30.0, 1.0)

func fade_out_musica() -> void:
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -100.0, 0.5)

func _on_settings_button_pressed() -> void:
	if OptionsMenu.visible:
		OptionsMenu.hide_menu()
	else:
		OptionsMenu.show_menu()
