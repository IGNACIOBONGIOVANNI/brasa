extends GutTest
## Hito 27: los jefes muestran todos sus ataques aunque la pelea dure poco (eligen primero lo que todavía
## no mostraron, recorren la fase entera antes de repetir y al cambiar de fase atacan enseguida), balas
## de jefe que rebotan, persiguen o se frenan en el aire, y un ataque más por jefe (bolas que giran,
## cerco que se cierra, paredes de balas, paso de sombra).

const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const BOSS_AT: Vector2 = Vector2(0, -30)
const PLAYER_AT: Vector2 = Vector2(30, 40)
const BOSSES: Array[String] = ["campanario", "rey_carnero", "raigon", "yunque", "tijeron", "rey_destronado", "alud", "cierzo"]

var _game: Game
var _player: Player


func before_each() -> void:
	GameRNG.start_run(2468)
	RunState.start_run()
	_game = ARENA_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.global_position = PLAYER_AT
	_player.health.grant_invulnerability(60.0)
	for rock: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		rock.free()


func _attack(id: StringName, kind: BossAttack.Kind) -> BossAttack:
	var attack := BossAttack.new()
	attack.id = id
	attack.kind = kind
	attack.windup = 0.1
	attack.recover = 0.1
	attack.warn_time = 0.4
	attack.count = 2
	attack.interval = 0.3
	attack.radius = 6.0
	attack.speed = 80.0
	attack.spread = 60.0
	attack.linger = 1.0
	return attack


func _boss(phases: Array[Array]) -> Enemy:
	var data := EnemyData.new()
	data.id = &"jefe_prueba"
	data.max_health = 400.0
	data.spawn_delay = 0.05
	data.body_radius = 10.0
	data.hurtbox_radius = 12.0
	data.contact_damage = 0.0
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


# --- Que se vean todos ---------------------------------------------------------------------------


func test_a_phase_shows_every_move_before_repeating() -> void:
	var moves: Array[BossAttack] = []
	for i: int in 5:
		moves.append(_attack(StringName("ataque_%d" % i), BossAttack.Kind.VOLLEY))
	var boss: Enemy = _boss([moves])
	await wait_physics_frames(2)
	var seen: Dictionary[StringName, bool] = {}
	for _i: int in 5:
		seen[boss.next_boss_attack().id] = true
	assert_eq(seen.size(), 5, "en una vuelta salen los cinco, sin repetir")
	seen.clear()
	for _i: int in 5:
		seen[boss.next_boss_attack().id] = true
	assert_gte(seen.size(), 4, "y en la vuelta siguiente también (salvo el que cerró la anterior, que no se repite seguido)")


func test_new_kinds_come_first_and_never_twice_in_a_row() -> void:
	var a := _attack(&"rafaga", BossAttack.Kind.VOLLEY)
	var b := _attack(&"rafaga_2", BossAttack.Kind.VOLLEY)
	var c := _attack(&"onda", BossAttack.Kind.TOLL)
	var boss: Enemy = _boss([[a, b, c]])
	await wait_physics_frames(2)
	var first: BossAttack = boss.next_boss_attack()
	var second: BossAttack = boss.next_boss_attack()
	assert_ne(first.kind, second.kind, "los dos primeros son de tipos distintos: primero lo que no mostró")
	var previous: BossAttack = second
	for _i: int in 12:
		var current: BossAttack = boss.next_boss_attack()
		assert_ne(current, previous, "nunca el mismo dos veces seguidas")
		previous = current


