extends GutTest
## Hito 18: armazones (mechas). En la arena: tocarlo lo sube, los golpes le sacan blindaje y no vida,
## camina a su velocidad con su arma, rodar lo hace saltar afuera (queda parado con lo que le quedaba),
## sin blindaje revienta y el HUD muestra la barra. En un piso real: el Galpón trae su armazón.

const ARENA_SCENE: PackedScene = preload("res://tests/fixtures/arena.tscn")
const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const PARKED_MECH_SCENE: PackedScene = preload("res://entities/mechs/parked_mech.tscn")
const CALDERA: MechData = preload("res://content/mechs/caldera.tres")
const ZANCOS: MechData = preload("res://content/mechs/zancos.tres")
const GALPON: RoomTemplate = preload("res://content/rooms/floor_1/galpon.tres")
const TRABUCO: WeaponData = preload("res://content/weapons/trabuco.tres")
const SEED: int = 1234
const USED_ACTIONS: Array[StringName] = [&"dodge", &"move_right", &"swap_weapon"]

var _game: Game
var _player: Player


func before_each() -> void:
	GameRNG.start_run(SEED)
	RunState.start_run()


func after_each() -> void:
	for action: StringName in USED_ACTIONS:
		Input.action_release(action)


func _arena() -> void:
	_game = ARENA_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player


func _park(data: MechData, at: Vector2) -> ParkedMech:
	var parked := PARKED_MECH_SCENE.instantiate() as ParkedMech
	parked.setup(data)
	parked.position = at
	_game.world.get_node(^"Entities").add_child(parked)
	return parked


func _parked() -> Array[ParkedMech]:
	var result: Array[ParkedMech] = []
	for node: Node in _game.world.get_node(^"Entities").get_children():
		if node is ParkedMech and not node.is_queued_for_deletion():
			result.append(node as ParkedMech)
	return result


func _board(data: MechData) -> void:
	_park(data, _player.global_position)
	await wait_physics_frames(3)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await wait_physics_frames(1)
	Input.action_release(action)
	await wait_physics_frames(1)


func test_touching_a_mech_boards_it() -> void:
	_arena()
	var parked: ParkedMech = _park(CALDERA, _player.global_position + Vector2(20, 0))
	await wait_physics_frames(3)
	assert_false(_player.is_piloting(), "de lejos no")
	_player.global_position = parked.global_position
	await wait_physics_frames(3)
	assert_true(_player.is_piloting(), "al tocarlo se sube")
	assert_eq(_player.mech, CALDERA)
	assert_eq(_player.weapon.weapon(), CALDERA.weapon, "con su arma")
	assert_eq(_player.hurtbox.health, _player.mech_armor, "los golpes van al blindaje")
	assert_eq(_player.mech_armor.current, CALDERA.armor, "lleno")
	assert_eq(_parked().size(), 0, "ya no está parado")


func test_hits_take_armor_not_health() -> void:
	_arena()
	await _board(CALDERA)
	var health: float = _player.health.current
	assert_true(_player.hurtbox.receive_hit(HitInfo.create(2.0, Vector2.LEFT, 100.0)))
	assert_eq(_player.mech_armor.current, CALDERA.armor - 2.0, "le sacó blindaje")
	assert_eq(_player.health.current, health, "y nada de vida")
	var bar := _game.get_node(^"Hud/Mech") as MechDisplay
	assert_true(bar.visible, "el HUD muestra el blindaje")
	assert_almost_eq(bar.armor_fraction(), (CALDERA.armor - 2.0) / CALDERA.armor, 0.001)
	await wait_physics_frames(2)


func test_walks_at_the_mech_speed() -> void:
	_arena()
	await _board(ZANCOS)
	Input.action_press(&"move_right")
	await wait_physics_frames(30)
	assert_almost_eq(_player.move_velocity.x, ZANCOS.move_speed, 1.0, "a la velocidad del armazón")


