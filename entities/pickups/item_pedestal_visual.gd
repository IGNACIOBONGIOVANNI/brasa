@tool
class_name ItemPedestalVisual
extends Node2D
## Placeholder del pedestal: bloque de piedra, el ícono del item flotando arriba con la letra de su
## calidad encima (S y S++ con un halo; S++ además con chispitas) y, si tiene precio, una moneda con
## el número debajo.

const STONE_COLOR: Color = Color("6b6278")
const STONE_TOP_COLOR: Color = Color("847a92")
const OUTLINE_COLOR: Color = Color("120c16")
const PRICE_COLOR: Color = Color("f2efe6")
const COIN_COLOR: Color = Color("f2c14e")
const BOB_SPEED: float = 2.5
## Separación entre la letra de calidad y el ícono.
const QUALITY_GAP: float = 2.0
const GLOW_RADIUS: float = 7.0
const GLOW_FILL_ALPHA: float = 0.12
const SPARKLE_COUNT: int = 4
const SPARKLE_RADIUS: float = 10.0
const SPARKLE_SPEED: float = 1.6

var _item: ItemData
var _price: int = 0
var _time: float = 0.0


func set_item(item: ItemData, price: int) -> void:
	_item = item
	_price = price
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 5), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(-6, -3, 12, 8), OUTLINE_COLOR)
	draw_rect(Rect2(-5, -2, 10, 6), STONE_COLOR)
	draw_rect(Rect2(-5, -2, 10, 2), STONE_TOP_COLOR)
	if _item != null:
		var icon: PackedStringArray = _item.get_icon()
		if not icon.is_empty():
			var bob: float = roundf(sin(_time * BOB_SPEED) * 1.5)
			var origin: Vector2 = (-PixelIcons.size_of(icon) * 0.5).round() + Vector2(0, -12 + bob)
			_draw_quality_glow(Vector2(0, -12 + bob))
			PixelBitmap.paint_outlined(self, icon, origin, _item.get_icon_color(), OUTLINE_COLOR)
			var letters: PackedStringArray = PixelIcons.word(_item.quality_name())
			var letters_size: Vector2 = PixelIcons.size_of(letters)
			var letters_origin := Vector2(roundf(-letters_size.x * 0.5), origin.y - QUALITY_GAP - letters_size.y)
			PixelBitmap.paint_outlined(self, letters, letters_origin, _item.quality_color(), OUTLINE_COLOR)
	if _price > 0:
		var digits: int = str(_price).length()
		var width: float = PixelIcons.size_of(PixelIcons.COIN).x + 2.0 + digits * (PixelIcons.DIGIT_WIDTH + 1) - 1
		var origin := Vector2(roundf(-width * 0.5), 8)
		PixelBitmap.paint_outlined(self, PixelIcons.COIN, origin, COIN_COLOR, OUTLINE_COLOR)
		PixelIcons.paint_number(self, _price, digits, origin + Vector2(PixelIcons.size_of(PixelIcons.COIN).x + 2, 0),
				PRICE_COLOR, OUTLINE_COLOR)


## S y S++ tienen un aro de su color que late detrás del ícono; S++ además tiene chispitas que giran
## y titilan.
func _draw_quality_glow(center: Vector2) -> void:
	if _item.quality < ItemData.Quality.S:
		return
	var color: Color = _item.quality_color()
	var pulse: float = 0.6 + 0.4 * sin(_time * 3.0)
	draw_circle(center, GLOW_RADIUS, Color(color, GLOW_FILL_ALPHA))
	draw_arc(center, GLOW_RADIUS, 0.0, TAU, 24, Color(color, pulse), 1.0)
	if _item.quality < ItemData.Quality.S_PLUS_PLUS:
		return
	for i: int in SPARKLE_COUNT:
		var angle: float = _time * SPARKLE_SPEED + TAU * i / SPARKLE_COUNT
		var at: Vector2 = (center + Vector2.from_angle(angle) * SPARKLE_RADIUS).round()
		var lit: bool = int(_time * 4.0 + i) % 2 == 0
		draw_rect(Rect2(at, Vector2.ONE), Color.WHITE if lit else color)
		if lit:
			draw_rect(Rect2(at + Vector2(-1, 0), Vector2(3, 1)), Color(color, 0.6))
			draw_rect(Rect2(at + Vector2(0, -1), Vector2(1, 3)), Color(color, 0.6))
