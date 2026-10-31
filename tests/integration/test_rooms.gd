extends GutTest
## Hito 3 en la sala fija de pruebas: fosos, bombas (rocas, daño) y pickups.

const GAME_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const ROOM_SCENE: PackedScene = preload("res://world/room.tscn")
const FLOOR_1: FloorTheme = preload("res://content/floors/floor_1.tres")
const PICKUP_SCENE: PackedScene = preload("res://entities/pickups/pickup.tscn")
const BULLET_SCENE: PackedScene = preload("res://entities/bullets/bullet.tscn")
const VIGIA: EnemyData = preload("res://content/enemies/vigia.tres")
## Sala con una fila de fosos en el medio (fila 4).
const PIT_ROW_LAYOUT: String = """
...............
...............
...............
...............
.ooooo...ooooo.
...............
...............
...............
...............
"""
const USED_ACTIONS: Array[StringName] = [&"bomb", &"move_down", &"aim_right", &"dodge"]

var _game: Game
var _player: Player


func before_each() -> void:
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player


func after_each() -> void:
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_physics_frames(1)
	Input.action_release(action)


func _pickup(id: String, at: Vector2) -> Pickup:
	var pickup := PICKUP_SCENE.instantiate() as Pickup
	pickup.data = load("res://content/pickups/%s.tres" % id)
	pickup.position = at
	_game.world.add_child(pickup)
	return pickup


## Sala suelta armada con una plantilla de prueba, lejos de la sala fija.
func _build_room(text: String, at: Vector2) -> Room:
	var template := RoomTemplate.new()
	template.layout = text
	var slot := RoomSlot.new(Vector2i.ZERO)
	slot.template = template
	var room := ROOM_SCENE.instantiate() as Room
	room.position = at
	var no_neighbors: Dictionary[Vector2i, RoomSlot.Kind] = {}
	var no_barriers: Dictionary[Vector2i, Door.Mode] = {}
	room.setup(slot, FLOOR_1, no_neighbors, no_barriers, _game.world.get_node("Entities") as Node2D)
	_game.world.add_child(room)
	return room


func test_pits_stop_the_player_but_not_bullets() -> void:
	var room: Room = _build_room(PIT_ROW_LAYOUT, Vector2(0, 1000))
	await wait_physics_frames(1)
	# Arriba del foso de la izquierda (columna 2), caminando hacia abajo.
	_player.global_position = room.to_global(RoomGrid.cell_center(Vector2i(2, 2)))
	Input.action_press(&"move_down")
	await wait_physics_frames(90)
	var pit_top: float = room.to_global(RoomGrid.cell_center(Vector2i(2, 4))).y - RoomGrid.TILE * 0.5
	assert_lt(_player.global_position.y, pit_top, "el foso frenó al jugador")
	var bullet := Bullet.spawn(get_tree(), BULLET_SCENE, ShotSpec.from_pattern(BulletPatternData.new()),
			room.to_global(RoomGrid.cell_center(Vector2i(3, 2))), Vector2.DOWN,
			PhysicsLayers.ENEMY_BULLET, PhysicsLayers.WALL)
	await wait_physics_frames(30)
	assert_true(is_instance_valid(bullet), "la bala pasó por arriba del foso")
	assert_gt(bullet.global_position.y, pit_top + RoomGrid.TILE, "ya cruzó la fila de fosos")


func test_bomb_breaks_rocks_and_hurts_everyone_near() -> void:
	# Roca en (-80, 32). El jugador queda al lado y un Vigía cerca, quieto (sigue apareciendo).
	_player.global_position = Vector2(-60, 32)
	var still := VIGIA.duplicate() as EnemyData
	still.spawn_delay = 10.0
	var enemy: Enemy = _game.spawn_enemy(still, Vector2(-45, 12))
	var rock: Node = _game.world.get_node("Room/Rocks/Rock3")
	assert_eq(RunState.bombs, RunState.START_BOMBS)
	await _tap(&"bomb")
	await wait_physics_frames(2)
	assert_eq(RunState.bombs, RunState.START_BOMBS - 1, "gastó una bomba")
	assert_eq(get_tree().get_nodes_in_group(Fx.ENTITIES_GROUP)[0].get_children().filter(
			func(node: Node) -> bool: return node is Bomb).size(), 1, "la bomba está en el piso")
	await wait_physics_frames(roundi(Bomb.FUSE_TIME * 60.0) + 10)
	assert_false(is_instance_valid(rock), "la roca se rompió")
	assert_false(is_instance_valid(enemy), "el Vigía murió")
	assert_eq(_player.health.current, _player.health.max_health - Bomb.PLAYER_DAMAGE, "al jugador le sacó medio corazón")


