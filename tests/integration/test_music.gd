extends GutTest
## Hito 14: la música. El tema del menú fuera de la run, el de cada piso, el del jefe mientras vive,
## silencio al morir, el volumen de la música en Opciones y que de verdad suene y pase de un tema a
## otro con un fundido. En los tests la música no suena (pre_run_hook): se mira qué tema se pidió,
## salvo en la prueba de reproducción.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const RUN: RunConfig = preload("res://content/run/run_config.tres")
const SEED: int = 1234


func before_each() -> void:
	AudioManager.stop_music(0.0)


func after_each() -> void:
	AudioManager.music_enabled = false
	AudioManager.stop_music(0.0)


func _start_floor() -> Game:
	GameRNG.start_run(SEED)
	RunState.start_run()
	var game := GAME_SCENE.instantiate() as Game
	add_child_autofree(game)
	game.player.health.always_invulnerable = true
	return game


func _boss() -> Enemy:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		if (node as Enemy).is_boss():
			return node as Enemy
	return null


func test_floors_and_bosses_have_their_music() -> void:
	for theme: FloorTheme in RUN.floors:
		assert_not_null(theme.music, "%s: tiene tema" % theme.id)
		assert_not_null(theme.boss_music, "%s: tiene tema de jefe" % theme.id)
	assert_ne(RUN.floors[0].music, RUN.floors[1].music, "cada piso suena distinto")


func test_menu_screens_play_the_menu_theme() -> void:
	var main := MAIN_SCENE.instantiate() as Main
	main.save_dir = ""
	add_child_autofree(main)
	assert_eq(AudioManager.current_music(), Main.MENU_MUSIC, "menú principal")
	main.start_run()
	await wait_physics_frames(2)
	assert_eq(AudioManager.current_music(), RUN.floors[0].music, "la run pone el tema del piso")
	main.show_options()
	assert_eq(AudioManager.current_music(), Main.MENU_MUSIC, "fuera de la run vuelve el del menú")
	# La pantalla anterior se libera al final del cuadro.
	await wait_physics_frames(2)


func test_boss_music_while_the_boss_lives_and_silence_on_death() -> void:
	var game: Game = _start_floor()
	var floor_controller: FloorController = game.floor_controller
	assert_eq(AudioManager.current_music(), RUN.floors[0].music)
	await floor_controller.move_to(floor_controller.layout.first_of_kind(RoomSlot.Kind.BOSS))
	await wait_physics_frames(2)
	assert_eq(AudioManager.current_music(), RUN.floors[0].boss_music, "apareció el jefe")
	_boss().health.kill()
	await wait_physics_frames(2)
	assert_eq(AudioManager.current_music(), RUN.floors[0].music, "vencido, vuelve el del piso")
	game.player.health.always_invulnerable = false
	game.player.health.kill()
	await wait_physics_frames(2)
	assert_null(AudioManager.current_music(), "al morir se apaga")


func test_each_floor_plays_its_own_theme() -> void:
	var game: Game = _start_floor()
	game.floor_controller.load_floor(2)
	await wait_physics_frames(2)
	assert_eq(AudioManager.current_music(), RUN.floors[2].music)


func test_options_change_the_music_volume() -> void:
	var main := MAIN_SCENE.instantiate() as Main
	main.save_dir = ""
	add_child_autofree(main)
	main.show_options()
	await wait_physics_frames(2)
	var options := main.screen as OptionsMenu
	var bus: int = AudioServer.get_bus_index(AudioManager.MUSIC_BUS)
	assert_almost_eq(SaveManager.options.music_volume, GameOptions.DEFAULT_MUSIC_VOLUME, 0.0001)
	options.change_music_volume(-OptionsMenu.VOLUME_STEP)
	assert_almost_eq(SaveManager.options.music_volume, 0.7, 0.0001)
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.7), 0.01, "se aplicó al bus de la música")
	assert_almost_eq(AudioServer.get_bus_volume_db(SaveManager.MASTER_BUS), linear_to_db(SaveManager.options.volume), 0.01, "el general no cambia")
	for _i: int in 10:
		options.change_music_volume(-OptionsMenu.VOLUME_STEP)
	assert_eq(SaveManager.options.music_volume, 0.0)
	assert_true(AudioServer.is_bus_mute(bus), "en 0 % no suena")
	assert_string_contains(_labels(options), "Música 0 %")
	SaveManager.set_music_volume(GameOptions.DEFAULT_MUSIC_VOLUME)


func _labels(root: Node) -> String:
	var lines: PackedStringArray = []
	for node: Node in root.find_children("*", "Label", true, false):
		lines.append((node as Label).text)
	return "\n".join(lines)


func _playing_music_players() -> int:
	var playing: int = 0
	for node: Node in AudioManager.get_children():
		var player := node as AudioStreamPlayer
		if player.bus == AudioManager.MUSIC_BUS and player.playing:
			playing += 1
	return playing


func test_music_really_plays_and_crossfades() -> void:
	AudioManager.music_enabled = true
	AudioManager.play_music(RUN.floors[0].music, 0.0)
	assert_true(AudioManager.is_music_playing(), "suena")
	AudioManager.play_music(RUN.floors[0].music)
	assert_eq(_playing_music_players(), 1, "pedir el mismo tema no lo reinicia")
	AudioManager.play_music(RUN.floors[0].boss_music, 0.2)
	assert_eq(_playing_music_players(), 2, "durante el fundido suenan los dos")
	await wait_seconds(0.4)
	assert_eq(_playing_music_players(), 1, "después queda solo el nuevo")
	assert_true(AudioManager.is_music_playing())
	AudioManager.music_enabled = false
	assert_eq(_playing_music_players(), 0, "apagar la música la corta")
	# Que Godot libere las reproducciones antes de seguir (si no, avisa al cerrar).
	await wait_seconds(0.6)