func test_a_new_phase_opens_with_its_new_moves_right_away() -> void:
	var old := _attack(&"vieja", BossAttack.Kind.VOLLEY)
	var old_2 := _attack(&"vieja_2", BossAttack.Kind.DEBRIS)
	var fresh := _attack(&"nueva", BossAttack.Kind.TOLL)
	var boss: Enemy = _boss([[old, old_2], [old, fresh]])
	await wait_physics_frames(2)
	boss.next_boss_attack()
	boss.next_boss_attack()
	boss.hurtbox.receive_hit(HitInfo.create(boss.health.max_health * 0.6, Vector2.UP, 0.0))
	await wait_physics_frames(1)
	assert_eq(boss.phase, 1)
	assert_true(boss.take_phase_rush(), "después de cambiar de fase ataca enseguida")
	assert_false(boss.take_phase_rush(), "una sola vez")
	assert_eq(boss.next_boss_attack().id, &"nueva", "lo primero de la fase nueva es lo que nunca mostró")


func test_every_boss_shows_its_kinds_in_a_short_fight() -> void:
	# Con el elegido nuevo, en tantos ataques como tipos tiene la fase, la fase muestra todos sus tipos.
	for id: String in BOSSES:
		var data := load("res://content/enemies/%s.tres" % id) as EnemyData
		for boss_phase: BossPhase in data.phases:
			var kinds: Dictionary[BossAttack.Kind, bool] = {}
			for attack: BossAttack in boss_phase.attacks:
				kinds[attack.kind] = true
			assert_gte(boss_phase.attacks.size(), 2, "%s: cada fase con al menos dos" % id)
			assert_gte(kinds.size(), 2, "%s: cada fase con al menos dos tipos" % id)


# --- Balas nuevas ---------------------------------------------------------------------------------


func _hostile_bullets() -> Array[Bullet]:
	var result: Array[Bullet] = []
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		if (node as Bullet).is_hostile_to_player():
			result.append(node as Bullet)
	return result


func _shoot(pattern: BulletPatternData, at: Vector2, direction: Vector2) -> Bullet:
	return Bullet.spawn(get_tree(), Bullet.default_scene(), ShotSpec.from_pattern(pattern), at, direction,
			PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL | PhysicsLayers.PLAYER_HURTBOX)


func test_pattern_bullets_can_bounce_home_and_wait() -> void:
	var pattern := BulletPatternData.new()
	pattern.bounces = 2
	pattern.homing = 0.5
	pattern.stall_after = 0.3
	pattern.stall_time = 0.5
	var spec := ShotSpec.from_pattern(pattern)
	assert_eq(spec.bounces, 2)
	assert_eq(spec.homing, 0.5)
	assert_eq(spec.stall_after, 0.3)
	assert_eq(spec.stall_time, 0.5)


func test_waiting_bullets_stop_then_fly_at_the_player() -> void:
	var pattern := BulletPatternData.new()
	pattern.bullet_speed = 100.0
	pattern.bullet_range = 500.0
	pattern.stall_after = 0.2
	pattern.stall_time = 0.4
	var bullet: Bullet = _shoot(pattern, Vector2(-60, -40), Vector2.LEFT)
	await wait_physics_frames(18)
	var stopped_at: Vector2 = bullet.global_position
	await wait_physics_frames(10)
	assert_eq(bullet.global_position, stopped_at, "se frena en el aire")
	await wait_physics_frames(20)
	var to_player: Vector2 = (_player.global_position - stopped_at).normalized()
	var moved: Vector2 = (bullet.global_position - stopped_at).normalized()
	assert_gt(moved.dot(to_player), 0.95, "y después sale derecho hacia el jugador")
	bullet.destroy()
	await wait_physics_frames(2)


func test_homing_enemy_bullets_turn_toward_the_player() -> void:
	var pattern := BulletPatternData.new()
	pattern.bullet_speed = 60.0
	pattern.bullet_range = 500.0
	pattern.homing = 1.0
	var bullet: Bullet = _shoot(pattern, Vector2(-80, 40), Vector2.UP)
	await wait_physics_frames(30)
	var heading: Vector2 = Vector2.from_angle(bullet.rotation)
	assert_gt(heading.dot((_player.global_position - bullet.global_position).normalized()), 0.5, "dobla hacia el jugador")
	bullet.destroy()
	await wait_physics_frames(2)


