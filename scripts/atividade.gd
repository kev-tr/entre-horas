class_name Atividade
extends Resource

@export var id: String = ""
@export var nome: String = ""
@export var local: String = ""
@export_multiline var descricao: String = ""

@export_category("Efeitos")
@export_range(-10, 10, 1) var produtividade: int = 0
@export_range(-10, 10, 1) var energia: int = 0
@export_range(-10, 10, 1) var saude_mental: int = 0

@export_category("Tempo")
@export var duracao_minutos: int = 30
@export var hora_inicio: int = 8
@export var hora_fim: int = 23
@export var usa_hora_inicio_como_prazo: bool = false
@export var duracao_disponibilidade_minutos: int = 0
# Campos legados mantidos para que os recursos antigos continuem abrindo no editor.
@export var tem_restricao_horario: bool = true
@export_range(0.0, 1.0, 0.05) var chance_surgimento: float = 1.0

@export_category("Inventario")
@export var item_necessario: String = ""
@export var consome_item: bool = false
@export var item_concedido: String = ""
@export var especial: bool = false
@export var grupo_escolha: String = ""

func esta_disponivel(minutos_do_dia: float) -> bool:
	if usa_hora_inicio_como_prazo:
		return minutos_do_dia < hora_inicio * 60
	var inicio := hora_inicio * 60
	var fim := hora_fim * 60
	return minutos_do_dia >= inicio and minutos_do_dia < fim

func pode_ser_concluida(minutos_do_dia: float) -> bool:
	if usa_hora_inicio_como_prazo:
		return minutos_do_dia < hora_inicio * 60
	return esta_disponivel(minutos_do_dia) and minutos_do_dia + duracao_minutos <= hora_fim * 60

static func criar(
	atividade_id: String, titulo: String, destino: String, texto: String,
	duracao: int, p: int, e: int, s: int, inicio: int, fim: int,
	necessario := "", consome := false, concedido := "", is_especial := false, usa_prazo := false, grupo := ""
) -> Atividade:
	var atividade := Atividade.new()
	atividade.id = atividade_id
	atividade.nome = titulo
	atividade.local = destino
	atividade.descricao = texto
	atividade.duracao_minutos = duracao
	atividade.produtividade = p
	atividade.energia = e
	atividade.saude_mental = s
	atividade.hora_inicio = inicio
	atividade.hora_fim = fim
	atividade.usa_hora_inicio_como_prazo = usa_prazo
	atividade.item_necessario = necessario
	atividade.consome_item = consome
	atividade.item_concedido = concedido
	atividade.especial = is_especial
	atividade.grupo_escolha = grupo
	return atividade
