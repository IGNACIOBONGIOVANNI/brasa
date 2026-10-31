class_name RoomBuilder
extends RefCounted
## Arma la geometría de una sala en coordenadas locales (origen en el centro del interior): piso,
## paredes con huecos para las puertas, rocas y fosos. Interior de 240 x 144 y paredes de 16 px.

const HALF_INTERIOR: Vector2 = Vector2(120, 72)
const WALL: float = 16.0
const DOOR_WIDTH: float = 32.0
## Distancia desde el borde del interior hasta donde aparece el jugador al entrar por una puerta.
const ENTRY_INSET: float = 14.0
const ROCK_SCENE: PackedScene = preload("res://world/rock.tscn")
const PIT_SCENE: PackedScene = preload("res://world/pit.tscn")


static func style_floor(visual: PlaceholderShape, theme: FloorTheme) -> void:
	visual.size = HALF_INTERIOR * 2.0
	visual.color = theme.floor_color
	visual.checker_color = theme.floor_checker_color


static func build_walls(parent: Node2D, door_sides: Array[Vector2i], theme: FloorTheme) -> void:
	for side: Vector2i in FloorLayout.DIRECTIONS:
		for rect: Rect2 in wall_rects(side, door_sides.has(side)):
			parent.add_child(_wall_segment(rect, theme))


## Tramos de pared de un lado, con un hueco en el medio si hay puerta. Las paredes de arriba y
## abajo incluyen las esquinas.
static func wall_rects(side: Vector2i, has_door: bool) -> Array[Rect2]:
	var outer: Vector2 = HALF_INTERIOR + Vector2(WALL, WALL)
	var full: Rect2
	if side == Vector2i.UP:
		full = Rect2(-outer.x, -outer.y, outer.x * 2.0, WALL)
	elif side == Vector2i.DOWN:
		full = Rect2(-outer.x, HALF_INTERIOR.y, outer.x * 2.0, WALL)
	elif side == Vector2i.LEFT:
		full = Rect2(-outer.x, -HALF_INTERIOR.y, WALL, HALF_INTERIOR.y * 2.0)
	else:
		full = Rect2(HALF_INTERIOR.x, -HALF_INTERIOR.y, WALL, HALF_INTERIOR.y * 2.0)
	var result: Array[Rect2] = [full]
	if not has_door:
		return result
	var half_gap: float = DOOR_WIDTH * 0.5
	result.clear()
	if side.y != 0:
		result.append(Rect2(full.position.x, full.position.y, -half_gap - full.position.x, WALL))
		result.append(Rect2(half_gap, full.position.y, full.end.x - half_gap, WALL))
	else:
		result.append(Rect2(full.position.x, full.position.y, WALL, -half_gap - full.position.y))
		result.append(Rect2(full.position.x, half_gap, WALL, full.end.y - half_gap))
	return result


## Centro del hueco de la puerta de ese lado.
static func door_position(side: Vector2i) -> Vector2:
	return Vector2(side) * (HALF_INTERIOR + Vector2(WALL, WALL) * 0.5)


## Dónde aparece el jugador al entrar por la puerta de ese lado.
static func entry_point(side: Vector2i) -> Vector2:
	return Vector2(side) * (HALF_INTERIOR - Vector2(ENTRY_INSET, ENTRY_INSET))


static func build_obstacles(parent: Node2D, grid: RoomGrid, theme: FloorTheme) -> void:
	for y: int in RoomGrid.HEIGHT:
		for x: int in RoomGrid.WIDTH:
			var cell := Vector2i(x, y)
			match grid.cell_at(cell):
				RoomGrid.Cell.ROCK:
					var rock := ROCK_SCENE.instantiate() as Rock
					rock.position = RoomGrid.cell_center(cell)
					rock.set_colors(theme.rock_color, theme.outline_color)
					parent.add_child(rock)
				RoomGrid.Cell.PIT:
					var pit := PIT_SCENE.instantiate() as StaticBody2D
					pit.position = RoomGrid.cell_center(cell)
					(pit.get_node(^"Visual") as PlaceholderShape).color = theme.pit_color
					parent.add_child(pit)


static func _wall_segment(rect: Rect2, theme: FloorTheme) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = PhysicsLayers.WALL
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	var visual := PlaceholderShape.new()
	visual.shape = PlaceholderShape.Shape.RECT
	visual.size = rect.size
	visual.color = theme.wall_color
	visual.outline_color = theme.outline_color
	body.add_child(visual)
	return body
