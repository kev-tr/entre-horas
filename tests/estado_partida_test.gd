extends SceneTree

func _init() -> void:
	_testar_sprites_das_estruturas_visiveis()
	_testar_relogio()
	_testar_limites_e_avanco_de_tempo()
	_testar_atividades_de_equilibrio()
	_testar_cadeia_sorteada()
	_testar_agenda_limpa_e_ordenada()
	_testar_locais_sorteaveis_existem_no_mapa()
	_testar_resultados_da_semana()
	print("estado_partida_test: OK")
	quit()

func _novo_estado() -> EstadoPartida:
	var estado := EstadoPartida.new()
	estado.iniciar_partida()
	return estado

func _testar_sprites_das_estruturas_visiveis() -> void:
	var cena: Node2D = load("res://cenas/main.tscn").instantiate()
	var estruturas: Node2D = cena.get_node("Estruturas")
	assert(estruturas.visible)
	for nome in ["Clinica", "Empresa", "Casa", "Restaurante", "Farmacia", "FastFood", "Biblioteca", "Banco"]:
		var sprite: Sprite2D = estruturas.get_node("%s/Sprite" % nome)
		assert(sprite.visible)
		assert(sprite.texture != null)
	_liberar_arvore(cena)

func _liberar_arvore(no: Node) -> void:
	for filho in no.get_children():
		_liberar_arvore(filho)
	no.free()

func _testar_relogio() -> void:
	var relogio = load("res://scripts/relogio.gd").new()
	relogio.iniciar_dia()
	relogio.avancar_tempo(90)
	assert(relogio.obter_hora_formatada() == "09:30")
	relogio.minutos_atuais = 23 * 60 + 58
	relogio.avancar_tempo(1)
	assert(relogio.dia_encerrado_automaticamente)

func _testar_prazo_da_atividade() -> void:
	var atividade := Atividade.criar("teste", "Teste", "Empresa", "", 90, 0, 0, 0, 10, 12, "", false, "", false, true)
	assert(atividade.esta_disponivel(8 * 60))
	assert(atividade.pode_ser_concluida(8 * 60))
	assert(atividade.pode_ser_concluida(9 * 60 + 59))
	assert(not atividade.pode_ser_concluida(10 * 60))
	assert(not atividade.esta_disponivel(10 * 60))
	var estado := _novo_estado()
	var relatorio := _atividade(estado, "relatorio")
	assert(relatorio.pode_ser_concluida(8 * 60))
	assert(not relatorio.pode_ser_concluida(9 * 60))
	assert(estado.aplicar_atividade(relatorio))
	assert(estado.obter_proxima_tarefa(8 * 60).id == "revisao_relatorio")

func _testar_limites_e_avanco_de_tempo() -> void:
	var estado := _novo_estado()
	estado.alterar_atributos(50, -50, 50)
	assert(estado.produtividade == 10)
	assert(estado.energia == 0)
	assert(estado.saude_mental == 10)
	estado.energia = 7
	estado.saude_mental = 7
	estado.encerrar_dia_por_sono(22)
	assert(estado.indice_dia == 1)
	assert(estado.energia == 8) # recuperação tardia: +1
	assert(estado.saude_mental == 7) # recuperação tardia: +0

func _testar_receita_e_remedio() -> void:
	var estado := _novo_estado()
	estado.indice_dia = 1
	var atividades := estado.obter_atividades()
	var consulta: Atividade
	var remedio: Atividade
	for atividade in atividades:
		if atividade.id == "consulta": consulta = atividade
		if atividade.id == "remedio": remedio = atividade
	assert(not estado.aplicar_atividade(remedio))
	assert(estado.obter_proxima_tarefa().id == "consulta")
	assert(estado.aplicar_atividade(consulta))
	assert(estado.obter_proxima_tarefa().id == "remedio")
	assert(remedio.esta_disponivel(9 * 60))
	assert(estado.itens.has("Receita"))
	assert(estado.aplicar_atividade(remedio))
	assert(not estado.itens.has("Receita"))

func _testar_atividades_de_equilibrio() -> void:
	var estado := _novo_estado()
	var estudo := _atividade(estado, "estudar_0")
	var financas := _atividade(estado, "financas_0")
	assert(estudo.local == "Biblioteca")
	assert(financas.local == "Banco")
	assert(estudo.esta_disponivel(9 * 60))
	assert(financas.esta_disponivel(15 * 60))
	assert(not financas.esta_disponivel(16 * 60))
	assert(estado.aplicar_atividade(estudo))
	assert(estado.saude_mental == 8)

