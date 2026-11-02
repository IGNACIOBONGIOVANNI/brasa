extends GutTest
## Hito 21: lo nuevo del capítulo 2, en la arena. La embestida de Testa, los enemigos del monte
## (rebotar, rondar, embestir en línea recta, tajos, soplidos, esquirlas al morir) y los movimientos de
## sus jefes (tijeretazo, estampida, bola de nieve, cerco de carámbanos y viento).

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const ROCK_SCENE: PackedScene = preload("res://world/rock.tscn")
const TESTA: CharacterData = preload("res://content/characters/testa.tres")
const OVILLO: EnemyData = preload("res://content/enemies/ovillo.tres")
const TIJERETA: EnemyData = preload("res://content/enemies/tijereta.tres")
const PEDRUSCO: EnemyData = preload("res://content/enemies/pedrusco.tres")
const LOBO: EnemyData = preload("res://content/enemies/lobo.tres")
const TEMPANO: EnemyData = preload("res://content/enemies/tempano.tres")
const SOPLO: EnemyData = preload("res://content/enemies/soplo.tres")
const BOSS_AT: Vector2 = Vector2(40, -40)
const PLAYER_AT: Vector2 = Vector2(40, 40)

var _game: Game
var _player: Player


func before_each() -> void:
	GameRNG.start_run(4321)
	RunState.start_run(TESTA)
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.global_position = PLAYER_AT
	for rock: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		rock.free()


func after_each() -> void:
	for action: StringName in [&"move_left", &"move_right", &"move_up", &"move_down", &"dodge"]:
		Input.action_release(action)


## Embiste hacia `direction` (una de las cuatro) y espera a que termine.
func _charge(action: StringName) -> void:
	Input.action_press(action)
	Input.action_press(&"dodge")
	await wait_physics_frames(2)
	Input.action_release(&"dodge")
	await wait_physics_frames(1)
	Input.action_release(action)


func _rock_at(at: Vector2) -> Rock:
	var rock := ROCK_SCENE.instantiate() as Rock
	rock.position = at
	_game.world.add_child(rock)
	return rock


## Un enemigo de prueba que no hace nada (para pegarle).
func _dummy(at: Vector2, shield: float = 0.0) -> Enemy:
	var data := EnemyData.new()
	data.id = &"maniqui"
	data.max_health = 100.0
	data.spawn_delay = 0.05
	data.move_style = EnemyData.MoveStyle.STAY
	data.attack_range = 0.0
	data.contact_damage = 0.0
	data.shield_degrees = shield
	return _game.spawn_enemy(data, at)


func _hostile_bullets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		if (node as Bullet).is_hostile_to_player():
			count += 1
	return count


func _strikes() -> Array[BossStrike]:
	var result: Array[BossStrike] = []
	for node: Node in get_tree().get_nodes_in_group(BossStrike.GROUP):
		result.append(node as BossStrike)
	return result


func _attack(kind: BossAttack.Kind) -> BossAttack:
	var attack := BossAttack.new()
	attack.id = &"prueba"
	attack.kind = kind
	attack.windup = 0.1
	attack.recover = 5.0
	attack.warn_time = 0.3
	return attack


## Un jefe quieto que solo hace `attack`.
func _boss_with(attack: BossAttack) -> Enemy:
	var data := EnemyData.new()
	data.id = &"jefe_prueba"
	data.max_health = 400.0
	data.spawn_delay = 0.05
	data.body_radius = 10.0
	data.hurtbox_radius = 12.0
	data.contact_damage = 0.0
	var behavior := EnemyData.new()
	behavior.move_style = EnemyData.MoveStyle.STAY
	behavior.attack_range = 400.0
	behavior.attack_cooldown = 0.05
	var boss_phase := BossPhase.new()
	boss_phase.behavior = behavior
	boss_phase.attacks.assign([attack])
	data.phases.append(boss_phase)
	return _game.spawn_enemy(data, BOSS_AT)


func _wait_for_state(enemy: Enemy, state: StringName, max_frames: int) -> bool:
	for _frame: int in max_frames:
		if enemy.machine.get_state_name() == state:
			return true
		await wait_physics_frames(1)
	return false


# --- Testa -------------------------------------------------------------------