func _bombs() -> Array[Bomb]:
	var result: Array[Bomb] = []
	for node: Node in get_tree().get_nodes_in_group(Fx.ENTITIES_GROUP)[0].get_children():
		if node is Bomb:
			result.append(node as Bomb)
	return result


func test_holding_the_bomb_button_aims_and_throws_it() -> void:
	_player.global_position = Vector2(-40, 56)
	Input.action_press(&"aim_right")
	Input.action_press(&"bomb")
	await wait_seconds(Player.BOMB_HOLD_TIME + 0.2)
	assert_true(_player.bomb_aim.is_shown(), "mientras se mantiene, marca dónde cae")
	assert_eq(_bombs().size(), 0, "todavía no la tiró")
	Input.action_release(&"bomb")
	await wait_physics_frames(2)
	assert_false(_player.bomb_aim.is_shown(), "al soltar se va la marca")
	assert_eq(RunState.bombs, RunState.START_BOMBS - 1, "gastó una")
	await wait_seconds(Bomb.FLIGHT_TIME + 0.1)
	var bomb: Bomb = _bombs()[0]
	assert_false(bomb.is_flying(), "ya cayó")
	assert_gt(bomb.global_position.x - _player.global_position.x, Player.BOMB_THROW_MIN - 4.0, "lejos, hacia la mira")


func test_thrown_bomb_lands_before_the_wall() -> void:
	_player.global_position = Vector2(60, 56)
	Input.action_press(&"aim_right")
	Input.action_press(&"bomb")
	await wait_seconds(Player.BOMB_HOLD_TIME + Player.BOMB_CHARGE_TIME + 0.1)
	Input.action_release(&"bomb")
	await wait_seconds(Bomb.FLIGHT_TIME + 0.15)
	var bomb: Bomb = _bombs()[0]
	assert_lt(bomb.global_position.x, 120.0, "no pasa la pared")
	assert_gt(bomb.global_position.x, 90.0, "pero llega lo más lejos que puede")


func test_rolling_cancels_the_aim_without_spending_the_bomb() -> void:
	Input.action_press(&"aim_right")
	Input.action_press(&"bomb")
	await wait_seconds(Player.BOMB_HOLD_TIME + 0.1)
	assert_true(_player.bomb_aim.is_shown())
	await _tap(&"dodge")
	await wait_physics_frames(1)
	assert_false(_player.bomb_aim.is_shown(), "rodar la cancela")
	Input.action_release(&"bomb")
	await wait_seconds(0.5)
	assert_eq(RunState.bombs, RunState.START_BOMBS, "no gastó la bomba")
	assert_eq(_bombs().size(), 0)


func test_without_bombs_nothing_is_placed() -> void:
	RunState.use_bomb()
	await _tap(&"bomb")
	await wait_physics_frames(2)
	assert_eq(get_tree().get_nodes_in_group(Fx.ENTITIES_GROUP)[0].get_children().filter(
			func(node: Node) -> bool: return node is Bomb).size(), 0)


func test_coins_bombs_and_keys_are_collected() -> void:
	_pickup("coin", _player.position)
	_pickup("bomb", _player.position + Vector2(2, 0))
	_pickup("key", _player.position + Vector2(-2, 0))
	await wait_physics_frames(5)
	assert_eq(RunState.coins, 1)
	assert_eq(RunState.bombs, RunState.START_BOMBS + 1)
	assert_eq(RunState.keys, RunState.START_KEYS + 1)
	await wait_physics_frames(1)


func test_heart_waits_until_the_player_is_hurt() -> void:
	var heart: Pickup = _pickup("heart", _player.position)
	await wait_physics_frames(5)
	assert_true(is_instance_valid(heart), "con vida llena el corazón queda en el piso")
	_player.health.take_damage(2.0)
	await wait_physics_frames(5)
	assert_false(is_instance_valid(heart), "lo agarró")
	assert_eq(_player.health.current, _player.health.max_health, "curó un corazón entero")
	await wait_physics_frames(1)


func test_popping_reward_cannot_be_collected_mid_air() -> void:
	var coin: Pickup = _pickup("coin", _player.position)
	coin.pop()
	await wait_physics_frames(5)
	assert_true(is_instance_valid(coin), "en el aire no se agarra")
	await wait_physics_frames(30)
	assert_false(is_instance_valid(coin), "al caer sí")
	await wait_physics_frames(1)
