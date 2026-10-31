class_name Main
extends Node
## Raíz del juego y flujo de pantallas: menú principal → run → resumen (al morir o ganar) → menú u
## otra run. También cierra el juego prolijo (corta el audio antes de salir).
## Con --skip-menu o --demo-input (argumentos de usuario) arranca directo en una run.

const MENU_SCENE: PackedScene = preload("res://ui/menus/main_menu.tscn")
const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const SUMMARY_SCENE: PackedScene = preload("res://ui/menus/run_summary.tscn")
## Segundos entre la muerte del jugador y el resumen.
const DEATH_DELAY: float = 1.5
## Espera entre cortar el audio y salir: Godot 4.7 tarda en liberar las reproducciones y, si el
## proceso sale antes, avisa "ObjectDB instances were leaked".
const QUIT_AUDIO_DRAIN: float = 0.5

## Pantalla actual (menú, run o resumen).
var screen: Node
var game: Game
var _quitting: bool = false


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	EventBus.player_died.connect(_on_player_died)
	EventBus.run_ended.connect(finish_run)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--skip-menu" in args or "--demo-input" in args:
		start_run()
	else:
		show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


func show_menu() -> void:
	var menu := MENU_SCENE.instantiate() as MainMenu
	menu.play_requested.connect(start_run)
	menu.quit_requested.connect(quit_game)
	_set_screen(menu)


func start_run() -> void:
	# Con --seed=N todas las runs usan esa seed; si no, cada run tiene una nueva.
	GameRNG.start_run(RngStreams.seed_from_args(OS.get_cmdline_user_args(), RngStreams.random_seed()))
	RunState.start_run()
	game = GAME_SCENE.instantiate() as Game
	game.menu_requested.connect(show_menu)
	game.quit_requested.connect(quit_game)
	_set_screen(game)


## Termina la run y muestra el resumen.
func finish_run(victory: bool) -> void:
	if game == null:
		return
	var summary := SUMMARY_SCENE.instantiate() as RunSummary
	summary.retry_requested.connect(start_run)
	summary.menu_requested.connect(show_menu)
	_set_screen(summary)
	summary.show_summary(victory)


## Cierra el juego: pausa, corta el audio, espera a que Godot lo libere y sale.
func quit_game() -> void:
	if _quitting:
		return
	_quitting = true
	get_tree().paused = true
	AudioManager.stop_all()
	get_tree().create_timer(QUIT_AUDIO_DRAIN, true, false, true).timeout.connect(get_tree().quit)


## Cambia de pantalla: saca la anterior del árbol en el acto (así sus grupos y señales se van ya).
func _set_screen(next: Node) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if screen != null:
		remove_child(screen)
		screen.queue_free()
	game = next as Game
	screen = next
	add_child(next)


func _on_player_died() -> void:
	# Conectado al timer (no con await): si la run ya terminó por otro lado, se ignora.
	var dying_game: Game = game
	get_tree().create_timer(DEATH_DELAY).timeout.connect(func() -> void:
		if game != null and game == dying_game:
			finish_run(false))
