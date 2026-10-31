class_name Main
extends Node
## Raíz del juego: arranca una run, la reinicia cuando muere el jugador y cierra el juego prolijo.
## Desde el hito 5 maneja el flujo menú → run → resumen.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
## Segundos entre la muerte del jugador y el reinicio.
const RESTART_DELAY: float = 1.5
## Espera entre cortar el audio y salir: Godot 4.7 tarda en liberar las reproducciones y, si el
## proceso sale antes, avisa "ObjectDB instances were leaked".
const QUIT_AUDIO_DRAIN: float = 0.5

var game: Game
var _quitting: bool = false


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	EventBus.player_died.connect(_on_player_died)
	start_run()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


func start_run() -> void:
	if game != null:
		remove_child(game)
		game.queue_free()
	# Con --seed=N todas las runs usan esa seed; si no, cada run tiene una nueva.
	GameRNG.start_run(RngStreams.seed_from_args(OS.get_cmdline_user_args(), RngStreams.random_seed()))
	RunState.start_run()
	game = GAME_SCENE.instantiate() as Game
	add_child(game)


## Cierra el juego: pausa, corta el audio, espera a que Godot lo libere y sale.
func quit_game() -> void:
	if _quitting:
		return
	_quitting = true
	get_tree().paused = true
	AudioManager.stop_all()
	get_tree().create_timer(QUIT_AUDIO_DRAIN, true, false, true).timeout.connect(get_tree().quit)


func _on_player_died() -> void:
	# Conectado al timer (no con await): si main se libera antes, la conexión desaparece sola.
	get_tree().create_timer(RESTART_DELAY).timeout.connect(start_run)
