extends GutTest
## Hito 19: los movimientos propios de los jefes (BossAttack), cada uno con un jefe de prueba que solo
## hace ese movimiento, en la arena.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const PIT_SCENE: PackedScene = preload("res://world/pit.tscn")
const CARNERO: EnemyData = preload("res://content/enemies/carnero.tres")
const BOSS_AT: Vector2 = Vector2(40, -40)
const PLAYER_AT: Vector2 = Vector2(40, 40)

var _game: Game
var _player: Player


func before_each() -> void:
	GameRNG.start_run(4321)
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.global_position = PLAYER_AT
	# Sin las rocas de la arena: así nada tapa las líneas entre el jefe y el jugador.
	for rock: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		rock.free()


## Un movimiento con aviso corto (para que los tests no esperen de más) y una pausa larga al final,
## así el jefe lo hace una sola vez durante el test.
func _attack(kind: BossAttack.Kind) -> BossAttack:
	var attack := BossAttack.new()
	attack.id = &"prueba"
	attack.kind = kind
	attack.windup = 0.1
	attack.recover = 5.0
	attack.warn_time = 0.3
	return attack


## Un jefe quieto que solo hace `attacks` (una fase por lista).
func _boss_with(phases: Array) -> Enemy:
	var data := EnemyData.new()
	data.id = &"jefe_prueba"
	data.max_health = 400.0
	data.spawn_delay = 0.05
	data.body_radius = 10.0
	data.hurtbox_radius = 12.0
	var fraction: float = 1.0
	for attacks: Array in phases:
		var behavior := EnemyData.new()
		behavior.move_style = EnemyData.MoveStyle.STAY
		behavior.attack_range = 400.0
		behavior.attack_cooldown = 0.05
		var boss_phase := BossPhase.new()
		boss_phase.health_fraction = fraction
		boss_phase.behavior = behavior
		boss_phase.attacks.assign(attacks)
		data.phases.append(boss_phase)
		fraction *= 0.5
	return _game.spawn_enemy(data, BOSS_AT)


func _wait_for_state(enemy: Enemy, state: StringName, max_frames: int) -> bool:
	for _frame: int in max_frames:
		if enemy.machine.get_state_name() == state:
			return true
		await wait_physics_frames(1)
	return false


func _strikes() -> Array[BossStrike]:
	var result: Array[BossStrike] = []
	for node: Node in get_tree().get_nodes_in_group(BossStrike.GROUP):
		result.append(node as BossStrike)
	return result


func _hostile_bullets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		if (node as Bullet).is_hostile_to_player():
			count += 1
	return count


func test_boss_uses_its_own_moves_instead_of_the_common_attack() -> void:
	var volley: BossAttack = _attack(BossAttack.Kind.VOLLEY)
	var ring := BulletPatternData.new()
	ring.kind = BulletPatternData.Kind.RING
	ring.count = 8
	volley.pattern = ring
	var boss: Enemy = _boss_with([[volley]])
	assert_true(boss.has_boss_attacks())
	assert_true(await _wait_for_state(boss, &"BossAttack", 60), "ataca con su movimiento")
	assert_eq(boss.attack, volley)
	await wait_physics_frames(12)
	assert_gte(_hostile_bullets(), 8, "dispara el patrón")
	assert_true(await _wait_for_state(boss, &"Recover", 60), "después hace su pausa")


func test_moves_alternate_without_repeating() -> void:
	var first: BossAttack = _attack(BossAttack.Kind.SUMMON)
	var second: BossAttack = _attack(BossAttack.Kind.SUMMON)
	var boss: Enemy = _boss_with([[first, second]])
	await wait_physics_frames(1)
	var last: BossAttack = boss.next_boss_attack()
	for _i: int in 10:
		var next: BossAttack = boss.next_boss_attack()
		assert_ne(next, last, "nunca el mismo dos veces seguidas")
		last = next


