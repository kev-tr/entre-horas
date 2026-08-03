class_name Salvamento
extends Node

const ARQUIVO := "user://entre_horas.json"

var dados: Dictionary = {"melhor_pontuacao": 0, "partida": {}}

func _ready() -> void:
	carregar()

func salvar_partida(estado: EstadoPartida, minutos: float) -> void:
	if not estado.iniciado:
		return
	dados.partida = {
		"produtividade": estado.produtividade, "energia": estado.energia, "saude_mental": estado.saude_mental,
		"indice_dia": estado.indice_dia, "itens": estado.itens,
		"concluidas": estado.atividades_concluidas.keys(), "perdidas": estado.tarefas_perdidas.keys(),
		"grupos": estado.grupos_escolhidos.keys(), "minutos": minutos
	}
	_gravar()

func registrar_resultado(avaliacao: Dictionary) -> void:
	dados.melhor_pontuacao = maxi(int(dados.get("melhor_pontuacao", 0)), int(avaliacao.get("pontuacao", 0)))
	dados.partida = {}
	_gravar()

func tem_partida() -> bool:
	return not (dados.get("partida", {}) as Dictionary).is_empty()

func carregar() -> void:
	if not FileAccess.file_exists(ARQUIVO):
		return
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.READ)
	var lido = JSON.parse_string(arquivo.get_as_text())
	if lido is Dictionary:
		dados = lido

func _gravar() -> void:
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	arquivo.store_string(JSON.stringify(dados))
