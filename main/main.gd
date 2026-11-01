class_name Main
extends Node
## Raíz del juego y flujo de pantallas: partidas (elegir uno de los cuatro espacios de guardado) →
## menú principal → (la primera vez, la intro) → elegir personaje → run → resumen (al morir o ganar,
## con lo ganado) → menú u otra run. Desde el menú también se va al Taller, a los logros, a las
## opciones (que pueden volver a mostrar la intro) y de vuelta a las partidas.
## Abre el guardado al arrancar y cierra el juego prolijo (corta el audio antes de salir). Fuera de
## la run suena el tema del menú (la run pone el de cada piso).
## Argumentos de usuario: --skip-menu o --demo-input arrancan directo en una run (--skip-menu en la
## última partida); --save=RUTA usa un archivo suelto en vez de las partidas (vacío = memoria); con
## --demo-input (y sin --save) el progreso queda solo en memoria.

const MENU_SCENE: PackedScene = preload("res://ui/menus/main_menu.tscn")
const CHARACTER_SCENE: PackedScene = preload("res://ui/menus/character_select.tscn")
const WORKSHOP_SCENE: PackedScene = preload("res://ui/menus/workshop_menu.tscn")
const ACHIEVEMENTS_SCENE: PackedScene = preload("res://ui/menus/achievements_menu.tscn")
const OPTIONS_SCENE: PackedScene = preload("res://ui/menus/options_menu.tscn")
const INTRO_SCENE: PackedScene = preload("res://ui/menus/intro_screen.tscn")
const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const SUMMARY_SCENE: PackedScene = preload("res://ui/menus/run_summary.tscn")
const SLOTS_SCENE: PackedScene = preload("res://ui/menus/save_slots_menu.tscn")
const MENU_MUSIC: AudioStream = preload("res://content/music/menu.wav")
## En el resumen el tema del menú entra despacio, después del sonido de victoria o derrota.
const SUMMARY_MUSIC_FADE: float = 3.0
const SAVE_ARG: String = "--save="
## Chispas que da el comando de debug.
const DEV_SPARKS: int = 100
## Segundos entre la muerte del jugador y el resumen.
const DEATH_DELAY: float = 1.5
## Espera entre cortar el audio y salir: Godot 4.7 tarda en liberar las reproducciones y, si el
## proceso sale antes, avisa "ObjectDB instances were leaked".
const QUIT_AUDIO_DRAIN: float = 0.5

## Carpeta de las partidas (los argumentos la pisan; vacío = sin partidas, todo en memoria).
@export var save_dir: String = SaveManager.DEFAULT_DIR

## Pantalla actual (un menú, la run o el resumen).
var screen: Node
var game: Game
var _quitting: bool = false


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	get_window().title = MenuBuilder.GAME_TITLE
	get_window().size_changed.connect(_fit_text_to_window)
	_fit_text_to_window()
	EventBus.player_died.connect(_on_player_died)
	EventBus.run_ended.connect(finish_run)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if uses_slots(args):
		SaveManager.use_slots(save_dir)
	else:
		SaveManager.use_slots("")
		SaveManager.open(save_path_from_args(args))
	Debug.add_command(self, "Progreso/+%d chispas" % DEV_SPARKS, SaveManager.add_sparks.bind(DEV_SPARKS))
	Debug.add_command(self, "Progreso/Desbloquear todo", SaveManager.unlock_everything)
	Debug.add_command(self, "Progreso/Borrar progreso", SaveManager.reset_progress)
	if "--skip-menu" in args or "--demo-input" in args:
		if SaveManager.has_slots():
			SaveManager.open_slot(SaveManager.last_slot())
		start_run()
	elif SaveManager.has_slots():
		show_slots()
	else:
		show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


## Sin --save= ni --demo-input se usan las partidas.
static func uses_slots(args: PackedStringArray) -> bool:
	for arg: String in args:
		if arg.begins_with(SAVE_ARG):
			return false
	return not "--demo-input" in args


## El archivo de --save=RUTA; si no hay, vacío (solo en memoria, como con --demo-input).
static func save_path_from_args(args: PackedStringArray) -> String:
	for arg: String in args:
		if arg.begins_with(SAVE_ARG):
			return arg.trim_prefix(SAVE_ARG)
	return ""


