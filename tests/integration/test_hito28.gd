extends GutTest
## Hito 28: cada jefe entra a su sala con una cinemática propia (BossIntro): mientras dura el jugador
## mira (quieto, sin disparar, con franjas negras), el jefe no pega ni recibe y la barra aparece al
## terminar. Se puede saltear y nunca deja al jugador trabado.

const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const BOSS_AT: Vector2 = Vector2(0, -30)
const PLAYER_AT: Vector2 = Vector2(30, 40)
const BOSSES: Array[String] = ["campanario", "rey_carnero", "raigon", "yunque", "tijeron", "rey_destronado", "alud", "cierzo"]
## Lo más que puede durar una entrada (con margen).
const MAX_INTRO: float = 4.0

var _game: Game
var _player: Player


func before_each() -> void:
	GameRNG.start_run(2828)
	RunState.start_run()
	_game = ARENA_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.global_position = PLAYER_AT
	_player.health.grant_invulnerability(60.0)


func after_each() -> void:
	for action: StringName in [&"ui_accept", &"move_right", &"shoot"]:
		Input.action_release(action)


func _data(id: String) -> EnemyData:
	return load("res://content/enemies/%s.tres" % id) as EnemyData


## Pone un jefe como lo hace la sala del jefe (con su entrada).
func _spawn_with_intro(id: String) -> Enemy:
	var boss := Game.ENEMY_SCENE.instantiate() as Enemy
	boss.data = _data(id)
	boss.play_intro = true
	boss.position = BOSS_AT
	_player.get_parent().add_child(boss)
	return boss


func _intro_of(boss: Enemy) -> BossIntro:
	for child: Node in boss.get_children():
		if child is BossIntro:
			return child as BossIntro
	return null


func test_every_boss_has_its_own_entrance() -> void:
	var seen: Dictionary[EnemyData.Intro, String] = {}
	for id: String in BOSSES:
		var intro: EnemyData.Intro = _data(id).intro
		assert_ne(intro, EnemyData.Intro.NONE, "%s tiene entrada" % id)
		assert_false(seen.has(intro), "%s no repite la entrada de %s" % [id, seen.get(intro, "")])
		seen[intro] = id
		assert_true(BossIntro.DURATIONS.has(intro), "la entrada de %s dice cuánto dura" % id)


func test_minibosses_and_normal_enemies_appear_as_always() -> void:
	for id: String in ["carnero_veterano", "grasa_erizada", "pehuen", "bigornia", "carnero"]:
		assert_eq(_data(id).intro, EnemyData.Intro.NONE, "%s aparece sin cinemática" % id)


func test_the_boss_room_asks_for_the_entrance() -> void:
	var source: String = FileAccess.get_file_as_string("res://world/room.gd")
	assert_string_contains(source, "enemy.play_intro = slot.kind == RoomSlot.Kind.BOSS")


func test_a_boss_without_play_intro_appears_at_once() -> void:
	watch_signals(EventBus)
	var boss := _game.spawn_enemy(_data("raigon"), BOSS_AT)
	await wait_physics_frames(2)
	assert_false(boss.in_intro(), "sin la sala del jefe no hay entrada")
	assert_null(_intro_of(boss))
	assert_signal_emitted(EventBus, "boss_spawned")
	assert_false(_player.in_cinematic())


func test_the_entrance_locks_the_player_and_the_bar_comes_after() -> void:
	watch_signals(EventBus)
	var boss := _spawn_with_intro("raigon")
	await wait_physics_frames(3)
	assert_true(boss.in_intro(), "está entrando")
	assert_not_null(_intro_of(boss))
	assert_true(_player.in_cinematic(), "el jugador mira")
	assert_true(boss.is_airborne(), "mientras entra no pega ni recibe")
	assert_signal_emitted(EventBus, "boss_intro_started")
	assert_signal_emitted_with_parameters(EventBus, "cinematic_changed", [true])
	assert_signal_not_emitted(EventBus, "boss_spawned", "la barra todavía no")
	assert_true((_game.get_node("Hud") as Hud).cinematic_bars.is_showing(), "franjas negras")
	# No camina ni dispara aunque se aprieten las teclas.
	var before: Vector2 = _player.global_position
	Input.action_press(&"move_right")
	Input.action_press(&"shoot")
	await wait_physics_frames(20)
	Input.action_release(&"move_right")
	Input.action_release(&"shoot")
	assert_almost_eq(_player.global_position.x, before.x, 0.5, "quieto")
	assert_eq(get_tree().get_nodes_in_group(Bullet.GROUP).size(), 0, "sin balas")
	await wait_until(func() -> bool: return not boss.in_intro(), MAX_INTRO)
	assert_false(boss.in_intro(), "terminó sola")
	assert_false(_player.in_cinematic(), "el jugador vuelve a moverse")
	assert_false(boss.is_airborne())
	assert_signal_emit_count(EventBus, "boss_spawned", 1)
	assert_signal_emitted_with_parameters(EventBus, "cinematic_changed", [false])
	assert_null(_intro_of(boss), "la cinemática se fue")
	await wait_physics_frames(2)


