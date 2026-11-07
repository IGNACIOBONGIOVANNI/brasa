extends GutTest
## Hito 29: el camino secreto del capítulo 1. Un brasero frío en una sala del Sótano se enciende con una
## bomba y da el Ascua; en la sala del jefe de las Cloacas hay una boca tapiada que solo se abre con el
## Ascua y la sala limpia; abajo está el Cenicero, un piso secreto con enemigos, trampa, música y jefe
## propios (el Deshollinador, que barre dejando nubes de hollín que revientan). Su trampilla sigue en
## Raíces. Todo se guarda con la run.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const RUN: RunConfig = preload("res://content/run/run_config.tres")
const META: MetaConfig = preload("res://content/meta/meta_config.tres")
const CATALOG: ItemCatalog = preload("res://content/items/catalog.tres")
const SECRET_ENEMIES: Array[String] = ["pavesa", "doliente", "cenizo"]
const SEED: int = 2929

var _main: Main


func before_each() -> void:
	RunState.start_run()


func after_each() -> void:
	SaveManager.clear_run()


func _start() -> void:
	GameRNG.start_run(SEED)
	_main = MAIN_SCENE.instantiate() as Main
	_main.save_dir = ""
	add_child_autofree(_main)
	SaveManager.clear_run()
	_main.start_run()
	await wait_physics_frames(2)


func _floor() -> FloorController:
	return _main.game.floor_controller


func _player() -> Player:
	return _main.game.player


func _boss_of(theme: FloorTheme) -> EnemyData:
	for enemy: EnemyData in theme.enemies:
		if not enemy.phases.is_empty() and not enemy.miniboss:
			return enemy
	return null


func _prop(room: Room, kind: Script) -> Node2D:
	for child: Node in room.get_node(^"Pickups").get_children():
		if child.get_script() == kind:
			return child as Node2D
	return null


## Va a la sala, mata a todos y espera a que se limpie.
func _go_and_clear(cell: Vector2i) -> Room:
	await _floor().move_to(cell)
	await wait_physics_frames(2)
	_floor()._clear_current_room()
	await wait_until(func() -> bool: return _floor().current_room().phase == Room.Phase.CLEARED, 3.0)
	return _floor().current_room()


func _boss_cell() -> Vector2i:
	return _floor().layout.first_of_kind(RoomSlot.Kind.BOSS)


# --- Contenido ---------------------------------------------------------------------------------------


func test_chapter_one_has_a_secret_floor_between_its_floors() -> void:
	assert_not_null(RUN.secret_floor, "el capítulo 1 tiene piso secreto")
	assert_false(RUN.floors.has(RUN.secret_floor), "no es uno de los pisos de siempre")
	assert_lt(RUN.secret_brazier_floor, RUN.secret_gate_floor, "el brasero está antes que la boca")
	assert_lt(RUN.secret_gate_floor, RUN.floors.size() - 1, "después del secreto queda al menos un piso")
	assert_eq(RUN.secret_floor.display_name, "El Cenicero")
	assert_ne(RUN.secret_floor.tagline, "", "tiene su línea de historia")
	assert_not_null(RUN.secret_floor.music, "su música")
	assert_not_null(RUN.secret_floor.boss_music, "y la de su jefe")
	for chapter: RunConfig in META.chapters.slice(1):
		assert_null(chapter.secret_floor, "%s todavía no tiene camino secreto" % chapter.id)


func test_the_ash_pit_has_its_own_enemies_and_boss() -> void:
	var others: Dictionary[EnemyData, bool] = {}
	for chapter: RunConfig in META.chapters:
		for theme: FloorTheme in chapter.floors:
			for enemy: EnemyData in theme.enemies:
				others[enemy] = true
	for id: String in SECRET_ENEMIES:
		var enemy := load("res://content/enemies/%s.tres" % id) as EnemyData
		assert_true(RUN.secret_floor.enemies.has(enemy), "%s está en el Cenicero" % id)
		assert_false(others.has(enemy), "%s solo está en el Cenicero" % id)
	var boss: EnemyData = _boss_of(RUN.secret_floor)
	assert_not_null(boss)
	assert_eq(boss.id, &"deshollinador")
	assert_false(others.has(boss), "su jefe es solo suyo")
	assert_gte(boss.phases.size(), 3, "tres fases")


