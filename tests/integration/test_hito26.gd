extends GutTest
## Hito 26: la opción de temblor de pantalla, fosos que se leen como pozos (con su borde por afuera),
## un ataque único nuevo para cada jefe (onda con hueco, corona-bumerán, raíces que persiguen, cruz de
## rayos, ovillos con hilo, ecos de la embestida, espiral de carámbanos y el ojo del huracán) y los
## dibujos propios de los jefes.

const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const META: MetaConfig = preload("res://content/meta/meta_config.tres")
const NEW_KINDS: Dictionary[StringName, BossAttack.Kind] = {
	&"campanario": BossAttack.Kind.TOLL, &"rey_carnero": BossAttack.Kind.CROWN_BOOMERANG,
	&"raigon": BossAttack.Kind.BURROWERS, &"yunque": BossAttack.Kind.BEAM_CROSS,
	&"tijeron": BossAttack.Kind.THREAD_TRAIL, &"rey_destronado": BossAttack.Kind.ECHO_CHARGES,
	&"alud": BossAttack.Kind.ICE_SPIRAL, &"cierzo": BossAttack.Kind.VORTEX,
}
const BOSS_AT: Vector2 = Vector2(0, -30)
const PLAYER_AT: Vector2 = Vector2(30, 40)

var _game: Game
var _player: Player


func before_each() -> void:
	GameRNG.start_run(2468)
	RunState.start_run()
	_game = ARENA_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.global_position = PLAYER_AT
	for rock: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		rock.free()


func after_each() -> void:
	SaveManager.options.screen_shake = 1.0


func _attack(kind: BossAttack.Kind) -> BossAttack:
	var attack := BossAttack.new()
	attack.id = &"prueba"
	attack.kind = kind
	attack.windup = 0.1
	attack.recover = 5.0
	attack.warn_time = 0.4
	attack.count = 2
	attack.interval = 0.3
	attack.radius = 6.0
	attack.speed = 80.0
	attack.spread = 60.0
	attack.linger = 1.0
	return attack


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


## Espera hasta que haya algo de `type` en los peligros sueltos del jefe (o en `group`).
func _wait_for(group: StringName, check: Callable, max_frames: int) -> Node:
	for _frame: int in max_frames:
		for node: Node in get_tree().get_nodes_in_group(group):
			if check.call(node):
				return node
		await wait_physics_frames(1)
	return null


# --- Opciones y fosos ------------------------------------------------------------------------


func test_screen_shake_option_saves_and_cycles() -> void:
	var options := GameOptions.new()
	assert_eq(options.screen_shake, 1.0, "arranca fuerte")
	assert_eq(GameOptions.next_shake(1.0), 0.5, "fuerte → suave")
	assert_eq(GameOptions.next_shake(0.5), 0.0, "suave → no")
	assert_eq(GameOptions.next_shake(0.0), 1.0, "no → fuerte")
	options.screen_shake = 0.0
	assert_eq(GameOptions.from_dict(options.to_dict()).screen_shake, 0.0, "se guarda")
	assert_eq(GameOptions.from_dict({"screen_shake": 0.4}).screen_shake, 0.5, "un valor raro queda en el más cercano")
	assert_eq(GameOptions.shake_name(0.0), "no")


func test_no_shake_means_a_still_camera() -> void:
	var camera := get_tree().get_first_node_in_group(&"camera") as GameCamera
	if camera == null:
		for node: Node in _game.find_children("*", "Camera2D", true, false):
			camera = node as GameCamera
	assert_not_null(camera)
	SaveManager.options.screen_shake = 0.0
	EventBus.shake_requested.emit(1.0)
	assert_eq(camera.trauma(), 0.0, "sin temblor la explosión no mueve la cámara")
	SaveManager.options.screen_shake = 0.5
	EventBus.shake_requested.emit(0.8)
	assert_almost_eq(camera.trauma(), 0.4, 0.001, "suave: la mitad")


func test_pits_know_which_sides_face_the_floor() -> void:
	var grid: RoomGrid = RoomTemplateParser.parse("""...............
...............
...............
.....oo........
.....oo........
...............
...............
...............
...............""")
	var top_left: int = RoomBuilder.pit_edges(grid, Vector2i(5, 3))
	assert_eq(top_left, SceneryDrawing.PIT_UP | SceneryDrawing.PIT_LEFT, "arriba a la izquierda: borde arriba y a la izquierda")
	var bottom_right: int = RoomBuilder.pit_edges(grid, Vector2i(6, 4))
	assert_eq(bottom_right, SceneryDrawing.PIT_DOWN | SceneryDrawing.PIT_RIGHT)


