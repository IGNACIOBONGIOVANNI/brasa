@tool
class_name ItemsDisplay
extends Control
## Fila de íconos de los items pasivos que lleva el jugador (abajo a la izquierda). Con `columns` > 0
## los acomoda en filas de esa cantidad (el resumen de la run).

const SPACING: float = 9.0
const OUTLINE_COLOR: Color = Color("120c16")
const ROW_HEIGHT: float = 8.0

## Íconos por fila (0 = todos en una).
var columns: int = 0

var _items: Array[ItemData] = []


func set_items(items: Array[ItemData]) -> void:
	_items = items.duplicate()
	queue_redraw()


func _draw() -> void:
	for i: int in _items.size():
		var icon: PackedStringArray = _items[i].get_icon()
		if not icon.is_empty():
			PixelBitmap.paint_outlined(self, icon, slot_position(i), _items[i].get_icon_color(), OUTLINE_COLOR)


## Dónde va el ícono número `index`.
func slot_position(index: int) -> Vector2:
	if columns <= 0:
		return Vector2(index * SPACING, 0)
	return Vector2((index % columns) * SPACING, floori(float(index) / columns) * ROW_HEIGHT)
