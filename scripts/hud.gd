extends CanvasLayer

signal iniciar_solicitado
signal reiniciar_solicitado
signal continuar_solicitado
signal retomar_solicitado

const MAX_ATRIBUTO := 10
const SEGMENTOS := 10
const COR_PRODUTIVIDADE := Color("3DCC5A")
const COR_ENERGIA := Color("E8B82A")
const COR_SAUDE_MENTAL := Color("3A8FE8")
const COR_SEGMENTO_VAZIO := Color("2A2620")
const COR_BORDA_SEGMENTO := Color("1A1814")
const COR_FUNDO := Color("10151D")
const COR_CARTAO := Color("192433")
const COR_ACENTO := Color("F6C453")

@onready var valor_produtividade: Label = $PainelAtributos/VBox/LinhaProdutividade/ColunaProdutividade/CabecalhoProdutividade/ValorProdutividade
@onready var valor_energia: Label = $PainelAtributos/VBox/LinhaEnergia/ColunaEnergia/CabecalhoEnergia/ValorEnergia
@onready var valor_saude_mental: Label = $PainelAtributos/VBox/LinhaSaudeMental/ColunaSaudeMental/CabecalhoSaudeMental/ValorSaudeMental
@onready var segmentos_produtividade: HBoxContainer = $PainelAtributos/VBox/LinhaProdutividade/ColunaProdutividade/SegmentosProdutividade
@onready var segmentos_energia: HBoxContainer = $PainelAtributos/VBox/LinhaEnergia/ColunaEnergia/SegmentosEnergia
@onready var segmentos_saude_mental: HBoxContainer = $PainelAtributos/VBox/LinhaSaudeMental/ColunaSaudeMental/SegmentosSaudeMental
@onready var label_relogio: Label = %LabelRelogio
@onready var painel_interacao: Control = $PainelInteracao
@onready var label_atividade: Label = $PainelInteracao/VBoxContainer/LabelAtividade
@onready var label_instrucao: Label = $PainelInteracao/VBoxContainer/LabelInstrucao

var estado: EstadoPartida
var personagem: Node2D
var label_dia: Label
var agenda: RichTextLabel
var proxima_tarefa: Label
var agenda_painel: PanelContainer
var inventario: Label
var notificacao: PanelContainer
var toast_titulo: Label
var toast_texto: Label
var overlay: ColorRect
var overlay_caixa: VBoxContainer
var minutos_do_dia := 8 * 60
var pausado := false

func _ready() -> void:
	_montar_segmentos(segmentos_produtividade)
	_montar_segmentos(segmentos_energia)
	_montar_segmentos(segmentos_saude_mental)
	painel_interacao.visible = false
	_criar_interface_semana()

func preparar(novo_estado: EstadoPartida) -> void:
	estado = novo_estado
	estado.atributos_alterados.connect(atualizar_atributos)
	estado.dia_alterado.connect(_atualizar_dia)
	estado.notificacao_recebida.connect(mostrar_mensagem)
	estado.inventario_alterado.connect(_atualizar_inventario)
	estado.agenda_alterada.connect(_atualizar_agenda)

func definir_personagem(novo_personagem: Node2D) -> void:
	personagem = novo_personagem

func _process(delta: float) -> void:
	if personagem == null or agenda_painel == null:
		return
	var posicao_tela: Vector2 = personagem.get_global_transform_with_canvas().origin
	var area_da_agenda := Rect2(agenda_painel.position, agenda_painel.size).grow(28)
	var opacidade_alvo := 0.42 if area_da_agenda.has_point(posicao_tela) else 1.0
	agenda_painel.modulate.a = move_toward(agenda_painel.modulate.a, opacidade_alvo, delta * 3.5)

func atualizar_atributos(produtividade: int, energia: int, saude_mental: int) -> void:
	valor_produtividade.text = "%d/10" % produtividade
	valor_energia.text = "%d/10" % energia
	valor_saude_mental.text = "%d/10" % saude_mental
	_atualizar_segmentos(segmentos_produtividade, produtividade, COR_PRODUTIVIDADE)
	_atualizar_segmentos(segmentos_energia, energia, COR_ENERGIA)
	_atualizar_segmentos(segmentos_saude_mental, saude_mental, COR_SAUDE_MENTAL)

func atualizar_relogio(horario: String) -> void:
	label_relogio.text = horario
	var partes := horario.split(":")
	if partes.size() == 2:
		minutos_do_dia = partes[0].to_int() * 60 + partes[1].to_int()
		_atualizar_agenda()

