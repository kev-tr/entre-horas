extends CharacterBody2D

const SPEED := 200.0
const VELOCIDADE_ESGOTADO := 125.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var relogio = get_node("../Relogio")
@onready var estado: EstadoPartida = get_node("../EstadoPartida")

var direcao := "down"
var ponto_interacao_atual: Area2D = null
var confirmando_sono := false

func _physics_process(_delta: float) -> void:
	if not estado.iniciado:
		velocity = Vector2.ZERO
		return
	player_movement()
	if Input.is_action_just_pressed("ui_focus_next") and ponto_interacao_atual != null:
		ponto_interacao_atual.proxima_opcao()
	if Input.is_action_just_pressed("ui_accept") and ponto_interacao_atual != null:
		_realizar_atividade()

func _realizar_atividade() -> void:
	var atividade: Atividade = ponto_interacao_atual.atividade_atual
	if atividade == null:
		ponto_interacao_atual.hud.mostrar_mensagem("Sem atividade", "Não há nada disponível aqui neste horário.")
		return
	if not atividade.pode_ser_concluida(relogio.minutos_atuais):
		ponto_interacao_atual.hud.mostrar_mensagem("Prazo encerrado", "Não há tempo suficiente para concluir esta atividade antes do horário-limite.")
		return
	if atividade.id.begins_with("dormir_"):
		if not confirmando_sono:
			confirmando_sono = true
			ponto_interacao_atual.hud.mostrar_mensagem("Confirmar descanso", "Pressione ESPAÇO novamente para dormir e encerrar o dia.")
			return
		confirmando_sono = false
		relogio.parar_dia()
		get_node("../Audio").tocar_noite()
		estado.encerrar_dia_por_sono(int(relogio.minutos_atuais / 60))
		if estado.iniciado:
			relogio.iniciar_dia()
		return
	if estado.aplicar_atividade(atividade):
		get_node("../Audio").tocar_confirmacao()
		confirmando_sono = false
		relogio.avancar_tempo(atividade.duracao_minutos)
		if estado.obter_proxima_tarefa(relogio.minutos_atuais) != null:
			get_node("../Audio").tocar_alerta()
		if ponto_interacao_atual.atividade_atual != null:
			ponto_interacao_atual.mostrar_atividade_atual()
		else:
			ponto_interacao_atual.hud.esconder_interacao()

func player_movement() -> void:
	var velocidade := VELOCIDADE_ESGOTADO if estado.em_esgotamento else SPEED
	if Input.is_action_pressed("ui_right"):
		direcao = "right"; velocity = Vector2.RIGHT * velocidade
	elif Input.is_action_pressed("ui_left"):
		direcao = "left"; velocity = Vector2.LEFT * velocidade
	elif Input.is_action_pressed("ui_up"):
		direcao = "up"; velocity = Vector2.UP * velocidade
	elif Input.is_action_pressed("ui_down"):
		direcao = "down"; velocity = Vector2.DOWN * velocidade
	else:
		velocity = Vector2.ZERO
	_animar(velocity != Vector2.ZERO)
	move_and_slide()

func _animar(movendo: bool) -> void:
	var sufixo := "side" if direcao == "left" or direcao == "right" else ("back" if direcao == "up" else "front")
	animated_sprite_2d.flip_h = direcao == "left"
	animated_sprite_2d.play(("walk_" if movendo else "idle_") + sufixo)
