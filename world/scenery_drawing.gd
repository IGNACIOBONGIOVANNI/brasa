class_name SceneryDrawing
extends RefCounted
## Cómo se ve el escenario de cada piso (FloorTheme.Scenery), dibujado por código: las paredes con sus
## cosas, lo que brilla o se mueve en ellas (velas, gotas, hongos, lava, faroles, chispas de nieve,
## banderines), las rocas, los fosos y los detalles del piso. Todo sale de la paleta del piso y de una
## semilla por sala (`noise`, con la `salt` de la sala): la misma sala se ve siempre igual. Sótano: ladrillos con nichos de velas
## y telarañas. Cloacas: ladrillos mojados, un caño, rejillas que gotean. Raíces: tierra con raíces y
## árboles en las esquinas. Forja: chapas remachadas con grietas de lava y bocas de horno.
## Esquiladero: tablas con postes de cerca, fardos, lana enganchada, herraduras y faroles. Cantera:
## bloques de piedra, andamios, picos y faroles. Ventisquero: una hilera de pinos nevados, carámbanos
## y montículos de nieve. Cumbre: riscos con nieve, cerca de soga con banderines, apachetas y árboles
## secos. Cenicero (piso secreto): ladrillos tiznados con nichos de urnas y bocas de carbón por donde
## caen brasas, ceniza amontonada y marcas de escoba en el piso, urnas como rocas y fosos de brasas.

const WALL: float = 16.0
const HALF: Vector2 = Vector2(120, 72)
## Una esquina de la sala (el cuadrado de pared donde se juntan dos lados).
const CORNER: Vector2 = Vector2(128, 80)
const FLAME_COLOR: Color = Color("ffcf6b")
const FLAME_CORE: Color = Color("fff6d5")
const WAX_COLOR: Color = Color("e8dcc0")
const COBWEB_COLOR: Color = Color(0.85, 0.85, 0.9, 0.35)
const MOSS_COLOR: Color = Color("4f7a3a")
const PIPE_COLOR: Color = Color("6f7f74")
const WATER_COLOR: Color = Color("8fc6c2")
const ROOT_COLOR: Color = Color("6e4a5a")
const BARK_COLOR: Color = Color("4a3428")
const LEAF_COLOR: Color = Color("3c4a5e")
const MUSHROOM_COLORS: Array[Color] = [Color("7ae0c8"), Color("c88aff"), Color("9ad2ff")]
const LAVA_COLOR: Color = Color("ff7a2e")
const LAVA_CORE: Color = Color("ffd166")
const IRON_COLOR: Color = Color("5a5560")
const HAY_COLOR: Color = Color("c9a650")
const STRAP_COLOR: Color = Color("8a3a2a")
const WOOL_COLOR: Color = Color("efe9da")
const STEEL_COLOR: Color = Color("aab3c0")
const WOOD_COLOR: Color = Color("7a5636")
const ROPE_COLOR: Color = Color("c2a36e")
const PINE_COLOR: Color = Color("2c5248")
const SNOW_COLOR: Color = Color("eef4fa")
const ICE_COLOR: Color = Color("a8dcff")
const FLAG_COLORS: Array[Color] = [Color("e0464e"), Color("ffd166"), Color("5fb8ff"), Color("7ad18b")]
const STONE_COLOR: Color = Color("8c877e")
const ASH_COLOR: Color = Color("8a8490")
const URN_COLOR: Color = Color("8a6a52")
const EMBER_COLOR: Color = Color("ff8a3d")


## Un número de 0 a 1 que depende solo de la semilla y del índice (siempre el mismo).
static func noise(salt: int, index: int) -> float:
	return float(posmod(hash(Vector3i(salt, index, 7919)), 10007)) / 10006.0


## De qué lado de la sala es un tramo de pared (arriba y abajo incluyen las esquinas).
static func side_of(rect: Rect2) -> Vector2i:
	if rect.end.y <= -HALF.y + 0.5:
		return Vector2i.UP
	if rect.position.y >= HALF.y - 0.5:
		return Vector2i.DOWN
	return Vector2i.LEFT if rect.end.x <= -HALF.x + 0.5 else Vector2i.RIGHT


## Lugares a lo largo de un tramo, cada `spacing` px más o menos, en el medio de la pared (lejos de
## las puntas y de las esquinas).
static func spots(rect: Rect2, spacing: float, salt: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var horizontal: bool = rect.size.x > rect.size.y
	var length: float = rect.size.x if horizontal else rect.size.y
	var start: float = rect.position.x if horizontal else rect.position.y
	var count: int = floori(length / spacing)
	for i: int in count:
		var along: float = start + spacing * (i + 0.5) + (noise(salt, i) - 0.5) * spacing * 0.4
		if horizontal and absf(along) > HALF.x - 6.0:
			continue
		if not horizontal and absf(along) > HALF.y - 6.0:
			continue
		var center: Vector2 = rect.get_center()
		result.append((Vector2(along, center.y) if horizontal else Vector2(center.x, along)).round())
	return result


## Las esquinas de la sala que caen adentro de este tramo.
static func corners_in(rect: Rect2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for x: float in [-1.0, 1.0]:
		for y: float in [-1.0, 1.0]:
			var corner := Vector2(CORNER.x * x, CORNER.y * y)
			if rect.grow(0.5).has_point(corner):
				result.append(corner)
	return result


## Hacia adentro de la sala desde ese lado.
static func inward(side: Vector2i) -> Vector2:
	return -Vector2(side)


# --- Paredes -----------------------------------------------------------------


static func draw_walls(canvas: CanvasItem, rects: Array[Rect2], scenery: FloorTheme.Scenery, theme: FloorTheme,
		salt: int) -> void:
	for i: int in rects.size():
		var rect: Rect2 = rects[i]
		var side: Vector2i = side_of(rect)
		var part_seed: int = salt + i * 101
		canvas.draw_rect(rect, theme.outline_color)
		match scenery:
			FloorTheme.Scenery.BASEMENT:
				_basement(canvas, rect, theme, part_seed)
			FloorTheme.Scenery.SEWER:
				_sewer(canvas, rect, side, theme, part_seed)
			FloorTheme.Scenery.ROOTS:
				_roots(canvas, rect, side, theme, part_seed)
			FloorTheme.Scenery.FORGE:
				_forge(canvas, rect, theme, part_seed)
			FloorTheme.Scenery.SHED:
				_shed(canvas, rect, side, theme, part_seed)
			FloorTheme.Scenery.QUARRY:
				_quarry(canvas, rect, side, theme, part_seed)
			FloorTheme.Scenery.SNOWFIELD:
				_snowfield(canvas, rect, side, theme, part_seed)
			FloorTheme.Scenery.SUMMIT:
				_summit(canvas, rect, side, theme, part_seed)
			FloorTheme.Scenery.ASHPIT:
				_ashpit(canvas, rect, side, theme, part_seed)
			_:
				canvas.draw_rect(rect.grow(-1.0), theme.wall_color)
		_inner_shade(canvas, rect, side, theme.outline_color)


## Ladrillos (o bloques) en hileras desfasadas, cada uno con un poco más o menos de luz.
static func _bricks(canvas: CanvasItem, rect: Rect2, size: Vector2, base: Color, salt: int, variance: float) -> void:
	var rows: int = ceili(rect.size.y / size.y)
	for row: int in rows:
		var y: float = rect.position.y + row * size.y
		var offset: float = fmod(rect.position.x, size.x) + (size.x * 0.5 if posmod(roundi(y / size.y), 2) == 1 else 0.0)
		var x: float = rect.position.x - offset
		var index: int = 0
		while x < rect.end.x:
			var brick := Rect2(x + 1.0, y + 1.0, size.x - 1.0, size.y - 1.0).intersection(rect)
			if brick.has_area():
				var shade: float = (noise(salt, row * 97 + index) - 0.5) * 2.0 * variance
				canvas.draw_rect(brick, base.lightened(shade) if shade > 0.0 else base.darkened(-shade))
			x += size.x
			index += 1


## Una sombra fina del lado de adentro (la pared "tapa" un poco el piso).
static func _inner_shade(canvas: CanvasItem, rect: Rect2, side: Vector2i, outline: Color) -> void:
	var shade := Color(outline, 0.6)
	match side:
		Vector2i.UP:
			canvas.draw_rect(Rect2(rect.position.x, rect.end.y - 1.0, rect.size.x, 1.0), shade)
		Vector2i.DOWN:
			canvas.draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 1.0), shade)
		Vector2i.LEFT:
			canvas.draw_rect(Rect2(rect.end.x - 1.0, rect.position.y, 1.0, rect.size.y), shade)
		_:
			canvas.draw_rect(Rect2(rect.position.x, rect.position.y, 1.0, rect.size.y), shade)


