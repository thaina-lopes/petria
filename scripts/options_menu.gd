extends CanvasLayer

const CONFIG_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var music_bus_index: int
var sfx_bus_index: int

@onready var color_rect = $ColorRect
@onready var panel = $PanelContainer
@onready var music_checkbox = $PanelContainer/MarginContainer/VBoxContainer/MusicCheckBox
@onready var sfx_checkbox = $PanelContainer/MarginContainer/VBoxContainer/SFXCheckBox
@onready var close_button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	close_button.pressed.connect(hide_menu)
	music_checkbox.toggled.connect(_on_music_toggled)
	sfx_checkbox.toggled.connect(_on_sfx_toggled)
	
	load_settings()
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and event.is_pressed() and not event.is_echo():
		if visible:
			hide_menu()
		else:
			show_menu()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	visible = true
	get_tree().paused = true
	# Garante que o menu bloqueie cliques em itens abaixo
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	music_checkbox.grab_focus()

func hide_menu() -> void:
	visible = false
	get_tree().paused = false
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_music_toggled(button_pressed: bool) -> void:
	# button_pressed = true significa "Desativar música"
	AudioServer.set_bus_mute(music_bus_index, button_pressed)
	save_settings()

func _on_sfx_toggled(button_pressed: bool) -> void:
	# button_pressed = true significa "Desativar efeitos"
	AudioServer.set_bus_mute(sfx_bus_index, button_pressed)
	save_settings()

func save_settings() -> void:
	config.set_value("audio", "music_disabled", music_checkbox.button_pressed)
	config.set_value("audio", "sfx_disabled", sfx_checkbox.button_pressed)
	config.save(CONFIG_PATH)

func load_settings() -> void:
	var err = config.load(CONFIG_PATH)
	if err == OK:
		var music_disabled = config.get_value("audio", "music_disabled", false)
		var sfx_disabled = config.get_value("audio", "sfx_disabled", false)
		
		music_checkbox.button_pressed = music_disabled
		sfx_checkbox.button_pressed = sfx_disabled
		
		AudioServer.set_bus_mute(music_bus_index, music_disabled)
		AudioServer.set_bus_mute(sfx_bus_index, sfx_disabled)