func test_the_sweeper_has_its_own_entrance_and_its_own_attack() -> void:
	var boss: EnemyData = _boss_of(RUN.secret_floor)
	var sweeps: int = 0
	for boss_phase: BossPhase in boss.phases:
		assert_gte(boss_phase.attacks.size(), 2)
		for attack: BossAttack in boss_phase.attacks:
			if attack.kind == BossAttack.Kind.SOOT_SWEEP:
				sweeps += 1
	assert_gt(sweeps, 0, "barre")
	assert_ne(boss.intro, EnemyData.Intro.NONE)
	for chapter: RunConfig in META.chapters:
		for theme: FloorTheme in chapter.floors:
			var other: EnemyData = _boss_of(theme)
			assert_ne(other.intro, boss.intro, "entra distinto que %s" % other.id)
			for boss_phase: BossPhase in other.phases:
				for attack: BossAttack in boss_phase.attacks:
					assert_ne(attack.kind, BossAttack.Kind.SOOT_SWEEP, "%s no barre" % other.id)


func test_beating_the_sweeper_unlocks_an_item() -> void:
	var found: AchievementData = null
	for achievement: AchievementData in META.achievements:
		if achievement.boss != null and achievement.boss.id == &"deshollinador":
			found = achievement
	assert_not_null(found, "hay logro por vencerlo")
	assert_eq(found.unlock_items.size(), 1)
	var item: ItemData = found.unlock_items[0]
	assert_true(item.locked, "el item arranca bloqueado")
	assert_true(CATALOG.items.has(item), "y está en el catálogo")


# --- El Ascua ----------------------------------------------------------------------------------------


func test_the_ember_goes_from_none_to_carried_to_spent() -> void:
	watch_signals(RunState)
	assert_eq(RunState.secret, RunState.Secret.NONE)
	assert_false(RunState.spend_ember(), "sin Ascua no hay nada que gastar")
	assert_true(RunState.give_ember())
	assert_true(RunState.has_ember())
	assert_false(RunState.give_ember(), "una sola por run")
	assert_true(RunState.spend_ember())
	assert_eq(RunState.secret, RunState.Secret.OPENED)
	assert_false(RunState.has_ember())
	assert_signal_emit_count(RunState, "secret_changed", 2)
	RunState.start_run()
	assert_eq(RunState.secret, RunState.Secret.NONE, "una run nueva empieza sin Ascua")


func test_the_snapshot_keeps_the_secret_path() -> void:
	var snapshot := RunSnapshot.new()
	snapshot.run_seed = 1
	snapshot.character = &"brasa"
	snapshot.secret_step = RunState.Secret.EMBER
	snapshot.secret_floor = true
	var copy: RunSnapshot = RunSnapshot.from_dict(JSON.parse_string(JSON.stringify(snapshot.to_dict())))
	assert_eq(copy.secret_step, RunState.Secret.EMBER)
	assert_true(copy.secret_floor)
	var old: Dictionary = snapshot.to_dict()
	old.erase("secret")
	old.erase("secret_floor")
	var from_old: RunSnapshot = RunSnapshot.from_dict(old)
	assert_not_null(from_old, "una run guardada de antes sigue sirviendo")
	assert_eq(from_old.secret_step, 0)
	assert_false(from_old.secret_floor)


# --- El brasero frío ---------------------------------------------------------------------------------