static func _basement(canvas: CanvasItem, rect: Rect2, theme: FloorTheme, salt: int) -> void:
	_bricks(canvas, rect, Vector2(8, 4), theme.wall_color, salt, 0.1)
	var points: Array[Vector2] = spots(rect, 40.0, salt)
	for i: int in points.size():
		var at: Vector2 = points[i]
		if noise(salt, 500 + i) < 0.55:
			# Nicho con una vela (la llama la dibuja draw_glow).
			canvas.draw_rect(Rect2(at + Vector2(-3, -3), Vector2(6, 7)), theme.outline_color)
			canvas.draw_circle(at + Vector2(0, -3), 3.0, theme.outline_color)
			canvas.draw_rect(Rect2(at + Vector2(-1, 0), Vector2(2, 3)), WAX_COLOR)
		else:
			var crack := PackedVector2Array([at + Vector2(-3, -5), at + Vector2(-1, -2), at + Vector2(-2, 1), at + Vector2(1, 4)])
			canvas.draw_polyline(crack, theme.outline_color, 1.0)
	for corner: Vector2 in corners_in(rect):
		var toward: Vector2 = -corner.sign()
		var origin: Vector2 = corner + Vector2(corner.sign().x * -8.0 + toward.x, corner.sign().y * -8.0 + toward.y)
		for k: int in 4:
			var reach: Vector2 = Vector2(toward.x * (10.0 - k * 2.0), toward.y * (2.0 + k * 2.5))
			canvas.draw_line(origin, origin + reach, COBWEB_COLOR, 1.0)
		canvas.draw_arc(origin, 6.0, Vector2(toward.x, 0.0).angle(), Vector2(0.0, toward.y).angle(), 5, COBWEB_COLOR, 1.0)


static func _sewer(canvas: CanvasItem, rect: Rect2, side: Vector2i, theme: FloorTheme, salt: int) -> void:
	_bricks(canvas, rect, Vector2(12, 5), theme.wall_color, salt, 0.12)
	var horizontal: bool = side.y != 0
	var center: Vector2 = rect.get_center()
	# Un caño a lo largo, con uniones.
	if horizontal:
		var pipe := Rect2(rect.position.x, center.y - 3.0, rect.size.x, 4.0)
		canvas.draw_rect(pipe.grow(1.0).intersection(rect), theme.outline_color)
		canvas.draw_rect(pipe, PIPE_COLOR)
		canvas.draw_rect(Rect2(pipe.position.x, pipe.position.y, pipe.size.x, 1.0), PIPE_COLOR.lightened(0.25))
		var x: float = ceilf(rect.position.x / 24.0) * 24.0
		while x < rect.end.x - 2.0:
			canvas.draw_rect(Rect2(x, pipe.position.y - 1.0, 2.0, 6.0), PIPE_COLOR.darkened(0.35))
			x += 24.0
	else:
		var pipe := Rect2(center.x - 2.0, rect.position.y, 4.0, rect.size.y)
		canvas.draw_rect(pipe.grow(1.0).intersection(rect), theme.outline_color)
		canvas.draw_rect(pipe, PIPE_COLOR)
		canvas.draw_rect(Rect2(pipe.position.x, pipe.position.y, 1.0, pipe.size.y), PIPE_COLOR.lightened(0.25))
	# Verdín del lado de adentro, chorreando.
	var edge: Vector2 = _inner_edge_line(rect, side)
	var length: float = rect.size.x if horizontal else rect.size.y
	for k: int in floori(length / 3.0):
		var t: float = k * 3.0
		var drip: float = 1.0 + floorf(noise(salt, 900 + k) * 3.0)
		if horizontal:
			canvas.draw_rect(Rect2(rect.position.x + t, edge.y - (2.0 if side == Vector2i.UP else 0.0), 3.0, 2.0), MOSS_COLOR)
			if side == Vector2i.UP:
				canvas.draw_rect(Rect2(rect.position.x + t + 1.0, edge.y, 1.0, drip), MOSS_COLOR.darkened(0.2))
		else:
			canvas.draw_rect(Rect2(edge.x - (2.0 if side == Vector2i.LEFT else 0.0), rect.position.y + t, 2.0, 3.0), MOSS_COLOR)
	# Rejillas.
	var points: Array[Vector2] = spots(rect, 48.0, salt)
	for i: int in points.size():
		if horizontal and noise(salt, 300 + i) < 0.6:
			var at: Vector2 = points[i] + Vector2(0, 4 if side == Vector2i.UP else -4)
			canvas.draw_rect(Rect2(at + Vector2(-4, -2), Vector2(8, 4)), theme.outline_color.darkened(0.3))
			for b: int in 3:
				canvas.draw_rect(Rect2(at + Vector2(-3 + b * 3, -2), Vector2(1, 4)), PIPE_COLOR.darkened(0.2))


## El borde de la pared que toca el piso: un punto con la coordenada que importa (y para arriba y
## abajo, x para los costados).
static func _inner_edge_line(rect: Rect2, side: Vector2i) -> Vector2:
	match side:
		Vector2i.UP:
			return Vector2(0, rect.end.y)
		Vector2i.DOWN:
			return Vector2(0, rect.position.y)
		Vector2i.LEFT:
			return Vector2(rect.end.x, 0)
	return Vector2(rect.position.x, 0)


static func _roots(canvas: CanvasItem, rect: Rect2, side: Vector2i, theme: FloorTheme, salt: int) -> void:
	canvas.draw_rect(rect.grow(-1.0), theme.wall_color)
	var horizontal: bool = side.y != 0
	# Tierra con piedritas.
	for k: int in floori(rect.size.x * rect.size.y / 40.0):
		var at := Vector2(rect.position.x + noise(salt, k * 2) * rect.size.x, rect.position.y + noise(salt, k * 2 + 1) * rect.size.y)
		canvas.draw_rect(Rect2(at.floor(), Vector2.ONE), theme.wall_color.darkened(0.25))
	# Raíces enredadas.
	for r: int in 3:
		var phase: float = noise(salt, 40 + r) * TAU
		var offset: float = (r - 1) * 4.0
		var line := PackedVector2Array()
		var length: float = rect.size.x if horizontal else rect.size.y
		var steps: int = maxi(2, ceili(length / 4.0))
		for k: int in steps + 1:
			var t: float = minf(k * 4.0, length)
			var wave: float = sin(t * 0.12 + phase) * 4.0 + offset
			if horizontal:
				line.append(Vector2(rect.position.x + t, rect.get_center().y + wave))
			else:
				line.append(Vector2(rect.get_center().x + wave, rect.position.y + t))
		canvas.draw_polyline(line, ROOT_COLOR.darkened(0.3), 3.0)
		canvas.draw_polyline(line, ROOT_COLOR, 1.0)
	# Puntas de raíz que cuelgan hacia adentro y los tallos de los hongos (los sombreros brillan).
	var points: Array[Vector2] = spots(rect, 22.0, salt)
	for i: int in points.size():
		var at: Vector2 = points[i]
		if noise(salt, 600 + i) < 0.5:
			var tip: Vector2 = at + inward(side) * 10.0
			canvas.draw_line(at + inward(side) * 6.0, tip, ROOT_COLOR, 1.0)
		else:
			canvas.draw_rect(Rect2(at + Vector2(-0.5, 0), Vector2(1, 3)), WAX_COLOR.darkened(0.2))
	for corner: Vector2 in corners_in(rect):
		_tree(canvas, corner, corner.sign(), theme)


## Un árbol enorme en una esquina: tronco con corteza, raíces y copa hacia afuera de la sala.
static func _tree(canvas: CanvasItem, corner: Vector2, outward: Vector2, theme: FloorTheme) -> void:
	var canopy: Vector2 = corner + outward * 7.0
	for k: int in 5:
		var angle: float = TAU * k / 5.0 + 0.4
		canvas.draw_circle(canopy + Vector2.from_angle(angle) * 6.0, 8.0, theme.outline_color)
	for k: int in 5:
		var angle: float = TAU * k / 5.0 + 0.4
		canvas.draw_circle(canopy + Vector2.from_angle(angle) * 6.0, 7.0, LEAF_COLOR)
		canvas.draw_circle(canopy + Vector2.from_angle(angle) * 6.0 + Vector2(-2, -2), 3.0, LEAF_COLOR.lightened(0.15))
	var trunk := Rect2(corner + Vector2(-5, -6), Vector2(10, 14))
	canvas.draw_rect(trunk.grow(1.0), theme.outline_color)
	canvas.draw_rect(trunk, BARK_COLOR)
	for k: int in 3:
		canvas.draw_line(trunk.position + Vector2(2 + k * 3, 2), trunk.position + Vector2(2 + k * 3, 12), BARK_COLOR.darkened(0.35), 1.0)
	for k: int in 2:
		var root_end: Vector2 = corner - outward * Vector2(6 + k * 4, 8 - k * 4)
		canvas.draw_line(corner + Vector2(0, 6), root_end, BARK_COLOR, 2.0)


