extends GutTest
## Hito 23: lo que pidió el usuario después de probar el hito 22. Un armazón cuya arma perdió el ícono
## ya no traba el juego, la rueda de armas (mantener Tab) y las teclas 1 a 9, los movimientos nuevos
## del Tijerón (corte en el aire y clavada), los poltergeist (ojos en el borde que se van con ellos),
## los corazones en filas y el resumen con muchos items.

const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const SUMMARY_SCENE: PackedScene = preload("res://ui/menus/run_summary.tscn")
const CALDERA: MechData = preload("res://content/mechs/caldera.tres")
const TRABUCO: WeaponData = preload("res://content/weapons/trabuco.tres")
const METRALLA: WeaponData = preload("res://content/weapons/metralla.tres")
const POLTERGEIST: EnemyData = preload("res://content/enemies/poltergeist.tres")
const POLTERGEIST_ROJO: EnemyData = preload("res://content/enemies/poltergeist_rojo.tres")
const CATALOG: ItemCatalog = preload("res://content/items/catalog.tres")
const USED_ACTIONS: Array[StringName] = [&"swap_weapon", &"weapon_2", &"weapon_3"]
const BOSS_AT: Vector2 = Vector2(40, -40)
const PLAYER_AT: Vector2 = Vector2(40, 40)

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
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)
	get_tree().paused = false


func _wheel() -> WeaponWheel:
	return _game._hud.weapon_wheel


func _three_weapons() -> void:
	RunState.add_weapon(TRABUCO)
	RunState.add_weapon(METRALLA)
	RunState.select_weapon(0)


func _hostile_bullets() -> int:
	var count: int = 0
	for node: Node in get_tree().get_nodes_in_group(Bullet.GROUP):
		if (node as Bullet).is_hostile_to_player():
			count += 1
	return count


func _attack(kind: BossAttack.Kind) -> BossAttack:
	var attack := BossAttack.new()
	attack.id = &"prueba"
	attack.kind = kind
	attack.windup = 0.1
	attack.recover = 5.0
	attack.warn_time = 0.3
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


func _wait_for_state(enemy: Enemy, state: StringName, max_frames: int) -> bool:
	for _frame: int in max_frames:
		if enemy.machine.get_state_name() == state:
			return true
		await wait_physics_frames(1)
	return false


# --- El crash del armazón -------------------------------------------------------------


func test_a_weapon_without_icon_still_draws() -> void:
	assert_eq(PixelIcons.size_of(PackedStringArray()), Vector2.ZERO, "medir un ícono vacío no rompe")
	var broken := CALDERA.weapon.duplicate() as WeaponData
	broken.icon = PackedStringArray()
	assert_eq(broken.display_icon(), WeaponData.FALLBACK_ICON, "sin ícono, una pistola genérica")
	assert_eq(CALDERA.weapon.display_icon(), CALDERA.weapon.icon, "con ícono, el suyo")


func test_every_weapon_icon_survives() -> void:
	# El editor de Godot borra los íconos de los sub-recursos al guardar: si pasa, esto lo avisa.
	for mech: MechData in (load("res://content/run/run_config.tres") as RunConfig).mechs:
		assert_eq(mech.weapon.icon.size(), 5, "%s: el arma del armazón tiene su ícono" % mech.id)
	for item: ItemData in CATALOG.items:
		if item.weapon != null:
			assert_false(item.weapon.icon.is_empty(), "%s: el arma tiene su ícono" % item.id)


# --- Rueda de armas y teclas -----------------------------------------------------------


func test_number_keys_pick_a_weapon() -> void:
	_three_weapons()
	Input.action_press(&"weapon_3")
	await wait_physics_frames(2)
	Input.action_release(&"weapon_3")
	assert_eq(RunState.current_weapon, 2, "el 3 equipa la tercera")
	Input.action_press(&"weapon_2")
	await wait_physics_frames(2)
	assert_eq(RunState.current_weapon, 1)


func test_tapping_still_swaps_to_the_next() -> void:
	_three_weapons()
	Input.action_press(&"swap_weapon")
	await wait_physics_frames(2)
	Input.action_release(&"swap_weapon")
	await wait_physics_frames(2)
	assert_eq(RunState.current_weapon, 1, "un toque: la siguiente")
	assert_false(_wheel().is_open(), "sin rueda")


