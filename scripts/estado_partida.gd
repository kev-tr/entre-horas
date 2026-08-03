class_name EstadoPartida
extends Node

signal atributos_alterados(produtividade: int, energia: int, saude_mental: int)
signal dia_alterado(nome_dia: String, indice: int)
signal notificacao_recebida(titulo: String, descricao: String)
signal inventario_alterado(itens: Array[String])
signal agenda_alterada
signal partida_encerrada(vitoria: bool, mensagem: String)
signal prazo_perdido(atividade: Atividade)
signal sintoma_alterado(ativo: bool, mensagem: String)

const DIAS := ["Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira"]
const META_PRODUTIVIDADE := 8

var produtividade := 3
var energia := 7
var saude_mental := 7
var indice_dia := 0
var itens: Array[String] = []
var atividades_concluidas: Dictionary = {}
var tarefas_perdidas: Dictionary = {}
var grupos_escolhidos: Dictionary = {}
var iniciado := false
var resultado_final := false
var em_esgotamento := false
var ultima_avaliacao: Dictionary = {}

func iniciar_partida() -> void:
	produtividade = 3
	energia = 6
	saude_mental = 6
	indice_dia = 0
	itens.clear()
	atividades_concluidas.clear()
	tarefas_perdidas.clear()
	grupos_escolhidos.clear()
	iniciado = true
	em_esgotamento = false
	ultima_avaliacao.clear()
	atributos_alterados.emit(produtividade, energia, saude_mental)
	dia_alterado.emit(nome_dia(), indice_dia)
	inventario_alterado.emit(itens)
	agenda_alterada.emit()
	notificar_dia()

func restaurar_partida(dados: Dictionary) -> void:
	produtividade = int(dados.get("produtividade", 3))
	energia = int(dados.get("energia", 6))
	saude_mental = int(dados.get("saude_mental", 6))
	indice_dia = clampi(int(dados.get("indice_dia", 0)), 0, DIAS.size() - 1)
	itens.assign(Array(dados.get("itens", []), TYPE_STRING, "", null))
	atividades_concluidas.clear(); tarefas_perdidas.clear(); grupos_escolhidos.clear()
	for id in dados.get("concluidas", []): atividades_concluidas[str(id)] = true
	for id in dados.get("perdidas", []): tarefas_perdidas[str(id)] = true
	for id in dados.get("grupos", []): grupos_escolhidos[str(id)] = true
	iniciado = true
	resultado_final = false
	em_esgotamento = energia <= 2 or saude_mental <= 2
	atributos_alterados.emit(produtividade, energia, saude_mental)
	dia_alterado.emit(nome_dia(), indice_dia)
	inventario_alterado.emit(itens)
	agenda_alterada.emit()

func nome_dia() -> String:
	return DIAS[indice_dia]

func aplicar_atividade(atividade: Atividade) -> bool:
	if not iniciado or atividades_concluidas.has(atividade.id):
		return false
	if atividade.item_necessario != "" and not itens.has(atividade.item_necessario):
		notificacao_recebida.emit("Item necessário", "Você precisa de %s." % atividade.item_necessario)
		return false
	if atividade.consome_item:
		itens.erase(atividade.item_necessario)
	if atividade.item_concedido != "":
		itens.append(atividade.item_concedido)
	atividades_concluidas[atividade.id] = true
	if atividade.grupo_escolha != "":
		grupos_escolhidos[atividade.grupo_escolha] = true
	alterar_atributos(atividade.produtividade, atividade.energia, atividade.saude_mental)
	inventario_alterado.emit(itens)
	agenda_alterada.emit()
	var texto := atividade.descricao
	if atividade.item_concedido != "":
		texto += "\nItem recebido: %s." % atividade.item_concedido
	notificacao_recebida.emit(atividade.nome, texto)
	return true

func alterar_atributos(p: int, e: int, s: int) -> void:
	produtividade = clampi(produtividade + p, 0, 10)
	energia = clampi(energia + e, 0, 10)
	saude_mental = clampi(saude_mental + s, 0, 10)
	atributos_alterados.emit(produtividade, energia, saude_mental)
	_avaliar_esgotamento()