static func _forge(canvas: CanvasItem, rect: Rect2, theme: FloorTheme, salt: int) -> void:
	_bricks(canvas, rect, Vector2(16, 8), theme.wall_color.darkened(0.15), salt, 0.08)
	# Remaches en las chapas.
	var x: float = floorf(rect.position.x / 8.0) * 8.0 + 2.0
	while x < rect.end.x:
		var y: float = floorf(rect.position.y / 8.0) * 8.0 + 2.0
		while y < rect.end.y:
			if rect.has_point(Vector2(x, y)):
				canvas.draw_rect(Rect2(x, y, 1, 1), theme.wall_color.lightened(0.3))
			y += 8.0
		x += 8.0
	# Cadenas y bocas de horno (el fuego de adentro lo dibuja draw_glow).
	var points: Array[Vector2] = spots(rect, 36.0, salt)
	for i: int in points.size():
		var at: Vector2 = points[i]
		if noise(salt, 700 + i) < 0.4:
			canvas.draw_rect(Rect2(at + Vector2(-5, -4), Vector2(10, 9)), theme.outline_color)
			canvas.draw_circle(at + Vector2(0, -4), 5.0, theme.outline_color)
		else:
			for link: int in 4:
				canvas.draw_rect(Rect2(at + Vector2(-1, -6 + link * 3), Vector2(2, 2)), IRON_COLOR)


static func _shed(canvas: CanvasItem, rect: Rect2, side: Vector2i, theme: FloorTheme, salt: int) -> void:
	var horizontal: bool = side.y != 0
	# Tablas (a lo largo de la pared) con nudos y clavos.
	var plank: float = 4.0
	var count: int = ceili((rect.size.y if horizontal else rect.size.x) / plank)
	for k: int in count:
		var shade: float = (noise(salt, k) - 0.5) * 0.16
		var color: Color = theme.wall_color.lightened(shade) if shade > 0.0 else theme.wall_color.darkened(-shade)
		var board: Rect2
		if horizontal:
			board = Rect2(rect.position.x, rect.position.y + k * plank, rect.size.x, plank - 1.0)
		else:
			board = Rect2(rect.position.x + k * plank, rect.position.y, plank - 1.0, rect.size.y)
		canvas.draw_rect(board.intersection(rect), color)
	# Postes de la cerca.
	var length: float = rect.size.x if horizontal else rect.size.y
	var start: float = rect.position.x if horizontal else rect.position.y
	var post: float = ceilf(start / 24.0) * 24.0
	while post < start + length - 2.0:
		var pole: Rect2 = Rect2(post - 2.0, rect.position.y, 4.0, rect.size.y) if horizontal \
				else Rect2(rect.position.x, post - 2.0, rect.size.x, 4.0)
		canvas.draw_rect(pole.grow(1.0).intersection(rect), theme.outline_color)
		canvas.draw_rect(pole.intersection(rect), WOOD_COLOR.darkened(0.25))
		var nail: Vector2 = pole.get_center()
		canvas.draw_rect(Rect2(nail.floor(), Vector2.ONE), STEEL_COLOR)
		post += 24.0
	# Lana enganchada, herraduras y tijeras colgadas (los faroles brillan).
	var points: Array[Vector2] = spots(rect, 26.0, salt)
	for i: int in points.size():
		var at: Vector2 = points[i]
		var pick: float = noise(salt, 800 + i)
		if pick < 0.4:
			for k: int in 3:
				canvas.draw_circle(at + Vector2(-2 + k * 2, (k % 2) * -1.0), 2.0, WOOL_COLOR)
		elif pick < 0.6:
			canvas.draw_arc(at, 3.0, 0.0, PI, 6, STEEL_COLOR, 1.5)
		elif pick < 0.72:
			canvas.draw_line(at + Vector2(-3, -3), at + Vector2(3, 3), STEEL_COLOR, 1.0)
			canvas.draw_line(at + Vector2(3, -3), at + Vector2(-3, 3), STEEL_COLOR, 1.0)
			canvas.draw_circle(at + Vector2(-3, 3), 1.5, theme.outline_color)
		elif pick < 0.88:
			canvas.draw_rect(Rect2(at + Vector2(-2, -3), Vector2(4, 6)), theme.outline_color)
	for corner: Vector2 in corners_in(rect):
		_hay_bale(canvas, corner + Vector2(-7, -5), theme.outline_color)


static func _hay_bale(canvas: CanvasItem, origin: Vector2, outline: Color) -> void:
	var bale := Rect2(origin, Vector2(14, 10))
	canvas.draw_rect(bale.grow(1.0), outline)
	canvas.draw_rect(bale, HAY_COLOR)
	for k: int in 4:
		canvas.draw_line(origin + Vector2(1, 2 + k * 2), origin + Vector2(13, 2 + k * 2), HAY_COLOR.darkened(0.2), 1.0)
	canvas.draw_rect(Rect2(origin + Vector2(3, 0), Vector2(1, 10)), STRAP_COLOR)
	canvas.draw_rect(Rect2(origin + Vector2(10, 0), Vector2(1, 10)), STRAP_COLOR)
	canvas.draw_rect(Rect2(origin, Vector2(14, 1)), HAY_COLOR.lightened(0.25))


static func _quarry(canvas: CanvasItem, rect: Rect2, side: Vector2i, theme: FloorTheme, salt: int) -> void:
	# Bloques de piedra de distintos largos, con marcas de cincel.
	var rows: int = ceili(rect.size.y / 8.0)
	for row: int in rows:
		var y: float = rect.position.y + row * 8.0
		var x: float = rect.position.x - noise(salt, row) * 10.0
		var index: int = 0
		while x < rect.end.x:
			var width: float = 10.0 + floorf(noise(salt, row * 53 + index) * 12.0)
			var block := Rect2(x + 1.0, y + 1.0, width - 1.0, 7.0).intersection(rect)
			if block.has_area():
				var shade: float = (noise(salt, row * 31 + index + 7) - 0.5) * 0.2
				var color: Color = theme.wall_color.lightened(shade) if shade > 0.0 else theme.wall_color.darkened(-shade)
				canvas.draw_rect(block, color)
				canvas.draw_rect(Rect2(block.position, Vector2(block.size.x, 1.0)), color.lightened(0.2))
				if block.size.x > 6.0:
					var mark: Vector2 = block.position + Vector2(3, 3)
					canvas.draw_line(mark, mark + Vector2(2, 2), color.darkened(0.35), 1.0)
			x += width
			index += 1
	# Andamios: postes con un travesaño y una riostra.
	var horizontal: bool = side.y != 0
	var points: Array[Vector2] = spots(rect, 30.0, salt)
	for i: int in points.size():
		var at: Vector2 = points[i]
		var pick: float = noise(salt, 400 + i)
		if pick < 0.4:
			if horizontal:
				canvas.draw_rect(Rect2(at.x - 2.0, rect.position.y, 3.0, rect.size.y), WOOD_COLOR)
				canvas.draw_line(Vector2(at.x - 8.0, rect.position.y + 3.0), Vector2(at.x + 8.0, rect.position.y + 3.0), WOOD_COLOR, 2.0)
				canvas.draw_line(Vector2(at.x, rect.position.y + 3.0), Vector2(at.x + 7.0, rect.end.y - 1.0), WOOD_COLOR.darkened(0.2), 1.0)
			else:
				canvas.draw_rect(Rect2(rect.position.x, at.y - 2.0, rect.size.x, 3.0), WOOD_COLOR)
		elif pick < 0.65:
			canvas.draw_line(at + Vector2(-4, 4), at + Vector2(3, -4), WOOD_COLOR, 1.0)
			canvas.draw_line(at + Vector2(0, -6), at + Vector2(6, -2), STEEL_COLOR, 2.0)
		elif pick < 0.8:
			canvas.draw_arc(at, 3.0, 0.0, TAU, 8, ROPE_COLOR, 1.0)
			canvas.draw_arc(at, 1.5, 0.0, TAU, 6, ROPE_COLOR, 1.0)
		else:
			canvas.draw_rect(Rect2(at + Vector2(-2, -3), Vector2(4, 6)), theme.outline_color)