## La pantalla de partidas: elegir una la abre y lleva al menú.
func show_slots() -> void:
	var slots_menu := SLOTS_SCENE.instantiate() as SaveSlotsMenu
	slots_menu.slot_chosen.connect(_on_slot_chosen)
	slots_menu.quit_requested.connect(quit_game)
	_set_screen(slots_menu)


func show_menu() -> void:
	var menu := MENU_SCENE.instantiate() as MainMenu
	menu.play_requested.connect(_on_play_requested)
	menu.workshop_requested.connect(show_workshop)
	menu.achievements_requested.connect(show_achievements)
	menu.options_requested.connect(show_options)
	menu.change_slot_requested.connect(_on_change_slot_requested)
	menu.quit_requested.connect(quit_game)
	_set_screen(menu)


## Muestra la intro y después llama a `next` (la intro queda marcada como vista).
func show_intro(next: Callable) -> void:
	var intro := INTRO_SCENE.instantiate() as IntroScreen
	intro.finished.connect(func() -> void:
		SaveManager.mark_intro_seen()
		next.call())
	_set_screen(intro)


func show_character_select() -> void:
	var select := CHARACTER_SCENE.instantiate() as CharacterSelect
	select.character_chosen.connect(start_run)
	select.back_requested.connect(show_menu)
	_set_screen(select)


func show_workshop() -> void:
	var workshop := WORKSHOP_SCENE.instantiate() as WorkshopMenu
	workshop.back_requested.connect(show_menu)
	_set_screen(workshop)


func show_achievements() -> void:
	var achievements := ACHIEVEMENTS_SCENE.instantiate() as AchievementsMenu
	achievements.back_requested.connect(show_menu)
	_set_screen(achievements)


func show_options() -> void:
	var options := OPTIONS_SCENE.instantiate() as OptionsMenu
	options.back_requested.connect(show_menu)
	options.story_requested.connect(show_intro.bind(show_options))
	_set_screen(options)


## Empieza una run con ese personaje (null = el último elegido).
func start_run(character: CharacterData = null) -> void:
	if character == null:
		character = SaveManager.selected_character()
	SaveManager.select_character(character)
	# Con --seed=N todas las runs usan esa seed; si no, cada run tiene una nueva.
	GameRNG.start_run(RngStreams.seed_from_args(OS.get_cmdline_user_args(), RngStreams.random_seed()))
	RunState.start_run(character, SaveManager.profile)
	game = GAME_SCENE.instantiate() as Game
	game.menu_requested.connect(show_menu)
	game.quit_requested.connect(quit_game)
	_set_screen(game)


## Termina la run: la suma al progreso (chispas, logros) y muestra el resumen. Abandonarla desde la
## pausa no pasa por acá: no cuenta.
func finish_run(victory: bool) -> void:
	if game == null:
		return
	AudioManager.play_music(MENU_MUSIC, SUMMARY_MUSIC_FADE)
	var rewards: MetaProfile.RunRewards = SaveManager.record_run(RunState.make_record(victory))
	var summary := SUMMARY_SCENE.instantiate() as RunSummary
	summary.retry_requested.connect(start_run)
	summary.menu_requested.connect(show_menu)
	_set_screen(summary)
	summary.show_summary(victory, rewards)


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
	if game == null:
		AudioManager.play_music(MENU_MUSIC)
	add_child(next)


## Las letras se rasterizan a una resolución que depende del tamaño de la ventana y se agrandan sin
## suavizar (filtro nearest, sin antialiasing): pixeladas, más finas que el mundo y siempre parejas.
func _fit_text_to_window() -> void:
	var window: Window = get_window()
	window.oversampling_override = WindowScales.text_oversampling(WindowScales.scale_for(window.size))


func _on_slot_chosen(slot: int) -> void:
	SaveManager.open_slot(slot)
	show_menu()


func _on_change_slot_requested() -> void:
	SaveManager.close_slot()
	show_slots()


func _on_play_requested() -> void:
	if SaveManager.profile.intro_seen:
		show_character_select()
	else:
		show_intro(show_character_select)


func _on_player_died() -> void:
	# Conectado al timer (no con await): si la run ya terminó por otro lado, se ignora.
	var dying_game: Game = game
	get_tree().create_timer(DEATH_DELAY).timeout.connect(func() -> void:
		if game != null and game == dying_game:
			finish_run(false))
