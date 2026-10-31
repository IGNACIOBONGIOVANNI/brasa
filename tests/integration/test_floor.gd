extends GutTest
## Hito 3: el piso generado. Sala inicial, cruzar puertas, combate que cierra y abre puertas,
## salas sin enemigos, puerta secreta que se abre con una bomba y minimapa. Seed fija.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const BOMB_SCENE: PackedScene = preload("res://entities/bomb/bomb.tscn")
const SEED: int = 1234
const MOVE_ACTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.UP: &"move_up",
	Vector2i.DOWN: &"move_down",
	Vector2i.LEFT: &"move_left",
	Vector2i.RIGHT: &"move_right",
}

var _game: Game
var _floor: FloorController
var _layout: FloorLayout


func before_each() -> void:
	GameRNG.start_run(SEED)
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_floor = _game.floor_controller
	_layout = _floor.layout
	_game.player.health.always_invulnerable = true


func after_each() -> void:
	for action: StringName in MOVE_ACTIONS.values():
		Input.action_release(action)


## Lado de la sala inicial que lleva a una sala que no es la secreta.
func _open_side_from_start() -> Vector2i:
	for next: Vector2i in _layout.neighbors(_layout.start, false):
		return next - _layout.start
	return Vector2i.ZERO


func _is_inside_room(room: Room, global_point: Vector2) -> bool:
	var local: Vector2 = room.to_local(global_point)
	return absf(local.x) < RoomBuilder.HALF_INTERIOR.x and absf(local.y) < RoomBuilder.HALF_INTERIOR.y


## Mata a todos los enemigos hasta que la sala quede limpia (puede tener dos oleadas).
func _clear_current_room() -> void:
	for _attempt: int in 4:
		for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
			(node as Enemy).health.kill()
		await wait_physics_frames(60)
		if _floor.current_room().phase == Room.Phase.CLEARED:
			return


func test_start_room_has_a_door_per_neighbor() -> void:
	var room: Room = _floor.current_room()
	assert_eq(_floor.current_cell, _layout.start)
	assert_eq(room.doors.size(), _layout.neighbors(_layout.start).size(), "una puerta por vecina")
	for side: Vector2i in room.doors:
		var is_secret: bool = _layout.get_slot(_layout.start + side).kind == RoomSlot.Kind.SECRET
		var expected: Door.Mode = Door.Mode.HIDDEN if is_secret else Door.Mode.OPEN
		assert_eq(room.doors[side].mode, expected, "puerta %s" % side)
	assert_true(_is_inside_room(room, _game.player.global_position), "el jugador arranca adentro")
	assert_eq(_game.world.get_node("GameCamera").global_position, room.global_position, "cámara en la sala")
	assert_eq(room.phase, Room.Phase.CLEARED, "la sala inicial no tiene combate")


func test_walking_through_a_door_moves_to_the_next_room() -> void:
	var side: Vector2i = _open_side_from_start()
	var start_room: Room = _floor.current_room()
	_game.player.global_position = start_room.entry_point(side)
	Input.action_press(MOVE_ACTIONS[side])
	for _i: int in 60:
		await wait_physics_frames(1)
		if _floor.current_cell != _layout.start:
			break
	Input.action_release(MOVE_ACTIONS[side])
	await wait_physics_frames(2)
	assert_eq(_floor.current_cell, _layout.start + side, "pasó a la sala de al lado")
	assert_false(_floor.is_transitioning(), "terminó la transición")
	var room: Room = _floor.current_room()
	assert_eq(_game.world.get_node("GameCamera").global_position, room.global_position, "la cámara llegó")
	assert_true(_is_inside_room(room, _game.player.global_position), "el jugador está adentro de la nueva sala")
	assert_true(_floor.visited.has(_layout.start + side))


