extends CanvasLayer


@onready var barra_produtividade: ProgressBar = %BarraProdutividade
@onready var barra_energia: ProgressBar = %BarraEnergia
@onready var barra_saude_mental: ProgressBar = %BarraSaudeMental

@onready var valor_produtividade: Label = %ValorProdutividade
@onready var valor_energia: Label = %ValorEnergia
@onready var valor_saude_mental: Label = %ValorSaudeMental

@onready var label_relogio: Label = %LabelRelogio

@onready var painel_interacao = $PainelInteracao
@onready var label_atividade = $PainelInteracao/VBoxContainer/LabelAtividade
@onready var label_instrucao = $PainelInteracao/VBoxContainer/LabelInstrucao


func atualizar_atributos(
	produtividade: float,
	energia: float,
	saude_mental: float
) -> void:
	barra_produtividade.value = produtividade
	barra_energia.value = energia
	barra_saude_mental.value = saude_mental
	
	valor_produtividade.text = str(int(produtividade)) + " %"
	valor_energia.text = str(int(energia)) + " %"
	valor_saude_mental.text = str(int(saude_mental)) + " %"

func atualizar_relogio(horario: String) -> void:
	label_relogio.text = horario
	
func mostrar_interacao(nome_atividade: String) -> void:
	label_atividade.text = nome_atividade
	label_instrucao.text = "Pressione ESPAÇO"
	painel_interacao.visible = true

func esconder_interacao() -> void:
	painel_interacao.visible = false