func verificar_prazos(minutos_do_dia: float) -> void:
	if not iniciado:
		return
	for atividade in obter_atividades():
		if not atividade.usa_hora_inicio_como_prazo:
			continue
		if atividades_concluidas.has(atividade.id) or tarefas_perdidas.has(atividade.id):
			continue
		if minutos_do_dia >= atividade.hora_inicio * 60:
			tarefas_perdidas[atividade.id] = true
			alterar_atributos(-1, 0, -1)
			agenda_alterada.emit()
			prazo_perdido.emit(atividade)
			notificacao_recebida.emit("Prazo perdido", "%s não foi concluída até %02d:00. Produtividade e Saúde Mental diminuíram." % [atividade.nome, atividade.hora_inicio])

func _avaliar_esgotamento() -> void:
	var novo_estado := energia <= 2 or saude_mental <= 2
	if novo_estado == em_esgotamento:
		return
	em_esgotamento = novo_estado
	var mensagem := "Esgotamento: o Personagem está mais lento. Recupere Energia ou Saúde Mental." if em_esgotamento else "Você recuperou o ritmo."
	sintoma_alterado.emit(em_esgotamento, mensagem)

func encerrar_dia_por_sono(hora: int) -> void:
	var atraso: int = maxi(0, hora - 20)
	alterar_atributos(0, max(1, 3 - atraso), max(0, 2 - atraso))
	avancar_dia("Você descansou e começa o próximo dia.")

func encerrar_dia_automatico() -> void:
	alterar_atributos(0, 1, 0)

func avancar_dia(mensagem: String) -> void:
	if indice_dia == DIAS.size() - 1:
		finalizar_semana()
		return
	indice_dia += 1
	dia_alterado.emit(nome_dia(), indice_dia)
	notificacao_recebida.emit("Novo dia", mensagem)
	notificar_dia()

func finalizar_semana() -> void:
	iniciado = false
	var vitoria := produtividade >= META_PRODUTIVIDADE and energia >= 1 and saude_mental >= 1
	resultado_final = vitoria
	ultima_avaliacao = obter_avaliacao(vitoria)
	var mensagem := "Semana concluída! Produtividade %d/10, Energia %d/10, Saúde Mental %d/10." % [produtividade, energia, saude_mental]
	if vitoria:
		mensagem += " Você encontrou um ritmo sustentável."
	else:
		mensagem += " Para vencer, alcance Produtividade 8 e mantenha Energia e Saúde Mental acima de zero."
	partida_encerrada.emit(vitoria, mensagem)

func obter_avaliacao(vitoria := resultado_final) -> Dictionary:
	return {
		"vitoria": vitoria,
		"feitas": atividades_concluidas.size(),
		"perdidas": tarefas_perdidas.size(),
		"decisoes": grupos_escolhidos.size(),
		"pontuacao": produtividade + energia + saude_mental,
		"produtividade": produtividade,
		"energia": energia,
		"saude_mental": saude_mental,
		"orientacao": "Ritmo sustentavel." if vitoria else "Revise prazos e recupere seus atributos."
	}