func test_combat_room_locks_doors_until_cleared() -> void:
	var cell: Vector2i = _layout.cells_of_kind(RoomSlot.Kind.NORMAL)[0]
	await _floor.move_to(cell)
	await wait_physics_frames(2)
	var room: Room = _floor.current_room()
	assert_eq(room.phase, Room.Phase.FIGHTING)
	assert_gt(get_tree().get_nodes_in_group(Enemy.GROUP).size(), 0, "aparecieron enemigos")
	for door: Door in room.doors.values():
		assert_ne(door.mode, Door.Mode.OPEN, "puertas cerradas durante el combate")
	watch_signals(EventBus)
	await _clear_current_room()
	assert_eq(room.phase, Room.Phase.CLEARED)
	assert_signal_emitted(EventBus, "room_cleared")
	for door: Door in room.doors.values():
		if door.mode != Door.Mode.HIDDEN:
			assert_eq(door.mode, Door.Mode.OPEN, "puertas abiertas al limpiar")


func test_special_rooms_do_not_lock() -> void:
	await _floor.move_to(_layout.first_of_kind(RoomSlot.Kind.TREASURE))
	await wait_physics_frames(2)
	var room: Room = _floor.current_room()
	assert_eq(room.phase, Room.Phase.CLEARED)
	assert_eq(get_tree().get_nodes_in_group(Enemy.GROUP).size(), 0)
	for door: Door in room.doors.values():
		assert_eq(door.mode, Door.Mode.OPEN)


func test_bomb_reveals_the_secret_door() -> void:
	var secret: Vector2i = _layout.first_of_kind(RoomSlot.Kind.SECRET)
	var neighbor: Vector2i = _layout.neighbors(secret, false)[0]
	await _floor.move_to(neighbor)
	await _clear_current_room()
	var room: Room = _floor.current_room()
	var side: Vector2i = secret - neighbor
	assert_eq(room.doors[side].mode, Door.Mode.HIDDEN, "antes de la bomba no se ve")
	var bomb := BOMB_SCENE.instantiate() as Bomb
	bomb.position = room.entry_point(side)
	_game.world.get_node("Entities").add_child(bomb)
	await wait_physics_frames(roundi(Bomb.FUSE_TIME * 60.0) + 10)
	assert_eq(room.doors[side].mode, Door.Mode.OPEN, "la explosión destapó la puerta")
	assert_true(_floor.discovered_secrets.has(secret), "la secreta aparece en el minimapa")


func test_minimap_follows_visited_rooms() -> void:
	var side: Vector2i = _open_side_from_start()
	await _floor.move_to(_layout.start + side, side)
	var states: Dictionary[Vector2i, MinimapModel.CellState] = MinimapModel.compute(_layout, _floor.visited,
			_floor.current_cell, _floor.discovered_secrets, false)
	assert_eq(states[_layout.start], MinimapModel.CellState.VISITED)
	assert_eq(states[_layout.start + side], MinimapModel.CellState.CURRENT)


func _pedestals_in(room: Room) -> Array[ItemPedestal]:
	var result: Array[ItemPedestal] = []
	for child: Node in room.get_node("Pickups").get_children():
		if child is ItemPedestal:
			result.append(child as ItemPedestal)
	return result


## Camina hacia la puerta de ese lado desde adentro de la sala actual.
func _walk_into_door(room: Room, side: Vector2i) -> void:
	_game.player.global_position = room.entry_point(side)
	Input.action_press(MOVE_ACTIONS[side])
	await wait_physics_frames(15)
	Input.action_release(MOVE_ACTIONS[side])
	_game.player.global_position = room.to_global(room.spawn_point())
	await wait_physics_frames(2)


func test_treasure_room_has_a_free_item() -> void:
	await _floor.move_to(_layout.first_of_kind(RoomSlot.Kind.TREASURE))
	var pedestals: Array[ItemPedestal] = _pedestals_in(_floor.current_room())
	assert_eq(pedestals.size(), 1, "un pedestal")
	assert_not_null(pedestals[0].item, "con un item")
	assert_eq(pedestals[0].price, 0, "gratis")


