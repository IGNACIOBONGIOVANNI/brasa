@tool
class_name ActiveDisplay
extends Control
## Item activo del HUD: su ícono y debajo una barra con un segmento por sala de carga. Cuando está
## listo para usarse, la barra se pone celeste.

const SEGMENT: Vector2 = Vector2(3, 2)
const SEGMENT_GAP: float = 1.0
const EMPTY_COLOR: Color = Color("3a2a3f")
const CHARGING_COLOR: Color = Color("e8c170")
const READY_COLOR: Color = Color("7ad1ff")
const OUTLINE_COLOR: Color = Color("120c16")

var _item: ItemData
var _charge: int = 0


func set_active(item: ItemData, charge: int) -> void:
	_item = item
	_charge = charge
	queue_redraw()


func _draw() -> void:
	if _item == null:
		return
	PixelBitmap.paint_outlined(self, _item.get_icon(), Vector2.ZERO, _item.get_icon_color(), OUTLINE_COLOR)
	var ready_to_use: bool = _charge >= _item.max_charge
	var bar_y: float = PixelIcons.size_of(_item.get_icon()).y + 2.0
	for i: int in _item.max_charge:
		var segment := Rect2(Vector2(i * (SEGMENT.x + SEGMENT_GAP), bar_y), SEGMENT)
		draw_rect(segment.grow(1.0), OUTLINE_COLOR)
		var color: Color = EMPTY_COLOR
		if ready_to_use:
			color = READY_COLOR
		elif i < _charge:
			color = CHARGING_COLOR
		draw_rect(segment, color)