func mostrar_interacao(nome_atividade: String, descricao := "") -> void:
	label_atividade.text = nome_atividade
	label_instrucao.text = (descricao + "\n" if descricao != "" else "") + "[ESPAÇO] realizar"
	painel_interacao.visible = true

func esconder_interacao() -> void:
	painel_interacao.visible = false

func mostrar_mensagem(titulo: String, descricao: String) -> void:
	toast_titulo.text = titulo
	toast_texto.text = descricao
	notificacao.visible = true
	var timer := get_tree().create_timer(4.0)
	timer.timeout.connect(func(): notificacao.visible = false)

func mostrar_menu(pode_retomar := false) -> void:
	if pode_retomar:
		call_deferred("_adicionar_botao_retomar")
	_montar_overlay("ENTRE HORAS", "Equilibre carreira, Energia e Saúde Mental durante uma semana.\n\nExplore o mapa, aproxime-se de uma Estrutura e pressione ESPAÇO para escolher uma atividade. Dormir na Casa após 20:00 encerra o dia.", "INICIAR SEMANA", func(): iniciar_solicitado.emit(), "INSTRUÇÕES", "Tarefas da agenda mostram o prazo final. TAB alterna escolhas. ESC pausa. Meta: Produtividade 8/10 e Energia e Saúde Mental acima de zero na sexta-feira.")

func _adicionar_botao_retomar() -> void:
	var retomar := Button.new()
	retomar.text = "CONTINUAR SEMANA SALVA"
	retomar.custom_minimum_size = Vector2(0, 44)
	retomar.pressed.connect(func(): retomar_solicitado.emit())
	overlay_caixa.add_child(retomar)

func mostrar_resultado(vitoria: bool, mensagem: String) -> void:
	_montar_overlay("SEMANA CONCLUÍDA" if vitoria else "SEMANA DIFÍCIL", mensagem, "JOGAR NOVAMENTE", func(): reiniciar_solicitado.emit(), "", "")

func esconder_telas() -> void:
	overlay.visible = false

func _atualizar_dia(nome: String, _indice: int) -> void:
	label_dia.text = nome.to_upper()
	_atualizar_agenda()

func _atualizar_inventario(itens: Array[String]) -> void:
	inventario.text = "INVENTÁRIO\n" + (", ".join(itens) if not itens.is_empty() else "Vazio")

func _atualizar_agenda() -> void:
	if estado == null:
		return
	var linhas: Array[String] = ["[b]AGENDA DO DIA[/b]"]
	var proxima := estado.obter_proxima_tarefa(minutos_do_dia)
	if proxima == null:
		proxima_tarefa.text = "PRÓXIMA TAREFA\nNenhuma pendência profissional."
		proxima_tarefa.add_theme_color_override("font_color", Color("B8C7D8"))
	else:
		var restantes := proxima.hora_inicio * 60 - minutos_do_dia
		var cor_urgencia := COR_ACENTO if restantes > 60 else (Color("FF8D5B") if restantes > 30 else Color("F45B69"))
		proxima_tarefa.text = "PRÓXIMA TAREFA\nATÉ %02d:00  %s\nRestam %d min · %s" % [proxima.hora_inicio, proxima.nome, restantes, proxima.local]
		proxima_tarefa.add_theme_color_override("font_color", cor_urgencia)
	for atividade in estado.obter_atividades():
		if atividade.local == "Casa" or atividade.local == "Restaurante Saudável" or atividade.local == "Fast Food" or atividade.local == "Parque":
			continue
		var marca := "✓" if estado.atividades_concluidas.has(atividade.id) else ("✕" if estado.tarefas_perdidas.has(atividade.id) else "•")
		linhas.append("%s ATÉ %02d:00  %s\n   %s" % [marca, atividade.hora_inicio, atividade.nome, atividade.local])
	agenda.text = "\n".join(linhas)

