extends Node2D

@onready var hud = $HUD
@onready var relogio = $Relogio
@onready var estado: EstadoPartida = $EstadoPartida
@onready var gerenciador = $GerenciadorAtividades
@onready var player: CharacterBody2D = $Player
@onready var audio = $Audio
@onready var luz_do_dia: CanvasModulate = $LuzDoDia
@onready var salvamento: Salvamento = $Salvamento

var posicao_inicial_player: Vector2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_adicionar_rotulos_de_locais()
	hud.preparar(estado)
	hud.definir_personagem($Player)
	hud.iniciar_solicitado.connect(_iniciar_partida)
	hud.reiniciar_solicitado.connect(_iniciar_partida)
	hud.continuar_solicitado.connect(_continuar_partida)
	hud.retomar_solicitado.connect(_retomar_partida)
	hud.proximo_dia_solicitado.connect(_iniciar_proximo_dia)
	relogio.horario_alterado.connect(hud.atualizar_relogio)
	relogio.horario_alterado.connect(_verificar_prazos)
	relogio.horario_alterado.connect(_atualizar_luz_do_dia)
	relogio.fim_do_dia_automatico.connect(_fim_automatico)
	relogio.horario_alterado.connect(_verificar_tutorial_noite)
	estado.partida_encerrada.connect(_mostrar_avaliacao)
	estado.partida_encerrada.connect(audio.tocar_resultado)
	estado.prazo_perdido.connect(func(_atividade: Atividade): audio.tocar_erro())
	estado.prazo_perdido.connect(_ao_perder_prazo)
	estado.sintoma_alterado.connect(func(ativo: bool, _mensagem: String): audio.tocar_esgotamento() if ativo else audio.tocar_confirmacao())
	estado.atributos_alterados.connect(func(_p: int, _e: int, _s: int): _salvar_progresso())
	estado.atributos_alterados.connect(_verificar_tutoriais_atributos)
	estado.agenda_alterada.connect(_salvar_progresso)
	estado.dia_alterado.connect(func(_nome: String, _dia: int): _salvar_progresso())
	estado.rendimento_reduzido_energia.connect(hud.mostrar_tutorial_rendimento_energia)
	estado.rendimento_reduzido_saude_mental.connect(hud.mostrar_tutorial_rendimento_saude_mental)
	estado.energia_esgotada.connect(_encerrar_dia_por_esgotamento)
	estado.saude_mental_esgotada.connect(_encerrar_partida_por_saude_mental)
	hud.mostrar_menu(salvamento.tem_partida())
	posicao_inicial_player = player.global_position
	

func _iniciar_partida() -> void:
	get_tree().paused = true
	estado.iniciar_partida()
	audio.iniciar_musica()
	gerenciador._atualizar_pontos()
	hud.esconder_telas()
	hud.mostrar_tutorial_inicial(_comecar_primeiro_dia)
	
func _comecar_primeiro_dia() -> void:
	get_tree().paused = false
	relogio.iniciar_dia()
	hud.esconder_telas()
	estado.notificar_dia()

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
	hud.mostrar_fim_do_dia()

func _iniciar_proximo_dia() -> void:
	hud.esconder_telas()

	estado.avancar_dia("Você começa um novo dia.")

	if estado.iniciado:
		player.global_position = posicao_inicial_player
		relogio.iniciar_dia()
		gerenciador._atualizar_pontos()

func _verificar_prazos(_horario: String) -> void:
	estado.verificar_prazos(relogio.minutos_atuais)

func _encerrar_dia_por_esgotamento() -> void:
	relogio.parar_dia()
	hud.mostrar_energia_esgotada(_confirmar_encerramento_por_esgotamento)

func _encerrar_partida_por_saude_mental() -> void:
	relogio.parar_dia()
	hud.mostrar_saude_mental_esgotada(_confirmar_encerramento_por_saude_mental)

func _confirmar_encerramento_por_saude_mental() -> void:
	estado.finalizar_por_saude_mental()

func _confirmar_encerramento_por_esgotamento() -> void:
	estado.encerrar_dia_por_sono(20)

	if estado.iniciado:
		relogio.iniciar_dia()

func _mostrar_avaliacao(_vitoria: bool, _mensagem: String) -> void:
	var avaliacao := estado.ultima_avaliacao
	salvamento.registrar_resultado(avaliacao)

	var texto := "%d tarefas concluidas\n%d prazos perdidos\n%d decisoes tomadas\n\nProdutividade %d/10 · Energia %d/10 · Saude Mental %d/10\nMenores níveis na semana: Energia %d/10 · Saude Mental %d/10\n\n%s" % [
		avaliacao.feitas,
		avaliacao.perdidas,
		avaliacao.decisoes,
		avaliacao.produtividade,
		avaliacao.energia,
		avaliacao.saude_mental,
		avaliacao.energia_minima,
		avaliacao.saude_mental_minima,
		avaliacao.orientacao
	]

	var produtividade_ok: bool = avaliacao.produtividade >= EstadoPartida.META_PRODUTIVIDADE
	var houve_desgaste: bool = (avaliacao.saude_mental_minima <= 2 or avaliacao.dias_com_energia_critica >= 3)

	var titulo: String

	if avaliacao.saude_mental == 0:
		titulo = "ESGOTAMENTO GRAVE"
	elif produtividade_ok and not houve_desgaste:
		titulo = "SEMANA EQUILIBRADA"
	elif produtividade_ok:
		titulo = "RESULTADOS COM DESGASTE"
	elif not houve_desgaste:
		titulo = "METAS PENDENTES"
	else:
		titulo = "SEMANA SOBRECARREGADA"

	hud.mostrar_resultado(titulo, texto)

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
	destinos["InteracaoBiblioteca"] = "BIBLIOTECA"
	destinos["InteracaoBanco"] = "BANCO"
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

func _verificar_tutoriais_atributos(produtividade: int, energia: int, saude_mental: int) -> void:
	if produtividade <= 2 and not hud.tutorial_produtividade_baixa_mostrado:
		hud.mostrar_tutorial_produtividade_baixa()
	elif energia <= 2 and not hud.tutorial_cansaco_mostrado:
		hud.mostrar_tutorial_cansaco()
	elif saude_mental <= 2 and not hud.tutorial_saude_mental_mostrado:
		hud.mostrar_tutorial_saude_mental()
		
func _verificar_tutorial_noite(_horario: String) -> void:
	if estado.indice_dia != 0:
		return

	if hud.tutorial_noite_mostrado:
		return

	if relogio.minutos_atuais >= 20 * 60:
		hud.mostrar_tutorial_noite()

func _ao_perder_prazo(_atividade: Atividade) -> void:
	if not hud.tutorial_prazo_perdido_mostrado:
		hud.mostrar_tutorial_prazo_perdido()
		
		