static func _snowfield(canvas: CanvasItem, rect: Rect2, side: Vector2i, theme: FloorTheme, salt: int) -> void:
	canvas.draw_rect(rect.grow(-1.0), theme.wall_color.darkened(0.2))
	var horizontal: bool = side.y != 0
	# Pinos: en fila a lo largo de la pared, de atrás para adelante.
	var bases: Array[Vector2] = []
	var length: float = rect.size.x if horizontal else rect.size.y
	var start: float = rect.position.x if horizontal else rect.position.y
	var step: float = 10.0
	for k: int in ceili(length / step) + 1:
		var along: float = start + k * step + (noise(salt, k) - 0.5) * 4.0
		if along < start - 2.0 or along > start + length + 2.0:
			continue
		var depth: float = noise(salt, 200 + k)
		var base: Vector2
		match side:
			Vector2i.UP:
				base = Vector2(along, rect.end.y - 2.0 - depth * 3.0)
			Vector2i.DOWN:
				base = Vector2(along, rect.end.y - depth * 2.0)
			Vector2i.LEFT:
				base = Vector2(rect.get_center().x + (depth - 0.5) * 6.0, along + 6.0)
			_:
				base = Vector2(rect.get_center().x + (depth - 0.5) * 6.0, along + 6.0)
		bases.append(base.round())
	bases.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	var tall: float = 18.0 if side == Vector2i.UP else 14.0
	for i: int in bases.size():
		_pine(canvas, bases[i], tall + noise(salt, 300 + i) * 4.0, theme.outline_color)
	# Nieve amontonada del lado de adentro.
	var edge: Vector2 = _inner_edge_line(rect, side)
	for k: int in ceili(length / 5.0):
		var along: float = start + k * 5.0
		var size: float = 2.0 + noise(salt, 500 + k) * 2.0
		var at: Vector2
		if horizontal:
			at = Vector2(along, edge.y)
		else:
			at = Vector2(edge.x, along)
		canvas.draw_circle(at, size, SNOW_COLOR)
	# Carámbanos que cuelgan de arriba.
	if side == Vector2i.UP:
		for k: int in ceili(length / 7.0):
			if noise(salt, 600 + k) < 0.5:
				var x: float = start + k * 7.0 + 3.0
				var spike := PackedVector2Array([Vector2(x - 1.5, edge.y), Vector2(x + 1.5, edge.y), Vector2(x, edge.y + 2.0 + noise(salt, 650 + k) * 3.0)])
				canvas.draw_colored_polygon(spike, ICE_COLOR)


## Un pino nevado parado en `base`, de `height` px.
static func _pine(canvas: CanvasItem, base: Vector2, height: float, outline: Color) -> void:
	canvas.draw_rect(Rect2(base + Vector2(-1, -3), Vector2(2, 3)), Color("5a3a2a"))
	for tier: int in 3:
		var width: float = 6.0 - tier * 1.5
		var bottom: float = base.y - 2.0 - tier * height * 0.25
		var top: float = bottom - height * 0.45
		var shape := PackedVector2Array([Vector2(base.x - width - 1.0, bottom + 1.0), Vector2(base.x + width + 1.0, bottom + 1.0),
				Vector2(base.x, top - 1.0)])
		canvas.draw_colored_polygon(shape, outline)
		shape = PackedVector2Array([Vector2(base.x - width, bottom), Vector2(base.x + width, bottom), Vector2(base.x, top)])
		canvas.draw_colored_polygon(shape, PINE_COLOR.lightened(tier * 0.06))
		var cap := PackedVector2Array([Vector2(base.x - width * 0.45, top + (bottom - top) * 0.45),
				Vector2(base.x + width * 0.45, top + (bottom - top) * 0.45), Vector2(base.x, top)])
		canvas.draw_colored_polygon(cap, SNOW_COLOR)


static func _summit(canvas: CanvasItem, rect: Rect2, side: Vector2i, theme: FloorTheme, salt: int) -> void:
	canvas.draw_rect(rect.grow(-1.0), theme.wall_color.darkened(0.15))
	var horizontal: bool = side.y != 0
	var length: float = rect.size.x if horizontal else rect.size.y
	var start: float = rect.position.x if horizontal else rect.position.y
	# Riscos: dientes de roca con nieve en la punta, hacia afuera.
	var step: float = 8.0
	for k: int in ceili(length / step):
		var along: float = start + k * step
		var height: float = 7.0 + noise(salt, k) * 7.0
		var half: float = step * 0.5 + 1.0
		var tooth: PackedVector2Array
		var snow: PackedVector2Array
		var out: Vector2 = Vector2(side)
		var base_line: Vector2
		if horizontal:
			base_line = Vector2(along + half - 1.0, rect.end.y if side == Vector2i.UP else rect.position.y)
			var tip: Vector2 = base_line + out * height + Vector2(noise(salt, 40 + k) * 2.0 - 1.0, 0)
			tooth = PackedVector2Array([base_line - Vector2(half, 0), base_line + Vector2(half, 0), tip])
			snow = PackedVector2Array([tip.lerp(base_line - Vector2(half, 0), 0.3), tip.lerp(base_line + Vector2(half, 0), 0.3), tip])
		else:
			base_line = Vector2(rect.end.x if side == Vector2i.LEFT else rect.position.x, along + half - 1.0)
			var tip: Vector2 = base_line + out * height
			tooth = PackedVector2Array([base_line - Vector2(0, half), base_line + Vector2(0, half), tip])
			snow = PackedVector2Array([tip.lerp(base_line - Vector2(0, half), 0.3), tip.lerp(base_line + Vector2(0, half), 0.3), tip])
		var shade: float = noise(salt, 80 + k) * 0.15
		canvas.draw_colored_polygon(tooth, theme.wall_color.lightened(shade))
		canvas.draw_colored_polygon(snow, SNOW_COLOR)
	# Cerca de soga: postes del lado de adentro y la soga colgando entre ellos.
	var edge: Vector2 = _inner_edge_line(rect, side)
	var posts: Array[Vector2] = []
	var post: float = ceilf(start / 26.0) * 26.0
	while post < start + length - 2.0:
		var at: Vector2 = Vector2(post, edge.y - 3.0 * float(-side.y)) if horizontal else Vector2(edge.x - 3.0 * float(-side.x), post)
		posts.append(at.round())
		post += 26.0
	for i: int in posts.size():
		var at: Vector2 = posts[i]
		var pick: float = noise(salt, 900 + i)
		canvas.draw_rect(Rect2(at + Vector2(-1, -6), Vector2(2, 7)), WOOD_COLOR)
		if pick < 0.3:
			for stone: int in 3:
				canvas.draw_circle(at + Vector2(4, -1 - stone * 2.5), 2.5 - stone * 0.5, STONE_COLOR.darkened(stone * 0.1))
		elif pick < 0.5:
			var trunk: Vector2 = at + Vector2(-5, 0)
			canvas.draw_line(trunk, trunk + Vector2(0, -9), BARK_COLOR, 2.0)
			canvas.draw_line(trunk + Vector2(0, -5), trunk + Vector2(-3, -8), BARK_COLOR, 1.0)
			canvas.draw_line(trunk + Vector2(0, -7), trunk + Vector2(3, -10), BARK_COLOR, 1.0)
		if i + 1 < posts.size():
			canvas.draw_polyline(rope(at + Vector2(0, -5), posts[i + 1] + Vector2(0, -5)), ROPE_COLOR, 1.0)


