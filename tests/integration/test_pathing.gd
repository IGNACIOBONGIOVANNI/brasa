extends GutTest
## Hito 19: los enemigos que caminan rodean fosos y rocas (RoomNav) y los que embisten no se quedan
## embistiendo contra un foso: antes, con el jugador del otro lado, el carnero cargaba contra el borde
## una y otra vez sin llegar nunca.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const SEED: int = 1234
## Una pared de fosos de arriba a abajo con huecos en la primera y en las dos últimas filas; el
## carnero (C) a la izquierda.
const PITS: String = """
...............
.......o.......
.......o.......
.......o.......
...C...o.......
.......o.......
.......o.......
...............
...............
"""
const ROCKS: String = """
...............
.......#.......
.......#.......
.......#.......
...C...#.......
.......#.......
.......#.......
...............
...............
"""
const PLAYER_CELL: Vector2i = Vector2i(11, 4)

var _game: Game
var _floor: FloorController
var _player: Player


func before_each() -> void:
	GameRNG.start_run(SEED)
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_floor = _game.floor_controller
	_player = _game.player
	_player.health.always_invulnerable = true


## Convierte una sala normal sin armar en una con esta plantilla y entra.
func _enter_room_with(layout: String) -> Room:
	var template := RoomTemplate.new()
	template.id = &"prueba_caminos"
	template.layout = layout
	for cell: Vector2i in _floor.layout.slots:
		var slot: RoomSlot = _floor.layout.get_slot(cell)
		if slot.kind == RoomSlot.Kind.NORMAL and _floor.get_room(cell) == null:
			slot.template = template
			slot.rule = null
			await _floor.move_to(cell)
			return _floor.current_room()
	return null


func _charger(room: Room) -> Enemy:
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		var enemy := node as Enemy
		var inside: bool = Rect2(-Enemy.ROOM_HALF, Enemy.ROOM_HALF * 2.0).has_point(room.to_local(enemy.global_position))
		if enemy.data.attack_kind == EnemyData.AttackKind.CHARGE and inside:
			return enemy
	return null


## Frames hasta que el enemigo llega a `reach` px del jugador (o -1 si no llegó).
func _frames_to_reach(enemy: Enemy, reach: float, max_frames: int) -> int:
	for frame: int in max_frames:
		if enemy.global_position.distance_to(_player.global_position) <= reach:
			return frame
		await wait_physics_frames(1)
	return -1


func test_charger_goes_around_the_pits_to_reach_the_player() -> void:
	var room: Room = await _enter_room_with(PITS)
	assert_not_null(room)
	_player.global_position = room.to_global(RoomGrid.cell_center(PLAYER_CELL))
	await wait_physics_frames(2)
	var charger: Enemy = _charger(room)
	assert_not_null(charger, "está el carnero")
	assert_not_null(charger.nav, "la sala le pasó sus caminos")
	assert_false(charger.has_clear_path(_player.global_position), "los fosos tapan la línea recta")
	var frames: int = await _frames_to_reach(charger, 24.0, 600)
	assert_gt(frames, -1, "rodeó los fosos y llegó al jugador")


func test_charger_goes_around_rocks_and_reaches_when_one_breaks() -> void:
	var room: Room = await _enter_room_with(ROCKS)
	_player.global_position = room.to_global(RoomGrid.cell_center(PLAYER_CELL))
	await wait_physics_frames(2)
	var charger: Enemy = _charger(room)
	assert_not_null(charger)
	assert_gt(await _frames_to_reach(charger, 24.0, 600), -1, "rodeó las rocas")
	assert_false(room.nav.is_open(Vector2i(7, 4)))
	for node: Node in get_tree().get_nodes_in_group(Rock.GROUP):
		var rock := node as Rock
		if room.to_local(rock.global_position) == RoomGrid.cell_center(Vector2i(7, 4)):
			rock.destroy()
	await wait_physics_frames(2)
	assert_true(room.nav.is_open(Vector2i(7, 4)), "la roca rota deja pasar")


func test_charger_never_charges_into_a_pit() -> void:
	var room: Room = await _enter_room_with(PITS)
	_player.global_position = room.to_global(RoomGrid.cell_center(PLAYER_CELL))
	await wait_physics_frames(2)
	var charger: Enemy = _charger(room)
	assert_not_null(charger)
	for _frame: int in 240:
		var state: StringName = charger.machine.get_state_name()
		if state == &"Telegraph":
			assert_true(charger.has_clear_path(_player.global_position), "solo avisa la embestida con el camino libre")
			break
		await wait_physics_frames(1)
	for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
		(node as Enemy).health.kill()
	await wait_physics_frames(25)
