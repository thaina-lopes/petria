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

	spawn_sparkles_on_decorations()
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


func spawn_sparkles_on_decorations() -> void:
	if not has_node("Tiles/Decoration"): return
	var dec = $Tiles/Decoration
	var ts = dec.tile_set
	if not ts: return
	
	var cogu_source_id = -1
	for i in range(ts.get_source_count()):
		var source_id = ts.get_source_id(i)
		var source = ts.get_source(source_id)
		if source is TileSetAtlasSource and source.texture and source.texture.resource_path.ends_with("cogu.png"):
			cogu_source_id = source_id
			break
			
	if cogu_source_id == -1: return
	
	var sparkle_scene = preload("res://scenes/magic_sparkles.tscn")
	for cell in dec.get_used_cells():
		if dec.get_cell_source_id(cell) == cogu_source_id:
			var sparkle = sparkle_scene.instantiate()
			sparkle.position = dec.map_to_local(cell)
			dec.add_child(sparkle)