## La soga entre dos postes, colgando un poco.
## Cenicero: ladrillos tiznados, nichos con urnas y bocas de carbón con rejilla (las brasas que caen
## las dibuja draw_glow), y ceniza amontonada al pie de la pared.
static func _ashpit(canvas: CanvasItem, rect: Rect2, side: Vector2i, theme: FloorTheme, salt: int) -> void:
	_bricks(canvas, rect, Vector2(10, 5), theme.wall_color, salt, 0.12)
	canvas.draw_rect(rect, Color(0.05, 0.04, 0.05, 0.25))
	var points: Array[Vector2] = spots(rect, 30.0, salt)
	for i: int in points.size():
		var at: Vector2 = points[i]
		if noise(salt, 900 + i) < 0.55:
			# Nicho con una urna.
			canvas.draw_rect(Rect2(at + Vector2(-4, -5), Vector2(8, 9)), theme.outline_color)
			canvas.draw_circle(at + Vector2(0, -5), 4.0, theme.outline_color)
			canvas.draw_rect(Rect2(at + Vector2(-2, -2), Vector2(4, 5)), URN_COLOR)
			canvas.draw_rect(Rect2(at + Vector2(-1, -4), Vector2(2, 2)), URN_COLOR.darkened(0.2))
			canvas.draw_rect(Rect2(at + Vector2(-2, 0), Vector2(4, 1)), URN_COLOR.lightened(0.25))
		else:
			# Boca de carbón con rejilla.
			canvas.draw_rect(Rect2(at + Vector2(-5, -4), Vector2(10, 8)), theme.outline_color)
			canvas.draw_rect(Rect2(at + Vector2(-4, -3), Vector2(8, 6)), Color("0c090c"))
			for bar: int in 3:
				canvas.draw_rect(Rect2(at + Vector2(-3 + bar * 3, -3), Vector2(1, 6)), IRON_COLOR)
	# Ceniza amontonada contra la pared, del lado de la sala.
	var edge: Vector2 = _inner_edge_line(rect, side)
	var horizontal: bool = side.y != 0
	var length: float = rect.size.x if horizontal else rect.size.y
	var start: float = rect.position.x if horizontal else rect.position.y
	for k: int in floori(length / 14.0):
		if noise(salt, 950 + k) < 0.5:
			continue
		var along: float = start + 7.0 + k * 14.0
		var at: Vector2 = (Vector2(along, edge.y) if horizontal else Vector2(edge.x, along)).round()
		canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.5) if horizontal else Vector2(0.5, 1.0))
		canvas.draw_circle(Vector2.ZERO, 4.0 + noise(salt, 960 + k) * 3.0, Color(ASH_COLOR, 0.7))
		canvas.draw_set_transform(Vector2.ZERO)


static func rope(from: Vector2, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k: int in 7:
		var t: float = k / 6.0
		var sag: float = 4.0 * t * (1.0 - t) * 3.0
		var down: Vector2 = Vector2(0, sag) if absf(to.x - from.x) > absf(to.y - from.y) else Vector2(sag * 0.6, 0)
		points.append(from.lerp(to, t) + down)
	return points


# --- Lo que brilla o se mueve -------------------------------------------------


static func draw_glow(canvas: CanvasItem, rects: Array[Rect2], scenery: FloorTheme.Scenery, salt: int, time: float) -> void:
	for i: int in rects.size():
		var rect: Rect2 = rects[i]
		var side: Vector2i = side_of(rect)
		var part_seed: int = salt + i * 101
		match scenery:
			FloorTheme.Scenery.BASEMENT:
				var points: Array[Vector2] = spots(rect, 40.0, part_seed)
				for k: int in points.size():
					if noise(part_seed, 500 + k) < 0.55:
						_flame(canvas, points[k] + Vector2(0, -2), time + k * 1.7)
			FloorTheme.Scenery.SEWER:
				var points: Array[Vector2] = spots(rect, 48.0, part_seed)
				for k: int in points.size():
					if side.y != 0 and noise(part_seed, 300 + k) < 0.6:
						var fall: float = fmod(time * 18.0 + k * 7.0, 12.0)
						var at: Vector2 = points[k] + Vector2(0, (4 if side == Vector2i.UP else -4) + 2) + Vector2(0, fall)
						canvas.draw_rect(Rect2(at.round(), Vector2(1, 2)), Color(WATER_COLOR, 1.0 - fall / 12.0))
			FloorTheme.Scenery.ROOTS:
				var points: Array[Vector2] = spots(rect, 22.0, part_seed)
				for k: int in points.size():
					if noise(part_seed, 600 + k) >= 0.5:
						var color: Color = MUSHROOM_COLORS[k % MUSHROOM_COLORS.size()]
						var pulse: float = 0.6 + 0.4 * sin(time * 2.0 + k)
						canvas.draw_circle(points[k] + Vector2(0, -1), 4.0, Color(color, 0.15 * pulse))
						canvas.draw_circle(points[k] + Vector2(0, -1), 2.0, Color(color, 0.6 + 0.4 * pulse))
			FloorTheme.Scenery.FORGE:
				_lava(canvas, rect, side, part_seed, time)
				var points: Array[Vector2] = spots(rect, 36.0, part_seed)
				for k: int in points.size():
					if noise(part_seed, 700 + k) < 0.4:
						var heat: float = 0.6 + 0.4 * sin(time * 3.0 + k * 2.0)
						canvas.draw_rect(Rect2(points[k] + Vector2(-4, -2), Vector2(8, 6)), Color(LAVA_COLOR, heat))
						canvas.draw_rect(Rect2(points[k] + Vector2(-2, 0), Vector2(4, 4)), Color(LAVA_CORE, heat))
			FloorTheme.Scenery.SHED:
				var points: Array[Vector2] = spots(rect, 26.0, part_seed)
				for k: int in points.size():
					var pick: float = noise(part_seed, 800 + k)
					if pick >= 0.72 and pick < 0.88:
						_flame(canvas, points[k], time + k)
			FloorTheme.Scenery.QUARRY:
				var points: Array[Vector2] = spots(rect, 30.0, part_seed)
				for k: int in points.size():
					if noise(part_seed, 400 + k) >= 0.8:
						_flame(canvas, points[k], time + k * 1.3)
			FloorTheme.Scenery.SNOWFIELD:
				for k: int in 6:
					var at := Vector2(rect.position.x + noise(part_seed, 1000 + k) * rect.size.x,
							rect.position.y + noise(part_seed, 1100 + k) * rect.size.y)
					var twinkle: float = maxf(0.0, sin(time * 3.0 + k * 2.3))
					if twinkle > 0.6:
						canvas.draw_rect(Rect2(at.round(), Vector2.ONE), Color(1, 1, 1, twinkle))
			FloorTheme.Scenery.SUMMIT:
				_flags(canvas, rect, side, part_seed, time)
			FloorTheme.Scenery.ASHPIT:
				var points: Array[Vector2] = spots(rect, 30.0, part_seed)
				for k: int in points.size():
					if noise(part_seed, 900 + k) >= 0.55:
						# Brasas que caen por la boca de carbón y un resplandor adentro.
						var heat: float = 0.5 + 0.3 * sin(time * 2.0 + k * 1.3)
						canvas.draw_rect(Rect2(points[k] + Vector2(-4, 1), Vector2(8, 2)), Color(EMBER_COLOR, 0.35 * heat))
						for spark: int in 2:
							var fall: float = fmod(time * 9.0 + spark * 3.0 + k * 2.0, 6.0)
							canvas.draw_rect(Rect2((points[k] + Vector2(-2 + spark * 3, -3 + fall)).round(), Vector2.ONE),
									Color(EMBER_COLOR, 1.0 - fall / 6.0))


## Una llamita que titila (vela, farol).
static func _flame(canvas: CanvasItem, at: Vector2, time: float) -> void:
	var flicker: float = 0.5 + 0.5 * sin(time * 13.0) * sin(time * 7.3)
	canvas.draw_circle(at, 4.0, Color(FLAME_COLOR, 0.12 + 0.08 * flicker))
	canvas.draw_rect(Rect2(at + Vector2(-1, -2), Vector2(2, 3)), Color(FLAME_COLOR, 0.8 + 0.2 * flicker))
	canvas.draw_rect(Rect2(at + Vector2(0, -1 - roundf(flicker)), Vector2(1, 1)), FLAME_CORE)


## Grietas de lava que laten a lo largo de la pared.
static func _lava(canvas: CanvasItem, rect: Rect2, side: Vector2i, salt: int, time: float) -> void:
	var horizontal: bool = side.y != 0
	var length: float = rect.size.x if horizontal else rect.size.y
	var start: float = rect.position.x if horizontal else rect.position.y
	var center: Vector2 = rect.get_center()
	var line := PackedVector2Array()
	for k: int in ceili(length / 6.0) + 1:
		var along: float = start + minf(k * 6.0, length)
		var wobble: float = (noise(salt, 1200 + k) - 0.5) * 8.0
		line.append(Vector2(along, center.y + wobble) if horizontal else Vector2(center.x + wobble, along))
	var pulse: float = 0.45 + 0.35 * sin(time * 2.2 + salt % 7)
	canvas.draw_polyline(line, Color(LAVA_COLOR, pulse), 2.0)
	canvas.draw_polyline(line, Color(LAVA_CORE, pulse * 0.8), 1.0)


## Banderines en la soga entre algunos postes, al viento.
static func _flags(canvas: CanvasItem, rect: Rect2, side: Vector2i, salt: int, time: float) -> void:
	var horizontal: bool = side.y != 0
	var length: float = rect.size.x if horizontal else rect.size.y
	var start: float = rect.position.x if horizontal else rect.position.y
	var edge: Vector2 = _inner_edge_line(rect, side)
	var post: float = ceilf(start / 26.0) * 26.0
	var index: int = 0
	while post + 26.0 < start + length - 2.0:
		if noise(salt, 1300 + index) < 0.6:
			var from: Vector2 = (Vector2(post, edge.y - 3.0 * float(-side.y)) if horizontal else Vector2(edge.x - 3.0 * float(-side.x), post)).round() + Vector2(0, -5)
			var to: Vector2 = (Vector2(post + 26.0, edge.y - 3.0 * float(-side.y)) if horizontal else Vector2(edge.x - 3.0 * float(-side.x), post + 26.0)).round() + Vector2(0, -5)
			var line: PackedVector2Array = rope(from, to)
			for k: int in range(1, line.size() - 1):
				var color: Color = FLAG_COLORS[(k + index) % FLAG_COLORS.size()]
				var flutter: float = sin(time * 8.0 + k * 1.3 + index) * 1.5
				var tip: Vector2 = line[k] + (Vector2(flutter, 4.0) if horizontal else Vector2(4.0, flutter))
				canvas.draw_colored_polygon(PackedVector2Array([line[k] - Vector2(1.5, 0), line[k] + Vector2(1.5, 0), tip]), color)
		post += 26.0
		index += 1


# --- Piso ---------------------------------------------------------------------


## Detalles sueltos en el piso (debajo de todo, se oscurecen con la penumbra): poco y suave, para no
## confundirse con nada del juego.
static func draw_floor(canvas: CanvasItem, scenery: FloorTheme.Scenery, theme: FloorTheme, salt: int) -> void:
	var dark: Color = theme.floor_color.darkened(0.3)
	var light: Color = theme.floor_checker_color.lightened(0.12)
	if scenery == FloorTheme.Scenery.SHED:
		# Tablones de punta a punta, con las uniones desfasadas.
		for row: int in 18:
			var y: float = -HALF.y + row * 8.0
			canvas.draw_line(Vector2(-HALF.x, y), Vector2(HALF.x, y), Color(dark, 0.5), 1.0)
			var joint: float = -HALF.x + 24.0 + noise(salt, row) * 48.0
			while joint < HALF.x:
				canvas.draw_line(Vector2(joint, y), Vector2(joint, y + 8.0), Color(dark, 0.5), 1.0)
				joint += 64.0
	for k: int in 14:
		var at := Vector2((noise(salt, k * 2) - 0.5) * (HALF.x * 2.0 - 16.0), (noise(salt, k * 2 + 1) - 0.5) * (HALF.y * 2.0 - 16.0)).round()
		var pick: float = noise(salt, 100 + k)
		match scenery:
			FloorTheme.Scenery.BASEMENT:
				if pick < 0.5:
					canvas.draw_polyline(PackedVector2Array([at, at + Vector2(3, 2), at + Vector2(4, 5), at + Vector2(7, 6)]), dark, 1.0)
				else:
					canvas.draw_circle(at, 1.5, Color(WAX_COLOR, 0.35))
			FloorTheme.Scenery.SEWER:
				if pick < 0.6:
					canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.5))
					canvas.draw_circle(Vector2.ZERO, 6.0 + pick * 6.0, Color(WATER_COLOR.darkened(0.6), 0.45))
					canvas.draw_set_transform(Vector2.ZERO)
					canvas.draw_rect(Rect2(at + Vector2(-2, -1), Vector2(3, 1)), Color(WATER_COLOR, 0.3))
				else:
					canvas.draw_rect(Rect2(at, Vector2(2, 2)), Color(MOSS_COLOR, 0.5))
			FloorTheme.Scenery.ROOTS:
				if pick < 0.5:
					canvas.draw_polyline(PackedVector2Array([at, at + Vector2(3, -1), at + Vector2(6, 1)]), Color(ROOT_COLOR, 0.7), 1.0)
				else:
					canvas.draw_circle(at, 1.5, Color(LEAF_COLOR.lightened(0.2), 0.6))
			FloorTheme.Scenery.FORGE:
				if pick < 0.5:
					canvas.draw_circle(at, 4.0, Color(0, 0, 0, 0.25))
				else:
					canvas.draw_rect(Rect2(at, Vector2(2, 1)), Color(IRON_COLOR, 0.7))
			FloorTheme.Scenery.SHED:
				canvas.draw_line(at, at + Vector2(3, 1 if pick < 0.5 else -1), Color(HAY_COLOR, 0.6), 1.0)
				if pick > 0.85:
					canvas.draw_circle(at + Vector2(4, 3), 1.5, Color(WOOL_COLOR, 0.6))
			FloorTheme.Scenery.QUARRY:
				for g: int in 3:
					canvas.draw_rect(Rect2(at + Vector2(g * 2, (g % 2) * 2), Vector2.ONE), light)
			FloorTheme.Scenery.SNOWFIELD:
				if pick < 0.6:
					canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.55))
					canvas.draw_circle(Vector2.ZERO, 5.0 + pick * 6.0, Color(SNOW_COLOR, 0.35))
					canvas.draw_set_transform(Vector2.ZERO)
				else:
					# Huellas de pezuña (del rebaño que bajó).
					for step: int in 3:
						var hoof: Vector2 = at + Vector2(step * 5, (step % 2) * 3)
						canvas.draw_rect(Rect2(hoof, Vector2(1, 2)), dark)
						canvas.draw_rect(Rect2(hoof + Vector2(2, 0), Vector2(1, 2)), dark)
			FloorTheme.Scenery.ASHPIT:
				if pick < 0.45:
					canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.5))
					canvas.draw_circle(Vector2.ZERO, 5.0 + pick * 8.0, Color(ASH_COLOR, 0.3))
					canvas.draw_set_transform(Vector2.ZERO)
				elif pick < 0.8:
					# Marcas de escoba: tres rayas curvas parejas.
					for line: int in 3:
						canvas.draw_arc(at + Vector2(0, line * 2), 6.0, PI * 1.15, PI * 1.85, 6, Color(ASH_COLOR, 0.35), 1.0)
				else:
					canvas.draw_rect(Rect2(at, Vector2.ONE), Color(EMBER_COLOR, 0.6))
			FloorTheme.Scenery.SUMMIT:
				if pick < 0.5:
					canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.5))
					canvas.draw_circle(Vector2.ZERO, 4.0 + pick * 6.0, Color(SNOW_COLOR, 0.25))
					canvas.draw_set_transform(Vector2.ZERO)
				else:
					canvas.draw_circle(at, 1.5, Color(STONE_COLOR, 0.6))


