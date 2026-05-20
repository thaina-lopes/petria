extends Node2D

var total_estatuas := 2
var estatuas_usadas := 0

var total_fragmentos := 0
var coletados := 0

var fase_finalizada := false

func _ready() -> void:
	if has_node("Fragments"):
		total_fragmentos = $Fragments.get_child_count()

		for fragment in $Fragments.get_children():
			if fragment.has_signal("coletado"):
				fragment.coletado.connect(_on_fragmento_coletado)

	if has_node("Player"):
		$Player.estatua_criada.connect(_on_estatua_criada)
		$Player.morreu.connect(_on_player_morreu)
		if $Player.has_signal("vida_alterada"):
			$Player.vida_alterada.connect(_on_vida_alterada)

	atualizar_hud()

	if has_node("TransitionLayer/FadeRect"):
		$TransitionLayer/FadeRect.color.a = 1.0
	if has_node("TransitionLayer/AnimationPlayer"):
		$TransitionLayer/AnimationPlayer.play("fade_in")

	if has_node("Music"):
		$Music.volume_db = -80
		$Music.play()
		fade_in_musica()

	spawn_sparkles_on_decorations()

func _on_estatua_criada(qtd) -> void:
	estatuas_usadas = qtd
	atualizar_hud()

func _on_vida_alterada(qtd) -> void:
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
	
	if has_node("TransitionLayer/AnimationPlayer"):
		$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	if has_node("TransitionLayer/AnimationPlayer"):
		await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().reload_current_scene()

func atualizar_hud() -> void:
	if has_node("CanvasLayer/HUD/FragmentsLabel"):
		$CanvasLayer/HUD/FragmentsLabel.text = tr("KEY_CRYSTALS") % ("%d/%d" % [coletados, total_fragmentos])
	if has_node("CanvasLayer/HUD/EstatuesLabel"):
		$CanvasLayer/HUD/EstatuesLabel.text = tr("KEY_STATUES") % ("%d/%d" % [estatuas_usadas, total_estatuas])
	if has_node("CanvasLayer/HUD/VidasLabel"):
		$CanvasLayer/HUD/VidasLabel.text = tr("KEY_VITALITY") % str(GameManager.vidas)

func finalizar_fase() -> void:
	if has_node("TransitionLayer/AnimationPlayer"):
		$TransitionLayer/AnimationPlayer.play("fade_out")
	fade_out_musica()

	if has_node("TransitionLayer/AnimationPlayer"):
		await $TransitionLayer/AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")

func fade_in_musica() -> void:
	if not has_node("Music"): return
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -25.0, 1.0)

func fade_out_musica() -> void:
	if not has_node("Music"): return
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
