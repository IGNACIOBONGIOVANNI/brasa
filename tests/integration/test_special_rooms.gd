extends GutTest
## Hito 16: reglas de sala y salas especiales nuevas en un piso real (seed fija). Para no depender de
## qué tocó en el piso, cada test convierte una sala normal todavía sin armar en la que necesita
## (tipo, plantilla, regla y ofertas) antes de entrar.

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const SEED: int = 1234
const CATALOG: ItemCatalog = preload("res://content/items/catalog.tres")
const PRUEBA: RoomTemplate = preload("res://content/rooms/floor_1/prueba.tres")
const ALTAR: RoomTemplate = preload("res://content/rooms/floor_1/altar.tres")
const POZO: RoomTemplate = preload("res://content/rooms/floor_1/pozo.tres")
const FURIA: RoomRule = preload("res://content/rules/furia.tres")
const EXTRA_KINDS: Array[RoomSlot.Kind] = [RoomSlot.Kind.CHALLENGE, RoomSlot.Kind.ALTAR, RoomSlot.Kind.WELL,
		RoomSlot.Kind.HANGAR]

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


func after_each() -> void:
	Input.action_release(&"blank")


func _hud() -> Hud:
	return _game.get_node(^"Hud") as Hud


## Una sala normal lejos del inicio que todavía no se armó, convertida en `kind`.
func _prepare(kind: RoomSlot.Kind, template: RoomTemplate, rule: RoomRule, offers: Array[ItemData]) -> Vector2i:
	for cell: Vector2i in _floor.layout.slots:
		var slot: RoomSlot = _floor.layout.get_slot(cell)
		if slot.kind == RoomSlot.Kind.NORMAL and _floor.get_room(cell) == null:
			slot.kind = kind
			if template != null:
				slot.template = template
			slot.rule = rule
			slot.offers = offers
			return cell
	return FloorLayout.NO_CELL


func _passives(count: int) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item: ItemData in CATALOG.items:
		if item.kind == ItemData.Kind.PASSIVE and result.size() < count:
			result.append(item)
	return result


func _pickups_in(room: Room) -> int:
	var count: int = 0
	for child: Node in room.get_node(^"Pickups").get_children():
		if child is Pickup:
			count += 1
	return count


func _pedestals_in(room: Room) -> Array[ItemPedestal]:
	var result: Array[ItemPedestal] = []
	for child: Node in room.get_node(^"Pickups").get_children():
		if child is ItemPedestal and not child.is_queued_for_deletion():
			result.append(child as ItemPedestal)
	return result


## Mata a todos los enemigos hasta que la sala quede limpia (puede tener dos oleadas).
func _clear_current_room() -> void:
	for _attempt: int in 6:
		for node: Node in get_tree().get_nodes_in_group(Enemy.GROUP):
			(node as Enemy).health.kill()
		await wait_physics_frames(60)
		if _floor.current_room().phase == Room.Phase.CLEARED:
			return


func _press_blank() -> void:
	Input.action_press(&"blank")
	await wait_physics_frames(2)
	Input.action_release(&"blank")
	await wait_physics_frames(2)


func test_the_floor_has_its_extra_special_rooms() -> void:
	var found: int = 0
	for kind: RoomSlot.Kind in EXTRA_KINDS:
		for cell: Vector2i in _floor.layout.cells_of_kind(kind):
			found += 1
			var slot: RoomSlot = _floor.layout.get_slot(cell)
			assert_eq(slot.template.kind, kind, "plantilla de su tipo")
			assert_eq(_floor.layout.neighbors(cell, false).size(), 1, "en un callejón")
			if kind == RoomSlot.Kind.CHALLENGE:
				assert_not_null(slot.rule, "la Prueba tiene regla")
	assert_eq(found, _floor.theme.extra_room_count)


func test_a_rule_room_announces_itself_and_changes_the_enemies() -> void:
	var rule := RoomRule.new()
	rule.display_name = "Prueba de regla"
	rule.enemy_health_mult = 2.0
	rule.enemy_pace = 1.5
	rule.bonus_rewards = 3
	var none: Array[ItemData] = []
	var cell: Vector2i = _prepare(RoomSlot.Kind.NORMAL, null, rule, none)
	watch_signals(EventBus)
	await _floor.move_to(cell)
	await wait_physics_frames(2)
	assert_signal_emitted_with_parameters(EventBus, "room_rule_changed", [rule])
	assert_string_contains(_hud().rule_text(), "Prueba de regla", "queda escrita arriba")
	var enemies: Array[Node] = get_tree().get_nodes_in_group(Enemy.GROUP)
	assert_gt(enemies.size(), 0)
	for node: Node in enemies:
		var enemy := node as Enemy
		assert_eq(enemy.pace, 1.5, "más rápidos")
		assert_almost_eq(enemy.health.max_health, enemy.data.max_health * _floor.theme.enemy_health_mult * 2.0, 0.001,
				"aguantan el doble")
	var room: Room = _floor.current_room()
	var before: int = _pickups_in(room)
	await _clear_current_room()
	assert_eq(room.phase, Room.Phase.CLEARED)
	assert_eq(_hud().rule_text(), "", "al limpiarla se borra")
	assert_gte(_pickups_in(room), before + 3, "suelta los pickups extra")


