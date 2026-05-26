extends Control

var anim_offset := 0.0
var anim_tween: Tween

func _ready():
	# Usa o sistema de tradução nativo que você configurou no CSV!
	$Label.text = tr("KEY_DRAG_TO_MOVE")
		
	# Nunca bloqueie o mouse ou toques da tela
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0 # Começa invisível
	
	# Sequência principal
	_fade_in()
	_iniciar_animacao_arrasto()
	
	# Agenda fade out e destruição após 5 segundos
	var destroy_timer = get_tree().create_timer(4.0)
	destroy_timer.timeout.connect(_fade_out_and_destroy)

func _fade_in():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

func _fade_out_and_destroy():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _iniciar_animacao_arrasto():
	anim_tween = create_tween().set_loops()
	# Dedo vai 25 pixels para a direita, depois para a esquerda
	anim_tween.tween_property(self, "anim_offset", 25.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	anim_tween.tween_property(self, "anim_offset", -25.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(_delta):
	# Obriga a chamar _draw() todo frame para rodar a animação
	queue_redraw()

func _draw():
	# A coordenada Y onde a animação ocorre (logo abaixo do texto)
	var pos_y = 20.0
	
	# Trilho horizontal sutil
	draw_line(Vector2(-25, pos_y), Vector2(25, pos_y), Color(1, 1, 1, 0.15), 2.0)
	
	# Ponto central discreto
	draw_circle(Vector2(0, pos_y), 3.0, Color(1, 1, 1, 0.2))
	
	# Simulação do dedo animado
	draw_circle(Vector2(anim_offset, pos_y), 10.0, Color(1, 1, 1, 0.5))
	draw_circle(Vector2(anim_offset, pos_y), 6.0, Color(1, 1, 1, 0.9))
