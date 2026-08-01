extends CanvasLayer


const MAX_ATRIBUTO := 100
const SEGMENTOS := 10

const COR_PRODUTIVIDADE := Color("3DCC5A")
const COR_ENERGIA := Color("E8B82A")
const COR_SAUDE_MENTAL := Color("3A8FE8")
const COR_SEGMENTO_VAZIO := Color("2A2620")
const COR_BORDA_SEGMENTO := Color("1A1814")


@onready var valor_produtividade: Label = $PainelAtributos/VBox/LinhaProdutividade/ColunaProdutividade/CabecalhoProdutividade/ValorProdutividade
@onready var valor_energia: Label = $PainelAtributos/VBox/LinhaEnergia/ColunaEnergia/CabecalhoEnergia/ValorEnergia
@onready var valor_saude_mental: Label = $PainelAtributos/VBox/LinhaSaudeMental/ColunaSaudeMental/CabecalhoSaudeMental/ValorSaudeMental

@onready var segmentos_produtividade: HBoxContainer = $PainelAtributos/VBox/LinhaProdutividade/ColunaProdutividade/SegmentosProdutividade
@onready var segmentos_energia: HBoxContainer = $PainelAtributos/VBox/LinhaEnergia/ColunaEnergia/SegmentosEnergia
@onready var segmentos_saude_mental: HBoxContainer = $PainelAtributos/VBox/LinhaSaudeMental/ColunaSaudeMental/SegmentosSaudeMental

@onready var label_relogio: Label = %LabelRelogio

@onready var painel_interacao = $PainelInteracao
@onready var label_atividade = $PainelInteracao/VBoxContainer/LabelAtividade
@onready var label_instrucao = $PainelInteracao/VBoxContainer/LabelInstrucao


func _ready() -> void:
	_montar_segmentos(segmentos_produtividade)
	_montar_segmentos(segmentos_energia)
	_montar_segmentos(segmentos_saude_mental)


func atualizar_atributos(
	produtividade: float,
	energia: float,
	saude_mental: float
) -> void:
	var p := _normalizar(produtividade)
	var e := _normalizar(energia)
	var s := _normalizar(saude_mental)

	valor_produtividade.text = str(p) + " %"
	valor_energia.text = str(e) + " %"
	valor_saude_mental.text = str(s) + " %"

	_atualizar_segmentos(
		segmentos_produtividade,
		p,
		COR_PRODUTIVIDADE
	)

	_atualizar_segmentos(
		segmentos_energia,
		e,
		COR_ENERGIA
	)

	_atualizar_segmentos(
		segmentos_saude_mental,
		s,
		COR_SAUDE_MENTAL
	)


func atualizar_relogio(horario: String) -> void:
	label_relogio.text = horario


func mostrar_interacao(nome_atividade: String) -> void:
	label_atividade.text = nome_atividade
	label_instrucao.text = "Pressione ESPAÇO"
	painel_interacao.visible = true


func esconder_interacao() -> void:
	painel_interacao.visible = false


func _normalizar(valor: float) -> int:
	return clampi(roundi(valor), 0, MAX_ATRIBUTO)


func _montar_segmentos(container: HBoxContainer) -> void:
	for filho in container.get_children():
		filho.queue_free()

	for _i in SEGMENTOS:
		var segmento := Panel.new()
		segmento.custom_minimum_size = Vector2(14, 12)
		segmento.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segmento.add_theme_stylebox_override(
			"panel",
			_estilo_segmento(COR_SEGMENTO_VAZIO)
		)
		container.add_child(segmento)


func _atualizar_segmentos(
	container: HBoxContainer,
	valor: int,
	cor_cheia: Color
) -> void:
	var segmentos_preenchidos := roundi(
		float(valor) / MAX_ATRIBUTO * SEGMENTOS
	)

	var filhos := container.get_children()

	for i in filhos.size():
		var cor := (
			cor_cheia
			if i < segmentos_preenchidos
			else COR_SEGMENTO_VAZIO
		)

		filhos[i].add_theme_stylebox_override(
			"panel",
			_estilo_segmento(cor)
		)


func _estilo_segmento(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.border_color = COR_BORDA_SEGMENTO
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(2)

	return estilo
