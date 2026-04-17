extends Node

var tempo_total := 0.0
var mortes := 0
var jogo_ativo := false

func iniciar_jogo() -> void:
	tempo_total = 0.0
	mortes = 0
	jogo_ativo = true

func registrar_morte() -> void:
	mortes += 1

func pausar_tempo() -> void:
	jogo_ativo = false

func retomar_tempo() -> void:
	jogo_ativo = true

func finalizar_jogo() -> void:
	jogo_ativo = false

func _process(delta: float) -> void:
	if jogo_ativo:
		tempo_total += delta

func formatar_tempo() -> String:
	var total_segundos := int(tempo_total)
	var minutos := floori(total_segundos / 60.0)
	var segundos := total_segundos % 60
	return "%02d:%02d" % [minutos, segundos]
