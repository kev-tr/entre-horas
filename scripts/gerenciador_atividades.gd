extends Node

@onready var estado: EstadoPartida = $"../EstadoPartida"
@onready var relogio = $"../Relogio"

var locais: Dictionary = {}

func _ready() -> void:
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

func _atualizar_pontos() -> void:
	var proxima := estado.obter_proxima_tarefa(relogio.minutos_atuais)
	for ponto in locais.values():
		ponto.definir_atividades(_atividades_para_local(ponto.tipo_local))
		ponto.destacar_como_proxima(ponto.atividade_atual != null and proxima != null and ponto.atividade_atual.id == proxima.id)
		if ponto.player_na_area != null:
			if ponto.atividade_atual != null:
				ponto.mostrar_atividade_atual()
			else:
				ponto.hud.mostrar_interacao("Indisponível", "Não há atividade viável aqui agora. Consulte a agenda para o próximo prazo.")

func _atividades_para_local(local: String) -> Array[Atividade]:
	var disponiveis: Array[Atividade] = []
	if not estado.iniciado:
		return disponiveis
	for atividade in estado.obter_atividades():
		if atividade.local == local and not estado.atividade_bloqueada(atividade) and atividade.pode_ser_concluida(relogio.minutos_atuais):
			disponiveis.append(atividade)
	return disponiveis
