@tool
class_name ItemsDisplay
extends Control
## Fila de íconos de los items pasivos que lleva el jugador (abajo a la izquierda).

const SPACING: float = 9.0
const OUTLINE_COLOR: Color = Color("120c16")

var _items: Array[ItemData] = []


func set_items(items: Array[ItemData]) -> void:
	_items = items.duplicate()
	queue_redraw()


func _draw() -> void:
	for i: int in _items.size():
		var icon: PackedStringArray = _items[i].get_icon()
		if not icon.is_empty():
			PixelBitmap.paint_outlined(self, icon, Vector2(i * SPACING, 0), _items[i].get_icon_color(), OUTLINE_COLOR)
