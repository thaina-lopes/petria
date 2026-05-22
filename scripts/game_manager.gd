extends Node

var tempo_total := 0.0
var mortes := 0
var vidas := 3
var jogo_ativo := false
var jogo_foi_iniciado := false
var tutorial_movimento_visto := false

var canvas_mod: CanvasModulate

func _ready() -> void:
	canvas_mod = CanvasModulate.new()
	canvas_mod.color = Color(0.25, 0.25, 0.45) # Clima mágico noturno
	add_child(canvas_mod)

func iniciar_jogo() -> void:
	tempo_total = 0.0
	mortes = 0
	vidas = 3
	jogo_ativo = true
	jogo_foi_iniciado = true

func registrar_morte() -> void:
	mortes += 1
	if vidas <= 0:
		vidas = 3 # Reseta as vidas ao reiniciar da morte total

func pausar_tempo() -> void:
	jogo_ativo = false

func retomar_tempo() -> void:
	jogo_ativo = true

func finalizar_jogo() -> void:
	jogo_ativo = false

func _process(delta: float) -> void:
	if jogo_ativo:
		tempo_total += delta
		
	if get_tree().current_scene:
		var scene_name = get_tree().current_scene.name
		
		# Auto-inicia o sistema de contagem caso a fase seja rodada diretamente (F6) para testes
		if scene_name != "MainMenu" and scene_name != "FinalScene" and not jogo_foi_iniciado:
			iniciar_jogo()
			
		if scene_name == "MainMenu" or scene_name == "FinalScene":
			canvas_mod.color = Color(1, 1, 1) # Remove o filtro
		else:
			canvas_mod.color = Color(0.4, 0.4, 0.6) # Aplica o filtro mágico

func formatar_tempo() -> String:
	var total_segundos := int(tempo_total)
	var minutos := floori(total_segundos / 60.0)
	var segundos := total_segundos % 60
	return "%02d:%02d" % [minutos, segundos]
