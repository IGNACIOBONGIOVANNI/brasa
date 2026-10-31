class_name PixelBitmap
extends RefCounted
## Dibuja íconos escritos como texto ("#" = píxel encendido) desde el _draw de un CanvasItem.
## Sirve para el HUD y los avisos placeholder sin necesitar imágenes.


## Dibuja las columnas [col_from, col_to) de `rows` con la esquina superior izquierda en `origin`.
## col_to negativo = hasta el final de cada fila.
static func paint(canvas: CanvasItem, rows: PackedStringArray, origin: Vector2, color: Color,
		col_from: int = 0, col_to: int = -1) -> void:
	for y: int in rows.size():
		var row: String = rows[y]
		var last: int = row.length() if col_to < 0 else mini(col_to, row.length())
		for x: int in range(col_from, last):
			if row[x] == "#":
				canvas.draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), color)


## Igual que paint() pero con un borde de 1 px alrededor.
static func paint_outlined(canvas: CanvasItem, rows: PackedStringArray, origin: Vector2, color: Color,
		outline: Color) -> void:
	for offset: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		paint(canvas, rows, origin + offset, outline)
	paint(canvas, rows, origin, color)
