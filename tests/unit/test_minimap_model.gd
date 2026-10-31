extends GutTest
## MinimapModel: salas visitadas, vecinas conocidas y la secreta oculta hasta descubrirla.
##
## Layout de prueba (fila del medio): [secreta][inicio][normal][jefe], y una normal arriba del inicio.

const START := Vector2i(2, 2)
const SECRET := Vector2i(1, 2)
const EAST := Vector2i(3, 2)
const BOSS := Vector2i(4, 2)
const NORTH := Vector2i(2, 1)

var _layout: FloorLayout
var _none: Dictionary[Vector2i, bool] = {}


func before_each() -> void:
	_layout = FloorLayout.new()
	_layout.grid_size = Vector2i(6, 5)
	_layout.start = START
	_layout.slots[START] = RoomSlot.new(START, RoomSlot.Kind.START)
	_layout.slots[EAST] = RoomSlot.new(EAST)
	_layout.slots[BOSS] = RoomSlot.new(BOSS, RoomSlot.Kind.BOSS)
	_layout.slots[NORTH] = RoomSlot.new(NORTH)
	_layout.slots[SECRET] = RoomSlot.new(SECRET, RoomSlot.Kind.SECRET)


func test_start_shows_current_and_neighbors() -> void:
	var visited: Dictionary[Vector2i, bool] = {START: true}
	var states: Dictionary[Vector2i, MinimapModel.CellState] = MinimapModel.compute(_layout, visited, START, _none, false)
	assert_eq(states[START], MinimapModel.CellState.CURRENT)
	assert_eq(states[EAST], MinimapModel.CellState.KNOWN)
	assert_eq(states[NORTH], MinimapModel.CellState.KNOWN)
	assert_eq(states[BOSS], MinimapModel.CellState.HIDDEN, "a dos salas de distancia")
	assert_eq(states[SECRET], MinimapModel.CellState.HIDDEN, "la secreta no se ve por estar al lado")


func test_visited_rooms_stay_visited() -> void:
	var visited: Dictionary[Vector2i, bool] = {START: true, EAST: true}
	var states: Dictionary[Vector2i, MinimapModel.CellState] = MinimapModel.compute(_layout, visited, EAST, _none, false)
	assert_eq(states[START], MinimapModel.CellState.VISITED)
	assert_eq(states[EAST], MinimapModel.CellState.CURRENT)
	assert_eq(states[BOSS], MinimapModel.CellState.KNOWN)


func test_discovered_secret_is_shown() -> void:
	var visited: Dictionary[Vector2i, bool] = {START: true}
	var discovered: Dictionary[Vector2i, bool] = {SECRET: true}
	var states: Dictionary[Vector2i, MinimapModel.CellState] = MinimapModel.compute(_layout, visited, START, discovered, false)
	assert_eq(states[SECRET], MinimapModel.CellState.KNOWN)


func test_reveal_all_shows_everything() -> void:
	var visited: Dictionary[Vector2i, bool] = {START: true}
	var states: Dictionary[Vector2i, MinimapModel.CellState] = MinimapModel.compute(_layout, visited, START, _none, true)
	assert_eq(states[BOSS], MinimapModel.CellState.KNOWN)
	assert_eq(states[SECRET], MinimapModel.CellState.KNOWN)