func test_the_cold_brazier_is_in_a_normal_room_of_the_basement() -> void:
	await _start()
	var cell: Vector2i = _floor().brazier_cell
	assert_ne(cell, FloorController.NO_CELL, "el Sótano tiene brasero")
	assert_eq(_floor().layout.get_slot(cell).kind, RoomSlot.Kind.NORMAL)
	assert_ne(cell, _floor().layout.start)
	await _floor().advance_floor()
	assert_eq(_floor().brazier_cell, FloorController.NO_CELL, "las Cloacas no")
	await wait_physics_frames(2)


func test_a_bomb_lights_the_brazier_and_gives_the_ember() -> void:
	await _start()
	watch_signals(EventBus)
	var room: Room = await _go_and_clear(_floor().brazier_cell)
	var brazier := _prop(room, Brazier) as Brazier
	assert_not_null(brazier, "la sala tiene el brasero")
	assert_false(brazier.lit, "frío")
	assert_false(room.nav.is_open(RoomNav.cell_of(brazier.position)), "tapa el paso a los enemigos")
	EventBus.exploded.emit(brazier.global_position + Vector2(120, 0), Bomb.RADIUS)
	assert_false(brazier.lit, "una bomba lejos no lo prende")
	EventBus.exploded.emit(brazier.global_position + Vector2(20, 0), Bomb.RADIUS)
	assert_true(brazier.lit, "una bomba cerca sí")
	assert_true(RunState.has_ember(), "da el Ascua")
	assert_signal_emitted_with_parameters(EventBus, "message_requested", [Brazier.TITLE, Brazier.SUBTITLE])
	var counters := _main.game.get_node(^"Hud/Counters") as CountersDisplay
	assert_true(counters.ember, "el HUD la muestra")
	await wait_physics_frames(3)


# --- La boca y el Cenicero ---------------------------------------------------------------------------


func test_the_mouth_stays_shut_without_the_ember() -> void:
	await _start()
	await _floor().advance_floor()
	await _floor().move_to(_boss_cell())
	await wait_physics_frames(2)
	var chute := _prop(_floor().current_room(), AshChute) as AshChute
	assert_not_null(chute, "la sala del jefe de las Cloacas tiene la boca")
	watch_signals(EventBus)
	_player().global_position = chute.global_position
	await wait_physics_frames(3)
	assert_signal_not_emitted(EventBus, "message_requested", "en plena pelea no dice nada")
	_player().global_position = chute.global_position + Vector2(0, -40)
	_floor()._clear_current_room()
	await wait_until(func() -> bool: return _floor().current_room().phase == Room.Phase.CLEARED, 3.0)
	_player().global_position = chute.global_position
	await wait_physics_frames(3)
	assert_signal_emitted_with_parameters(EventBus, "message_requested", [AshChute.SEALED_TITLE, AshChute.SEALED_HINT])
	assert_eq(chute.mode, AshChute.Mode.SEALED, "sin fuego no cede")
	await wait_seconds(0.3)
	assert_false(_floor().in_secret)
	await wait_physics_frames(3)


func test_the_ember_opens_the_mouth_down_to_the_ash_pit_and_out_to_the_roots() -> void:
	await _start()
	RunState.give_ember()
	await _floor().advance_floor()
	await _go_and_clear(_boss_cell())
	var chute := _prop(_floor().current_room(), AshChute) as AshChute
	_player().global_position = chute.global_position
	await wait_physics_frames(3)
	assert_eq(chute.mode, AshChute.Mode.BURNING, "el Ascua prende el hollín")
	assert_eq(RunState.secret, RunState.Secret.OPENED, "y se gasta")
	await wait_seconds(AshChute.BURN_TIME + 0.2)
	assert_eq(chute.mode, AshChute.Mode.OPEN)
	assert_false(_floor().in_secret, "si sigue parado ahí no baja solo")
	_player().global_position = chute.global_position + Vector2(0, -40)
	await wait_physics_frames(3)
	_player().global_position = chute.global_position
	await wait_until(func() -> bool: return _floor().in_secret and not _floor().is_transitioning(), 4.0)
	assert_true(_floor().in_secret, "bajó al Cenicero")
	assert_eq(_floor().theme, RUN.secret_floor)
	assert_eq(_floor().floor_index, RUN.secret_gate_floor, "el número de piso sigue siendo el de la boca")
	assert_eq(RunState.floor_name, "El Cenicero")
	assert_false(_floor().is_last_floor())
	assert_eq(_floor().brazier_cell, FloorController.NO_CELL)
	assert_false(_floor().is_gate_room(_boss_cell()), "abajo no hay otra boca")
	await _floor().advance_floor()
	assert_false(_floor().in_secret, "su trampilla sale del secreto")
	assert_eq(_floor().theme, RUN.floors[RUN.secret_gate_floor + 1], "a Raíces")
	await wait_physics_frames(3)


