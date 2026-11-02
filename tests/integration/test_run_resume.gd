extends GutTest
## Hito 20: la run se guarda sola y al salir, y "Continuar la run" la sigue donde estaba: mismo piso y
## sala, lo que llevaba el jugador, las salas limpias siguen limpias, lo que se llevó no vuelve y, si
## salió en medio de una pelea, la pelea se repite como al entrar. Morir, ganar, abandonar o empezar
## otra la borran. Todo en memoria (Main sin carpeta de partidas).

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const CATALOG: ItemCatalog = preload("res://content/items/catalog.tres")
const RUN: RunConfig = preload("res://content/run/run_config.tres")
const SEED: int = 4242

var _main: Main


func before_each() -> void:
	GameRNG.start_run(SEED)
	_main = MAIN_SCENE.instantiate() as Main
	_main.save_dir = ""
	add_child_autofree(_main)
	SaveManager.clear_run()


func after_each() -> void:
	SaveManager.clear_run()


## Deja que se liberen las pantallas reemplazadas antes de terminar el test (GUT cuenta huérfanos).
func _settle() -> void:
	await wait_physics_frames(3)


func _start() -> Game:
	GameRNG.start_run(SEED)
	_main.start_run()
	await wait_physics_frames(2)
	return _main.game


func _floor() -> FloorController:
	return _main.game.floor_controller


func _first_passive() -> ItemData:
	for item: ItemData in CATALOG.items:
		if item.kind == ItemData.Kind.PASSIVE and not item.locked:
			return item
	return null


## Una sala normal con enemigos (y con rocas si `with_rock`), la más cercana al inicio.
func _fight_cell(with_rock: bool = false) -> Vector2i:
	var layout: FloorLayout = _floor().layout
	var best: Vector2i = FloorLayout.NO_CELL
	for cell: Vector2i in layout.slots:
		var slot: RoomSlot = layout.get_slot(cell)
		if slot.kind != RoomSlot.Kind.NORMAL:
			continue
		var grid: RoomGrid = RoomTemplateParser.parse(slot.template.layout)
		if grid.enemies.is_empty() or (with_rock and _rock_cell(grid) == FloorLayout.NO_CELL):
			continue
		if best == FloorLayout.NO_CELL or slot.distance < layout.get_slot(best).distance:
			best = cell
	return best


func _rock_cell(grid: RoomGrid) -> Vector2i:
	for y: int in RoomGrid.HEIGHT:
		for x: int in RoomGrid.WIDTH:
			if grid.cell_at(Vector2i(x, y)) == RoomGrid.Cell.ROCK:
				return Vector2i(x, y)
	return FloorLayout.NO_CELL


func _enemies() -> int:
	return get_tree().get_nodes_in_group(Enemy.GROUP).size()


## Mata a todos hasta que la sala quede limpia (puede tener dos oleadas).
func _clear_current_room() -> void:
	for _attempt: int in 6:
		for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
			(node as Enemy).health.kill()
		await wait_physics_frames(60)
		if _floor().current_room().phase == Room.Phase.CLEARED:
			return


## "Guardar y volver al menú" y después "Continuar la run".
func _save_leave_and_continue() -> Game:
	_main.game.menu_requested.emit()
	assert_true(_main.screen is MainMenu, "vuelve al menú")
	assert_true(SaveManager.has_saved_run(), "quedó guardada")
	await _settle()
	_main.continue_run()
	await wait_physics_frames(2)
	assert_true(_main.screen is Game, "sigue la run")
	return _main.game


func test_save_and_continue_keeps_the_run() -> void:
	var game: Game = await _start()
	game.player.health.always_invulnerable = false
	var item: ItemData = _first_passive()
	RunState.add_item(item)
	RunState.add_coins(7)
	RunState.add_bombs(2)
	RunState.select_next_weapon()
	game.player.health.take_damage(2.0)
	var health: float = game.player.health.current
	var cell: Vector2i = _floor().current_cell
	var position: Vector2 = game.player.global_position
	var resumed: Game = await _save_leave_and_continue()
	assert_ne(resumed, game, "es otra escena")
	assert_eq(_floor().floor_index, 0)
	assert_eq(_floor().current_cell, cell, "en la misma sala")
	assert_almost_eq(resumed.player.global_position.distance_to(position), 0.0, 1.0, "en el mismo lugar")
	assert_has(RunState.items, item, "con sus items")
	assert_eq(RunState.coins, 7)
	assert_eq(RunState.bombs, RunState.START_BOMBS + 2)
	assert_eq(resumed.player.health.current, health, "con la vida que tenía")
	assert_eq(RunState.stats.max_health, resumed.player.health.max_health)
	await _settle()


