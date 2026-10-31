class_name FloorLayout
extends RefCounted
## Resultado de FloorGenerator: qué celdas de la grilla tienen sala y de qué tipo. Dos salas vecinas
## en la grilla siempre están conectadas por una puerta (oculta si una de las dos es la secreta).

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const NO_CELL: Vector2i = Vector2i(-1, -1)

var grid_size: Vector2i
var start: Vector2i
var slots: Dictionary[Vector2i, RoomSlot] = {}


func has_room(cell: Vector2i) -> bool:
	return slots.has(cell)


## La sala de esa celda, o null si no hay.
func get_slot(cell: Vector2i) -> RoomSlot:
	return slots.get(cell)


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


## Celdas vecinas con sala. Con include_secret = false se ignora la sala secreta.
func neighbors(cell: Vector2i, include_secret: bool = true) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		var slot: RoomSlot = get_slot(cell + direction)
		if slot != null and (include_secret or slot.kind != RoomSlot.Kind.SECRET):
			result.append(cell + direction)
	return result


func cells_of_kind(kind: RoomSlot.Kind) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in slots:
		if slots[cell].kind == kind:
			result.append(cell)
	return result


## Primera sala del tipo pedido, o NO_CELL si no hay.
func first_of_kind(kind: RoomSlot.Kind) -> Vector2i:
	var cells: Array[Vector2i] = cells_of_kind(kind)
	return cells[0] if not cells.is_empty() else NO_CELL
