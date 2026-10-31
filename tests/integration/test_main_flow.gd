extends GutTest
## Main: cuando el jugador muere, la run se reinicia sola.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")


func test_run_restarts_after_player_death() -> void:
	var main := MAIN_SCENE.instantiate() as Main
	add_child_autofree(main)
	var first_game: Game = main.game
	RunState.use_blank()
	first_game.player.health.kill()
	# Reinicia RESTART_DELAY (1.5 s) después de morir, más el hit-stop de la muerte.
	await wait_physics_frames(roundi(Main.RESTART_DELAY * 60.0) + 30)
	assert_ne(main.game, first_game, "hay una run nueva")
	assert_false(is_instance_valid(first_game) and first_game.is_inside_tree(), "la run vieja salió del árbol")
	assert_eq(main.game.player.health.current, main.game.player.health.max_health, "vida llena")
	assert_eq(RunState.blanks, RunState.START_BLANKS, "Pulsos recargados")
