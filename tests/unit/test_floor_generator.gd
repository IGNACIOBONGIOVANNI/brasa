extends GutTest
## FloorGenerator sobre 500 seeds: conectividad, cantidad de salas, jefe lejos y en un callejón,
## salas especiales presentes (también las extra de cada piso, en callejones) y reglas de la secreta.
## Misma seed = mismo piso.

const SEEDS: int = 500
## Seeds por cada piso de la run (con los parámetros de su tema).
const SEEDS_PER_FLOOR: int = 200
const RUN: RunConfig = preload("res://content/run/run_config.tres")

var _params := FloorParams.new()


func _generate(seed_value: int, params: FloorParams = _params) -> FloorLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return FloorGenerator.generate(rng, params)


## Celdas alcanzables desde el inicio sin pasar por la secreta.
func _reachable(layout: FloorLayout) -> Dictionary[Vector2i, bool]:
	var seen: Dictionary[Vector2i, bool] = {layout.start: true}
	var queue: Array[Vector2i] = [layout.start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for next: Vector2i in layout.neighbors(cell, false):
			if not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


## Firma de texto del layout para comparar pisos.
func _signature(layout: FloorLayout) -> String:
	var parts := PackedStringArray()
	for cell: Vector2i in layout.slots:
		parts.append("%d,%d:%d" % [cell.x, cell.y, layout.slots[cell].kind])
	return ";".join(parts)


func test_every_seed_generates_a_valid_floor() -> void:
	var failures: int = 0
	for seed_value: int in SEEDS:
		var layout: FloorLayout = _generate(seed_value)
		if layout == null:
			failures += 1
			continue
		var problems: PackedStringArray = _problems(layout, _params)
		if not problems.is_empty():
			failures += 1
			if failures <= 5:
				gut.p("seed %d: %s" % [seed_value, ", ".join(problems)])
	assert_eq(failures, 0, "pisos inválidos en %d seeds" % SEEDS)


func test_every_floor_of_the_run_generates() -> void:
	for theme: FloorTheme in RUN.floors:
		var params := FloorParams.new()
		params.room_count_min = theme.room_count_min
		params.room_count_max = theme.room_count_max
		params.min_boss_distance = theme.min_boss_distance
		var failures: int = 0
		for seed_value: int in SEEDS_PER_FLOOR:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			params.extra_rooms = FloorGenerator.pick_extra_rooms(theme.extra_rooms, theme.extra_room_count, rng)
			var layout: FloorLayout = _generate(seed_value, params)
			if layout == null or not _problems(layout, params).is_empty():
				failures += 1
		assert_eq(failures, 0, "%s: pisos inválidos en %d seeds" % [theme.id, SEEDS_PER_FLOOR])


func _problems(layout: FloorLayout, params: FloorParams) -> PackedStringArray:
	var problems := PackedStringArray()
	var normal_rooms: int = layout.slots.size() - 1
	var counted: int = normal_rooms - params.extra_rooms.size()
	if counted < params.room_count_min or counted > params.room_count_max:
		problems.append("%d salas sin contar la secreta" % normal_rooms)
	if layout.get_slot(layout.start).kind != RoomSlot.Kind.START:
		problems.append("el inicio no es START")
	var unique: Array[RoomSlot.Kind] = [RoomSlot.Kind.BOSS, RoomSlot.Kind.TREASURE, RoomSlot.Kind.SHOP, RoomSlot.Kind.SECRET]
	for kind: RoomSlot.Kind in unique + params.extra_rooms:
		if layout.cells_of_kind(kind).size() != 1:
			problems.append("%d salas de tipo %d" % [layout.cells_of_kind(kind).size(), kind])
	if not problems.is_empty():
		return problems
	var reachable: Dictionary[Vector2i, bool] = _reachable(layout)
	if reachable.size() != normal_rooms:
		problems.append("solo se llega a %d de %d salas" % [reachable.size(), normal_rooms])
	# Árbol: sin ciclos (aristas = salas - 1; cada arista se cuenta desde sus dos salas).
	var edge_ends: int = 0
	for cell: Vector2i in reachable:
		edge_ends += layout.neighbors(cell, false).size()
	if edge_ends != 2 * (normal_rooms - 1):
		problems.append("hay ciclos")
	var boss: Vector2i = layout.first_of_kind(RoomSlot.Kind.BOSS)
	var boss_distance: int = layout.get_slot(boss).distance
	if boss_distance < params.min_boss_distance:
		problems.append("jefe a %d pasos" % boss_distance)
	var dead_end_kinds: Array[RoomSlot.Kind] = [RoomSlot.Kind.BOSS, RoomSlot.Kind.TREASURE, RoomSlot.Kind.SHOP]
	for kind: RoomSlot.Kind in dead_end_kinds + params.extra_rooms:
		if layout.neighbors(layout.first_of_kind(kind), false).size() != 1:
			problems.append("la sala %d no es un callejón" % kind)
	for cell: Vector2i in reachable:
		var slot: RoomSlot = layout.get_slot(cell)
		if cell != layout.start and layout.neighbors(cell, false).size() == 1 and slot.distance > boss_distance:
			problems.append("hay un callejón más lejos que el jefe")
	var secret: Vector2i = layout.first_of_kind(RoomSlot.Kind.SECRET)
	var around_secret: Array[Vector2i] = layout.neighbors(secret, false)
	if around_secret.size() < 2:
		problems.append("la secreta tiene %d vecinas" % around_secret.size())
	if around_secret.has(boss):
		problems.append("la secreta toca al jefe")
	for cell: Vector2i in layout.slots:
		if not layout.is_inside(cell):
			problems.append("sala fuera de la grilla")
	return problems


func test_extra_rooms_are_distinct_and_capped() -> void:
	var candidates: Array[RoomSlot.Kind] = [RoomSlot.Kind.CHALLENGE, RoomSlot.Kind.ALTAR, RoomSlot.Kind.WELL]
	var rng := RandomNumberGenerator.new()
	var all_seen: Dictionary[RoomSlot.Kind, bool] = {}
	for seed_value: int in 60:
		rng.seed = seed_value
		var picked: Array[RoomSlot.Kind] = FloorGenerator.pick_extra_rooms(candidates, 2, rng)
		assert_eq(picked.size(), 2)
		assert_ne(picked[0], picked[1], "distintas")
		for kind: RoomSlot.Kind in picked:
			all_seen[kind] = true
	assert_eq(all_seen.size(), candidates.size(), "todas pueden salir")
	assert_eq(FloorGenerator.pick_extra_rooms(candidates, 9, rng).size(), candidates.size(), "no más que las que hay")


func test_same_seed_gives_same_floor() -> void:
	for seed_value: int in [1, 42, 1234, 99999]:
		assert_eq(_signature(_generate(seed_value)), _signature(_generate(seed_value)), "seed %d" % seed_value)


func test_different_seeds_give_different_floors() -> void:
	var signatures: Dictionary[String, bool] = {}
	for seed_value: int in 50:
		signatures[_signature(_generate(seed_value))] = true
	assert_gt(signatures.size(), 45, "casi todos los pisos son distintos")


func test_distances_count_steps_from_start() -> void:
	var layout: FloorLayout = _generate(7)
	assert_eq(layout.get_slot(layout.start).distance, 0)
	for cell: Vector2i in layout.slots:
		var slot: RoomSlot = layout.get_slot(cell)
		if slot.kind == RoomSlot.Kind.SECRET or cell == layout.start:
			continue
		var closest: int = 1 << 30
		for next: Vector2i in layout.neighbors(cell, false):
			closest = mini(closest, layout.get_slot(next).distance)
		assert_eq(slot.distance, closest + 1, "distancia de %s" % cell)
