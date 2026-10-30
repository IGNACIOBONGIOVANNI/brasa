extends Node
## Punto único para reproducir efectos de sonido.
## Si un id no tiene sonido registrado no hace nada, así la lógica no depende de que existan los assets.

const POOL_SIZE: int = 12

var _streams: Dictionary[StringName, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _missing_reported: Dictionary[StringName, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func register_sfx(id: StringName, stream: AudioStream) -> void:
	_streams[id] = stream


func has_sfx(id: StringName) -> bool:
	return _streams.has(id)


## Reproduce el efecto `id`. pitch_jitter varía el tono al azar (cosmético) para que no canse.
func play_sfx(id: StringName, pitch_jitter: float = 0.0) -> void:
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		if not _missing_reported.has(id):
			_missing_reported[id] = true
			print_verbose("AudioManager: todavía no hay sonido para '%s'" % id)
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % POOL_SIZE
	player.stream = stream
	player.pitch_scale = 1.0
	if pitch_jitter > 0.0:
		player.pitch_scale += GameRNG.stream(RngStreams.COSMETIC).randf_range(-pitch_jitter, pitch_jitter)
	player.play()