func obter_atividades() -> Array[Atividade]:
	var dia := indice_dia
	var atividades: Array[Atividade] = [
		Atividade.criar("almoco_%d" % dia, "Almoço", "Restaurante Saudável", "Uma refeição equilibrada recupera seu ritmo.", 45, 0, 2, 1, 11, 14),
		Atividade.criar("lanche_%d" % dia, "Lanche", "Fast Food", "Uma solução rápida para a fome.", 30, 0, 1, 0, 10, 22),
		Atividade.criar("caminhar_%d" % dia, "Caminhar", "Parque", "Um intervalo para respirar e reorganizar os pensamentos.", 45, 0, -1, 2, 8, 17),
		Atividade.criar("correr_%d" % dia, "Correr", "Parque", "Movimento intenso para aliviar a pressão.", 45, 0, -2, 2, 17, 21),
		Atividade.criar("amigos_%d" % dia, "Encontrar amigos", "Parque", "Conexão também faz parte da rotina.", 60, 0, -1, 2, 17, 22),
		Atividade.criar("dormir_%d" % dia, "Dormir", "Casa", "Encerre o dia e recupere parte das forças.", 1, 0, 0, 0, 20, 24)
	]
	atividades.append(Atividade.criar("estudar_%d" % dia, "Estudar em silencio", "Biblioteca", "Um tempo tranquilo para organizar os pensamentos.", 35, 0, -1, 2, 9, 17))
	atividades.append(Atividade.criar("financas_%d" % dia, "Organizar financas", "Banco", "Planejar as contas reduz a pressao da semana.", 25, 0, 1, 1, 9, 16))
	match dia:
		0: atividades.append(Atividade.criar("relatorio", "Relatório", "Empresa", "Um avanço importante no projeto da semana.", 60, 2, -3, -2, 9, 17, "", false, "", false, true))
		1:
			atividades.append(Atividade.criar("consulta", "Consulta", "Clínica", "A consulta ajuda você a cuidar de si.", 60, 0, -1, 1, 9, 17, "", false, "Receita", false, true))
			atividades.append(Atividade.criar("remedio", "Retirar remédio", "Farmácia", "Com o tratamento em dia, o peso da semana diminui.", 15, 0, 1, 2, 10, 20, "Receita", true, "", false, true))
			atividades.append(Atividade.criar("hora_extra", "Hora extra", "Empresa", "Você ganha visibilidade, mas sacrifica seu descanso.", 90, 3, -4, -3, 15, 17, "", false, "", true, true, "decisao_tarde"))
			atividades.append(Atividade.criar("tempo_pessoal", "Proteger seu tempo", "Empresa", "Você recusa a hora extra e preserva seu equilíbrio.", 30, 0, 0, 2, 15, 17, "", false, "", true, true, "decisao_tarde"))
		2: atividades.append(Atividade.criar("reuniao", "Reunião urgente", "Empresa", "Evento especial: sua presença é necessária agora.", 90, 2, -3, -2, 10, 16, "", false, "", true, true))
		3: atividades.append(Atividade.criar("plano", "Plano de carreira", "Empresa", "Você transforma esforço em direção profissional.", 60, 2, -3, -2, 9, 17, "", false, "", false, true))
		4: atividades.append(Atividade.criar("entrega", "Entrega final", "Empresa", "A entrega fecha os compromissos da semana.", 90, 1, -3, -2, 10, 17, "", false, "", true, true))
	if dia == 0:
		atividades.append(Atividade.criar("revisao_relatorio", "Revisar relatorio", "Empresa", "A gerente pediu ajustes antes da reuniao de equipe.", 20, 1, -2, -1, 10, 17, "", false, "", true, true))
	elif dia == 2:
		atividades.append(Atividade.criar("ata_reuniao", "Enviar ata", "Empresa", "Registre os acordos enquanto a reuniao ainda esta fresca.", 20, 1, -2, -1, 11, 16, "", false, "", false, true))
	elif dia == 3:
		atividades.append(Atividade.criar("alinhamento", "Alinhamento", "Empresa", "Uma conversa curta evita retrabalho no fim da semana.", 20, 1, -2, -1, 10, 17, "", false, "", false, true))
	elif dia == 4:
		atividades.append(Atividade.criar("apresentacao", "Apresentar entrega", "Empresa", "Defenda o resultado para encerrar a semana.", 25, 1, -2, -1, 11, 17, "", false, "", true, true))
	return atividades

func obter_proxima_tarefa(minutos_do_dia := 0.0) -> Atividade:
	var proxima: Atividade = null
	for atividade in obter_atividades():
		if atividade.local == "Biblioteca" or atividade.local == "Banco":
			continue
		if atividade.local in ["Casa", "Restaurante Saudável", "Fast Food", "Parque"] or atividade_bloqueada(atividade):
			continue
		if atividade.usa_hora_inicio_como_prazo and minutos_do_dia >= atividade.hora_inicio * 60:
			continue
		if proxima == null or atividade.hora_inicio < proxima.hora_inicio:
			proxima = atividade
	return proxima

func atividade_bloqueada(atividade: Atividade) -> bool:
	return atividades_concluidas.has(atividade.id) or tarefas_perdidas.has(atividade.id) or (atividade.grupo_escolha != "" and grupos_escolhidos.has(atividade.grupo_escolha))

func notificar_dia() -> void:
	var destaque := obter_atividades().filter(func(a: Atividade): return a.especial or a.local == "Empresa")
	if not destaque.is_empty():
		var atividade: Atividade = destaque[0]
		notificacao_recebida.emit("Agenda de %s" % nome_dia(), "%s — %s (até %02d:00)" % [atividade.nome, atividade.local, atividade.hora_inicio])