func test_leaving_in_the_middle_of_a_fight_repeats_it() -> void:
	await _start()
	var cell: Vector2i = _fight_cell()
	assert_ne(cell, FloorLayout.NO_CELL, "hay una sala con enemigos")
	await _floor().move_to(cell)
	await wait_physics_frames(2)
	assert_eq(_floor().current_room().phase, Room.Phase.FIGHTING)
	var coins: int = RunState.coins
	var bombs: int = RunState.bombs
	# A mitad de la pelea gana monedas y gasta una bomba; al salir no se guarda eso.
	RunState.add_coins(5)
	RunState.use_bomb()
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		(node as Enemy).health.kill()
	await wait_physics_frames(2)
	await _save_leave_and_continue()
	await wait_physics_frames(5)
	assert_eq(_floor().current_cell, cell, "en la sala de la pelea")
	assert_eq(_floor().current_room().phase, Room.Phase.FIGHTING, "la pelea se repite")
	assert_gt(_enemies(), 0, "con los enemigos de nuevo")
	assert_eq(RunState.coins, coins, "como estaba al entrar")
	assert_eq(RunState.bombs, bombs)
	await _settle()


func test_cleared_rooms_and_taken_items_stay_that_way() -> void:
	await _start()
	var fight: Vector2i = _fight_cell()
	await _floor().move_to(fight)
	await _clear_current_room()
	assert_eq(_floor().current_room().phase, Room.Phase.CLEARED)
	var treasure: Vector2i = _floor().layout.first_of_kind(RoomSlot.Kind.TREASURE)
	await _floor().move_to(treasure)
	await wait_physics_frames(2)
	var pedestal: ItemPedestal = null
	for child: Node in _floor().current_room().get_node(^"Pickups").get_children():
		if child is ItemPedestal:
			pedestal = child as ItemPedestal
	assert_not_null(pedestal, "el tesoro tiene su pedestal")
	var item: ItemData = pedestal.item
	_main.game.player.global_position = pedestal.global_position
	await wait_physics_frames(3)
	assert_null(pedestal.item, "se lo llevó")
	var shop: Vector2i = _floor().layout.first_of_kind(RoomSlot.Kind.SHOP)
	var shop_offers: Array[ItemData] = _floor().layout.get_slot(shop).offers.duplicate()
	var visited: int = _floor().visited.size()
	await _save_leave_and_continue()
	assert_eq(_floor().current_cell, treasure)
	var restored: ItemPedestal = null
	for child: Node in _floor().current_room().get_node(^"Pickups").get_children():
		if child is ItemPedestal and not child.is_queued_for_deletion():
			restored = child as ItemPedestal
	assert_not_null(restored, "el pedestal sigue ahí")
	assert_null(restored.item, "vacío")
	if item.kind == ItemData.Kind.PASSIVE:
		assert_has(RunState.items, item, "el item lo tiene el jugador")
	assert_eq(_floor().visited.size(), visited, "el mapa recuerda lo visitado")
	assert_eq(_floor().layout.get_slot(shop).offers, shop_offers, "la tienda vende lo mismo")
	await _floor().move_to(fight)
	await wait_physics_frames(5)
	assert_eq(_floor().current_room().phase, Room.Phase.CLEARED, "la sala limpia sigue limpia")
	assert_eq(_enemies(), 0, "sin enemigos")
	await _settle()


