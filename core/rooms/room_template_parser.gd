class_name RoomTemplateParser
extends RefCounted
## Convierte el texto de una RoomTemplate en un RoomGrid y valida que la sala se pueda jugar.
##
## Leyenda: "." piso, "#" roca, "o" foso; letra mayúscula = enemigo de la primera oleada,
## minúscula = de la segunda (la letra la define EnemyData.template_char; la "o" queda para los
## fosos); "$" moneda, "+" corazón, "%" bomba, "&" llave (PickupData.template_symbol); "*" lugar
## para un pedestal con item (tesoro y tienda) o el pozo; "^" trampa (la del piso: FloorTheme.trap).
## Reglas: 9 filas de 15 caracteres, las celdas frente a las 4 puertas libres (también de trampas), y
## desde cualquier puerta se llega a las otras, a todos los pickups y a todos los pedestales.

const PICKUP_SYMBOLS: String = "$+%&"
const ITEM_SPOT_SYMBOL: String = "*"
const TRAP_SYMBOL: String = "^"


static func parse(text: String) -> RoomGrid:
	var grid := RoomGrid.new()
	var rows: PackedStringArray = _rows(text)
	if rows.size() != RoomGrid.HEIGHT:
		grid.errors.append("tiene %d filas y tienen que ser %d" % [rows.size(), RoomGrid.HEIGHT])
		return grid
	for y: int in RoomGrid.HEIGHT:
		if rows[y].length() != RoomGrid.WIDTH:
			grid.errors.append("la fila %d tiene %d caracteres y tienen que ser %d" % [y, rows[y].length(), RoomGrid.WIDTH])
			return grid
	for y: int in RoomGrid.HEIGHT:
		for x: int in RoomGrid.WIDTH:
			grid.cells.append(_read_cell(grid, rows[y][x], Vector2i(x, y)))
	_validate(grid)
	return grid


static func _rows(text: String) -> PackedStringArray:
	var rows := PackedStringArray()
	for line: String in text.split("\n"):
		var clean: String = line.strip_edges()
		if not clean.is_empty():
			rows.append(clean)
	return rows


static func _read_cell(grid: RoomGrid, symbol: String, pos: Vector2i) -> RoomGrid.Cell:
	match symbol:
		".":
			return RoomGrid.Cell.FLOOR
		"#":
			return RoomGrid.Cell.ROCK
		"o":
			return RoomGrid.Cell.PIT
	if symbol == ITEM_SPOT_SYMBOL:
		grid.item_spots.append(pos)
	elif symbol == TRAP_SYMBOL:
		grid.traps.append(pos)
	elif PICKUP_SYMBOLS.contains(symbol):
		var pickup := RoomGrid.PickupMarker.new()
		pickup.cell = pos
		pickup.symbol = symbol
		grid.pickups.append(pickup)
	elif symbol.to_upper() != symbol.to_lower():
		var enemy := RoomGrid.EnemyMarker.new()
		enemy.cell = pos
		enemy.symbol = symbol.to_upper()
		enemy.wave = 0 if symbol == enemy.symbol else 1
		grid.enemies.append(enemy)
	else:
		grid.errors.append("símbolo desconocido '%s' en (%d, %d)" % [symbol, pos.x, pos.y])
	return RoomGrid.Cell.FLOOR


static func _validate(grid: RoomGrid) -> void:
	for side: Vector2i in FloorLayout.DIRECTIONS:
		for cell: Vector2i in RoomGrid.door_cells(side):
			if not grid.is_walkable(cell):
				grid.errors.append("la puerta %s está tapada en (%d, %d)" % [side, cell.x, cell.y])
			elif grid.traps.has(cell):
				grid.errors.append("hay una trampa en la puerta %s, en (%d, %d)" % [side, cell.x, cell.y])
	if not grid.is_valid():
		return
	var reachable: Dictionary[Vector2i, bool] = grid.reachable_from(RoomGrid.door_cells(Vector2i.UP)[1])
	for side: Vector2i in FloorLayout.DIRECTIONS:
		if not reachable.has(RoomGrid.door_cells(side)[1]):
			grid.errors.append("no se llega a la puerta %s" % side)
	for spot: Vector2i in grid.item_spots:
		if not reachable.has(spot):
			grid.errors.append("no se llega al pedestal de (%d, %d)" % [spot.x, spot.y])
	for pickup: RoomGrid.PickupMarker in grid.pickups:
		if not reachable.has(pickup.cell):
			grid.errors.append("no se llega al pickup de (%d, %d)" % [pickup.cell.x, pickup.cell.y])
