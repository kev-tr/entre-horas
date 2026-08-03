extends Node2D

@onready var hud = $HUD
@onready var relogio = $Relogio
@onready var estado: EstadoPartida = $EstadoPartida
@onready var gerenciador = $GerenciadorAtividades
@onready var audio = $Audio
@onready var luz_do_dia: CanvasModulate = $LuzDoDia
@onready var salvamento: Salvamento = $Salvamento

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	_adicionar_rotulos_de_locais()
	hud.preparar(estado)
	hud.definir_personagem($Player)
	hud.iniciar_solicitado.connect(_iniciar_partida)
	hud.reiniciar_solicitado.connect(_iniciar_partida)
	hud.continuar_solicitado.connect(_continuar_partida)
	hud.retomar_solicitado.connect(_retomar_partida)
	relogio.horario_alterado.connect(hud.atualizar_relogio)
	relogio.horario_alterado.connect(_verificar_prazos)
	relogio.horario_alterado.connect(_atualizar_luz_do_dia)
	relogio.fim_do_dia_automatico.connect(_fim_automatico)
	estado.partida_encerrada.connect(_mostrar_avaliacao)
	estado.partida_encerrada.connect(audio.tocar_resultado)
	estado.prazo_perdido.connect(func(_atividade: Atividade): audio.tocar_erro())
	estado.sintoma_alterado.connect(func(ativo: bool, _mensagem: String): audio.tocar_esgotamento() if ativo else audio.tocar_confirmacao())
	estado.atributos_alterados.connect(func(_p: int, _e: int, _s: int): _salvar_progresso())
	estado.agenda_alterada.connect(_salvar_progresso)
	estado.dia_alterado.connect(func(_nome: String, _dia: int): _salvar_progresso())
	hud.mostrar_menu(salvamento.tem_partida())

func _iniciar_partida() -> void:
	get_tree().paused = false
	estado.iniciar_partida()
	audio.iniciar_musica()
	relogio.iniciar_dia()
	gerenciador._atualizar_pontos()
	hud.esconder_telas()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_continuar_partida()
		else:
			get_tree().paused = true
			hud.mostrar_pausa()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R and not get_tree().paused:
		_iniciar_partida()
		get_viewport().set_input_as_handled()

func _continuar_partida() -> void:
	get_tree().paused = false
	hud.esconder_pausa()

func _retomar_partida() -> void:
	var dados: Dictionary = salvamento.dados.partida
	if dados.is_empty():
		return
	get_tree().paused = false
	estado.restaurar_partida(dados)
	relogio.retomar_dia(float(dados.get("minutos", 8 * 60)))
	audio.iniciar_musica()
	gerenciador._atualizar_pontos()
	hud.esconder_telas()

func _fim_automatico() -> void:
	if not estado.iniciado:
		return
	estado.encerrar_dia_automatico()
	if estado.iniciado:
		relogio.iniciar_dia()
		gerenciador._atualizar_pontos()

func _verificar_prazos(_horario: String) -> void:
	estado.verificar_prazos(relogio.minutos_atuais)

func _mostrar_avaliacao(_vitoria: bool, _mensagem: String) -> void:
	var avaliacao := estado.ultima_avaliacao
	salvamento.registrar_resultado(avaliacao)
	var texto := "%d tarefas concluidas\n%d prazos perdidos\n%d decisoes tomadas\n\nProdutividade %d/10 · Energia %d/10 · Saude Mental %d/10\n\n%s" % [avaliacao.feitas, avaliacao.perdidas, avaliacao.decisoes, avaliacao.produtividade, avaliacao.energia, avaliacao.saude_mental, avaliacao.orientacao]
	hud.mostrar_resultado(avaliacao.vitoria, texto)

func _atualizar_luz_do_dia(_horario: String) -> void:
	var hora: float = relogio.minutos_atuais / 60.0
	if hora < 17.0:
		luz_do_dia.color = Color.WHITE
	elif hora < 20.0:
		luz_do_dia.color = Color.WHITE.lerp(Color("D7C2B5"), (hora - 17.0) / 3.0)
	else:
		luz_do_dia.color = Color("9FAED0")

func _salvar_progresso() -> void:
	if estado.iniciado:
		salvamento.salvar_partida(estado, relogio.minutos_atuais)

func _adicionar_rotulos_de_locais() -> void:
	var destinos := {
		"InteracaoCasa": "CASA", "InteracaoEmpresa": "EMPRESA", "InteracaoClinica": "CLÍNICA",
		"InteracaoRestaurante": "RESTAURANTE", "InteracaoFastFood": "FAST FOOD",
		"InteracaoFarmacia": "FARMÁCIA", "InteracaoParque": "PARQUE"
	}
	for no in destinos:
		var ponto: Area2D = get_node(NodePath(no))
		var rotulo := Label.new()
		rotulo.text = destinos[no]
		rotulo.position = Vector2(-62, -112)
		rotulo.size = Vector2(124, 26)
		rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rotulo.z_index = 10
		rotulo.add_theme_font_size_override("font_size", 13)
		rotulo.add_theme_color_override("font_color", Color("FFF4CC"))
		rotulo.add_theme_color_override("font_outline_color", Color("18212B"))
		rotulo.add_theme_constant_override("outline_size", 4)
		ponto.add_child(rotulo)