# --- Rocas y fosos --------------------------------------------------------------


## Una roca de 16 x 16 (centrada) con el aspecto del piso: cajón, tonel, tocón, bloque de hierro,
## fardo, bloque de piedra, bloque de hielo o peñasco nevado.
static func draw_obstacle(canvas: CanvasItem, scenery: FloorTheme.Scenery, color: Color, outline: Color, variant: int) -> void:
	var box := Rect2(-8, -8, 16, 16)
	match scenery:
		FloorTheme.Scenery.BASEMENT:
			canvas.draw_rect(box, outline)
			canvas.draw_rect(box.grow(-1.0), WOOD_COLOR)
			for k: int in 3:
				canvas.draw_line(Vector2(-7, -3 + k * 5), Vector2(6, -3 + k * 5), WOOD_COLOR.darkened(0.3), 1.0)
			canvas.draw_line(Vector2(-6, -6), Vector2(5, 5), WOOD_COLOR.lightened(0.15), 2.0)
			canvas.draw_rect(Rect2(-7, -7, 14, 1), WOOD_COLOR.lightened(0.25))
		FloorTheme.Scenery.SEWER:
			canvas.draw_rect(Rect2(-6, -8, 12, 16), outline)
			canvas.draw_rect(Rect2(-5, -7, 10, 14), color)
			canvas.draw_set_transform(Vector2(0, -6), 0.0, Vector2(1.0, 0.4))
			canvas.draw_circle(Vector2.ZERO, 5.0, color.lightened(0.15))
			canvas.draw_set_transform(Vector2.ZERO)
			for y: float in [-3.0, 3.0]:
				canvas.draw_rect(Rect2(-5, y, 10, 1), IRON_COLOR)
			canvas.draw_rect(Rect2(-4 + variant % 3, 0, 2, 2), Color("8a4a2a"))
			canvas.draw_rect(Rect2(-5, 5, 10, 2), MOSS_COLOR)
		FloorTheme.Scenery.ROOTS:
			canvas.draw_rect(Rect2(-7, -3, 14, 10), outline)
			canvas.draw_rect(Rect2(-6, -3, 12, 9), BARK_COLOR)
			for k: int in 3:
				canvas.draw_line(Vector2(-4 + k * 4, -2), Vector2(-4 + k * 4, 5), BARK_COLOR.darkened(0.35), 1.0)
			canvas.draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.5))
			canvas.draw_circle(Vector2.ZERO, 7.0, outline)
			canvas.draw_circle(Vector2.ZERO, 6.0, Color("b08a5a"))
			canvas.draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 10, Color("8a6a42"), 1.0)
			canvas.draw_arc(Vector2.ZERO, 2.0, 0.0, TAU, 8, Color("8a6a42"), 1.0)
			canvas.draw_set_transform(Vector2.ZERO)
			canvas.draw_line(Vector2(-6, 6), Vector2(-8, 8), BARK_COLOR, 2.0)
			canvas.draw_line(Vector2(6, 6), Vector2(8, 8), BARK_COLOR, 2.0)
		FloorTheme.Scenery.FORGE:
			canvas.draw_rect(box, outline)
			canvas.draw_rect(box.grow(-1.0), IRON_COLOR)
			canvas.draw_rect(Rect2(-7, -7, 14, 3), IRON_COLOR.lightened(0.2))
			canvas.draw_rect(Rect2(-7, -4, 14, 1), LAVA_COLOR.darkened(0.3))
			for corner: Vector2 in [Vector2(-5, -1), Vector2(4, -1), Vector2(-5, 5), Vector2(4, 5)]:
				canvas.draw_rect(Rect2(corner, Vector2.ONE), IRON_COLOR.lightened(0.4))
		FloorTheme.Scenery.SHED:
			_hay_bale(canvas, Vector2(-7, -6), outline)
			canvas.draw_rect(Rect2(-7, 4, 14, 3), HAY_COLOR.darkened(0.25))
		FloorTheme.Scenery.QUARRY:
			canvas.draw_rect(box, outline)
			canvas.draw_rect(box.grow(-1.0), color)
			canvas.draw_rect(Rect2(-7, -7, 14, 2), color.lightened(0.2))
			canvas.draw_line(Vector2(-4, -2), Vector2(-2, 0), color.darkened(0.35), 1.0)
			canvas.draw_line(Vector2(2, 2), Vector2(4, 4), color.darkened(0.35), 1.0)
			if variant % 2 == 0:
				canvas.draw_polyline(PackedVector2Array([Vector2(1, -7), Vector2(0, -3), Vector2(2, 1)]), color.darkened(0.45), 1.0)
		FloorTheme.Scenery.SNOWFIELD:
			canvas.draw_rect(box, outline)
			canvas.draw_rect(box.grow(-1.0), ICE_COLOR.darkened(0.15))
			canvas.draw_line(Vector2(-5, 5), Vector2(4, -4), ICE_COLOR.lightened(0.3), 1.0)
			canvas.draw_rect(Rect2(-7, -7, 14, 4), SNOW_COLOR)
			canvas.draw_rect(Rect2(-7 + variant % 4, -3, 3, 2), SNOW_COLOR)
		FloorTheme.Scenery.ASHPIT:
			# Una urna de barro con tapa y faja (y, a veces, una grieta).
			var urn := PackedVector2Array([Vector2(-4, -6), Vector2(4, -6), Vector2(7, -1), Vector2(6, 6), Vector2(3, 8),
					Vector2(-3, 8), Vector2(-6, 6), Vector2(-7, -1)])
			var rim := PackedVector2Array()
			for point: Vector2 in urn:
				rim.append(point + point.normalized())
			canvas.draw_colored_polygon(rim, outline)
			canvas.draw_colored_polygon(urn, color)
			canvas.draw_rect(Rect2(-6, -1, 12, 2), color.darkened(0.3))
			canvas.draw_line(Vector2(-5, -4), Vector2(-6, 3), color.lightened(0.25), 1.0)
			canvas.draw_rect(Rect2(-4, -8, 8, 2), outline)
			canvas.draw_rect(Rect2(-3, -8, 6, 1), color.lightened(0.15))
			canvas.draw_rect(Rect2(-1, -9, 2, 1), color.lightened(0.15))
			if variant % 3 == 0:
				canvas.draw_polyline(PackedVector2Array([Vector2(2, -5), Vector2(1, -1), Vector2(3, 3)]), outline, 1.0)
		FloorTheme.Scenery.SUMMIT:
			var points := PackedVector2Array([Vector2(-8, 6), Vector2(-7, -3), Vector2(-3, -8), Vector2(4, -7),
					Vector2(8, -2), Vector2(7, 7), Vector2(-2, 8)])
			canvas.draw_colored_polygon(points, outline)
			var inner := PackedVector2Array()
			for point: Vector2 in points:
				inner.append(point * 0.85)
			canvas.draw_colored_polygon(inner, color)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-5, -3), Vector2(-2, -6), Vector2(3, -6), Vector2(5, -2)]), SNOW_COLOR)
		_:
			canvas.draw_rect(box, outline)
			canvas.draw_rect(box.grow(-1.0), color)


