class_name Atividade
extends Resource

### Variáveis

@export var nome: String = ""

###
@export_category("Efeitos")
@export var produtividade: float = 0.0
@export var energia: float = 0.0
@export var saude_mental: float = 0.0

###
@export_category("Tempo")
@export var duracao_minutos: int = 0

###
@export_category("Disponibilidade")

@export var tem_restricao_horario: bool = false
@export_range(0, 23, 1) var hora_inicio: int = 8
@export_range(0, 23, 1) var hora_fim: int = 23

@export var duracao_disponibilidade_minutos: int = 0

@export_range(0.0, 1.0, 0.05) var chance_surgimento: float = 1.0

### Funções

func esta_disponivel(minutos_do_dia: float) -> bool:
	if not tem_restricao_horario:
		return true

	var inicio: int = hora_inicio * 60
	var fim: int = hora_fim * 60

	return minutos_do_dia >= inicio and minutos_do_dia < fim