func test_shop_opens_with_a_key_and_sells_items() -> void:
	var shop: Vector2i = _layout.first_of_kind(RoomSlot.Kind.SHOP)
	var neighbor: Vector2i = _layout.neighbors(shop, false)[0]
	await _floor.move_to(neighbor)
	await _clear_current_room()
	var room: Room = _floor.current_room()
	var side: Vector2i = shop - neighbor
	assert_eq(room.doors[side].mode, Door.Mode.LOCKED, "la tienda arranca con candado")
	RunState.add_keys(-RunState.keys)
	await _walk_into_door(room, side)
	assert_eq(room.doors[side].mode, Door.Mode.LOCKED, "sin llave no abre")
	RunState.add_keys(1)
	await _walk_into_door(room, side)
	assert_eq(room.doors[side].mode, Door.Mode.OPEN, "con la llave se abre")
	assert_eq(RunState.keys, 0, "y se gasta")
	# Al abrirse, el jugador puede haber seguido de largo y cruzado: se espera esa transición.
	for _i: int in 60:
		if not _floor.is_transitioning():
			break
		await wait_physics_frames(1)
	if _floor.current_cell != shop:
		await _floor.move_to(shop, side)
	var pedestals: Array[ItemPedestal] = _pedestals_in(_floor.current_room())
	assert_eq(pedestals.size(), FloorController.SHOP_OFFERS)
	for pedestal: ItemPedestal in pedestals:
		assert_gt(pedestal.price, 0, "en la tienda todo tiene precio")


func _exit_in(room: Room) -> Trapdoor:
	for child: Node in room.get_node("Pickups").get_children():
		if child is Trapdoor:
			return child as Trapdoor
	return null


## Va a la sala del jefe del piso actual, lo mata y espera a que la sala quede limpia.
func _beat_the_boss() -> Room:
	await _floor.move_to(_layout.first_of_kind(RoomSlot.Kind.BOSS))
	await wait_physics_frames(2)
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		(node as Enemy).health.kill()
	await wait_physics_frames(60)
	return _floor.current_room()


func test_beating_the_boss_gives_an_item_and_a_trapdoor() -> void:
	var room: Room = await _beat_the_boss()
	assert_eq(room.phase, Room.Phase.CLEARED)
	assert_eq(_pedestals_in(room).size(), 1, "el pedestal del jefe")
	assert_not_null(_pedestals_in(room)[0].item)
	var exit: Trapdoor = _exit_in(room)
	assert_not_null(exit, "apareció la trampilla")
	assert_false(exit.final, "en el piso 1 no es la salida final")


func test_trapdoor_takes_the_player_to_floor_two() -> void:
	var room: Room = await _beat_the_boss()
	RunState.use_blank()
	_game.player.global_position = _exit_in(room).global_position
	for _i: int in 180:
		await wait_physics_frames(1)
		if _floor.floor_index == 1 and not _floor.is_transitioning():
			break
	assert_eq(_floor.floor_index, 1, "piso 2")
	assert_eq(RunState.floor_index, 1)
	assert_eq(RunState.floor_name, "Cloacas")
	assert_eq(_floor.current_cell, _floor.layout.start, "arranca en la sala inicial")
	assert_eq(_game.world.get_node("Rooms").get_child_count(), 1, "las salas del piso 1 se borraron")
	assert_eq(RunState.blanks, RunState.START_BLANKS, "Pulsos recargados")
	assert_false(get_tree().paused)


func test_last_floor_exit_wins_the_run() -> void:
	_floor.load_floor(_floor.run.floors.size() - 1)
	_layout = _floor.layout
	var room: Room = await _beat_the_boss()
	var exit: Trapdoor = _exit_in(room)
	assert_true(exit.final, "en el último piso es la salida final")
	watch_signals(EventBus)
	_game.player.global_position = exit.global_position
	await wait_physics_frames(roundi(Trapdoor.ARM_TIME * 60.0) + 5)
	assert_signal_emitted_with_parameters(EventBus, "run_ended", [true])