## Lados de un foso que dan al piso (los demás siguen siendo foso): los usa draw_pit para que un foso
## de varias celdas se vea como un solo pozo, con su borde solo por afuera.
const PIT_UP: int = 1
const PIT_RIGHT: int = 2
const PIT_DOWN: int = 4
const PIT_LEFT: int = 8
const PIT_ALL_SIDES: int = 15
## Alto de la pared del fondo que se ve adentro del pozo (debajo del borde de arriba).
const PIT_BACK_WALL: int = 6


## Un foso de 16 x 16 (centrado) con el aspecto del piso. `edges` (PIT_UP | PIT_RIGHT ...) dice qué
## lados dan al piso. Se tiene que leer como un pozo y no como pared: el borde de cada lado abierto es
## un canto con luz, debajo del de arriba se ve la pared del fondo bajando hacia lo oscuro (del material
## del piso: ladrillos, tierra con raíces, tablas, piedra, hielo, roca) y en el fondo flota polvo. El
## agua de las cloacas y el metal fundido de la forja son líquidos con su orilla.
static func draw_pit(canvas: CanvasItem, scenery: FloorTheme.Scenery, color: Color, variant: int,
		edges: int = PIT_ALL_SIDES) -> void:
	match scenery:
		FloorTheme.Scenery.SEWER:
			_water_pit(canvas, variant, edges)
		FloorTheme.Scenery.FORGE:
			_molten_pit(canvas, variant, edges)
		_:
			_hole_pit(canvas, scenery, color, variant, edges)


## Material de la pared del fondo y del canto de cada escenario.
static func _pit_palette(scenery: FloorTheme.Scenery) -> Array[Color]:
	match scenery:
		FloorTheme.Scenery.BASEMENT:
			return [Color("5e4b57"), Color("9a8798")]
		FloorTheme.Scenery.ROOTS:
			return [Color("5a4030"), Color("9a7a52")]
		FloorTheme.Scenery.SHED:
			return [WOOD_COLOR.darkened(0.25), WOOD_COLOR.lightened(0.2)]
		FloorTheme.Scenery.QUARRY:
			return [Color("6f6a62"), STONE_COLOR.lightened(0.25)]
		FloorTheme.Scenery.SNOWFIELD:
			return [Color("6fa8c8"), SNOW_COLOR]
		FloorTheme.Scenery.SUMMIT:
			return [Color("565b6a"), SNOW_COLOR]
		FloorTheme.Scenery.ASHPIT:
			return [Color("4a4248"), ASH_COLOR]
	return [Color("4a4553"), Color("7a7488")]


