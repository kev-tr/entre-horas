extends Node

@onready var casa = $"../InteracaoCasa"
@onready var empresa = $"../InteracaoEmpresa"
@onready var clinica = $"../InteracaoClinica"
@onready var restaurante = $"../InteracaoRestaurante"
@onready var fast_food = $"../InteracaoFastFood"
@onready var farmacia = $"../InteracaoFarmacia"
@onready var parque = $"../InteracaoParque"
@onready var relogio = $"../Relogio"

@export_category("Atividades por Local")

@export var atividades_casa: Array[Atividade] = []
@export var atividades_empresa: Array[Atividade] = []
@export var atividades_clinica: Array[Atividade] = []
@export var atividades_restaurante: Array[Atividade] = []
@export var atividades_fast_food: Array[Atividade] = []
@export var atividades_farmacia: Array[Atividade] = []
@export var atividades_parque: Array[Atividade] = []

var locais: Array = []

@export var intervalo_tentativa_minutos: int = 30

var proxima_tentativa: float = 0.0

func _ready() -> void:
	proxima_tentativa = relogio.minutos_atuais + intervalo_tentativa_minutos
	
	locais = [
	{
		"ponto": casa,
		"atividades": atividades_casa
	},
	{
		"ponto": empresa,
		"atividades": atividades_empresa
	},
	{
		"ponto": clinica,
		"atividades": atividades_clinica
	},
	{
		"ponto": restaurante,
		"atividades": atividades_restaurante
	},
	{
		"ponto": fast_food,
		"atividades": atividades_fast_food
	},
	{
		"ponto": farmacia,
		"atividades": atividades_farmacia
	},
	{
		"ponto": parque,
		"atividades": atividades_parque
	}
]

func _process(_delta: float) -> void:
	for local in locais:
		verificar_expiracao(local["ponto"])
	
	if relogio.minutos_atuais >= proxima_tentativa:
		tentar_gerar_atividades()
		proxima_tentativa = relogio.minutos_atuais + intervalo_tentativa_minutos

func definir_atividade(
	ponto_interacao: Area2D,
	atividade: Atividade
) -> void:
	ponto_interacao.atividade_atual = atividade
	ponto_interacao.minuto_inicio_atividade = relogio.minutos_atuais
	
	if ponto_interacao.player_na_area != null:
		ponto_interacao.hud.mostrar_interacao(atividade.nome)

func remover_atividade(
	ponto_interacao: Area2D
) -> void:
	ponto_interacao.atividade_atual = null
	ponto_interacao.minuto_inicio_atividade = -1.0

	ponto_interacao.minuto_liberacao_proxima_atividade = (
		relogio.minutos_atuais
		+ ponto_interacao.intervalo_minimo_entre_atividades
	)
	
func verificar_expiracao(ponto_interacao: Area2D) -> void:
	if ponto_interacao.atividade_atual == null:
		return

	var atividade = ponto_interacao.atividade_atual

	if atividade.duracao_disponibilidade_minutos <= 0:
		return

	var tempo_decorrido = (
		relogio.minutos_atuais
		- ponto_interacao.minuto_inicio_atividade
	)

	if tempo_decorrido >= atividade.duracao_disponibilidade_minutos:
		print("Atividade expirou: ", atividade.nome)
		remover_atividade(ponto_interacao)
		
func tentar_gerar_atividades() -> void:
	print("Tentativa de gerar atividade às ", relogio.obter_hora_formatada())

	for local in locais:
		tentar_gerar_no_ponto(
			local["ponto"],
			local["atividades"]
		)
			
func ponto_esta_livre(ponto_interacao: Area2D) -> bool:
	if ponto_interacao.atividade_atual != null:
		return false

	if relogio.minutos_atuais < ponto_interacao.minuto_liberacao_proxima_atividade:
		return false

	return true

func tentar_gerar_no_ponto(
	ponto_interacao: Area2D,
	atividades: Array[Atividade]
) -> void:
	if not ponto_esta_livre(ponto_interacao):
		return

	for atividade in atividades:
		if not atividade.esta_disponivel(relogio.minutos_atuais):
			continue

		if randf() <= atividade.chance_surgimento:
			definir_atividade(ponto_interacao, atividade)
			print(
				atividade.nome,
				" surgiu em: ",
				ponto_interacao.tipo_local
			)
			return
