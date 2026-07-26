extends Node2D


@onready var player = $Player
@onready var hud = $HUD


func _ready() -> void:
	player.atributos_alterados.connect(
		hud.atualizar_atributos
	)

	player.emitir_atributos()
