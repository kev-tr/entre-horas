extends Node2D


@onready var player = $Player
@onready var hud = $HUD
@onready var relogio = $Relogio


func _ready() -> void:
	player.atributos_alterados.connect(
		hud.atualizar_atributos
	)
	
	relogio.horario_alterado.connect(
		hud.atualizar_relogio
	)
	
	hud.atualizar_atributos(
		player.produtividade,
		player.energia,
		player.saude_mental
	)
