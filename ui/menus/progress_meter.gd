class_name ProgressMeter
extends Control
## Barra de progreso de una partida (0 a 1), con borde y relleno del color de las chispas; llena,
## dorada.

const EMPTY_COLOR: Color = Color("2a2232")
const FILL_COLOR: Color = MenuBuilder.SPARK_COLOR
const FULL_COLOR: Color = MenuBuilder.TITLE_COLOR

var value: float = 0.0:
	set(new_value):
		value = clampf(new_value, 0.0, 1.0)
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(72, 4)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area.grow(1.0), MenuBuilder.OUTLINE_COLOR)
	draw_rect(area, EMPTY_COLOR)
	if value > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(maxf(1.0, size.x * value), size.y)), FULL_COLOR if value >= 1.0 else FILL_COLOR)