# --- Movimientos nuevos ---------------------------------------------------------------------------


func _wait_for(group: StringName, check: Callable, max_frames: int) -> Node:
	for _frame: int in max_frames:
		for node: Node in get_tree().get_nodes_in_group(group):
			if check.call(node):
				return node
		await wait_physics_frames(1)
	return null


func test_orbiters_spin_around_the_boss() -> void:
	var attack := _attack(&"badajos", BossAttack.Kind.ORBITERS)
	attack.count = 3
	attack.linger = 2.0
	var boss: Enemy = _boss([[attack, _attack(&"otra", BossAttack.Kind.VOLLEY)]])
	boss.force_attack(attack)
	var ball := await _wait_for(BossMove.HAZARD_GROUP, func(n: Node) -> bool: return n is OrbitBall, 90) as OrbitBall
	assert_not_null(ball, "salen las bolas")
	await wait_physics_frames(3)
	var first: Vector2 = ball.global_position - boss.global_position
	await wait_physics_frames(20)
	var later: Vector2 = ball.global_position - boss.global_position
	assert_gt(absf(first.angle_to(later)), 0.2, "giran alrededor del jefe")


func test_the_thorn_ring_closes_in() -> void:
	var attack := _attack(&"cerco", BossAttack.Kind.CLOSING_RING)
	attack.count = 1
	var boss: Enemy = _boss([[attack, _attack(&"otra", BossAttack.Kind.VOLLEY)]])
	boss.force_attack(attack)
	var ring := await _wait_for(BossMove.HAZARD_GROUP, func(n: Node) -> bool: return n is ShockRing, 90) as ShockRing
	assert_not_null(ring, "aparece el cerco")
	assert_true(ring.thorny, "de espinas")
	var start: float = ring.radius
	await wait_physics_frames(15)
	assert_lt(ring.radius, start, "se cierra hacia el jefe")


func test_bullet_walls_leave_one_gap_near_the_player() -> void:
	var attack := _attack(&"costura", BossAttack.Kind.BULLET_WALL)
	attack.count = 1
	attack.spread = 34.0
	attack.pattern = load("res://content/patterns/tijeron_costura.tres") as BulletPatternData
	var boss: Enemy = _boss([[attack, _attack(&"otra", BossAttack.Kind.TOLL)]])
	boss.force_attack(attack)
	var bullets: Array[Bullet] = []
	for _frame: int in 90:
		bullets = _hostile_bullets()
		if bullets.size() >= 10:
			break
		await wait_physics_frames(1)
	assert_gte(bullets.size(), 10, "sale una pared de balas")
	var xs: Array[float] = []
	for bullet: Bullet in bullets:
		xs.append(bullet.global_position.x)
	xs.sort()
	var widest: float = 0.0
	for i: int in range(1, xs.size()):
		widest = maxf(widest, xs[i] - xs[i - 1])
	assert_gt(widest, attack.spread * 0.8, "con un hueco para pasar")
	for bullet: Bullet in bullets:
		bullet.destroy()
	await wait_physics_frames(2)


func test_shadow_step_reappears_next_to_the_player() -> void:
	var attack := _attack(&"sombra", BossAttack.Kind.BLINK_STRIKE)
	attack.count = 1
	attack.warn_time = 0.5
	var boss: Enemy = _boss([[attack, _attack(&"otra", BossAttack.Kind.VOLLEY)]])
	boss.force_attack(attack)
	var vanished: bool = false
	for _frame: int in 30:
		if boss.is_airborne():
			vanished = true
			break
		await wait_physics_frames(1)
	assert_true(vanished, "se desvanece (ni pega ni recibe)")
	for _frame: int in 60:
		if not boss.is_airborne():
			break
		await wait_physics_frames(1)
	assert_false(boss.is_airborne(), "vuelve")
	assert_lt(boss.global_position.distance_to(_player.global_position), 45.0, "al lado del jugador")
	await wait_physics_frames(25)