func _criar_interface_semana() -> void:
	label_dia = Label.new()
	label_dia.position = Vector2(24, 178)
	label_dia.add_theme_font_size_override("font_size", 18)
	label_dia.add_theme_color_override("font_color", COR_ACENTO)
	add_child(label_dia)

	agenda_painel = PanelContainer.new()
	agenda_painel.position = Vector2(20, 210)
	agenda_painel.size = Vector2(255, 250)
	agenda_painel.add_theme_stylebox_override("panel", _cartao())
	add_child(agenda_painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	agenda_painel.add_child(caixa)
	proxima_tarefa = Label.new()
	proxima_tarefa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	proxima_tarefa.add_theme_color_override("font_color", COR_ACENTO)
	caixa.add_child(proxima_tarefa)
	agenda = RichTextLabel.new()
	agenda.bbcode_enabled = true
	agenda.fit_content = true
	agenda.custom_minimum_size = Vector2(230, 120)
	caixa.add_child(agenda)
	inventario = Label.new()
	inventario.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caixa.add_child(inventario)

	notificacao = PanelContainer.new()
	notificacao.position = Vector2(410, 20)
	notificacao.size = Vector2(400, 100)
	notificacao.add_theme_stylebox_override("panel", _cartao(COR_ACENTO))
	add_child(notificacao)
	var toast_box := VBoxContainer.new()
	notificacao.add_child(toast_box)
	toast_titulo = Label.new(); toast_titulo.add_theme_font_size_override("font_size", 20); toast_box.add_child(toast_titulo)
	toast_texto = Label.new(); toast_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; toast_box.add_child(toast_texto)
	notificacao.visible = false

	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.05, 0.08, 0.92)
	add_child(overlay)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(centro)
	overlay_caixa = VBoxContainer.new()
	overlay_caixa.custom_minimum_size = Vector2(540, 0)
	overlay_caixa.add_theme_constant_override("separation", 18)
	centro.add_child(overlay_caixa)

func _montar_overlay(titulo: String, texto: String, acao: String, callback: Callable, rotulo_secundario: String, texto_secundario: String) -> void:
	for filho in overlay_caixa.get_children(): filho.queue_free()
	var cabecalho := Label.new()
	cabecalho.text = titulo
	cabecalho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cabecalho.add_theme_font_size_override("font_size", 42)
	cabecalho.add_theme_color_override("font_color", COR_ACENTO)
	overlay_caixa.add_child(cabecalho)
	var descricao := Label.new()
	descricao.text = texto
	descricao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao.add_theme_font_size_override("font_size", 18)
	overlay_caixa.add_child(descricao)
	if rotulo_secundario != "":
		var instrucao := Label.new(); instrucao.text = rotulo_secundario + "\n" + texto_secundario; instrucao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; instrucao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; instrucao.add_theme_color_override("font_color", Color("C5D1DD")); overlay_caixa.add_child(instrucao)
	var botao := Button.new()
	botao.text = acao
	botao.custom_minimum_size = Vector2(0, 52)
	botao.add_theme_font_size_override("font_size", 18)
	botao.pressed.connect(callback)
	overlay_caixa.add_child(botao)
	overlay.visible = true

func mostrar_pausa() -> void:
	pausado = true
	_montar_overlay("PAUSADO", "Confira a agenda, planeje o próximo prazo e retome quando estiver pronto.", "CONTINUAR", func(): continuar_solicitado.emit(), "ATALHOS", "ESC pausa ou continua. R reinicia a semana.")
	var reiniciar := Button.new()
	reiniciar.text = "REINICIAR SEMANA"
	reiniciar.custom_minimum_size = Vector2(0, 44)
	reiniciar.pressed.connect(func(): reiniciar_solicitado.emit())
	overlay_caixa.add_child(reiniciar)

func esconder_pausa() -> void:
	pausado = false
	esconder_telas()

func _montar_segmentos(container: HBoxContainer) -> void:
	for filho in container.get_children(): filho.queue_free()
	for _i in SEGMENTOS:
		var segmento := Panel.new(); segmento.custom_minimum_size = Vector2(14, 12); segmento.size_flags_horizontal = Control.SIZE_EXPAND_FILL; segmento.add_theme_stylebox_override("panel", _estilo_segmento(COR_SEGMENTO_VAZIO)); container.add_child(segmento)

func _atualizar_segmentos(container: HBoxContainer, valor: int, cor_cheia: Color) -> void:
	for i in container.get_child_count():
		container.get_child(i).add_theme_stylebox_override("panel", _estilo_segmento(cor_cheia if i < valor else COR_SEGMENTO_VAZIO))

func _estilo_segmento(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new(); estilo.bg_color = cor; estilo.border_color = COR_BORDA_SEGMENTO; estilo.set_border_width_all(1); estilo.set_corner_radius_all(2); return estilo

func _cartao(borda := Color("32465D")) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new(); estilo.bg_color = COR_CARTAO; estilo.border_color = borda; estilo.set_border_width_all(2); estilo.set_corner_radius_all(10); estilo.content_margin_left = 14; estilo.content_margin_right = 14; estilo.content_margin_top = 12; estilo.content_margin_bottom = 12; return estilo
