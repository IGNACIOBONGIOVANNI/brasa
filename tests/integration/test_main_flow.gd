extends GutTest
## Main: menú → run → resumen (al morir o ganar) → otra run o menú, y la pausa.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

var _main: Main


func before_each() -> void:
	_main = MAIN_SCENE.instantiate() as Main
	_main.save_path = ""
	add_child_autofree(_main)


func after_each() -> void:
	Input.action_release(&"pause")


## Deja que se liberen las pantallas reemplazadas antes de terminar el test (GUT cuenta huérfanos).
func _settle() -> void:
	await wait_physics_frames(2)


func test_starts_on_the_main_menu() -> void:
	assert_true(_main.screen is MainMenu)
	assert_null(_main.game)


func test_death_shows_the_summary_and_retry_starts_a_new_run() -> void:
	_main.start_run()
	var first_game: Game = _main.game
	assert_not_null(first_game, "hay una run")
	first_game.player.health.kill()
	# El resumen aparece DEATH_DELAY después de morir, más el hit-stop de la muerte.
	await wait_physics_frames(roundi(Main.DEATH_DELAY * 60.0) + 30)
	assert_true(_main.screen is RunSummary, "muestra el resumen")
	assert_false(is_instance_valid(first_game) and first_game.is_inside_tree(), "la run salió del árbol")
	_main.start_run()
	assert_true(_main.screen is Game, "otra run")
	assert_eq(_main.game.player.health.current, _main.game.player.health.max_health, "vida llena")
	assert_eq(RunState.blanks, RunState.START_BLANKS, "Pulsos recargados")
	await _settle()


func test_victory_shows_the_summary() -> void:
	_main.start_run()
	await wait_physics_frames(2)
	EventBus.run_ended.emit(true)
	await wait_physics_frames(1)
	assert_true(_main.screen is RunSummary)
	var texts: PackedStringArray = []
	for node: Node in _main.screen.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_has(texts, RunSummary.VICTORY_TEXT, "con el final de la historia")
	await _settle()


func test_pause_freezes_the_game_and_resumes() -> void:
	_main.start_run()
	await wait_physics_frames(2)
	var pause: PauseMenu = _main.game.get_node("PauseMenu") as PauseMenu
	pause.open()
	assert_true(get_tree().paused, "en pausa")
	assert_true(pause.is_open())
	var time: float = RunState.run_time
	await wait_physics_frames(10)
	assert_eq(RunState.run_time, time, "el tiempo de la run no corre en pausa")
	pause.close()
	assert_false(get_tree().paused)
	await _settle()
	await wait_physics_frames(5)
	assert_gt(RunState.run_time, time, "vuelve a correr")
	await _settle()


func test_back_to_menu_from_the_pause() -> void:
	_main.start_run()
	await wait_physics_frames(2)
	_main.game.menu_requested.emit()
	assert_true(_main.screen is MainMenu)
	assert_false(get_tree().paused)
	await _settle()
