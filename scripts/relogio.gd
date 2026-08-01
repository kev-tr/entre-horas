extends Node

signal horario_alterado(horario: String)

@export var hora_inicial: int = 8
@export var hora_final: int = 24
@export var duracao_dia_real: float = 180.0

var minutos_atuais: float = 0.0
var minutos_inicio: int
var minutos_fim: int
var minutos_totais_dia: int


func _ready() -> void:
	minutos_inicio = hora_inicial * 60
	minutos_fim = hora_final * 60
	minutos_totais_dia = minutos_fim - minutos_inicio

	minutos_atuais = minutos_inicio
	
	print("Horário inicial: ", obter_hora_formatada())


func _process(delta: float) -> void:
	var minutos_por_segundo = minutos_totais_dia / duracao_dia_real

	minutos_atuais += minutos_por_segundo * delta

	if minutos_atuais > minutos_fim:
		minutos_atuais = minutos_fim
	
	horario_alterado.emit(obter_hora_formatada())
		
		
func obter_hora_formatada() -> String:
	var horas: int = int(minutos_atuais) / 60
	var minutos: int = int(minutos_atuais) % 60

	return "%02d:%02d" % [horas, minutos]
	
func avancar_tempo(minutos: int) -> void:
	minutos_atuais += minutos

	if minutos_atuais > minutos_fim:
		minutos_atuais = minutos_fim
	
	horario_alterado.emit(obter_hora_formatada())

	print("Novo horário: ", obter_hora_formatada())
