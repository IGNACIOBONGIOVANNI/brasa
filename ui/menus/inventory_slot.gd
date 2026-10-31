class_name InventorySlot
extends Control
## Casillero de la Mochila: un ícono de píxeles al doble de tamaño dentro de un marco. Se puede
## enfocar con teclado, mando o mouse (al pasar por encima); el menú escucha `focus_entered` para
## mostrar el detalle. `marked` dibuja una rayita abajo (el arma equipada) y `tint` tiñe el fondo
## (el color de la calidad; transparente = sin teñir).

const SIZE: Vector2 = Vector2(24, 16)
const ICON_SCALE: float = 2.0
const BACK_COLOR: Color = Color(0.17, 0.13, 0.2)
const BORDER_COLOR: Color = Color(0.36, 0.3, 0.42)
const FOCUS_COLOR: Color = Color(1, 0.82, 0.4)
const OUTLINE_COLOR: Color = Color("120c16")
const TINT_ALPHA: float = 0.35

var icon: PackedStringArray = []
var icon_color: Color = Color.WHITE
var marked: bool = false
var tint: Color = Color.TRANSPARENT


func _init(slot_icon: PackedStringArray = [], slot_color: Color = Color.WHITE, slot_marked: bool = false,
		slot_tint: Color = Color.TRANSPARENT) -> void:
	icon = slot_icon
	icon_color = slot_color
	marked = slot_marked
	tint = slot_tint
	custom_minimum_size = SIZE
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(grab_focus)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var frame := Rect2(Vector2.ZERO, size)
	draw_rect(frame, BACK_COLOR)
	if tint.a > 0.0:
		draw_rect(frame, Color(tint, TINT_ALPHA))
	draw_rect(frame.grow(-0.5), FOCUS_COLOR if has_focus() else BORDER_COLOR, false, 1.0)
	if marked:
		draw_rect(Rect2(3, size.y - 3, size.x - 6, 1), FOCUS_COLOR)
	if icon.is_empty():
		return
	var icon_size: Vector2 = PixelIcons.size_of(icon) * ICON_SCALE
	var origin: Vector2 = ((size - icon_size) / 2.0).floor()
	draw_set_transform(origin, 0.0, Vector2.ONE * ICON_SCALE)
	PixelBitmap.paint_outlined(self, icon, Vector2.ZERO, icon_color, OUTLINE_COLOR)
	draw_set_transform(Vector2.ZERO)
