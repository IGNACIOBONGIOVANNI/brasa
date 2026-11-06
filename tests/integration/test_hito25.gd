extends GutTest
## Hito 25: cada arma con su descripción, que sale en un cartel al acercarse a un pedestal fuera de
## combate (lo mismo para cualquier item) y en la Mochila, y un símbolo propio para cada sala especial
## (en el minimapa y en la puerta que lleva a ella).

const GAME_SCENE: PackedScene = preload("res://main/game.tscn")
const CATALOG: ItemCatalog = preload("res://content/items/catalog.tres")
const RUN: RunConfig = preload("res://content/run/run_config.tres")
const SPECIAL_KINDS: Array[RoomSlot.Kind] = [RoomSlot.Kind.BOSS, RoomSlot.Kind.TREASURE, RoomSlot.Kind.SHOP,
		RoomSlot.Kind.SECRET, RoomSlot.Kind.CHALLENGE, RoomSlot.Kind.ALTAR, RoomSlot.Kind.WELL, RoomSlot.Kind.HANGAR,
		RoomSlot.Kind.MINIBOSS]

var _game: Game
var _floor: FloorController
var _player: Player


func before_each() -> void:
	GameRNG.start_run(1234)
	RunState.start_run()
	_game = GAME_SCENE.instantiate() as Game
	add_child_autofree(_game)
	_floor = _game.floor_controller
	_player = _game.player
	_player.health.always_invulnerable = true
	await wait_physics_frames(1)


func after_each() -> void:
	get_tree().paused = false


func _info() -> PedestalInfo:
	return (_game.get_node(^"Hud") as Hud).pedestal_info


func _pedestals() -> Array[ItemPedestal]:
	var result: Array[ItemPedestal] = []
	for node: Node in get_tree().get_nodes_in_group(ItemPedestal.GROUP):
		if not node.is_queued_for_deletion():
			result.append(node as ItemPedestal)
	return result


# --- Descripciones -----------------------------------------------------------------------


func test_every_weapon_has_a_short_description() -> void:
	var weapons: Array[WeaponData] = [RunState.BASE_WEAPON]
	for item: ItemData in CATALOG.items:
		if item.weapon != null:
			weapons.append(item.weapon)
			assert_eq(item.describe(), item.weapon.description, "%s: el item cuenta lo de su arma" % item.id)
	for mech: MechData in RUN.mechs:
		weapons.append(mech.weapon)
	for weapon: WeaponData in weapons:
		assert_ne(weapon.description, "", "%s: tiene descripción" % weapon.id)
		assert_lt(weapon.description.length(), 100, "%s: es corta" % weapon.id)


func test_the_pedestal_tells_what_it_has_out_of_combat() -> void:
	await _floor.move_to(_floor.layout.first_of_kind(RoomSlot.Kind.TREASURE))
	await wait_physics_frames(2)
	var pedestal: ItemPedestal = _pedestals()[0]
	_player.global_position = pedestal.global_position + Vector2(0, PedestalInfo.REACH + 20.0)
	await wait_process_frames(2)
	assert_null(_info().shown_item(), "de lejos no dice nada")
	# Desde arriba del pedestal (el jugador queda en la mitad de arriba de la pantalla).
	_player.global_position = pedestal.global_position + Vector2(0, -(PedestalInfo.REACH - 14.0))
	await wait_process_frames(2)
	assert_eq(_info().shown_item(), pedestal.item, "cerca muestra el item")
	assert_eq(_info().description_text(), pedestal.item.describe(), "con la misma descripción de la Mochila")
	assert_string_contains(_info().title_text(), pedestal.item.display_name)
	assert_string_contains(_info().title_text(), pedestal.item.quality_name(), "y su calidad")
	assert_false(_info().is_at_top(), "el jugador arriba de la mitad: el cartel va abajo")
	var enemy: Enemy = _game.spawn_enemy(load("res://content/enemies/carnero.tres") as EnemyData,
			pedestal.global_position + Vector2(60, 0))
	await wait_process_frames(2)
	assert_null(_info().shown_item(), "en combate no aparece")
	enemy.queue_free()
	await wait_physics_frames(2)


