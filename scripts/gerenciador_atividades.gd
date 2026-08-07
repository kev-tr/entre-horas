extends Node

@export_category("Catálogo de Atividades")
@export var catalogo_atividades: Array[Atividade] = []

@onready var estado: EstadoPartida = $"../EstadoPartida"
@onready var relogio = $"../Relogio"

var locais: Dictionary = {}

func preparar_atividade_diaria(atividade_base: Atividade) -> Atividade:
	var atividade: Atividade = atividade_base.duplicate(true)
	atividade.id = "%s_%d" % [atividade_base.id, estado.indice_dia]
	return atividade
	
func obter_atividades_catalogo() -> Array[Atividade]:
	var atividades: Array[Atividade] = []

	for atividade_base in catalogo_atividades:
		if atividade_base == null:
			continue

		if (
			not atividade_base.dias_disponiveis.is_empty()
			and not atividade_base.dias_disponiveis.has(estado.indice_dia)
		):
			continue

		atividades.append(
			preparar_atividade_diaria(atividade_base)
		)

	return atividades

func _ready() -> void:
	estado.definir_gerenciador(self)
	
	locais = {
		"Casa": $"../InteracaoCasa", "Empresa": $"../InteracaoEmpresa", "Clínica": $"../InteracaoClinica",
		"Restaurante Saudável": $"../InteracaoRestaurante", "Fast Food": $"../InteracaoFastFood",
		"Farmácia": $"../InteracaoFarmacia", "Parque": $"../InteracaoParque"
	}
	locais["Biblioteca"] = $"../InteracaoBiblioteca"
	locais["Banco"] = $"../InteracaoBanco"
	estado.dia_alterado.connect(_atualizar_pontos)
	estado.atributos_alterados.connect(func(_p: int, _e: int, _s: int): _atualizar_pontos())
	relogio.horario_alterado.connect(func(_horario: String): _atualizar_pontos())

func _atualizar_pontos(_nome_dia = "", _indice_dia = 0) -> void:
	var proxima := estado.obter_proxima_tarefa(relogio.minutos_atuais)
	for ponto in locais.values():
		ponto.definir_atividades(_atividades_para_local(ponto.tipo_local))
		ponto.destacar_como_proxima(ponto.atividade_atual != null and proxima != null and ponto.atividade_atual.id == proxima.id)
		if ponto.player_na_area != null:
			if ponto.atividade_atual != null:
				ponto.mostrar_atividade_atual()
			else:
				ponto.hud.mostrar_interacao("Indisponível", "Não há atividade neste estabelecimento agora.", false)

func _atividades_para_local(local: String) -> Array[Atividade]:
	var disponiveis: Array[Atividade] = []
	if not estado.iniciado:
		return disponiveis
	for atividade in estado.obter_atividades():
		if atividade.local == local and estado.atividade_revelada(atividade) and not estado.atividade_bloqueada(atividade) and atividade.pode_ser_concluida(relogio.minutos_atuais):
			disponiveis.append(atividade)
	return disponiveis