func test_the_boss_waits_a_moment_after_its_entrance() -> void:
	var boss := _spawn_with_intro("campanario")
	await wait_until(func() -> bool: return not boss.in_intro(), MAX_INTRO)
	assert_eq(boss.machine.get_state_name(), &"Idle", "no ataca en el mismo instante en que termina")
	await wait_seconds(EnemyIdleState.AFTER_INTRO + 0.2)
	assert_ne(boss.machine.get_state_name(), &"Idle", "después pelea")


func test_enter_skips_the_entrance() -> void:
	watch_signals(EventBus)
	var boss := _spawn_with_intro("cierzo")
	await wait_seconds(BossIntro.SKIP_AFTER + 0.1)
	assert_true(boss.in_intro())
	Input.action_press(&"ui_accept")
	await wait_physics_frames(2)
	Input.action_release(&"ui_accept")
	assert_false(boss.in_intro(), "Enter la saltea")
	assert_false(_player.in_cinematic())
	assert_signal_emit_count(EventBus, "boss_spawned", 1)
	assert_eq(boss.flash.fade, 1.0, "se ve entero")
	assert_eq(boss.visual.intro_scale, Vector2.ONE, "de su tamaño")
	await wait_physics_frames(2)


func test_a_press_right_away_does_not_skip_it() -> void:
	var boss := _spawn_with_intro("alud")
	Input.action_press(&"ui_accept")
	await wait_physics_frames(3)
	Input.action_release(&"ui_accept")
	assert_true(boss.in_intro(), "un toque de más al entrar no la corta")
	boss.queue_free()
	await wait_physics_frames(2)


func test_a_boss_that_leaves_mid_entrance_never_traps_the_player() -> void:
	watch_signals(EventBus)
	var boss := _spawn_with_intro("rey_carnero")
	await wait_physics_frames(10)
	assert_true(_player.in_cinematic())
	assert_signal_emitted_with_parameters(EventBus, "darkness_requested", [0.92, 0.2], 0)
	boss.queue_free()
	await wait_physics_frames(2)
	assert_false(_player.in_cinematic(), "el jugador queda libre")
	assert_signal_emitted_with_parameters(EventBus, "darkness_requested", [0.0, 0.3], 1)


func test_every_entrance_plays_to_the_end_and_leaves_the_boss_as_it_was() -> void:
	for id: String in BOSSES:
		watch_signals(EventBus)
		var boss := _spawn_with_intro(id)
		await wait_physics_frames(2)
		assert_true(boss.in_intro(), "%s entra" % id)
		await wait_until(func() -> bool: return not boss.in_intro(), MAX_INTRO)
		assert_false(boss.in_intro(), "%s terminó su entrada" % id)
		assert_false(_player.in_cinematic(), "%s suelta al jugador" % id)
		assert_eq(boss.flash.fade, 1.0, "%s se ve entero" % id)
		assert_eq(boss.visual.intro_scale, Vector2.ONE, "%s de su tamaño" % id)
		assert_eq(boss.visual.rotation, 0.0, "%s derecho" % id)
		assert_almost_eq(boss.global_position.distance_to(BOSS_AT), 0.0, 2.0, "%s en su lugar" % id)
		if get_signal_emit_count(EventBus, "darkness_requested") > 0:
			assert_eq(get_signal_parameters(EventBus, "darkness_requested")[0], 0.0, "%s deja la luz como estaba" % id)
		boss.free()
		await wait_physics_frames(1)
	await wait_physics_frames(2)