func test_testa_charges_instead_of_rolling() -> void:
	_player.global_position = Vector2(-90, 0)
	await wait_physics_frames(2)
	Input.action_press(&"move_right")
	Input.action_press(&"dodge")
	await wait_physics_frames(2)
	assert_eq(_player.machine.get_state_name(), &"Charge", "Testa embiste")
	assert_true(_player.health.is_invulnerable(), "invulnerable como al rodar")
	Input.action_release(&"dodge")
	Input.action_release(&"move_right")
	await wait_physics_frames(25)
	assert_eq(_player.machine.get_state_name(), &"Move")
	assert_gt(_player.global_position.x, -90.0 + 60.0, "llega más lejos que una rodada")


func test_the_charge_hurts_each_enemy_once_through_its_shield() -> void:
	_player.global_position = Vector2(-60, 0)
	var dummy: Enemy = _dummy(Vector2(-20, 0), 360.0)
	await wait_physics_frames(10)
	var before: float = dummy.health.current
	await _charge(&"move_right")
	await wait_physics_frames(25)
	assert_almost_eq(before - dummy.health.current, RunState.stats.damage * PlayerChargeState.DAMAGE_FACTOR, 0.01,
			"un golpe de embestida, aunque tenga escudo")


func test_the_charge_breaks_a_rock_and_stops() -> void:
	_player.global_position = Vector2(-60, 0)
	var rock: Rock = _rock_at(Vector2(-30, 0))
	await wait_physics_frames(3)
	await _charge(&"move_right")
	await wait_physics_frames(25)
	assert_true(not is_instance_valid(rock) or rock.is_queued_for_deletion(), "cabeza dura: la roca se rompe")
	assert_lt(_player.global_position.x, -30.0, "y rebota, no la atraviesa")
	await wait_physics_frames(2)


func test_other_characters_still_roll() -> void:
	RunState.start_run()
	_player.global_position = Vector2(-90, 0)
	Input.action_press(&"move_right")
	Input.action_press(&"dodge")
	await wait_physics_frames(2)
	assert_eq(_player.machine.get_state_name(), &"Roll")
	Input.action_release(&"dodge")
	Input.action_release(&"move_right")
	await wait_physics_frames(25)


# --- Enemigos del monte -----------------------------------------------------


func test_yarn_rolls_and_bounces_inside_the_room() -> void:
	var ovillo: Enemy = _game.spawn_enemy(OVILLO, Vector2(-20, 10))
	_player.health.grant_invulnerability(10.0)
	var signs: Dictionary[float, bool] = {}
	for _frame: int in 300:
		await wait_physics_frames(1)
		if ovillo.machine.get_state_name() == &"Move" and absf(ovillo.move_velocity.y) > 1.0:
			signs[signf(ovillo.move_velocity.y)] = true
		assert_true(ovillo.room_rect().grow(2.0).has_point(ovillo.global_position), "no sale de la sala")
	assert_eq(signs.size(), 2, "rebotó: anduvo para arriba y para abajo")


func test_shears_slash_in_front() -> void:
	_player.global_position = Vector2(-60, 0)
	_player.health.grant_invulnerability(10.0)
	_game.spawn_enemy(TIJERETA, Vector2(-40, 0))
	var slash: BossStrike = null
	for _frame: int in 200:
		await wait_physics_frames(1)
		for strike: BossStrike in _strikes():
			if strike.look == BossAttack.Look.BLADE:
				slash = strike
		if slash != null:
			break
	assert_not_null(slash, "tira un tajo")
	if slash == null:
		return
	assert_true(slash.covers(_player.global_position), "justo donde está el jugador")
	assert_eq(slash.damage, TIJERETA.attack_damage)
	assert_ne(slash.slash, Vector2.ZERO, "es un tajo, no un círculo")


func test_boulder_waits_until_aligned_then_rams_and_breaks_rocks() -> void:
	_player.health.grant_invulnerability(10.0)
	_player.global_position = Vector2(-60, -40)
	var pedrusco: Enemy = _game.spawn_enemy(PEDRUSCO, Vector2(60, 30))
	var rock: Rock = _rock_at(Vector2(0, 30))
	await wait_physics_frames(110)
	assert_almost_eq(pedrusco.global_position.x, 60.0, 1.0, "sin alinearse no se mueve")
	_player.global_position = Vector2(-60, 30)
	await wait_physics_frames(90)
	assert_lt(pedrusco.global_position.x, 50.0, "alineado, embiste por la fila")
	assert_almost_eq(pedrusco.global_position.y, 30.0, 1.0, "derecho, sin desviarse")
	assert_true(not is_instance_valid(rock) or rock.is_queued_for_deletion(), "y rompe la roca que choca")


