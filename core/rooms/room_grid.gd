class_name RoomGrid
extends RefCounted
## Una sala parseada de su plantilla de texto (ver RoomTemplateParser): qué hay en cada celda del
## interior (15 x 9 tiles de 16 px) y dónde aparecen enemigos y pickups.

enum Cell { FLOOR, ROCK, PIT }

const WIDTH: int = 15
const HEIGHT: int = 9
const TILE: float = 16.0
const CENTER: Vector2i = Vector2i(7, 4)


## Enemigo de la plantilla: letra en mayúscula (EnemyData.template_char) y oleada (0 o 1).
class EnemyMarker:
	var cell: Vector2i
	var symbol: String
	var wave: int


## Pickup de la plantilla: símbolo (PickupData.template_symbol).
class PickupMarker:
	var cell: Vector2i
	var symbol: String


var cells: Array[Cell] = []
var enemies: Array[EnemyMarker] = []
var pickups: Array[PickupMarker] = []
## Lugares para pedestales con item.
var item_spots: Array[Vector2i] = []
var errors: PackedStringArray = []


## Centro de una celda en coordenadas de la sala (origen en el centro del interior).
static func cell_center(pos: Vector2i) -> Vector2:
	return Vector2(-112.0 + TILE * pos.x, -64.0 + TILE * pos.y)


## Celdas del interior pegadas a la puerta de ese lado: tienen que quedar libres.
static func door_cells(side: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset: int in [-1, 0, 1]:
		if side == Vector2i.UP:
			result.append(Vector2i(CENTER.x + offset, 0))
		elif side == Vector2i.DOWN:
			result.append(Vector2i(CENTER.x + offset, HEIGHT - 1))
		elif side == Vector2i.LEFT:
			result.append(Vector2i(0, CENTER.y + offset))
		else:
			result.append(Vector2i(WIDTH - 1, CENTER.y + offset))
	return result


static func is_inside(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < WIDTH and pos.y < HEIGHT


func is_valid() -> bool:
	return errors.is_empty()


## Fuera de la sala cuenta como roca.
func cell_at(pos: Vector2i) -> Cell:
	return cells[pos.y * WIDTH + pos.x] if is_inside(pos) and cells.size() == WIDTH * HEIGHT else Cell.ROCK


func is_walkable(pos: Vector2i) -> bool:
	return cell_at(pos) == Cell.FLOOR


func wave_count() -> int:
	var count: int = 0
	for marker: EnemyMarker in enemies:
		count = maxi(count, marker.wave + 1)
	return count


## Celdas caminables a las que se llega desde `from` moviéndose en 4 direcciones.
func reachable_from(from: Vector2i) -> Dictionary[Vector2i, bool]:
	var seen: Dictionary[Vector2i, bool] = {}
	if not is_walkable(from):
		return seen
	seen[from] = true
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction: Vector2i in FloorLayout.DIRECTIONS:
			var next: Vector2i = cell + direction
			if is_walkable(next) and not seen.has(next):
				seen[next] = true
				queue.append(next)
	return seen


## Celda caminable más cercana a `pos` (para soltar recompensas o aparecer en el centro), sin
## contar los lugares de pedestales: así nadie aparece arriba de un item. Con `enemy_clearance` > 0
## además se aleja esa cantidad de celdas (contando diagonales) de cada enemigo de la plantilla; si
## no hay ninguna así, se ignora esa condición.
func nearest_walkable(pos: Vector2i, enemy_clearance: int = 0) -> Vector2i:
	var best: Vector2i = pos
	var best_distance: int = 1 << 30
	for y: int in HEIGHT:
		for x: int in WIDTH:
			var cell := Vector2i(x, y)
			var distance: int = (cell - pos).length_squared()
			if is_walkable(cell) and not item_spots.has(cell) and distance < best_distance \
					and _far_from_enemies(cell, enemy_clearance):
				best = cell
				best_distance = distance
	if best_distance == 1 << 30 and enemy_clearance > 0:
		return nearest_walkable(pos)
	return best


func _far_from_enemies(cell: Vector2i, clearance: int) -> bool:
	for marker: EnemyMarker in enemies:
		var gap: Vector2i = (marker.cell - cell).abs()
		if maxi(gap.x, gap.y) < clearance:
			return false
	return true
