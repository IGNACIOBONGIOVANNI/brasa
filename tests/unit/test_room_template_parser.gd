extends GutTest
## RoomTemplateParser: lectura de la leyenda y validación de las reglas de las plantillas.

const VALID: String = """
...............
.#...........#.
...C.......v...
.....ooooo.....
...............
.....ooooo.....
...$.......F...
.#...........#.
...............
"""


func _with_row(row_index: int, row: String) -> String:
	var rows: PackedStringArray = VALID.strip_edges().split("\n")
	rows[row_index] = row
	return "\n".join(rows)


func test_valid_template_parses_cells_and_markers() -> void:
	var grid: RoomGrid = RoomTemplateParser.parse(VALID)
	assert_true(grid.is_valid(), "sin errores: %s" % ", ".join(grid.errors))
	assert_eq(grid.cell_at(Vector2i(1, 1)), RoomGrid.Cell.ROCK)
	assert_eq(grid.cell_at(Vector2i(5, 3)), RoomGrid.Cell.PIT)
	assert_eq(grid.cell_at(Vector2i(0, 0)), RoomGrid.Cell.FLOOR)
	assert_eq(grid.enemies.size(), 3)
	assert_eq(grid.pickups.size(), 1)
	assert_eq(grid.pickups[0].symbol, "$")
	assert_eq(grid.pickups[0].cell, Vector2i(3, 6))


func test_letter_case_sets_the_wave() -> void:
	var grid: RoomGrid = RoomTemplateParser.parse(VALID)
	var waves: Dictionary[String, int] = {}
	for marker: RoomGrid.EnemyMarker in grid.enemies:
		waves["%s@%d,%d" % [marker.symbol, marker.cell.x, marker.cell.y]] = marker.wave
	assert_eq(waves["C@3,2"], 0, "mayúscula = primera oleada")
	assert_eq(waves["V@11,2"], 1, "minúscula = segunda oleada, letra en mayúscula")
	assert_eq(grid.wave_count(), 2)


func test_cells_outside_count_as_rock() -> void:
	var grid: RoomGrid = RoomTemplateParser.parse(VALID)
	assert_false(grid.is_walkable(Vector2i(-1, 0)))
	assert_false(grid.is_walkable(Vector2i(0, RoomGrid.HEIGHT)))


func test_wrong_row_count_is_an_error() -> void:
	var grid: RoomGrid = RoomTemplateParser.parse("...............\n...............")
	assert_false(grid.is_valid())


func test_wrong_row_length_is_an_error() -> void:
	assert_false(RoomTemplateParser.parse(_with_row(4, "..............")).is_valid())


func test_unknown_symbol_is_an_error() -> void:
	assert_false(RoomTemplateParser.parse(_with_row(4, ".......?.......")).is_valid())


func test_blocked_door_is_an_error() -> void:
	assert_false(RoomTemplateParser.parse(_with_row(0, ".......#.......")).is_valid(), "puerta de arriba")
	assert_false(RoomTemplateParser.parse(_with_row(4, "o..............")).is_valid(), "puerta izquierda")


func test_unreachable_door_is_an_error() -> void:
	# Una pared de rocas de lado a lado deja la puerta de abajo sin conexión.
	var grid: RoomGrid = RoomTemplateParser.parse(_with_row(4, "###############"))
	assert_false(grid.is_valid())


func test_unreachable_pickup_is_an_error() -> void:
	var text: String = _with_row(5, ".....o$o.......")
	text = text.replace(".....ooooo.....\n...............\n.....o$o.......", ".....ooooo.....\n......o........\n.....o$o.......")
	var rows: PackedStringArray = text.split("\n")
	rows[6] = "......o.....F.."
	var grid: RoomGrid = RoomTemplateParser.parse("\n".join(rows))
	assert_false(grid.is_valid(), "el $ quedó encerrado entre fosos")


func test_cell_center_matches_room_coordinates() -> void:
	assert_eq(RoomGrid.cell_center(Vector2i(0, 0)), Vector2(-112, -64))
	assert_eq(RoomGrid.cell_center(RoomGrid.CENTER), Vector2.ZERO)
	assert_eq(RoomGrid.cell_center(Vector2i(14, 8)), Vector2(112, 64))


func test_nearest_walkable_skips_rocks() -> void:
	var rows := PackedStringArray()
	for y: int in RoomGrid.HEIGHT:
		rows.append("......###......" if y == RoomGrid.CENTER.y else "...............")
	var grid: RoomGrid = RoomTemplateParser.parse("\n".join(rows))
	var nearest: Vector2i = grid.nearest_walkable(RoomGrid.CENTER)
	assert_true(grid.is_walkable(nearest))
	assert_eq((nearest - RoomGrid.CENTER).length_squared(), 1, "la vecina directa más cercana")
