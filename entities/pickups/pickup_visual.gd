@tool
class_name PickupVisual
extends Node2D
## Placeholder de un pickup dibujado con PixelIcons: sombra, ícono con borde y un vaivén leve.

const COLORS: Dictionary[PickupData.Kind, Color] = {
	PickupData.Kind.COIN: Color("f2c14e"),
	PickupData.Kind.HEART: Color("e0464e"),
	PickupData.Kind.BOMB: Color("8a8299"),
	PickupData.Kind.KEY: Color("e8d27a"),
}
const OUTLINE_COLOR: Color = Color("120c16")
const BOB_SPEED: float = 3.0

@export var kind: PickupData.Kind = PickupData.Kind.COIN:
	set(value):
		kind = value
		queue_redraw()

var _time: float = 0.0


func main_color() -> Color:
	return COLORS[kind]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	var icon: PackedStringArray = _icon()
	var bob: float = -1.0 if sin(_time * BOB_SPEED) > 0.0 else 0.0
	var origin: Vector2 = (-PixelIcons.size_of(icon) * 0.5).round() + Vector2(0, bob - 1.0)
	PixelBitmap.paint_outlined(self, icon, origin, main_color(), OUTLINE_COLOR)
	if kind == PickupData.Kind.COIN or kind == PickupData.Kind.BOMB:
		draw_rect(Rect2(origin + Vector2(1, 1), Vector2.ONE), Color(1, 1, 1, 0.8))


func _icon() -> PackedStringArray:
	match kind:
		PickupData.Kind.HEART:
			return PixelIcons.HEART
		PickupData.Kind.BOMB:
			return PixelIcons.BOMB
		PickupData.Kind.KEY:
			return PixelIcons.KEY
	return PixelIcons.COIN
