class_name MinimapModel
extends RefCounted
## Qué muestra el minimapa de cada sala: oculta, conocida (vecina de una visitada), visitada o la
## actual. La sala secreta no aparece como vecina hasta que se la descubre.

enum CellState { HIDDEN, KNOWN, VISITED, CURRENT }


static func compute(layout: FloorLayout, visited: Dictionary[Vector2i, bool], current: Vector2i,
		discovered_secrets: Dictionary[Vector2i, bool], reveal_all: bool) -> Dictionary[Vector2i, CellState]:
	var states: Dictionary[Vector2i, CellState] = {}
	for cell: Vector2i in layout.slots:
		states[cell] = CellState.KNOWN if reveal_all else CellState.HIDDEN
	for cell: Vector2i in visited:
		if not layout.has_room(cell):
			continue
		states[cell] = CellState.VISITED
		for neighbor: Vector2i in layout.neighbors(cell):
			if states[neighbor] == CellState.HIDDEN and _is_findable(layout, neighbor, discovered_secrets):
				states[neighbor] = CellState.KNOWN
	if layout.has_room(current):
		states[current] = CellState.CURRENT
	return states


static func _is_findable(layout: FloorLayout, cell: Vector2i, discovered_secrets: Dictionary[Vector2i, bool]) -> bool:
	return layout.get_slot(cell).kind != RoomSlot.Kind.SECRET or discovered_secrets.has(cell)