func test_debug_can_force_a_move() -> void:
	var first: BossAttack = _attack(BossAttack.Kind.SUMMON)
	var second: BossAttack = _attack(BossAttack.Kind.SUMMON)
	first.recover = 0.1
	var boss: Enemy = _boss_with([[first, second]])
	assert_true(await _wait_for_state(boss, &"Move", 30))
	boss.force_attack(second)
	assert_eq(boss.machine.get_state_name(), &"BossAttack", "lo hace ya")
	assert_eq(boss.attack, second)


func test_debris_falls_where_the_player_is_and_hurts() -> void:
	var debris: BossAttack = _attack(BossAttack.Kind.DEBRIS)
	debris.count = 1
	var boss: Enemy = _boss_with([[debris]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var strikes: Array[BossStrike] = _strikes()
	assert_eq(strikes.size(), 1, "cae un cascote")
	assert_almost_eq(strikes[0].global_position.distance_to(PLAYER_AT), 0.0, 1.0, "justo donde está el jugador")
	assert_false(strikes[0].has_struck(), "primero avisa con la sombra")
	var health: float = _player.health.current
	await wait_physics_frames(25)
	assert_eq(_player.health.current, health - 1.0, "al caer lastima")
	await wait_physics_frames(25)
	assert_eq(_strikes().size(), 0, "después desaparece")


func test_rolling_through_a_strike_avoids_it() -> void:
	var debris: BossAttack = _attack(BossAttack.Kind.DEBRIS)
	var boss: Enemy = _boss_with([[debris]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	_player.health.grant_invulnerability(1.0)
	var health: float = _player.health.current
	await wait_physics_frames(25)
	assert_eq(_strikes().size(), 1)
	assert_true(_strikes()[0].has_struck())
	assert_eq(_player.health.current, health, "invulnerable (rodando) no le pega")


func test_frag_bombs_land_wait_and_burst_into_shrapnel() -> void:
	var bombs: BossAttack = _attack(BossAttack.Kind.FRAG_BOMBS)
	bombs.warn_time = 0.4
	var shrapnel := BulletPatternData.new()
	shrapnel.kind = BulletPatternData.Kind.RING
	shrapnel.count = 6
	bombs.pattern = shrapnel
	var boss: Enemy = _boss_with([[bombs]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var shells: Array[Node] = get_tree().get_nodes_in_group(LobShell.GROUP)
	assert_eq(shells.size(), 1, "tira una bomba")
	assert_eq((shells[0] as LobShell).fuse, 0.4, "con mecha")
	await wait_physics_frames(50)
	assert_eq(get_tree().get_nodes_in_group(LobShell.GROUP).size(), 1, "cayó pero todavía no explota")
	await wait_physics_frames(30)
	assert_eq(get_tree().get_nodes_in_group(LobShell.GROUP).size(), 0, "explotó")
	assert_gte(_hostile_bullets(), 6, "suelta la metralla")
	await wait_physics_frames(10)


func test_dark_claws_turn_off_the_light_hide_and_come_back() -> void:
	var claws: BossAttack = _attack(BossAttack.Kind.DARK_CLAWS)
	claws.count = 2
	claws.interval = 0.2
	claws.darkness = 0.8
	watch_signals(EventBus)
	var boss: Enemy = _boss_with([[claws]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	assert_signal_emitted_with_parameters(EventBus, "darkness_requested", [0.8, claws.windup])
	await wait_physics_frames(12)
	assert_true(boss.is_hidden(), "escondido en la oscuridad")
	assert_eq(boss.visual.self_modulate.a, 0.0, "no se lo ve")
	var strikes: Array[BossStrike] = _strikes()
	assert_gt(strikes.size(), 0, "tira zarpazos")
	assert_ne(strikes[0].slash, Vector2.ZERO, "son tajos")
	assert_true(await _wait_for_state(boss, &"Recover", 120))
	assert_signal_emitted_with_parameters(EventBus, "darkness_requested", [0.0, DarkClawsMove.LIGHT_BACK_TIME])
	assert_false(boss.is_hidden(), "vuelve")
	assert_eq(boss.visual.self_modulate.a, 1.0)
	assert_gt(boss.global_position.distance_to(_player.global_position), 40.0, "lejos del jugador")
	await wait_physics_frames(25)


func test_snipe_moves_away_aims_locks_and_fires() -> void:
	var snipe: BossAttack = _attack(BossAttack.Kind.SNIPE)
	snipe.warn_time = 0.3
	snipe.lock_time = 0.1
	snipe.damage = 2.0
	var boss: Enemy = _boss_with([[snipe]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	var health: float = _player.health.current
	await wait_physics_frames(45)
	assert_gt(boss.global_position.distance_to(_player.global_position), 90.0, "saltó a una punta lejos")
	assert_true(await _wait_for_state(boss, &"Recover", 90), "disparó")
	assert_eq(_player.health.current, health - 2.0, "quieto, el rayo le pega")


func test_rolling_dodges_the_snipe() -> void:
	var snipe: BossAttack = _attack(BossAttack.Kind.SNIPE)
	snipe.warn_time = 0.3
	snipe.lock_time = 0.1
	var boss: Enemy = _boss_with([[snipe]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	var health: float = _player.health.current
	var locked: bool = false
	for _frame: int in 120:
		if boss.beam.is_locked():
			locked = true
			break
		await wait_physics_frames(1)
	assert_true(locked, "la mira se traba")
	# Rueda justo cuando la mira se traba: lo que dura una rodada.
	_player.health.grant_invulnerability(_player.roll_time)
	assert_true(await _wait_for_state(boss, &"Recover", 60))
	assert_eq(_player.health.current, health, "rodando no le pega")


func test_leap_is_untouchable_in_the_air_and_lands_on_the_player() -> void:
	var leap: BossAttack = _attack(BossAttack.Kind.LEAP)
	leap.warn_time = 1.0
	leap.lock_time = 0.1
	leap.radius = 20.0
	var boss: Enemy = _boss_with([[leap]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(20)
	assert_true(boss.is_airborne(), "en el aire")
	assert_true(boss.is_hidden(), "no lo toca nada")
	var health: float = _player.health.current
	assert_true(await _wait_for_state(boss, &"Recover", 120))
	assert_false(boss.is_airborne(), "cayó")
	assert_lt(boss.global_position.distance_to(_player.global_position), 20.0, "encima del jugador")
	assert_eq(_player.health.current, health - 1.0, "lo aplastó")
	await wait_physics_frames(25)


func test_charges_go_at_the_player() -> void:
	var charges: BossAttack = _attack(BossAttack.Kind.CHARGES)
	charges.warn_time = 0.2
	charges.speed = 260.0
	var boss: Enemy = _boss_with([[charges]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	var before: float = boss.global_position.distance_to(_player.global_position)
	assert_true(await _wait_for_state(boss, &"Recover", 120))
	assert_lt(boss.global_position.distance_to(_player.global_position), before - 30.0, "embistió hacia el jugador")


func test_charges_do_not_ram_a_pit_in_the_way() -> void:
	for x: int in [16, 32, 48, 64]:
		var pit := PIT_SCENE.instantiate() as Node2D
		pit.position = Vector2(x, 0)
		_game.world.add_child(pit)
	var charges: BossAttack = _attack(BossAttack.Kind.CHARGES)
	charges.warn_time = 0.2
	var boss: Enemy = _boss_with([[charges]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(2)
	assert_false(boss.has_clear_path(_player.global_position), "el foso tapa el camino")
	assert_true(await _wait_for_state(boss, &"Recover", 30), "corta enseguida, sin embestir")
	assert_lt(boss.global_position.distance_to(BOSS_AT), 4.0, "no se movió hacia el foso")


func test_summon_respects_the_cap() -> void:
	var summon: BossAttack = _attack(BossAttack.Kind.SUMMON)
	summon.summon = CARNERO
	summon.count = 2
	summon.cap = 3
	summon.recover = 0.2
	var boss: Enemy = _boss_with([[summon]])
	for _i: int in 3:
		assert_true(await _wait_for_state(boss, &"BossAttack", 90))
		assert_true(await _wait_for_state(boss, &"Recover", 30))
	assert_eq(boss.living_children(), 3, "no pasa del tope")
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		if node != boss:
			(node as Enemy).health.kill()
	await wait_physics_frames(25)


func test_ground_lines_advance_and_stop_at_the_wall() -> void:
	var lines: BossAttack = _attack(BossAttack.Kind.GROUND_LINES)
	lines.count = 1
	lines.interval = 0.02
	lines.warn_time = 0.2
	lines.look = BossAttack.Look.ROOT
	var boss: Enemy = _boss_with([[lines]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(30)
	var strikes: Array[BossStrike] = _strikes()
	assert_gte(strikes.size(), 4, "una línea de golpes")
	var room: Rect2 = boss.room_rect()
	for strike: BossStrike in strikes:
		assert_true(room.has_point(strike.global_position), "adentro de la sala")
		assert_eq(strike.look, BossAttack.Look.ROOT)
	var farthest: float = 0.0
	for strike: BossStrike in strikes:
		farthest = maxf(farthest, strike.global_position.distance_to(BOSS_AT))
	assert_gt(farthest, BOSS_AT.distance_to(PLAYER_AT) - 10.0, "llega hasta el jugador")
	await wait_physics_frames(40)


func test_sweep_turns_the_beam() -> void:
	var sweep: BossAttack = _attack(BossAttack.Kind.SWEEP)
	sweep.warn_time = 0.1
	sweep.spread = 90.0
	sweep.speed = 360.0
	var boss: Enemy = _boss_with([[sweep]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(14)
	assert_true(boss.beam.is_firing(), "dispara")
	var start: Vector2 = boss.beam_direction
	await wait_physics_frames(6)
	assert_gt(absf(start.angle_to(boss.beam_direction)), 0.3, "va barriendo")
	assert_true(await _wait_for_state(boss, &"Recover", 30))
	assert_false(boss.beam.is_firing(), "termina")


func test_molten_pool_keeps_burning() -> void:
	var molten: BossAttack = _attack(BossAttack.Kind.MOLTEN)
	molten.warn_time = 0.2
	molten.linger = 2.0
	var boss: Enemy = _boss_with([[molten]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	var health: float = _player.health.current
	await wait_physics_frames(25)
	assert_eq(_player.health.current, health - 1.0, "al caer quema")
	await wait_physics_frames(70)
	assert_eq(_player.health.current, health - 2.0, "parado en el charco sigue quemando")
	assert_eq(_strikes().size(), 1, "el charco sigue ahí")


func test_phase_change_interrupts_and_brings_the_light_back() -> void:
	var claws: BossAttack = _attack(BossAttack.Kind.DARK_CLAWS)
	claws.count = 6
	claws.interval = 0.4
	var boss: Enemy = _boss_with([[claws], [_attack(BossAttack.Kind.SUMMON)]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(12)
	assert_true(boss.is_hidden())
	watch_signals(EventBus)
	boss.health.take_damage(250.0)
	boss._update_phase()
	assert_eq(boss.phase, 1)
	assert_signal_emitted_with_parameters(EventBus, "darkness_requested", [0.0, DarkClawsMove.LIGHT_BACK_TIME])
	assert_false(boss.is_hidden(), "aparece")
	assert_eq(boss.visual.self_modulate.a, 1.0)
	await wait_physics_frames(25)


func test_boss_death_clears_its_strikes_and_bombs() -> void:
	var debris: BossAttack = _attack(BossAttack.Kind.DEBRIS)
	debris.count = 3
	debris.interval = 0.05
	debris.warn_time = 2.0
	var boss: Enemy = _boss_with([[debris]])
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(20)
	assert_gt(_strikes().size(), 0)
	boss.health.kill()
	await wait_physics_frames(2)
	assert_eq(_strikes().size(), 0, "se borran con el jefe")
	await wait_physics_frames(25)
