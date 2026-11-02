class_name RoomNav
extends RefCounted
## Caminos dentro de una sala: una grilla A* de 15 x 9 celdas con las rocas y los fosos tapados, para
## que los enemigos que caminan rodeen lo que no pueden cruzar en vez de quedarse empujando contra
## eso (y para que un jefe que salta caiga en una celda libre). Trabaja en coordenadas de la sala
## (origen en el centro del interior, como RoomGrid.cell_center). Las rocas que se rompen se abren con
## set_open.

var _astar := AStarGrid2D.new()


static func from_grid(grid: RoomGrid) -> RoomNav:
	var nav := RoomNav.new()
	nav._astar.region = Rect2i(0, 0, RoomGrid.WIDTH, RoomGrid.HEIGHT)
	nav._astar.cell_size = Vector2(RoomGrid.TILE, RoomGrid.TILE)
	nav._astar.offset = RoomGrid.cell_center(Vector2i.ZERO)
	nav._astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav._astar.update()
	for y: int in RoomGrid.HEIGHT:
		for x: int in RoomGrid.WIDTH:
			var cell := Vector2i(x, y)
			nav._astar.set_point_solid(cell, not grid.is_walkable(cell))
	return nav


## Celda de la sala que contiene `local` (las de afuera se pegan al borde).
static func cell_of(local: Vector2) -> Vector2i:
	var origin: Vector2 = RoomGrid.cell_center(Vector2i.ZERO)
	var cell := Vector2i(((local - origin) / RoomGrid.TILE).round())
	return cell.clamp(Vector2i.ZERO, Vector2i(RoomGrid.WIDTH - 1, RoomGrid.HEIGHT - 1))


func is_open(cell: Vector2i) -> bool:
	return RoomGrid.is_inside(cell) and not _astar.is_point_solid(cell)


## Destapa (o tapa) una celda: una roca que se rompió.
func set_open(cell: Vector2i, open: bool) -> void:
	if RoomGrid.is_inside(cell):
		_astar.set_point_solid(cell, not open)


## Punto (de la sala) hacia el que caminar para ir de `from` a `to` rodeando lo tapado: el centro de
## la próxima celda del camino. Si `to` está en una celda tapada va hasta la más cercana; si ya está
## en la misma celda (o no hay camino), devuelve `to`.
func next_point(from: Vector2, to: Vector2) -> Vector2:
	var start: Vector2i = nearest_open_cell(cell_of(from))
	var goal: Vector2i = nearest_open_cell(cell_of(to))
	if start == goal:
		return to
	var path: PackedVector2Array = _astar.get_point_path(start, goal, true)
	if path.size() < 2:
		return to
	return path[1]


## Celda libre más cercana a `cell` (ella misma si está libre).
func nearest_open_cell(cell: Vector2i) -> Vector2i:
	if is_open(cell):
		return cell
	var best: Vector2i = cell
	var best_distance: int = 1 << 30
	for y: int in RoomGrid.HEIGHT:
		for x: int in RoomGrid.WIDTH:
			var candidate := Vector2i(x, y)
			var distance: int = (candidate - cell).length_squared()
			if is_open(candidate) and distance < best_distance:
				best = candidate
				best_distance = distance
	return best


## `local` si su celda está libre; si no, el centro de la celda libre más cercana.
func nearest_open(local: Vector2) -> Vector2:
	var cell: Vector2i = cell_of(local)
	return local if is_open(cell) else RoomGrid.cell_center(nearest_open_cell(cell))
