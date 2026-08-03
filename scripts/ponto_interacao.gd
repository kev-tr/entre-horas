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
var marcador: Label
var atividades_disponiveis: Array[Atividade] = []
var indice_atividade := 0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_na_area = body
		body.ponto_interacao_atual = self

		if atividade_atual != null:
			mostrar_atividade_atual()
		else:
			hud.mostrar_interacao("Indisponível", "Não há atividade viável aqui agora. Consulte a agenda para o próximo prazo.")

		print("Player entrou em: ", tipo_local)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_na_area = null
		
		if body.ponto_interacao_atual == self:
			body.ponto_interacao_atual = null
			hud.esconder_interacao()

		print("Player saiu de: ", tipo_local)

func definir_atividades(atividades: Array[Atividade]) -> void:
	atividades_disponiveis = atividades
	indice_atividade = mini(indice_atividade, maxi(0, atividades.size() - 1))
	atividade_atual = atividades[indice_atividade] if not atividades.is_empty() else null

func proxima_opcao() -> void:
	if atividades_disponiveis.size() < 2:
		return
	indice_atividade = (indice_atividade + 1) % atividades_disponiveis.size()
	atividade_atual = atividades_disponiveis[indice_atividade]
	if player_na_area != null:
		mostrar_atividade_atual()

func mostrar_atividade_atual() -> void:
	if atividade_atual == null:
		hud.esconder_interacao()
		return
	var complemento := "\n[TAB] outra opção" if atividades_disponiveis.size() > 1 else ""
	hud.mostrar_interacao(atividade_atual.nome, atividade_atual.descricao + complemento)

func destacar_como_proxima(destacar: bool) -> void:
	if marcador == null:
		marcador = Label.new()
		marcador.text = "!"
		marcador.position = Vector2(-10, -142)
		marcador.size = Vector2(20, 26)
		marcador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marcador.z_index = 20
		marcador.add_theme_font_size_override("font_size", 24)
		marcador.add_theme_color_override("font_color", Color("FFD452"))
		marcador.add_theme_color_override("font_outline_color", Color("42191D"))
		marcador.add_theme_constant_override("outline_size", 4)
		add_child(marcador)
	marcador.visible = destacar
