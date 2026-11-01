extends Node
## Punto único para reproducir efectos de sonido y música.
## Al arrancar registra todos los sonidos de la SfxLibrary: los que tienen archivo usan ese archivo,
## el resto se sintetiza con SfxSynth. Si un id no tiene sonido no hace nada, así la lógica no
## depende de que existan los assets.
##
## Cada sonido usa un reproductor libre del pool; si están todos ocupados, el sonido nuevo se omite.
## La música va por el bus "Music" (su volumen es una opción) con dos reproductores, para pasar de un
## tema a otro con un fundido cruzado; sigue sonando con el juego en pausa.
## Al cerrar el juego hay que llamar a stop_all() y esperar ~0.5 s (lo hace Main.quit_game): en
## Godot 4.7 las reproducciones activas o recién terminadas tardan en liberarse y, si el proceso
## sale antes, avisa "ObjectDB instances were leaked".

const POOL_SIZE: int = 16
const LIBRARY: SfxLibrary = preload("res://content/sfx/sfx_library.tres")
const MUSIC_BUS: StringName = &"Music"
## Segundos del fundido cruzado entre temas.
const MUSIC_FADE: float = 1.0
## Nivel de la música respecto de los efectos (los temas están todos al mismo volumen).
const MUSIC_DB: float = -9.0
const SILENT_DB: float = -40.0

## Con false (los tests) recuerda qué tema se pidió pero no lo reproduce.
var music_enabled: bool = true:
	set(value):
		music_enabled = value
		if not value:
			_stop_music_players()

var _streams: Dictionary[StringName, AudioStream] = {}
var _players: Array[AudioStreamPlayer] = []
var _missing_reported: Dictionary[StringName, bool] = {}
var _silenced: bool = false
var _music_players: Array[AudioStreamPlayer] = []
var _music_tweens: Array[Tween] = [null, null]
## Índice del reproductor del tema actual.
var _music_current: int = 0
var _music: AudioStream = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i: int in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	for sfx: SfxData in LIBRARY.sounds:
		register_sfx(sfx.id, sfx.stream if sfx.stream != null else SfxSynth.render(sfx))
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, MUSIC_BUS)
		AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")
	for _i: int in 2:
		var player := AudioStreamPlayer.new()
		player.bus = MUSIC_BUS
		add_child(player)
		_music_players.append(player)


func register_sfx(id: StringName, stream: AudioStream) -> void:
	_streams[id] = stream


func has_sfx(id: StringName) -> bool:
	return _streams.has(id)


## Corta todo lo que suena y no reproduce nada más (antes de cerrar el juego).
func stop_all() -> void:
	_silenced = true
	for player: AudioStreamPlayer in _players:
		player.stop()
	_stop_music_players()


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


## Pasa al tema `stream` con un fundido cruzado de `fade` segundos (null = silencio). Si ya está
## sonando, sigue sin cortarse.
func play_music(stream: AudioStream, fade: float = MUSIC_FADE) -> void:
	if stream == _music:
		return
	_music = stream
	if _silenced or not music_enabled:
		return
	_fade(_music_current, SILENT_DB, fade, true)
	if stream == null:
		return
	_music_current = 1 - _music_current
	var player: AudioStreamPlayer = _music_players[_music_current]
	player.stream = stream
	player.volume_db = SILENT_DB if fade > 0.0 else MUSIC_DB
	player.play()
	_fade(_music_current, MUSIC_DB, fade, false)


func stop_music(fade: float = MUSIC_FADE) -> void:
	play_music(null, fade)


## El tema pedido (aunque la música esté apagada); null = silencio.
func current_music() -> AudioStream:
	return _music


func is_music_playing() -> bool:
	return _music_players[_music_current].playing


## Volumen de la música (opción, 0 a 1).
func set_music_volume(volume: float) -> void:
	var bus: int = AudioServer.get_bus_index(MUSIC_BUS)
	AudioServer.set_bus_mute(bus, volume <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))


func _idle_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in _players:
		if not player.playing:
			return player
	return null


## Lleva el reproductor `index` a `volume_db` en `seconds` (sin tiempo, en el acto) y, si `stop`, lo
## corta al llegar. El fundido no se frena con el hit-stop.
func _fade(index: int, volume_db: float, seconds: float, stop: bool) -> void:
	var player: AudioStreamPlayer = _music_players[index]
	if _music_tweens[index] != null:
		_music_tweens[index].kill()
		_music_tweens[index] = null
	if seconds <= 0.0 or not player.playing:
		player.volume_db = volume_db
		if stop:
			player.stop()
		return
	var tween: Tween = create_tween().set_ignore_time_scale()
	tween.tween_property(player, ^"volume_db", volume_db, seconds)
	if stop:
		tween.tween_callback(player.stop)
	_music_tweens[index] = tween


func _stop_music_players() -> void:
	for index: int in _music_players.size():
		if _music_tweens[index] != null:
			_music_tweens[index].kill()
			_music_tweens[index] = null
		_music_players[index].stop()