static func _hole_pit(canvas: CanvasItem, scenery: FloorTheme.Scenery, deep: Color, variant: int, edges: int) -> void:
	var palette: Array[Color] = _pit_palette(scenery)
	var wall: Color = palette[0]
	var rim: Color = palette[1]
	canvas.draw_rect(Rect2(-8, -8, 16, 16), deep)
	# Polvo que flota en el fondo.
	for k: int in 3:
		var speck := Vector2(-6 + (variant * 3 + k * 7) % 12, -1 + (variant * 5 + k * 3) % 8)
		canvas.draw_rect(Rect2(speck, Vector2.ONE), deep.lerp(rim, 0.3))
	# Paredes de los costados: la izquierda con algo de luz, la derecha en sombra.
	if edges & PIT_LEFT:
		canvas.draw_rect(Rect2(-8, -8, 1, 16), wall.lerp(deep, 0.35))
		canvas.draw_rect(Rect2(-7, -8, 1, 16), wall.lerp(deep, 0.65))
	if edges & PIT_RIGHT:
		canvas.draw_rect(Rect2(7, -8, 1, 16), wall.lerp(deep, 0.6))
		canvas.draw_rect(Rect2(6, -8, 1, 16), wall.lerp(deep, 0.8))
	# La pared del fondo, que baja hacia lo oscuro.
	if edges & PIT_UP:
		for row: int in PIT_BACK_WALL:
			var t: float = float(row) / PIT_BACK_WALL
			canvas.draw_rect(Rect2(-8, -8 + row, 16, 1), wall.lerp(deep, 0.1 + 0.85 * t))
		_pit_back_detail(canvas, scenery, wall, variant)
	# El canto del piso en cada lado abierto.
	if edges & PIT_UP:
		canvas.draw_rect(Rect2(-8, -8, 16, 1), rim)
	if edges & PIT_DOWN:
		canvas.draw_rect(Rect2(-8, 7, 16, 1), rim.darkened(0.2))
	if edges & PIT_LEFT:
		canvas.draw_rect(Rect2(-8, -8, 1, 16), rim.darkened(0.1))
	if edges & PIT_RIGHT:
		canvas.draw_rect(Rect2(7, -8, 1, 16), rim.darkened(0.3))
	_pit_lip_detail(canvas, scenery, rim, variant, edges)


## Lo que se ve en la pared del fondo de cada escenario.
static func _pit_back_detail(canvas: CanvasItem, scenery: FloorTheme.Scenery, wall: Color, variant: int) -> void:
	var line: Color = wall.darkened(0.45)
	match scenery:
		FloorTheme.Scenery.BASEMENT:
			# Ladrillos: la junta del medio y las verticales desfasadas.
			canvas.draw_rect(Rect2(-8, -5, 16, 1), line)
			var joint: float = -6.0 + variant % 5
			canvas.draw_rect(Rect2(joint, -7, 1, 2), line)
			canvas.draw_rect(Rect2(joint + 8.0, -7, 1, 2), line)
			canvas.draw_rect(Rect2(joint + 4.0, -4, 1, 2), line)
		FloorTheme.Scenery.ROOTS:
			# Raíces finitas que cuelgan hacia adentro del pozo.
			canvas.draw_polyline(PackedVector2Array([Vector2(-4, -8), Vector2(-5, -4), Vector2(-4, 0)]), ROOT_COLOR, 1.0)
			canvas.draw_polyline(PackedVector2Array([Vector2(3, -8), Vector2(4, -5), Vector2(3, -2)]), ROOT_COLOR, 1.0)
			canvas.draw_rect(Rect2(-1 + variant % 3, -6, 1, 3), ROOT_COLOR.darkened(0.2))
		FloorTheme.Scenery.SHED:
			# Las tablas del piso, partidas: las puntas cuelgan sobre el pozo.
			canvas.draw_rect(Rect2(-8, -4, 16, 1), line)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8, -7), Vector2(-2, -7), Vector2(-6, -3)]), WOOD_COLOR.darkened(0.15))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(3, -7), Vector2(8, -7), Vector2(7, -4)]), WOOD_COLOR.darkened(0.15))
		FloorTheme.Scenery.QUARRY:
			# Piedras sueltas en la pared.
			for k: int in 4:
				canvas.draw_rect(Rect2(-7 + k * 4 + variant % 2, -6 + (k + variant) % 3, 2, 1), wall.lightened(0.2))
		FloorTheme.Scenery.SNOWFIELD:
			# Carámbanos colgando del borde.
			for k: int in 3:
				var x: float = -6.0 + k * 5.0 + variant % 2
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x, -7), Vector2(x + 2, -7), Vector2(x + 1, -3 - (k + variant) % 2)]), ICE_COLOR)
		FloorTheme.Scenery.ASHPIT:
			# Ceniza que chorrea por la pared y brasas allá en el fondo.
			canvas.draw_rect(Rect2(-5 + variant % 3, -8, 1, 4), ASH_COLOR.darkened(0.2))
			canvas.draw_rect(Rect2(3 - variant % 2, -8, 1, 3), ASH_COLOR.darkened(0.2))
			canvas.draw_rect(Rect2(-3 + variant % 4, 3, 1, 1), EMBER_COLOR)
			canvas.draw_rect(Rect2(2 + variant % 3, 5, 1, 1), EMBER_COLOR.darkened(0.3))
		FloorTheme.Scenery.SUMMIT:
			# Roca con grietas y, muy abajo, nubes.
			canvas.draw_line(Vector2(-5 + variant % 3, -7), Vector2(-3 + variant % 3, -3), line, 1.0)
			canvas.draw_set_transform(Vector2(variant % 3 - 1, 3), 0.0, Vector2(1.0, 0.35))
			canvas.draw_circle(Vector2.ZERO, 5.0, Color(SNOW_COLOR, 0.18))
			canvas.draw_set_transform(Vector2.ZERO)


## Lo que hay sobre el canto (nieve, polvo de piedra) en los lados abiertos.
static func _pit_lip_detail(canvas: CanvasItem, scenery: FloorTheme.Scenery, rim: Color, variant: int, edges: int) -> void:
	match scenery:
		FloorTheme.Scenery.SNOWFIELD, FloorTheme.Scenery.SUMMIT:
			# Nieve que cuelga del borde de arriba.
			if edges & PIT_UP:
				for k: int in 3:
					canvas.draw_rect(Rect2(-7 + k * 5 + variant % 3, -7, 2, 1), rim)
		FloorTheme.Scenery.QUARRY, FloorTheme.Scenery.BASEMENT, FloorTheme.Scenery.ROOTS, FloorTheme.Scenery.ASHPIT:
			# Piedritas sueltas al borde, del lado del piso.
			if edges & PIT_DOWN:
				canvas.draw_rect(Rect2(-4 + variant % 5, 8, 1, 1), rim.darkened(0.3))
			if edges & PIT_UP:
				canvas.draw_rect(Rect2(2 - variant % 4, -9, 1, 1), rim.darkened(0.3))


## Agua honda (Cloacas): una orilla de piedra en los lados abiertos, el agua que arranca un poco más
## abajo (se ve la pared mojada) y ondas.
static func _water_pit(canvas: CanvasItem, variant: int, edges: int) -> void:
	var water := Color("123638")
	var stone := Color("4a5a56")
	canvas.draw_rect(Rect2(-8, -8, 16, 16), water)
	if edges & PIT_UP:
		canvas.draw_rect(Rect2(-8, -8, 16, 3), Color("1e2e2c"))
		canvas.draw_rect(Rect2(-8, -5, 16, 1), Color("4f8a86"))
	for k: int in 2:
		var y: float = -1.0 + k * 5.0
		var x: float = -5.0 + (variant + k) % 4
		canvas.draw_line(Vector2(x, y), Vector2(x + 6.0, y), Color(WATER_COLOR, 0.55), 1.0)
	_liquid_rim(canvas, stone, edges)


## Metal fundido (Forja): la costra oscura en la orilla y el centro al rojo, con burbujas.
static func _molten_pit(canvas: CanvasItem, variant: int, edges: int) -> void:
	canvas.draw_rect(Rect2(-8, -8, 16, 16), LAVA_COLOR.darkened(0.3))
	if edges & PIT_UP:
		canvas.draw_rect(Rect2(-8, -8, 16, 3), Color("4a2418"))
	canvas.draw_rect(Rect2(-5 + variant % 3, -3, 6, 4), LAVA_COLOR)
	canvas.draw_rect(Rect2(-1, 2 + variant % 2, 6, 4), LAVA_COLOR)
	canvas.draw_rect(Rect2(-3 + variant % 3, -2, 2, 2), LAVA_CORE)
	canvas.draw_rect(Rect2(2, 3 + variant % 2, 2, 2), LAVA_CORE)
	_liquid_rim(canvas, Color("3a2a22"), edges)


## Orilla de 1 px (más clara arriba) en los lados abiertos de un foso con líquido.
static func _liquid_rim(canvas: CanvasItem, stone: Color, edges: int) -> void:
	if edges & PIT_UP:
		canvas.draw_rect(Rect2(-8, -8, 16, 1), stone.lightened(0.25))
	if edges & PIT_DOWN:
		canvas.draw_rect(Rect2(-8, 7, 16, 1), stone)
	if edges & PIT_LEFT:
		canvas.draw_rect(Rect2(-8, -8, 1, 16), stone.lightened(0.1))
	if edges & PIT_RIGHT:
		canvas.draw_rect(Rect2(7, -8, 1, 16), stone.darkened(0.1))