# --- Jefes: un ataque nuevo cada uno --------------------------------------------------------


func test_each_boss_has_its_new_unique_move() -> void:
	for chapter: RunConfig in META.chapters:
		for theme: FloorTheme in chapter.floors:
			for enemy: EnemyData in theme.enemies:
				if enemy.phases.is_empty() or enemy.miniboss:
					continue
				assert_true(NEW_KINDS.has(enemy.id), "%s: tiene un ataque nuevo" % enemy.id)
				var found: bool = false
				for boss_phase: BossPhase in enemy.phases:
					for attack: BossAttack in boss_phase.attacks:
						if attack.kind == NEW_KINDS.get(enemy.id, -1):
							found = true
				assert_true(found, "%s: hace %s" % [enemy.id, NEW_KINDS.get(enemy.id)])


func test_bosses_have_their_own_drawing() -> void:
	var looks: Dictionary[EnemyData.VisualStyle, bool] = {}
	for id: StringName in NEW_KINDS:
		var boss := load("res://content/enemies/%s.tres" % id) as EnemyData
		assert_false(looks.has(boss.visual_style), "%s: dibujo propio" % id)
		looks[boss.visual_style] = true
		for enemy_path: String in DirAccess.get_files_at("res://content/enemies/"):
			var other := load("res://content/enemies/" + enemy_path.trim_suffix(".remap")) as EnemyData
			if other != null and other.phases.is_empty():
				assert_ne(other.visual_style, boss.visual_style, "%s no se dibuja como %s" % [id, other.id])


func test_toll_rings_have_a_gap() -> void:
	var ring := ShockRing.new()
	ring.radius = 40.0
	ring.thickness = 4.0
	ring.gap_angle = 0.0
	ring.gap = deg_to_rad(60.0)
	add_child_autofree(ring)
	ring.global_position = Vector2.ZERO
	assert_true(ring.touches(Vector2(0, 40)), "sobre la onda, lastima")
	assert_false(ring.touches(Vector2(40, 0)), "en el hueco, no")
	assert_false(ring.touches(Vector2(0, 20)), "adentro de la onda, no")


func test_toll_sends_waves() -> void:
	_player.health.grant_invulnerability(30.0)
	_boss_with(_attack(BossAttack.Kind.TOLL))
	var ring: Node = await _wait_for(BossMove.HAZARD_GROUP, func(n: Node) -> bool: return n is ShockRing, 90)
	assert_not_null(ring, "sale una onda")


func test_the_crown_goes_and_comes_back() -> void:
	_player.health.grant_invulnerability(30.0)
	var attack: BossAttack = _attack(BossAttack.Kind.CROWN_BOOMERANG)
	attack.interval = 0.4
	_boss_with(attack)
	var crown := await _wait_for(BossMove.HAZARD_GROUP, func(n: Node) -> bool: return n is CrownBoomerang, 90) as CrownBoomerang
	assert_not_null(crown, "tira la corona")
	await wait_physics_frames(40)
	assert_true(not is_instance_valid(crown) or crown.is_returning(), "frena y vuelve")
	for _frame: int in 240:
		if not is_instance_valid(crown):
			break
		await wait_physics_frames(1)
	assert_false(is_instance_valid(crown), "vuelve a la mano del jefe")


func test_burrowers_hunt_and_erupt() -> void:
	_player.health.grant_invulnerability(30.0)
	var attack: BossAttack = _attack(BossAttack.Kind.BURROWERS)
	attack.linger = 0.5
	_boss_with(attack)
	var burrower := await _wait_for(BossMove.HAZARD_GROUP, func(n: Node) -> bool: return n is Burrower, 90) as Burrower
	assert_not_null(burrower, "salen raíces bajo tierra")
	var start: float = burrower.global_position.distance_to(_player.global_position)
	await wait_physics_frames(15)
	if is_instance_valid(burrower):
		assert_lt(burrower.global_position.distance_to(_player.global_position), start, "persiguen al jugador")
	var root: Node = await _wait_for(BossStrike.GROUP, func(n: Node) -> bool: return (n as BossStrike).look == BossAttack.Look.ROOT, 120)
	assert_not_null(root, "y revientan")


