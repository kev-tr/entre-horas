extends Area2D

@onready var hud = $"../HUD"

@export_enum(
	"Empresa",
	"Casa",
	"Restaurante Saudável",
	"Fast Food",
	"Farmácia",
	"Clínica",
	"Parque"
) var tipo_local: String

@export var atividade_atual: Atividade

@export_category("Atividades")
@export var intervalo_minimo_entre_atividades: int = 60

var minuto_inicio_atividade: float = -1.0
var minuto_liberacao_proxima_atividade: float = 0.0

var player_na_area: Node2D = null

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_na_area = body
		body.ponto_interacao_atual = self

		if atividade_atual != null:
			hud.mostrar_interacao(atividade_atual.nome)

		print("Player entrou em: ", tipo_local)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_na_area = null
		
		if body.ponto_interacao_atual == self:
			body.ponto_interacao_atual = null
			hud.esconder_interacao()

		print("Player saiu de: ", tipo_local)