func test_broken_rocks_stay_broken() -> void:
	await _start()
	var cell: Vector2i = _fight_cell(true)
	if cell == FloorLayout.NO_CELL:
		pass_test("este piso no tiene salas con rocas y enemigos")
		return
	await _floor().move_to(cell)
	await _clear_current_room()
	var room: Room = _floor().current_room()
	var rock_cell: Vector2i = _rock_cell(room.grid)
	for child: Node in room.get_node(^"Obstacles").get_children():
		if child is Rock and RoomNav.cell_of((child as Rock).position) == rock_cell:
			(child as Rock).destroy()
	await wait_physics_frames(2)
	await _save_leave_and_continue()
	room = _floor().current_room()
	for child: Node in room.get_node(^"Obstacles").get_children():
		if child is Rock and not child.is_queued_for_deletion():
			assert_ne(RoomNav.cell_of((child as Rock).position), rock_cell, "la roca rota no vuelve")
	assert_true(room.nav.is_open(rock_cell), "y se puede pasar")
	await _settle()


func test_the_mech_and_the_floor_come_back() -> void:
	await _start()
	var mech: MechData = RUN.mechs[1]
	_main.game.player.board(mech, 5.0)
	await _floor().advance_floor()
	await wait_physics_frames(2)
	assert_eq(_floor().floor_index, 1)
	var floor_name: String = RunState.floor_name
	await _save_leave_and_continue()
	assert_eq(_floor().floor_index, 1, "en el segundo piso")
	assert_eq(RunState.floor_name, floor_name)
	assert_eq(_floor().current_cell, _floor().layout.start)
	assert_eq(_main.game.player.mech, mech, "arriba del armazón")
	assert_eq(_main.game.player.mech_armor.current, 5.0, "con el blindaje que tenía")
	await _settle()


func test_dying_winning_or_abandoning_deletes_it() -> void:
	var game: Game = await _start()
	assert_true(SaveManager.has_saved_run(), "se guarda sola al entrar a la primera sala")
	game.player.health.kill()
	assert_false(SaveManager.has_saved_run(), "al morir se borra")
	await wait_physics_frames(roundi(Main.DEATH_DELAY * 60.0) + 30)
	await _start()
	EventBus.run_ended.emit(true)
	await wait_physics_frames(1)
	assert_false(SaveManager.has_saved_run(), "al ganar también")
	await _start()
	_main.game.abandon_requested.emit()
	assert_true(_main.screen is MainMenu)
	assert_false(SaveManager.has_saved_run(), "abandonarla también")
	await _settle()


func test_the_pause_asks_before_abandoning() -> void:
	await _start()
	var pause := _main.game.get_node(^"PauseMenu") as PauseMenu
	pause.open()
	watch_signals(pause)
	pause._abandon.pressed.emit()
	assert_true(pause.is_confirming_abandon(), "la primera vez pregunta")
	assert_signal_not_emitted(pause, "abandon_requested")
	pause.close()
	assert_false(pause.is_confirming_abandon(), "al cerrar se olvida")
	await _settle()


func test_the_menu_offers_to_continue_and_asks_before_a_new_run() -> void:
	await _start()
	RunState.add_coins(9)
	_main.game.menu_requested.emit()
	await _settle()
	var menu := _main.screen as MainMenu
	assert_not_null(menu._continue, "con una run guardada aparece Continuar")
	watch_signals(menu)
	menu._play.pressed.emit()
	assert_true(menu.is_confirming_new_run(), "Nueva run pregunta primero")
	assert_signal_not_emitted(menu, "play_requested")
	assert_true(SaveManager.has_saved_run(), "todavía no se perdió")
	menu._play.pressed.emit()
	assert_signal_emitted(menu, "play_requested")
	await _settle()
	_main.start_run()
	await wait_physics_frames(2)
	assert_eq(RunState.coins, 0, "la run nueva empieza de cero")
	_main.game.menu_requested.emit()
	await _settle()
	_main.continue_run()
	await wait_physics_frames(2)
	assert_eq(RunState.coins, 0, "lo guardado ahora es la run nueva")
	await _settle()


func test_quitting_saves_the_run() -> void:
	await _start()
	RunState.add_coins(4)
	_main.game.suspend()
	var snapshot: RunSnapshot = RunSnapshot.from_dict(SaveManager.load_run())
	assert_not_null(snapshot)
	assert_eq(snapshot.coins, 4, "lo que tenía al salir")
	assert_eq(snapshot.run_seed, GameRNG.get_run_seed())
	await _settle()