func test_rolling_jumps_out_and_leaves_it_parked() -> void:
	_arena()
	await _board(CALDERA)
	_player.hurtbox.receive_hit(HitInfo.create(3.0, Vector2.LEFT, 0.0))
	await wait_physics_frames(2)
	Input.action_press(&"move_right")
	await _tap(&"dodge")
	assert_false(_player.is_piloting(), "saltó afuera")
	assert_eq(_player.machine.get_state_name(), &"Roll", "rodando")
	assert_eq(_player.hurtbox.health, _player.health, "los golpes vuelven a la vida")
	assert_eq(_player.weapon.slot, RunState.current_weapon_slot(), "y vuelve su arma")
	await wait_physics_frames(3)
	var parked: Array[ParkedMech] = _parked()
	assert_eq(parked.size(), 1, "el armazón quedó parado")
	assert_eq(parked[0].armor, CALDERA.armor - 3.0, "con el blindaje que le quedaba")
	await wait_physics_frames(30)
	assert_false(_player.is_piloting(), "no se vuelve a subir solo")
	Input.action_release(&"move_right")
	_player.global_position = parked[0].global_position
	await wait_physics_frames(3)
	assert_true(_player.is_piloting(), "volviendo a tocarlo, sí")
	assert_eq(_player.mech_armor.current, CALDERA.armor - 3.0)


func test_without_armor_it_breaks_and_hurts_enemies_near() -> void:
	_arena()
	await _board(ZANCOS)
	var tough := (preload("res://content/enemies/carnero.tres") as EnemyData).duplicate() as EnemyData
	tough.max_health = 100.0
	var enemy: Enemy = _game.spawn_enemy(tough, _player.global_position + Vector2(25, 0))
	await wait_physics_frames(2)
	var enemy_health: float = enemy.health.current
	var health: float = _player.health.current
	_player.hurtbox.receive_hit(HitInfo.create(ZANCOS.armor, Vector2.LEFT, 0.0))
	await wait_physics_frames(2)
	assert_false(_player.is_piloting(), "reventó")
	assert_eq(_parked().size(), 0, "no queda nada")
	assert_eq(_player.health.current, health, "el jugador sale sano")
	assert_true(_player.health.is_invulnerable(), "e invulnerable un momento")
	assert_lt(enemy.health.current, enemy_health, "la explosión lastimó al de al lado")
	assert_false((_game.get_node(^"Hud/Mech") as MechDisplay).visible, "la barra se esconde")
	await wait_physics_frames(3)


func test_no_weapon_swap_while_piloting() -> void:
	_arena()
	RunState.add_weapon(TRABUCO)
	await _board(CALDERA)
	RunState.add_weapon(TRABUCO)
	await _tap(&"swap_weapon")
	assert_eq(_player.weapon.weapon(), CALDERA.weapon, "sigue con el arma del armazón")
	Input.action_press(&"move_right")
	await _tap(&"dodge")
	assert_eq(_player.weapon.weapon(), RunState.current_weapon_slot().weapon, "al bajar, la suya")
	await wait_physics_frames(2)


func test_hangar_has_its_mech() -> void:
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_player = _game.player
	_player.health.always_invulnerable = true
	var floor_controller: FloorController = _game.floor_controller
	var hangar: Vector2i = FloorLayout.NO_CELL
	for cell: Vector2i in floor_controller.layout.slots:
		var slot: RoomSlot = floor_controller.layout.get_slot(cell)
		if slot.kind == RoomSlot.Kind.NORMAL and hangar == FloorLayout.NO_CELL:
			slot.kind = RoomSlot.Kind.HANGAR
			slot.template = GALPON
			slot.mech = ZANCOS
			hangar = cell
	await floor_controller.move_to(hangar)
	await wait_physics_frames(2)
	var found: ParkedMech = null
	for child: Node in floor_controller.current_room().get_node(^"Pickups").get_children():
		if child is ParkedMech:
			found = child as ParkedMech
	assert_not_null(found, "el Galpón tiene su armazón")
	assert_eq(found.data, ZANCOS)
	assert_eq(floor_controller.current_room().phase, Room.Phase.CLEARED, "sin pelea")