func test_the_card_moves_up_when_the_player_is_low() -> void:
	await _floor.move_to(_floor.layout.first_of_kind(RoomSlot.Kind.TREASURE))
	await wait_physics_frames(2)
	var pedestal: ItemPedestal = _pedestals()[0]
	_player.global_position = pedestal.global_position + Vector2(0, PedestalInfo.REACH - 4.0)
	await wait_process_frames(2)
	assert_true(_info().is_at_top(), "con el jugador en la mitad de abajo el cartel sube")


func test_prices_are_explained() -> void:
	assert_eq(PedestalInfo.price_text(8, 0), "8 monedas")
	assert_eq(PedestalInfo.price_text(1, 0), "1 moneda")
	assert_eq(PedestalInfo.price_text(0, 2), "cuesta 1 corazón de vida máxima", "el Altar cobra el contenedor")
	assert_eq(PedestalInfo.price_text(0, 0), "", "gratis no dice nada")
	assert_eq(PedestalInfo.kind_name(load("res://content/items/arma_trabuco.tres") as ItemData), "Arma")


func test_the_backpack_shows_the_same_description() -> void:
	var item := load("res://content/items/arma_trabuco.tres") as ItemData
	RunState.add_item(item)
	var inventory := _game.get_node(^"Inventory") as InventoryMenu
	inventory.open()
	await wait_process_frames(2)
	assert_eq(inventory.detail_title(), "Trabuco", "arranca en el arma en la mano")
	assert_eq(inventory.detail_text(), item.describe(), "la misma descripción que en el pedestal")
	inventory.close()
	await wait_physics_frames(1)


# --- Símbolos de las salas especiales ------------------------------------------------------


func test_each_special_room_has_its_own_symbol() -> void:
	var seen: Dictionary[String, bool] = {}
	for kind: RoomSlot.Kind in SPECIAL_KINDS:
		var symbol: PackedStringArray = PixelIcons.room_symbol(kind)
		assert_eq(PixelIcons.size_of(symbol), Vector2(5, 5), "%d: símbolo de 5 x 5" % kind)
		var key: String = "".join(symbol)
		assert_false(seen.has(key), "%d: no se repite" % kind)
		seen[key] = true
		assert_true(Minimap.ICON_COLORS.has(kind), "%d: tiene su color en el minimapa" % kind)
	assert_eq(PixelIcons.room_symbol(RoomSlot.Kind.NORMAL).size(), 0, "las normales no tienen")
	assert_eq(PixelIcons.room_symbol(RoomSlot.Kind.START).size(), 0)
	assert_eq(seen.size(), RoomSlot.Kind.size() - 2, "todas las especiales tienen el suyo")


func test_the_door_shows_the_symbol_of_the_room_behind() -> void:
	var boss: Vector2i = _floor.layout.first_of_kind(RoomSlot.Kind.BOSS)
	var before: Vector2i = _floor.layout.neighbors(boss, false)[0]
	await _floor.move_to(before)
	await wait_physics_frames(2)
	var room: Room = _floor.current_room()
	var door: Door = room.doors[boss - before]
	var visual := door.get_node(^"Visual") as DoorVisual
	assert_eq(visual.symbol, PixelIcons.room_symbol(RoomSlot.Kind.BOSS), "la puerta al jefe tiene la calavera")
	assert_eq(visual.symbol_rotation, -door.rotation, "derecho aunque la puerta esté rotada")
	for side: Vector2i in room.doors:
		var other: RoomSlot.Kind = _floor.layout.get_slot(before + side).kind
		var other_visual := (room.doors[side] as Door).get_node(^"Visual") as DoorVisual
		assert_eq(other_visual.symbol, PixelIcons.room_symbol(other), "cada puerta con el de su sala")
