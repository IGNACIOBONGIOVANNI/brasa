extends GutTest
## Hito 19: caminos dentro de una sala (RoomNav) para que los enemigos rodeen fosos y rocas.

## Una fila de fosos de arriba a abajo en la columna 7, con un hueco abajo de todo.
const WALLED: String = """
.......o.......
.......o.......
.......o.......
.......o.......
.......o.......
.......o.......
.......o.......
.......o.......
...............
"""


func _nav(text: String) -> RoomNav:
	return RoomNav.from_grid(RoomTemplateParser.parse(text))


func test_cells_match_the_room_coordinates() -> void:
	assert_eq(RoomNav.cell_of(RoomGrid.cell_center(Vector2i(3, 5))), Vector2i(3, 5))
	assert_eq(RoomNav.cell_of(RoomGrid.cell_center(Vector2i(3, 5)) + Vector2(7, -7)), Vector2i(3, 5))
	assert_eq(RoomNav.cell_of(Vector2(-500, 500)), Vector2i(0, RoomGrid.HEIGHT - 1), "afuera se pega al borde")


func test_open_room_goes_straight() -> void:
	var nav: RoomNav = _nav(WALLED.replace("o", "."))
	var to: Vector2 = RoomGrid.cell_center(Vector2i(12, 1))
	var step: Vector2 = nav.next_point(RoomGrid.cell_center(Vector2i(2, 1)), to)
	assert_eq(step, RoomGrid.cell_center(Vector2i(3, 1)), "una celda hacia el objetivo")


func test_goes_around_a_line_of_pits() -> void:
	var nav: RoomNav = _nav(WALLED)
	var from: Vector2 = RoomGrid.cell_center(Vector2i(3, 1))
	var to: Vector2 = RoomGrid.cell_center(Vector2i(11, 1))
	var position: Vector2 = from
	for _step: int in 40:
		if position == to:
			break
		position = nav.next_point(position, to)
		assert_true(nav.is_open(RoomNav.cell_of(position)), "nunca pisa un foso")
	assert_eq(position, to, "llega rodeando por el hueco de abajo")


func test_target_inside_a_pit_uses_the_nearest_open_cell() -> void:
	var nav: RoomNav = _nav(WALLED)
	var pit: Vector2 = RoomGrid.cell_center(Vector2i(7, 3))
	assert_false(nav.is_open(Vector2i(7, 3)))
	assert_true(nav.is_open(RoomNav.cell_of(nav.nearest_open(pit))), "cae al lado del foso")
	assert_eq(nav.nearest_open(RoomGrid.cell_center(Vector2i(2, 2))), RoomGrid.cell_center(Vector2i(2, 2)),
			"una celda libre queda como está")


func test_broken_rock_opens_the_way() -> void:
	var nav: RoomNav = _nav(WALLED.replace("o", "#"))
	var from: Vector2 = RoomGrid.cell_center(Vector2i(6, 1))
	var to: Vector2 = RoomGrid.cell_center(Vector2i(8, 1))
	assert_ne(nav.next_point(from, to), RoomGrid.cell_center(Vector2i(7, 1)), "con la roca no pasa por ahí")
	nav.set_open(Vector2i(7, 1), true)
	assert_eq(nav.next_point(from, to), RoomGrid.cell_center(Vector2i(7, 1)), "rota, pasa derecho")
