extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const MAX_ATRIBUTO := 100.0


signal atributos_alterados(
	produtividade: float,
	energia: float,
	saude_mental: float
)


@export_category("Atributos")
@export_range(0.0, 100.0, 1.0) var produtividade: float = 20.0
@export_range(0.0, 100.0, 1.0) var energia: float = 100.0
@export_range(0.0, 100.0, 1.0) var saude_mental: float = 80.0


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var relogio = get_node("../Relogio")


var direcao = "none"
var ponto_interacao_atual: Area2D = null


func _ready() -> void:
	emitir_atributos()


func _physics_process(delta: float) -> void:
	player_movement(delta)

	if Input.is_action_just_pressed("ui_accept"):
		if ponto_interacao_atual != null:
			if ponto_interacao_atual.atividade_atual != null:
				var atividade = ponto_interacao_atual.atividade_atual

				if not atividade.esta_disponivel(relogio.minutos_atuais):
					print("Atividade indisponível neste horário")
					return

				print("Realizando atividade: ", atividade.nome)

				atualizar_atributos(
					atividade.produtividade,
					atividade.energia,
					atividade.saude_mental
				)

				relogio.avancar_tempo(
					atividade.duracao_minutos
				)

				ponto_interacao_atual.minuto_liberacao_proxima_atividade = (
					relogio.minutos_atuais
					+ ponto_interacao_atual.intervalo_minimo_entre_atividades
				)

				ponto_interacao_atual.atividade_atual = null
				ponto_interacao_atual.minuto_inicio_atividade = -1.0

				ponto_interacao_atual.hud.esconder_interacao()

			else:
				print("Nenhuma atividade disponível neste local")
		else:
			print("Nenhum ponto de interação próximo")


func player_movement(_delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		direcao = "right"
		animacao(1)
		velocity.x = SPEED
		velocity.y = 0

	elif Input.is_action_pressed("ui_left"):
		direcao = "left"
		animacao(1)
		velocity.x = -SPEED
		velocity.y = 0

	elif Input.is_action_pressed("ui_up"):
		direcao = "up"
		animacao(1)
		velocity.x = 0
		velocity.y = -SPEED

	elif Input.is_action_pressed("ui_down"):
		direcao = "down"
		animacao(1)
		velocity.x = 0
		velocity.y = SPEED

	else:
		animacao(0)
		velocity.x = 0
		velocity.y = 0

	move_and_slide()


func atualizar_atributos(
	delta_produtividade: float,
	delta_energia: float,
	delta_saude_mental: float
) -> void:
	produtividade = clamp(
		produtividade + delta_produtividade,
		0.0,
		MAX_ATRIBUTO
	)

	energia = clamp(
		energia + delta_energia,
		0.0,
		MAX_ATRIBUTO
	)

	saude_mental = clamp(
		saude_mental + delta_saude_mental,
		0.0,
		MAX_ATRIBUTO
	)

	emitir_atributos()


func emitir_atributos() -> void:
	print(
		"Produtividade: ", produtividade,
		" | Energia: ", energia,
		" | Saúde mental: ", saude_mental
	)

	atributos_alterados.emit(
		produtividade,
		energia,
		saude_mental
	)


func animacao(mov):
	if direcao == "right":
		animated_sprite_2d.flip_h = false
		if mov == 1:
			animated_sprite_2d.play("walk_side")
		elif mov == 0:
			animated_sprite_2d.play("idle_side")

	if direcao == "left":
		animated_sprite_2d.flip_h = true
		if mov == 1:
			animated_sprite_2d.play("walk_side")
		elif mov == 0:
			animated_sprite_2d.play("idle_side")

	if direcao == "up":
		animated_sprite_2d.flip_h = false
		if mov == 1:
			animated_sprite_2d.play("walk_back")
		elif mov == 0:
			animated_sprite_2d.play("idle_back")

	if direcao == "down":
		animated_sprite_2d.flip_h = false
		if mov == 1:
			animated_sprite_2d.play("walk_front")
		elif mov == 0:
			animated_sprite_2d.play("idle_front")
