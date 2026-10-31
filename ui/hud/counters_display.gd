@tool
class_name CountersDisplay
extends Control
## Monedas, bombas y llaves del HUD: ícono y número de 2 cifras, en una fila.

const ENTRY_WIDTH: int = 18
## Espacio entre el ícono y el número.
const NUMBER_OFFSET: int = 7

@export var coin_color: Color = Color("f2c14e")
@export var bomb_color: Color = Color("8a8299")
@export var key_color: Color = Color("e8d27a")
@export var text_color: Color = Color("f2efe6")
@export var outline_color: Color = Color("120c16")
@export var coins: int = 0:
	set(value):
		coins = value
		queue_redraw()
@export var bombs: int = 1:
	set(value):
		bombs = value
		queue_redraw()
@export var keys: int = 0:
	set(value):
		keys = value
		queue_redraw()


func set_values(coin_count: int, bomb_count: int, key_count: int) -> void:
	coins = coin_count
	bombs = bomb_count
	keys = key_count


func _draw() -> void:
	_draw_entry(0, PixelIcons.COIN, coin_color, coins)
	_draw_entry(1, PixelIcons.BOMB, bomb_color, bombs)
	_draw_entry(2, PixelIcons.KEY, key_color, keys)


func _draw_entry(index: int, icon: PackedStringArray, color: Color, value: int) -> void:
	var origin := Vector2(index * ENTRY_WIDTH, 0)
	PixelBitmap.paint_outlined(self, icon, origin, color, outline_color)
	PixelIcons.paint_number(self, value, 2, origin + Vector2(NUMBER_OFFSET, 0), text_color, outline_color)
