extends Node

signal horario_alterado(horario: String)
signal fim_do_dia_automatico

@export var hora_inicial: int = 8
@export var hora_final: int = 24
@export var duracao_dia_real: float = 60.0

var minutos_atuais: float
var ativo := false
var dia_encerrado_automaticamente := false

func _ready() -> void:
	minutos_atuais = hora_inicial * 60
	ativo = false

func iniciar_dia() -> void:
	minutos_atuais = hora_inicial * 60
	ativo = true
	dia_encerrado_automaticamente = false
	horario_alterado.emit(obter_hora_formatada())

func parar_dia() -> void:
	ativo = false

func retomar_dia(minutos: float) -> void:
	minutos_atuais = clampf(minutos, hora_inicial * 60.0, 23.0 * 60.0 + 59.0)
	ativo = true
	dia_encerrado_automaticamente = false
	horario_alterado.emit(obter_hora_formatada())

func _process(delta: float) -> void:
	if not ativo:
		return
	minutos_atuais += ((hora_final - hora_inicial) * 60.0 / duracao_dia_real) * delta
	if minutos_atuais >= 23 * 60 + 59:
		minutos_atuais = 23 * 60 + 59
		ativo = false
		dia_encerrado_automaticamente = true
		horario_alterado.emit(obter_hora_formatada())
		fim_do_dia_automatico.emit()
	else:
		horario_alterado.emit(obter_hora_formatada())

func avancar_tempo(minutos: int) -> void:
	if not ativo:
		return
	minutos_atuais = minf(minutos_atuais + minutos, 23 * 60 + 59)
	horario_alterado.emit(obter_hora_formatada())
	if minutos_atuais >= 23 * 60 + 59:
		ativo = false
		dia_encerrado_automaticamente = true
		fim_do_dia_automatico.emit()

func obter_hora_formatada() -> String:
	return "%02d:%02d" % [int(minutos_atuais / 60), int(minutos_atuais) % 60]
