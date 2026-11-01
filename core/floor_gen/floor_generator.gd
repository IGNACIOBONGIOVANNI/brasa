class_name FloorGenerator
extends RefCounted
## Genera el layout de un piso. Lógica pura: con el mismo RNG (misma seed) sale el mismo piso.
##
## Crece desde la sala del centro con una cola: cada sala intenta abrir vecinas en orden al azar, y
## una celda solo se ocupa si no toca otra sala (así no hay ciclos ni bloques de salas pegadas).
## Después: jefe en el callejón sin salida más lejano, tesoro, tienda y las especiales extra
## (FloorParams.extra_rooms, cada una suma una sala) en otros callejones, y la secreta en una celda
## vacía con 2 o más vecinas que no toque al jefe. Si algo no se cumple, reintenta con el mismo RNG
## (sigue siendo determinista).

const MAX_ATTEMPTS: int = 500


static func generate(rng: RandomNumberGenerator, params: FloorParams) -> FloorLayout:
	for _attempt: int in MAX_ATTEMPTS:
		var room_count: int = rng.randi_range(params.room_count_min, params.room_count_max) + params.extra_rooms.size()
		var layout: FloorLayout = _try_generate(rng, params, room_count)
		if layout != null:
			return layout
	push_error("FloorGenerator: no se pudo generar un piso con estos parámetros")
	return null


static func _try_generate(rng: RandomNumberGenerator, params: FloorParams, room_count: int) -> FloorLayout:
	var layout := FloorLayout.new()
	layout.grid_size = params.grid_size
	layout.start = Vector2i(floori(params.grid_size.x * 0.5), floori(params.grid_size.y * 0.5))
	layout.slots[layout.start] = RoomSlot.new(layout.start, RoomSlot.Kind.START)
	var queue: Array[Vector2i] = [layout.start]
	while not queue.is_empty() and layout.slots.size() < room_count:
		var cell: Vector2i = queue.pop_front()
		for direction: Vector2i in _shuffled(FloorLayout.DIRECTIONS, rng):
			var next: Vector2i = cell + direction
			if layout.slots.size() >= room_count or not layout.is_inside(next) or layout.has_room(next):
				continue
			# Solo si su única vecina es la sala de la que sale: sin ciclos ni salas amontonadas.
			if layout.neighbors(next).size() > 1 or rng.randf() < params.branch_skip_chance:
				continue
			layout.slots[next] = RoomSlot.new(next)
			queue.append(next)
	if layout.slots.size() < room_count:
		return null
	_compute_distances(layout)
	var dead_ends: Array[Vector2i] = _dead_ends(layout)
	if dead_ends.size() < 3 + params.extra_rooms.size():
		return null
	var boss: Vector2i = _farthest(layout, dead_ends)
	if layout.get_slot(boss).distance < params.min_boss_distance:
		return null
	layout.get_slot(boss).kind = RoomSlot.Kind.BOSS
	dead_ends.erase(boss)
	layout.get_slot(_take_random(dead_ends, rng)).kind = RoomSlot.Kind.TREASURE
	layout.get_slot(_take_random(dead_ends, rng)).kind = RoomSlot.Kind.SHOP
	for kind: RoomSlot.Kind in params.extra_rooms:
		layout.get_slot(_take_random(dead_ends, rng)).kind = kind
	var secret: Vector2i = _pick_secret_cell(layout, boss, rng)
	if secret == FloorLayout.NO_CELL:
		return null
	var secret_slot := RoomSlot.new(secret, RoomSlot.Kind.SECRET)
	secret_slot.distance = 1 + _min_neighbor_distance(layout, secret)
	layout.slots[secret] = secret_slot
	return layout


## Elige `count` tipos distintos de `candidates` al azar (las especiales extra de un piso).
static func pick_extra_rooms(candidates: Array[RoomSlot.Kind], count: int, rng: RandomNumberGenerator) -> Array[RoomSlot.Kind]:
	var pool: Array[RoomSlot.Kind] = candidates.duplicate()
	var result: Array[RoomSlot.Kind] = []
	while result.size() < count and not pool.is_empty():
		result.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	return result


## Distancia en pasos desde el inicio (BFS sin pasar por la secreta).
static func _compute_distances(layout: FloorLayout) -> void:
	var seen: Dictionary[Vector2i, bool] = {layout.start: true}
	var queue: Array[Vector2i] = [layout.start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for next: Vector2i in layout.neighbors(cell, false):
			if not seen.has(next):
				seen[next] = true
				layout.get_slot(next).distance = layout.get_slot(cell).distance + 1
				queue.append(next)


static func _dead_ends(layout: FloorLayout) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in layout.slots:
		if cell != layout.start and layout.neighbors(cell, false).size() == 1:
			result.append(cell)
	return result


static func _farthest(layout: FloorLayout, cells: Array[Vector2i]) -> Vector2i:
	var best: Vector2i = cells[0]
	for cell: Vector2i in cells:
		if layout.get_slot(cell).distance > layout.get_slot(best).distance:
			best = cell
	return best


## Celda vacía con más vecinas (2 o más), sin tocar al jefe. NO_CELL si no hay ninguna.
static func _pick_secret_cell(layout: FloorLayout, boss: Vector2i, rng: RandomNumberGenerator) -> Vector2i:
	var best: Array[Vector2i] = []
	var best_count: int = 2
	for y: int in layout.grid_size.y:
		for x: int in layout.grid_size.x:
			var cell := Vector2i(x, y)
			if layout.has_room(cell):
				continue
			var around: Array[Vector2i] = layout.neighbors(cell)
			if around.size() < best_count or around.has(boss):
				continue
			if around.size() > best_count:
				best.clear()
				best_count = around.size()
			best.append(cell)
	return best[rng.randi_range(0, best.size() - 1)] if not best.is_empty() else FloorLayout.NO_CELL


static func _min_neighbor_distance(layout: FloorLayout, cell: Vector2i) -> int:
	var result: int = 1 << 30
	for next: Vector2i in layout.neighbors(cell):
		result = mini(result, layout.get_slot(next).distance)
	return result


static func _take_random(cells: Array[Vector2i], rng: RandomNumberGenerator) -> Vector2i:
	var index: int = rng.randi_range(0, cells.size() - 1)
	var cell: Vector2i = cells[index]
	cells.remove_at(index)
	return cell


## Fisher-Yates con el RNG del piso (Array.shuffle() usa el RNG global).
static func _shuffled(items: Array[Vector2i], rng: RandomNumberGenerator) -> Array[Vector2i]:
	var result: Array[Vector2i] = items.duplicate()
	for i: int in range(result.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Vector2i = result[i]
		result[i] = result[j]
		result[j] = swap
	return result
