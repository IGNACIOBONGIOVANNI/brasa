@tool
class_name WeaponDisplay
extends Control
## Arma equipada en el HUD (abajo a la derecha): su ícono, la munición (cargador / reserva, o el
## símbolo de infinito) y una barra mientras recarga. Se redibuja cada frame porque la munición
## cambia con cada disparo.

const OUTLINE_COLOR: Color = Color("120c16")
const TEXT_COLOR: Color = Color("f2efe6")
const LOW_COLOR: Color = Color("e0464e")
const RELOAD_COLOR: Color = Color("e8c170")
const GAP: float = 3.0

var _slot: WeaponSlot


func set_slot(slot: WeaponSlot) -> void:
	_slot = slot
	queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if _slot == null:
		return
	var icon: PackedStringArray = _slot.weapon.display_icon()
	PixelBitmap.paint_outlined(self, icon, Vector2.ZERO, _slot.weapon.icon_color, OUTLINE_COLOR)
	var x: float = PixelIcons.size_of(icon).x + GAP
	if _slot.is_infinite() and not _slot.has_magazine():
		PixelBitmap.paint_outlined(self, PixelIcons.INFINITY, Vector2(x, 0), TEXT_COLOR, OUTLINE_COLOR)
	else:
		var loaded: int = _slot.loaded()
		var color: Color = LOW_COLOR if loaded == 0 else TEXT_COLOR
		x += PixelIcons.paint_number(self, loaded, 2, Vector2(x, 0), color, OUTLINE_COLOR) + 1.0
		if _slot.has_magazine():
			PixelBitmap.paint_outlined(self, PixelIcons.SLASH, Vector2(x, 0), TEXT_COLOR, OUTLINE_COLOR)
			x += 4.0
			if _slot.is_infinite():
				PixelBitmap.paint_outlined(self, PixelIcons.INFINITY, Vector2(x, 0), TEXT_COLOR, OUTLINE_COLOR)
			else:
				PixelIcons.paint_number(self, _slot.reserve, 2, Vector2(x, 0), TEXT_COLOR, OUTLINE_COLOR)
	if _slot.is_reloading():
		var width: float = PixelIcons.size_of(icon).x
		draw_rect(Rect2(0, 7, width, 2).grow(1.0), OUTLINE_COLOR)
		draw_rect(Rect2(0, 7, width * _slot.reload_progress(), 2), RELOAD_COLOR)