func test_wolf_prowls_around_the_player() -> void:
	var data := LOBO.duplicate() as EnemyData
	data.attack_range = 0.0
	_player.global_position = Vector2(-30, 0)
	_player.health.grant_invulnerability(10.0)
	var lobo: Enemy = _game.spawn_enemy(data, Vector2(40, 0))
	await wait_physics_frames(80)
	var start: float = (lobo.global_position - _player.global_position).angle()
	var turned: float = 0.0
	var last: float = start
	for _frame: int in 120:
		await wait_physics_frames(1)
		var angle: float = (lobo.global_position - _player.global_position).angle()
		turned += absf(wrapf(angle - last, -PI, PI))
		last = angle
	assert_gt(turned, 1.0, "da vueltas alrededor")
	assert_between(lobo.global_position.distance_to(_player.global_position), 25.0, 95.0, "a su distancia")


func test_ice_block_bursts_into_shards() -> void:
	var tempano: Enemy = _game.spawn_enemy(TEMPANO, Vector2(60, 0))
	await wait_physics_frames(3)
	var before: int = _hostile_bullets()
	tempano.health.kill()
	await wait_physics_frames(3)
	assert_gte(_hostile_bullets() - before, TEMPANO.death_pattern.count, "se parte en esquirlas")


func test_gust_pushes_the_player_back() -> void:
	_player.global_position = Vector2(-10, 0)
	_player.health.grant_invulnerability(10.0)
	_game.spawn_enemy(SOPLO, Vector2(60, 0))
	var pushed: bool = false
	for _frame: int in 240:
		await wait_physics_frames(1)
		if _player.global_position.x < -45.0:
			pushed = true
			break
	assert_true(pushed, "el soplido lo empuja para atrás")


# --- Jefes del monte ---------------------------------------------------------


func test_scissors_close_on_the_player() -> void:
	var scissors: BossAttack = _attack(BossAttack.Kind.SCISSORS)
	scissors.spread = 90.0
	scissors.speed = 180.0
	var boss: Enemy = _boss_with(scissors)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var beams: int = 0
	for child: Node in boss.get_children():
		if child is EnemyBeam:
			beams += 1
	assert_eq(beams, 2, "dos hojas")
	var health: float = _player.health.current
	await wait_physics_frames(40)
	assert_lt(_player.health.current, health, "entre las hojas, lo cortan")
	await wait_physics_frames(5)
	assert_ne(boss.machine.get_state_name(), &"BossAttack")
	beams = 0
	for child: Node in boss.get_children():
		if child is EnemyBeam and not child.is_queued_for_deletion():
			beams += 1
	assert_eq(beams, 1, "al terminar se va la hoja de más")


func test_stepping_out_of_the_scissors_is_safe() -> void:
	var scissors: BossAttack = _attack(BossAttack.Kind.SCISSORS)
	scissors.spread = 90.0
	scissors.speed = 180.0
	var boss: Enemy = _boss_with(scissors)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	_player.global_position = Vector2(110, -40)
	var health: float = _player.health.current
	await wait_physics_frames(45)
	assert_eq(_player.health.current, health, "al costado del jefe las hojas no llegan")


func test_stampede_leaves_one_gap() -> void:
	var stampede: BossAttack = _attack(BossAttack.Kind.STAMPEDE)
	stampede.count = 1
	stampede.linger = 0.3
	var boss: Enemy = _boss_with(stampede)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var strikes: Array[BossStrike] = _strikes()
	assert_eq(strikes.size(), 5, "seis franjas, una libre")
	var gap_y: float = INF
	for lane: int in 6:
		var center: float = -72.0 + StampedeMove.LANE * (lane + 0.5)
		var covered: bool = false
		for strike: BossStrike in strikes:
			covered = covered or absf(strike.global_position.y - center) < 1.0
		if not covered:
			gap_y = center
	assert_lt(absf(gap_y - PLAYER_AT.y), StampedeMove.LANE * 2.0, "el hueco queda cerca del jugador")
	_player.global_position = Vector2(PLAYER_AT.x, gap_y)
	var health: float = _player.health.current
	await wait_physics_frames(45)
	assert_eq(_player.health.current, health, "en el hueco pasa la manada sin tocarlo")