func _testar_cadeia_sorteada() -> void:
	var estado := _novo_estado()
	var primeira := _atividade(estado, "cadeia_0_0")
	var segunda := _atividade(estado, "cadeia_0_1")
	var terceira := _atividade(estado, "cadeia_0_2")
	assert(primeira.hora_inicio == 11)
	assert(segunda.hora_inicio == 14)
	assert(terceira.hora_inicio == 17)
	assert(not estado.atividade_revelada(segunda))
	assert(estado.aplicar_atividade(primeira))
	assert(estado.atividade_revelada(segunda))
	assert(not estado.atividade_revelada(terceira))
	assert(estado.aplicar_atividade(segunda))
	assert(estado.atividade_revelada(terceira))
	var locais := {primeira.local: true, segunda.local: true, terceira.local: true}
	assert(locais.size() == 3)
	var parque := _atividade(estado, "respirar_0")
	assert(parque.esta_disponivel(23 * 60))

func _testar_agenda_limpa_e_ordenada() -> void:
	var estado := _novo_estado()
	var agenda := estado.obter_tarefas_da_agenda()
	assert(agenda.size() == 1)
	assert(agenda[0].id == "cadeia_0_0")
	assert(agenda[0].hora_inicio == 11)
	assert(estado.aplicar_atividade(agenda[0]))
	agenda = estado.obter_tarefas_da_agenda()
	assert(agenda.size() == 2)
	assert(agenda[0].hora_inicio == 11)
	assert(agenda[1].hora_inicio == 14)
	assert(estado.aplicar_atividade(agenda[1]))
	agenda = estado.obter_tarefas_da_agenda()
	assert(agenda.size() == 3)
	assert(agenda[2].hora_inicio == 17)
	for tarefa in agenda:
		assert(tarefa.id.begins_with("cadeia_"))

func _testar_locais_sorteaveis_existem_no_mapa() -> void:
	var cena: Node2D = load("res://cenas/main.tscn").instantiate()
	var locais_do_mapa := {}
	for nome in ["InteracaoEmpresa", "InteracaoClinica", "InteracaoRestaurante", "InteracaoParque", "InteracaoBiblioteca", "InteracaoBanco"]:
		var ponto = cena.get_node(nome)
		locais_do_mapa[ponto.tipo_local] = true
	for definicao in EstadoPartida.POOL_CADEIA:
		assert(locais_do_mapa.has(definicao.local), "Local sorteável sem ponto de interação: %s" % definicao.local)
	_liberar_arvore(cena)

func _atividade(estado: EstadoPartida, id: String) -> Atividade:
	for atividade in estado.obter_atividades():
		if atividade.id == id:
			return atividade
	return null

func _testar_prazo_perdido_e_esgotamento() -> void:
	var estado := _novo_estado()
	estado.verificar_prazos(9 * 60)
	assert(estado.tarefas_perdidas.has("relatorio"))
	assert(estado.produtividade == 2)
	assert(estado.saude_mental == 5)
	estado.alterar_atributos(0, -4, 0)
	assert(estado.em_esgotamento)
	estado.alterar_atributos(0, 5, 0)
	assert(not estado.em_esgotamento)

func _testar_escolha_exclusiva() -> void:
	var estado := _novo_estado()
	estado.indice_dia = 1
	var hora_extra := _atividade(estado, "hora_extra")
	var tempo_pessoal := _atividade(estado, "tempo_pessoal")
	assert(estado.aplicar_atividade(hora_extra))
	assert(estado.atividade_bloqueada(tempo_pessoal))

func _testar_rota_vencedora_balanceada() -> void:
	var estado := _novo_estado()
	assert(estado.aplicar_atividade(_atividade(estado, "relatorio")))
	estado.encerrar_dia_por_sono(20)
	assert(estado.aplicar_atividade(_atividade(estado, "consulta")))
	assert(estado.aplicar_atividade(_atividade(estado, "remedio")))
	estado.encerrar_dia_por_sono(20)
	assert(estado.aplicar_atividade(_atividade(estado, "reuniao")))
	estado.encerrar_dia_por_sono(20)
	assert(estado.aplicar_atividade(_atividade(estado, "plano")))
	estado.encerrar_dia_por_sono(20)
	estado.finalizar_semana()
	assert(estado.resultado_final)

func _testar_resultados_da_semana() -> void:
	var estado := _novo_estado()
	estado.indice_dia = 4
	estado.produtividade = 8
	estado.energia = 1
	estado.saude_mental = 1
	estado.finalizar_semana()
	assert(estado.resultado_final)

	estado = _novo_estado()
	estado.produtividade = 6
	estado.finalizar_semana()
	assert(not estado.resultado_final)

	estado = _novo_estado()
	estado.produtividade = 8
	estado.energia = 0
	estado.finalizar_semana()
	assert(not estado.resultado_final)
