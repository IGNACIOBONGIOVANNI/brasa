@tool
class_name Minimap
extends Control
## Minimapa: solo las salas conocidas, en un recuadro pegado arriba a la derecha del control.
## Sala actual en blanco, visitadas en gris claro, conocidas en gris oscuro, y un punto de color en
## las salas especiales.

const CELL: Vector2 = Vector2(7, 5)
const PITCH: Vector2 = Vector2(8, 6)
const PADDING: float = 2.0
const BACKGROUND: Color = Color(0.03, 0.02, 0.05, 0.55)
const STATE_COLORS: Dictionary[MinimapModel.CellState, Color] = {
	MinimapModel.CellState.KNOWN: Color("4a4553"),
	MinimapModel.CellState.VISITED: Color("9a93a6"),
	MinimapModel.CellState.CURRENT: Color("f2efe6"),
}
const ICON_COLORS: Dictionary[RoomSlot.Kind, Color] = {
	RoomSlot.Kind.BOSS: Color("e0464e"),
	RoomSlot.Kind.TREASURE: Color("f2c14e"),
	RoomSlot.Kind.SHOP: Color("5fb36a"),
	RoomSlot.Kind.SECRET: Color("a77bd8"),
}

var _states: Dictionary[Vector2i, MinimapModel.CellState] = {}
var _kinds: Dictionary[Vector2i, RoomSlot.Kind] = {}


func set_map(states: Dictionary[Vector2i, MinimapModel.CellState], kinds: Dictionary[Vector2i, RoomSlot.Kind]) -> void:
	_states = states
	_kinds = kinds
	queue_redraw()


func _draw() -> void:
	var shown: Array[Vector2i] = []
	for cell: Vector2i in _states:
		if _states[cell] != MinimapModel.CellState.HIDDEN:
			shown.append(cell)
	if shown.is_empty():
		return
	var min_cell: Vector2i = shown[0]
	var max_cell: Vector2i = shown[0]
	for cell: Vector2i in shown:
		min_cell = min_cell.min(cell)
		max_cell = max_cell.max(cell)
	var cells_size := Vector2(max_cell - min_cell + Vector2i.ONE)
	var box_size: Vector2 = cells_size * PITCH - (PITCH - CELL) + Vector2.ONE * PADDING * 2.0
	var origin := Vector2(size.x - box_size.x, 0)
	draw_rect(Rect2(origin, box_size), BACKGROUND)
	for cell: Vector2i in shown:
		var top_left: Vector2 = origin + Vector2.ONE * PADDING + Vector2(cell - min_cell) * PITCH
		draw_rect(Rect2(top_left, CELL), STATE_COLORS[_states[cell]])
		if ICON_COLORS.has(_kinds.get(cell, RoomSlot.Kind.NORMAL)):
			draw_rect(Rect2(top_left + Vector2(2, 1), Vector2(3, 3)), ICON_COLORS[_kinds[cell]])
