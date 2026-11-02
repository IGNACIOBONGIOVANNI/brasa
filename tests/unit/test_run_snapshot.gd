extends GutTest
## Hito 20: la foto de una run a medias (RunSnapshot) pasa a JSON y vuelve igual, y una de otro
## formato no se sigue.


func _full_snapshot() -> RunSnapshot:
	var snapshot := RunSnapshot.new()
	snapshot.run_seed = 987654321
	snapshot.character = &"musgo"
	snapshot.floor_index = 2
	snapshot.run_time = 321.5
	snapshot.kills = 44
	snapshot.bosses_defeated.assign([&"campanario", &"rey_carnero"])
	snapshot.health = 3.5
	snapshot.blanks = 1
	snapshot.coins = 17
	snapshot.bombs = 3
	snapshot.keys = 2
	snapshot.items.assign([&"brasa_viva", &"hiel"])
	snapshot.active_item = &"botiquin"
	snapshot.active_charge = 2
	snapshot.weapon_paths.assign(["res://content/weapons/base_shot.tres", "res://content/weapons/haz.tres"])
	snapshot.weapon_magazines.assign([6, 30])
	snapshot.weapon_reserves.assign([-1, 120])
	snapshot.current_weapon = 1
	snapshot.taken.assign([&"brasa_viva", &"hiel", &"botiquin"])
	snapshot.mech = &"zancos"
	snapshot.mech_armor = 5.0
	snapshot.cell = Vector2i(4, 3)
	snapshot.position = Vector2(-12.5, 40)
	var offers: Array[StringName] = [&"grieta", &"agua_de_pozo"]
	snapshot.offers[Vector2i(5, 3)] = offers
	snapshot.hangar_mechs[Vector2i(3, 2)] = &"caldera"
	snapshot.visited.assign([Vector2i(4, 4), Vector2i(4, 3)])
	snapshot.discovered_secrets.assign([Vector2i(6, 6)])
	snapshot.map_revealed = true
	snapshot.opened_edges.assign([Vector4i(4, 3, 5, 3)])
	var room := RunSnapshot.RoomState.new()
	room.cleared = true
	var pedestal := RunSnapshot.PedestalState.new()
	pedestal.item = &"grieta"
	pedestal.price = 15
	pedestal.position = Vector2(-16, -16)
	room.pedestals.append(pedestal)
	var empty := RunSnapshot.PedestalState.new()
	empty.position = Vector2(16, -16)
	room.pedestals.append(empty)
	var pickup := RunSnapshot.PickupState.new()
	pickup.id = &"coin"
	pickup.position = Vector2(8, 24)
	room.pickups.append(pickup)
	room.broken_rocks.assign([Vector2i(3, 2)])
	room.well_dry = true
	var parked := RunSnapshot.MechState.new()
	parked.id = &"fuelle"
	parked.armor = 7.0
	parked.position = Vector2(0, 32)
	room.mechs.append(parked)
	snapshot.rooms[Vector2i(4, 3)] = room
	return snapshot


## Como queda después de guardarse en disco: JSON y de vuelta (los números vuelven como float).
func _through_json(snapshot: RunSnapshot) -> RunSnapshot:
	var json := JSON.new()
	assert_eq(json.parse(JSON.stringify(snapshot.to_dict())), OK)
	return RunSnapshot.from_dict(json.data as Dictionary)


func test_round_trip_keeps_everything() -> void:
	var original: RunSnapshot = _full_snapshot()
	var copy: RunSnapshot = _through_json(original)
	assert_not_null(copy)
	assert_eq(copy.to_dict(), _through_json(copy).to_dict(), "guardar dos veces da lo mismo")
	assert_eq(copy.run_seed, original.run_seed)
	assert_eq(copy.character, &"musgo")
	assert_eq(copy.floor_index, 2)
	assert_almost_eq(copy.run_time, 321.5, 0.001)
	assert_eq(copy.bosses_defeated, original.bosses_defeated)
	assert_eq(copy.health, 3.5)
	assert_eq([copy.blanks, copy.coins, copy.bombs, copy.keys], [1, 17, 3, 2])
	assert_eq(copy.items, original.items)
	assert_eq(copy.active_item, &"botiquin")
	assert_eq(copy.weapon_paths, original.weapon_paths)
	assert_eq(copy.weapon_magazines, original.weapon_magazines)
	assert_eq(copy.weapon_reserves, original.weapon_reserves, "la reserva infinita sigue siendo -1")
	assert_eq(copy.current_weapon, 1)
	assert_eq(copy.taken, original.taken)
	assert_eq(copy.mech, &"zancos")
	assert_eq(copy.cell, Vector2i(4, 3))
	assert_eq(copy.position, Vector2(-12.5, 40))
	assert_eq(copy.offers[Vector2i(5, 3)], original.offers[Vector2i(5, 3)])
	assert_eq(copy.hangar_mechs[Vector2i(3, 2)], &"caldera")
	assert_eq(copy.visited, original.visited)
	assert_eq(copy.discovered_secrets, original.discovered_secrets)
	assert_true(copy.map_revealed)
	assert_eq(copy.opened_edges, original.opened_edges)
	var room: RunSnapshot.RoomState = copy.rooms[Vector2i(4, 3)]
	assert_true(room.cleared)
	assert_eq(room.pedestals.size(), 2)
	assert_eq(room.pedestals[0].item, &"grieta")
	assert_eq(room.pedestals[0].price, 15)
	assert_eq(room.pedestals[1].item, &"", "el pedestal vacío sigue vacío")
	assert_eq(room.pickups[0].id, &"coin")
	assert_eq(room.pickups[0].position, Vector2(8, 24))
	assert_eq(room.broken_rocks, [Vector2i(3, 2)])
	assert_true(room.well_dry)
	assert_eq(room.mechs[0].id, &"fuelle")
	assert_eq(room.mechs[0].armor, 7.0)


func test_another_format_is_not_followed() -> void:
	var data: Dictionary = _full_snapshot().to_dict()
	data["format"] = RunSnapshot.FORMAT + 1
	assert_null(RunSnapshot.from_dict(data), "de otra versión del juego")
	assert_null(RunSnapshot.from_dict({}), "vacío")
	assert_null(RunSnapshot.from_dict({"format": RunSnapshot.FORMAT}), "sin seed ni personaje")