func test_stampede_runs_over_whoever_stays() -> void:
	var stampede: BossAttack = _attack(BossAttack.Kind.STAMPEDE)
	stampede.count = 1
	stampede.linger = 0.3
	var boss: Enemy = _boss_with(stampede)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var covered_y: float = _strikes()[0].global_position.y
	_player.global_position = Vector2(PLAYER_AT.x, covered_y)
	var health: float = _player.health.current
	await wait_physics_frames(45)
	assert_lt(_player.health.current, health, "en una franja lo atropellan")


func test_snowball_rolls_breaks_rocks_bounces_and_hurts() -> void:
	var snowball: BossAttack = _attack(BossAttack.Kind.SNOWBALL)
	snowball.radius = 8.0
	snowball.speed = 200.0
	snowball.linger = 2.0
	var rock: Rock = _rock_at(Vector2(40, 0))
	var boss: Enemy = _boss_with(snowball)
	var health: float = _player.health.current
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var balls: Array[Node] = get_tree().get_nodes_in_group(RollingBall.GROUP)
	assert_eq(balls.size(), 1, "rueda una bola")
	var ball := balls[0] as RollingBall
	var going_down: bool = ball.velocity.y > 0.0
	await wait_physics_frames(40)
	assert_true(not is_instance_valid(rock) or rock.is_queued_for_deletion(), "rompe la roca del camino")
	assert_lt(_player.health.current, health, "pasa por encima del jugador")
	assert_true(going_down and ball.velocity.y < 0.0, "rebotó en la pared de abajo")
	await wait_physics_frames(120)
	assert_eq(get_tree().get_nodes_in_group(RollingBall.GROUP).size(), 0, "después se deshace")


func test_ice_cage_rings_the_player_and_crushes_the_middle() -> void:
	var cage: BossAttack = _attack(BossAttack.Kind.ICE_CAGE)
	cage.count = 10
	cage.spread = 34.0
	cage.radius = 7.0
	cage.linger = 1.0
	var boss: Enemy = _boss_with(cage)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var strikes: Array[BossStrike] = _strikes()
	assert_eq(strikes.size(), 9, "ocho carámbanos en ronda (dos de hueco) y uno grande")
	var big: BossStrike = null
	for strike: BossStrike in strikes:
		if strike.radius > cage.radius:
			big = strike
	assert_not_null(big)
	assert_almost_eq(big.global_position.distance_to(PLAYER_AT), 0.0, 1.0, "el grande cae donde está")
	var health: float = _player.health.current
	await wait_physics_frames(45)
	assert_lt(_player.health.current, health, "quedarse en el medio lastima")


func test_the_ice_cage_gap_lets_the_player_out() -> void:
	var cage: BossAttack = _attack(BossAttack.Kind.ICE_CAGE)
	cage.count = 10
	cage.spread = 34.0
	cage.radius = 7.0
	var boss: Enemy = _boss_with(cage)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	# El hueco: el lugar de la ronda más lejos de todos los carámbanos.
	var best: Vector2 = Vector2.ZERO
	var best_gap: float = 0.0
	for step: int in 72:
		var direction := Vector2.from_angle(TAU * step / 72.0)
		var at: Vector2 = PLAYER_AT + direction * cage.spread
		var nearest: float = INF
		for strike: BossStrike in _strikes():
			if strike.radius <= cage.radius:
				nearest = minf(nearest, strike.global_position.distance_to(at))
		if nearest > best_gap:
			best_gap = nearest
			best = direction
	_player.global_position = PLAYER_AT + best * (cage.spread + 6.0)
	var health: float = _player.health.current
	await wait_physics_frames(45)
	assert_eq(_player.health.current, health, "saliendo por el hueco no lo toca nada")


func test_the_gale_pushes_the_player() -> void:
	var gust: BossAttack = _attack(BossAttack.Kind.GUST)
	gust.warn_time = 0.2
	gust.linger = 0.8
	gust.speed = 80.0
	_player.global_position = Vector2(40, -10)
	var boss: Enemy = _boss_with(gust)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(65)
	assert_gt(_player.global_position.y, 30.0, "el viento lo lleva lejos del jefe")


func test_boss_death_clears_its_snowballs() -> void:
	var snowball: BossAttack = _attack(BossAttack.Kind.SNOWBALL)
	snowball.linger = 5.0
	var boss: Enemy = _boss_with(snowball)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	assert_eq(get_tree().get_nodes_in_group(RollingBall.GROUP).size(), 1)
	boss.health.kill()
	await wait_physics_frames(2)
	assert_eq(get_tree().get_nodes_in_group(RollingBall.GROUP).size(), 0, "la bola se va con el jefe")