func test_holding_opens_the_wheel_and_releasing_picks() -> void:
	_three_weapons()
	Input.action_press(&"swap_weapon")
	await wait_physics_frames(20)
	assert_true(_wheel().is_open(), "mantener abre la rueda")
	assert_true(get_tree().paused, "y pausa el juego")
	assert_eq(RunState.current_weapon, 0, "abrirla no cambia nada")
	_wheel().point_at(WeaponWheel.slot_direction(2, 3))
	assert_eq(_wheel().choice(), 2, "apuntando se marca")
	Input.action_release(&"swap_weapon")
	await wait_frames(3)
	assert_false(_wheel().is_open())
	assert_false(get_tree().paused, "vuelve el juego")
	assert_eq(RunState.current_weapon, 2, "al soltar se equipa la marcada")


func test_no_wheel_with_one_weapon_or_in_a_mech() -> void:
	_wheel().open()
	assert_false(_wheel().is_open(), "con una sola arma no hay rueda")
	_three_weapons()
	_player.board(CALDERA, CALDERA.armor)
	Input.action_press(&"swap_weapon")
	await wait_physics_frames(20)
	assert_false(_wheel().is_open(), "arriba de un armazón no se cambia de arma")
	Input.action_release(&"swap_weapon")


# --- Tijerón ---------------------------------------------------------------------------


func test_the_cut_stays_in_the_air_and_shoots() -> void:
	var cut: BossAttack = _attack(BossAttack.Kind.HANGING_CUT)
	cut.spread = 50.0
	cut.radius = 3.0
	cut.linger = 1.5
	cut.interval = 0.3
	cut.pattern = load("res://content/patterns/tijeron_corte.tres") as BulletPatternData
	var boss: Enemy = _boss_with(cut)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(10)
	var strikes: Array[Node] = get_tree().get_nodes_in_group(BossStrike.GROUP)
	assert_eq(strikes.size(), 1, "un corte")
	var strike := strikes[0] as BossStrike
	assert_almost_eq(strike.global_position.distance_to(PLAYER_AT), 0.0, 1.0, "donde está el jugador")
	_player.health.grant_invulnerability(10.0)
	await wait_physics_frames(40)
	assert_true(is_instance_valid(strike) and strike.has_struck(), "cortó y sigue en el aire")
	assert_gt(_hostile_bullets(), 0, "del corte salen disparos")


func test_touching_the_cut_hurts() -> void:
	var cut: BossAttack = _attack(BossAttack.Kind.HANGING_CUT)
	cut.spread = 50.0
	cut.radius = 3.0
	cut.linger = 2.0
	var boss: Enemy = _boss_with(cut)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(5)
	var strike := get_tree().get_nodes_in_group(BossStrike.GROUP)[0] as BossStrike
	_player.global_position = PLAYER_AT + Vector2(0, 26)
	await wait_physics_frames(30)
	assert_true(strike.has_struck())
	var health: float = _player.health.current
	_player.global_position = strike.global_position + strike.slash * 0.5
	await wait_physics_frames(3)
	assert_lt(_player.health.current, health, "quedó en el aire: tocarlo lastima")


func test_the_dive_shoots_rays_along_the_floor() -> void:
	var dive: BossAttack = _attack(BossAttack.Kind.DIVE)
	dive.count = 6
	dive.warn_time = 0.3
	dive.lock_time = 0.1
	dive.interval = 0.3
	dive.linger = 0.4
	dive.radius = 10.0
	var boss: Enemy = _boss_with(dive)
	assert_true(await _wait_for_state(boss, &"BossAttack", 60))
	await wait_physics_frames(8)
	assert_true(boss.is_airborne(), "salta")
	var rays: int = 0
	for _frame: int in 60:
		await wait_physics_frames(1)
		rays = 0
		for child: Node in boss.get_children():
			if child is EnemyBeam and not child.is_queued_for_deletion():
				rays += 1
		if rays > 1:
			break
	assert_false(boss.is_airborne(), "se clavó")
	assert_eq(rays, 1 + dive.count, "seis rayos (más el rayo propio)")
	var health: float = _player.health.current
	await wait_physics_frames(40)
	assert_lt(_player.health.current, health, "uno apunta al jugador: quedarse lastima")
	await wait_physics_frames(10)
	var left: int = 0
	for child: Node in boss.get_children():
		if child is EnemyBeam and not child.is_queued_for_deletion():
			left += 1
	assert_eq(left, 1, "al terminar se van los rayos de más")


