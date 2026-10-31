extends Node
## Punto único para reproducir efectos de sonido.
## Al arrancar registra todos los sonidos de la SfxLibrary: los que tienen archivo usan ese archivo,
## el resto se sintetiza con SfxSynth. Si un id no tiene sonido no hace nada, así la lógica no
## depende de que existan los assets.
##
## Cada sonido usa un reproductor libre del pool; si están todos ocupados, el sonido nuevo se omite.
## Al cerrar el juego hay que llamar a stop_all() y esperar ~0.5 s (lo hace Main.quit_game): en
## Godot 4.7 las reproducciones activas o recién terminadas tardan en liberarse y, si el proceso
## sale antes, avisa "ObjectDB instances were leaked".

const POOL_SIZE: int = 16
const LIBRARY: SfxLibrary = preload("res://content/sfx/sfx_library.tres")

var _streams: Dictionary[StringName, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _missing_reported: Dictionary[StringName, bool] = {}
var _silenced: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	for sfx: SfxData in LIBRARY.sounds:
		register_sfx(sfx.id, sfx.stream if sfx.stream != null else SfxSynth.render(sfx))


func register_sfx(id: StringName, stream: AudioStream) -> void:
	_streams[id] = stream


func has_sfx(id: StringName) -> bool:
	return _streams.has(id)


## Corta todo lo que suena y no reproduce nada más (antes de cerrar el juego).
func stop_all() -> void:
	_silenced = true
	for player: AudioStreamPlayer in _players:
		player.stop()


## Reproduce el efecto `id`. pitch_jitter varía el tono al azar (cosmético) para que no canse.
func play_sfx(id: StringName, pitch_jitter: float = 0.0) -> void:
	if _silenced:
		return
	var stream: AudioStream = _streams.get(id)
	if stream == null:
		if not _missing_reported.has(id):
			_missing_reported[id] = true
			print_verbose("AudioManager: todavía no hay sonido para '%s'" % id)
		return
	var player: AudioStreamPlayer = _idle_player()
	if player == null:
		return
	player.stream = stream
	player.pitch_scale = 1.0
	if pitch_jitter > 0.0:
		player.pitch_scale += GameRNG.stream(RngStreams.COSMETIC).randf_range(-pitch_jitter, pitch_jitter)
	player.play()


func _idle_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player
	return null
