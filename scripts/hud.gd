extends CanvasLayer


@onready var barra_produtividade: ProgressBar = %BarraProdutividade
@onready var barra_energia: ProgressBar = %BarraEnergia
@onready var barra_saude_mental: ProgressBar = %BarraSaudeMental


func atualizar_atributos(
	produtividade: float,
	energia: float,
	saude_mental: float
) -> void:
	barra_produtividade.value = produtividade
	barra_energia.value = energia
	barra_saude_mental.value = saude_mental