func test_the_ash_pit_survives_save_and_continue() -> void:
	await _start()
	RunState.give_ember()
	RunState.spend_ember()
	await _floor().advance_floor()
	await _floor().enter_secret_floor()
	await wait_physics_frames(2)
	assert_true(_floor().in_secret)
	var layout_start: Vector2i = _floor().layout.start
	_main.game.menu_requested.emit()
	assert_true(SaveManager.has_saved_run(), "quedó guardada")
	await wait_physics_frames(3)
	_main.continue_run()
	await wait_physics_frames(2)
	assert_true(_floor().in_secret, "sigue en el Cenicero")
	assert_eq(_floor().theme, RUN.secret_floor)
	assert_eq(_floor().layout.start, layout_start, "el mismo piso")
	assert_eq(RunState.secret, RunState.Secret.OPENED)
	await wait_physics_frames(3)


func test_the_secret_floor_is_generated_apart_from_the_floor_above() -> void:
	await _start()
	await _floor().advance_floor()
	var above: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in _floor().layout.slots:
		above[cell] = true
	await _floor().enter_secret_floor()
	var below: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in _floor().layout.slots:
		below[cell] = true
	assert_ne(above, below, "otro layout que el de las Cloacas")
	assert_between(_floor().layout.cells_of_kind(RoomSlot.Kind.NORMAL).size() + 4, RUN.secret_floor.room_count_min,
			RUN.secret_floor.room_count_max + 2, "un piso chico")
	await wait_physics_frames(3)


# --- El Deshollinador ---------------------------------------------------------------------------------


func test_the_soot_sweep_leaves_puffs_that_burst_into_embers() -> void:
	GameRNG.start_run(SEED)
	var arena := ARENA_SCENE.instantiate() as Game
	add_child_autofree(arena)
	arena.player.global_position = Vector2(0, 50)
	arena.player.health.grant_invulnerability(60.0)
	for rock: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		rock.free()
	var data := load("res://content/enemies/deshollinador.tres") as EnemyData
	var boss: Enemy = arena.spawn_enemy(data, Vector2(0, -40))
	await wait_seconds(data.spawn_delay + 0.1)
	var sweep: BossAttack = data.phases[0].attacks[0]
	assert_eq(sweep.kind, BossAttack.Kind.SOOT_SWEEP)
	boss.force_attack(sweep)
	var puffs: Callable = func() -> int:
		var count: int = 0
		for node: Node in get_tree().get_nodes_in_group(BossMove.HAZARD_GROUP):
			if node is AshPuff:
				count += 1
		return count
	await wait_until(func() -> bool: return puffs.call() > 0, 4.0)
	assert_gt(puffs.call(), 0, "deja nubes de hollín al barrer")
	await wait_until(func() -> bool: return get_tree().get_nodes_in_group(Bullet.GROUP).size() > 0, 3.0)
	assert_gt(get_tree().get_nodes_in_group(Bullet.GROUP).size(), 0, "las nubes revientan en brasas")
	boss.health.kill()
	await wait_physics_frames(3)
	assert_eq(puffs.call(), 0, "al morir el jefe se van")
	# Que terminen de sonar los estallidos (un sonido sonando al salir deja objetos sin liberar).
	await wait_seconds(1.0)
