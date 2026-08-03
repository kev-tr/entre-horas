extends Node

const TAXA := 22050

@export var musica_ambiente: AudioStream

var musica: AudioStreamPlayer

func _ready() -> void:
	musica = AudioStreamPlayer.new()
	musica.volume_db = -22.0
	add_child(musica)
	musica.finished.connect(_reiniciar_ambiente)

func iniciar_musica() -> void:
	if musica.playing:
		return
	if musica_ambiente != null:
		musica.stream = musica_ambiente
	else:
		var faixa := _criar_tom(146.83, 4.0, 0.10, [220.0, 293.66])
		faixa.loop_mode = AudioStreamWAV.LOOP_FORWARD
		faixa.loop_end = faixa.data.size() / 2
		musica.stream = faixa
	musica.play()

func parar_musica() -> void:
	musica.stop()

func definir_musica_silenciada(silenciada: bool) -> void:
	musica.volume_db = -80.0 if silenciada else -22.0

func _reiniciar_ambiente() -> void:
	if musica_ambiente != null and musica.stream == musica_ambiente:
		musica.play()

func tocar_confirmacao() -> void:
	_tocar(660.0, 0.10, 0.28)

func tocar_alerta() -> void:
	_tocar(440.0, 0.16, 0.26)

func tocar_erro() -> void:
	_tocar(180.0, 0.28, 0.34)

func tocar_esgotamento() -> void:
	_tocar(95.0, 0.42, 0.30)

func tocar_noite() -> void:
	_tocar(261.63, 0.45, 0.20)

func tocar_resultado(vitoria: bool) -> void:
	_tocar(523.25 if vitoria else 130.81, 0.55, 0.30)

func _tocar(frequencia: float, duracao: float, volume: float) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = _criar_tom(frequencia, duracao, volume)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _criar_tom(frequencia: float, duracao: float, volume: float, harmonicos: Array[float] = []) -> AudioStreamWAV:
	var total := int(TAXA * duracao)
	var dados := PackedByteArray()
	dados.resize(total * 2)
	for indice in total:
		var tempo := float(indice) / TAXA
		var envelope := minf(1.0, tempo * 18.0) * minf(1.0, (duracao - tempo) * 10.0)
		var sinal := sin(TAU * frequencia * tempo)
		for harmonico in harmonicos:
			sinal += sin(TAU * harmonico * tempo) * 0.35
		var amostra := int(clampf(sinal * volume * envelope, -1.0, 1.0) * 32767.0)
		dados[indice * 2] = amostra & 0xff
		dados[indice * 2 + 1] = (amostra >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = TAXA
	stream.data = dados
	return stream