func test_the_beam_cross_spins_several_beams() -> void:
	_player.health.grant_invulnerability(30.0)
	var attack: BossAttack = _attack(BossAttack.Kind.BEAM_CROSS)
	attack.count = 4
	var boss: Enemy = _boss_with(attack)
	var beams: int = 0
	for _frame: int in 90:
		beams = 0
		for child: Node in boss.get_children():
			if child is EnemyBeam:
				beams += 1
		if beams >= 4:
			break
		await wait_physics_frames(1)
	assert_eq(beams, 4, "cuatro rayos (el suyo y tres más)")
	await wait_physics_frames(60)
	assert_true(boss.beam.is_firing(), "disparan")


func test_thread_balls_leave_a_cutting_thread() -> void:
	_player.health.grant_invulnerability(30.0)
	_player.global_position = Vector2(-90, 50)
	var attack: BossAttack = _attack(BossAttack.Kind.THREAD_TRAIL)
	attack.linger = 2.0
	attack.interval = 2.0
	_boss_with(attack)
	var ball := await _wait_for(BossMove.HAZARD_GROUP, func(n: Node) -> bool: return n is ThreadBall, 90) as ThreadBall
	assert_not_null(ball, "sale un ovillo")
	var from: Vector2 = ball.global_position
	await wait_physics_frames(30)
	assert_true(ball.touches(from.lerp(ball.global_position, 0.2)), "por donde pasó quedó hilo que corta")


func test_echoes_replay_the_charges() -> void:
	_player.health.grant_invulnerability(30.0)
	var attack: BossAttack = _attack(BossAttack.Kind.ECHO_CHARGES)
	attack.speed = 220.0
	attack.count = 1
	_boss_with(attack)
	var echo: Node = await _wait_for(BossStrike.GROUP, func(n: Node) -> bool: return (n as BossStrike).look == BossAttack.Look.HOOVES, 200)
	assert_not_null(echo, "la manada fantasma repite la embestida")


func test_icicles_fall_in_a_spiral() -> void:
	_player.health.grant_invulnerability(30.0)
	var attack: BossAttack = _attack(BossAttack.Kind.ICE_SPIRAL)
	attack.count = 3
	attack.interval = 0.05
	_boss_with(attack)
	var distances: Array[float] = []
	for _frame: int in 120:
		distances.clear()
		for node: Node in get_tree().get_nodes_in_group(BossStrike.GROUP):
			distances.append((node as Node2D).global_position.distance_to(BOSS_AT))
		if distances.size() >= 9:
			break
		await wait_physics_frames(1)
	assert_gte(distances.size(), 9, "caen muchos carámbanos")
	distances.sort()
	assert_gt(distances[-1], distances[0] + 30.0, "cada vez más lejos del jefe")


func test_the_vortex_pulls_the_player_in() -> void:
	_player.health.grant_invulnerability(30.0)
	var attack: BossAttack = _attack(BossAttack.Kind.VORTEX)
	attack.warn_time = 0.1
	attack.linger = 2.0
	attack.speed = 50.0
	_player.global_position = Vector2(0, 50)
	_boss_with(attack)
	await wait_physics_frames(40)
	var before: float = _player.global_position.distance_to(BOSS_AT)
	await wait_physics_frames(30)
	assert_lt(_player.global_position.distance_to(BOSS_AT), before - 5.0, "lo chupa hacia el jefe")


func test_hazards_vanish_with_the_boss() -> void:
	_player.health.grant_invulnerability(30.0)
	var attack: BossAttack = _attack(BossAttack.Kind.THREAD_TRAIL)
	attack.linger = 5.0
	var boss: Enemy = _boss_with(attack)
	var ball: Node = await _wait_for(BossMove.HAZARD_GROUP, func(n: Node) -> bool: return n is ThreadBall, 90)
	assert_not_null(ball)
	boss.health.kill()
	await wait_physics_frames(3)
	assert_eq(get_tree().get_nodes_in_group(BossMove.HAZARD_GROUP).size(), 0, "al morir el jefe se va todo lo suyo")