func test_fragile_and_no_pulse_last_only_during_the_fight() -> void:
	var rule := RoomRule.new()
	rule.display_name = "Frágil sin Pulso"
	rule.damage_taken_mult = 2.0
	rule.no_pulse = true
	var none: Array[ItemData] = []
	await _floor.move_to(_prepare(RoomSlot.Kind.NORMAL, null, rule, none))
	await wait_physics_frames(2)
	assert_eq(_player.hurtbox.damage_multiplier, 2.0, "cada golpe pega el doble")
	var blanks: int = RunState.blanks
	await _press_blank()
	assert_eq(RunState.blanks, blanks, "el Pulso no funciona")
	await _clear_current_room()
	assert_eq(_player.hurtbox.damage_multiplier, 1.0, "al limpiarla vuelve a la normalidad")
	await _press_blank()
	assert_eq(RunState.blanks, blanks - 1, "y el Pulso anda")


func test_the_clock_runs_out() -> void:
	var rule := RoomRule.new()
	rule.display_name = "Reloj"
	rule.time_limit = 0.2
	var none: Array[ItemData] = []
	await _floor.move_to(_prepare(RoomSlot.Kind.NORMAL, null, rule, none))
	await wait_physics_frames(2)
	assert_string_contains(_hud().rule_text(), "s", "muestra los segundos")
	await wait_physics_frames(30)
	assert_eq(_floor.current_room().rule_time_left(), 0.0)
	assert_string_contains(_hud().rule_text(), "sin premio")
	await _clear_current_room()


func test_challenge_gives_its_item_after_both_waves() -> void:
	var offers: Array[ItemData] = _passives(1)
	await _floor.move_to(_prepare(RoomSlot.Kind.CHALLENGE, PRUEBA, FURIA, offers))
	await wait_physics_frames(2)
	var room: Room = _floor.current_room()
	assert_eq(room.phase, Room.Phase.FIGHTING, "la Prueba se pelea")
	assert_eq(_pedestals_in(room).size(), 0, "el premio todavía no está")
	assert_string_contains(_hud().rule_text(), FURIA.display_name)
	await _clear_current_room()
	var pedestals: Array[ItemPedestal] = _pedestals_in(room)
	assert_eq(pedestals.size(), 1, "al ganar aparece el pedestal")
	assert_eq(pedestals[0].item, offers[0])
	assert_eq(pedestals[0].price, 0, "gratis")


func test_altar_charges_health_and_keeps_only_one() -> void:
	var offers: Array[ItemData] = _passives(2)
	await _floor.move_to(_prepare(RoomSlot.Kind.ALTAR, ALTAR, null, offers))
	await wait_physics_frames(2)
	var room: Room = _floor.current_room()
	assert_eq(room.phase, Room.Phase.CLEARED, "sin pelea")
	var pedestals: Array[ItemPedestal] = _pedestals_in(room)
	assert_eq(pedestals.size(), FloorController.ALTAR_OFFERS)
	for pedestal: ItemPedestal in pedestals:
		assert_eq(pedestal.health_price, Room.ALTAR_HEALTH_PRICE, "se paga con vida")
	var health: float = _player.health.current
	_player.global_position = pedestals[0].global_position
	await wait_physics_frames(3)
	assert_eq(_player.health.current, health - Room.ALTAR_HEALTH_PRICE, "cobró un corazón")
	assert_has(RunState.items, offers[0], "se llevó el item")
	await wait_physics_frames(2)
	assert_false(is_instance_valid(pedestals[1]), "el otro desapareció")


func test_altar_never_kills() -> void:
	var offers: Array[ItemData] = _passives(2)
	await _floor.move_to(_prepare(RoomSlot.Kind.ALTAR, ALTAR, null, offers))
	await wait_physics_frames(2)
	_player.health.always_invulnerable = false
	_player.health.take_damage(_player.health.current - Room.ALTAR_HEALTH_PRICE)
	var pedestals: Array[ItemPedestal] = _pedestals_in(_floor.current_room())
	_player.global_position = pedestals[0].global_position
	await wait_physics_frames(3)
	assert_eq(_player.health.current, float(Room.ALTAR_HEALTH_PRICE), "con un corazón no alcanza")
	assert_does_not_have(RunState.items, offers[0])
	assert_eq(_pedestals_in(_floor.current_room()).size(), FloorController.ALTAR_OFFERS, "siguen los dos")


func test_well_heals_and_refills_pulses_once() -> void:
	var none: Array[ItemData] = []
	await _floor.move_to(_prepare(RoomSlot.Kind.WELL, POZO, null, none))
	await wait_physics_frames(2)
	var well: Well = null
	for child: Node in _floor.current_room().get_node(^"Pickups").get_children():
		if child is Well:
			well = child as Well
	assert_not_null(well, "la sala tiene su pozo")
	_player.global_position = well.global_position
	await wait_physics_frames(3)
	assert_false(well.dry, "con todo lleno no se gasta")
	_player.global_position = _floor.current_room().to_global(_floor.current_room().spawn_point())
	_player.health.always_invulnerable = false
	_player.health.take_damage(3.0)
	RunState.set_blanks(0)
	await wait_physics_frames(2)
	_player.global_position = well.global_position
	await wait_physics_frames(3)
	assert_true(well.dry, "se secó")
	assert_eq(_player.health.current, _player.health.max_health, "curó todo")
	assert_eq(RunState.blanks, RunState.START_BLANKS, "devolvió los Pulsos")
	await wait_physics_frames(2)