# --- Poltergeist -----------------------------------------------------------------------


func _eyes() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		if enemy != null and not enemy.is_queued_for_deletion() and enemy.data.id != POLTERGEIST.id \
				and enemy.data.id != POLTERGEIST_ROJO.id:
			result.append(enemy)
	return result


func _wait_for_eyes(max_frames: int) -> Array[Enemy]:
	for _frame: int in max_frames:
		await wait_physics_frames(1)
		var eyes: Array[Enemy] = _eyes()
		if not eyes.is_empty():
			return eyes
	return _eyes()


func test_poltergeist_opens_eyes_in_the_scenery() -> void:
	_player.health.grant_invulnerability(20.0)
	_player.global_position = Vector2.ZERO
	_game.spawn_enemy(POLTERGEIST, Vector2(60, 0))
	var eyes: Array[Enemy] = await _wait_for_eyes(400)
	assert_gt(eyes.size(), 0, "invoca ojos")
	for eye: Enemy in eyes:
		var local: Vector2 = eye.global_position - eye.nav_origin
		var cell: Vector2i = RoomNav.cell_of(local)
		var on_edge: bool = cell.x == 0 or cell.y == 0 or cell.x == RoomGrid.WIDTH - 1 or cell.y == RoomGrid.HEIGHT - 1
		assert_true(on_edge, "%s: en el borde de la sala" % cell)
		assert_gte(eye.global_position.distance_to(_player.global_position), Enemy.SCENERY_SPOT_CLEARANCE, "lejos del jugador")
		assert_eq(eye.data.attack_kind, EnemyData.AttackKind.SHOOT, "los ojos disparan")


func test_the_eyes_vanish_with_their_poltergeist() -> void:
	_player.health.grant_invulnerability(20.0)
	_player.global_position = Vector2.ZERO
	var poltergeist: Enemy = _game.spawn_enemy(POLTERGEIST, Vector2(60, 0))
	var eyes: Array[Enemy] = await _wait_for_eyes(400)
	assert_gt(eyes.size(), 0)
	var kills: int = RunState.kills
	poltergeist.health.kill()
	await wait_physics_frames(3)
	assert_eq(_eyes().size(), 0, "los ojos se van con él")
	assert_eq(RunState.kills, kills + 1, "solo cuenta el poltergeist")


func test_the_red_one_opens_eyes_with_beams() -> void:
	assert_eq(POLTERGEIST_ROJO.summon.attack_kind, EnemyData.AttackKind.BEAM, "sus ojos tiran rayos")
	assert_true(POLTERGEIST_ROJO.summons_die_with_me)
	assert_true(POLTERGEIST_ROJO.summon_anywhere)


# --- Interfaz --------------------------------------------------------------------------


func test_many_hearts_wrap_and_push_the_pulses_down() -> void:
	var hearts := _game._hud.get_node(^"Hearts") as HeartsDisplay
	var pulses := _game._hud.get_node(^"Pulses") as Control
	var counters := _game._hud.get_node(^"Counters") as Control
	assert_lte(hearts.position.x + HeartsDisplay.PER_ROW * HeartsDisplay.SPACING, counters.position.x + 2.0,
			"una fila de corazones no llega a los contadores")
	_player.health.setup(20.0, 20.0)
	await wait_physics_frames(2)
	assert_eq(hearts.rows(), 3, "diez corazones: tres filas")
	assert_eq(pulses.position.y, hearts.position.y + 3 * HeartsDisplay.ROW_HEIGHT, "los Pulsos bajan")


func test_the_summary_fits_with_many_items() -> void:
	for i: int in 50:
		RunState.items.append(CATALOG.items[i % CATALOG.items.size()])
	var summary := SUMMARY_SCENE.instantiate() as RunSummary
	add_child_autofree(summary)
	summary.show_summary(false)
	await wait_frames(4)
	var viewport: Rect2 = summary.get_viewport_rect()
	for button: Node in summary.find_children("*", "Button", true, false):
		var rect: Rect2 = (button as Button).get_global_rect()
		assert_true(viewport.encloses(rect), "%s se ve entero" % (button as Button).text)
	RunState.items.clear()
